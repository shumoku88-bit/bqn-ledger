#!/usr/bin/env bash
set -euo pipefail

# tools/plan-finish-replenish-ui.sh
#
# Interactive helper for a common daily workflow:
#   1. finish one open plan into journal.tsv
#   2. optionally replenish the future plan shelf from the finished plan
#
# The low-level editor commands stay small:
#   tools/edit plan finish  -> append journal actual row only
#   tools/edit plan add     -> append the next planned row
#
# This script owns only the follow-up interaction.

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck source=tools/lib/system-defaults.sh
source "$ROOT_DIR/tools/lib/system-defaults.sh"

usage() {
  cat <<'EOF'
Usage:
  tools/plan-finish-replenish-ui.sh [--base <dir>] [--check]

Finish one open plan, then optionally create a follow-up plan from it.

Replenishment choices:
  - do nothing
  - create the next plan after the finished plan date
  - extend after the latest related open plan

The follow-up plan is appended via `tools/edit plan add`.
The finished plan's plan_id is never copied.
EOF
}

shout() { printf '%s\n' "$*" >&2; }

base_dir="${LEDGER_DATA_DIR:-$(get_default_base_dir)}"
preflight=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      if [[ $# -lt 2 ]]; then
        shout "Error: --base requires a directory"
        usage
        exit 1
      fi
      base_dir="$2"
      shift 2
      ;;
    --check) preflight=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      shout "Error: Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

ensure_ledger_report_base "$base_dir"

select_line() {
  local prompt="$1"
  local -a lines=()
  local _line
  while IFS= read -r _line; do lines+=("$_line"); done

  if [[ ${#lines[@]} -eq 0 ]]; then
    shout "No candidates for: $prompt"
    return 1
  fi

  if command -v fzf >/dev/null 2>&1; then
    printf '%s\n' "${lines[@]}" |
      fzf --prompt="$prompt> " --height=40% --reverse --select-1 --exit-0
  elif command -v gum >/dev/null 2>&1; then
    printf '%s\n' "${lines[@]}" | gum filter --placeholder="$prompt"
  else
    shout "$prompt"
    local idx=1 ans
    for line in "${lines[@]}"; do
      printf '  %2d) %s\n' "$idx" "$line" >&2
      idx=$((idx + 1))
    done
    printf '> ' >&2
    read -r ans </dev/tty
    if [[ "$ans" =~ ^[0-9]+$ ]] && (( ans >= 1 && ans <= ${#lines[@]} )); then
      printf '%s\n' "${lines[$((ans - 1))]}"
    else
      printf '%s\n' "$ans"
    fi
  fi
}

read_tty() {
  local prompt="$1" default="${2:-}" ans
  if command -v gum >/dev/null 2>&1 && [[ -r /dev/tty ]]; then
    if [[ -n "$default" ]]; then
      ans="$(gum input --prompt "${prompt}: " --value "$default" </dev/tty || true)"
    else
      ans="$(gum input --prompt "${prompt}: " </dev/tty || true)"
    fi
  else
    if [[ -n "$default" ]]; then
      printf '%s [%s]: ' "$prompt" "$default" >&2
    else
      printf '%s: ' "$prompt" >&2
    fi
    read -r ans </dev/tty
  fi

  if [[ -z "$ans" && -n "$default" ]]; then
    printf '%s\n' "$default"
  else
    printf '%s\n' "$ans"
  fi
}

ask_yes_no() {
  local prompt="$1" default="${2:-N}" ans
  ans="$(read_tty "$prompt (y/N)" "$default")"
  case "$ans" in
    y|Y|yes|YES|Yes) return 0 ;;
    *) return 1 ;;
  esac
}

add_months() {
  local date_val="$1" months="$2"
  if date -j -v+"$months"m -f %Y-%m-%d "$date_val" +%Y-%m-%d >/dev/null 2>&1; then
    date -j -v+"$months"m -f %Y-%m-%d "$date_val" +%Y-%m-%d
  elif date -d "$date_val +$months month" +%Y-%m-%d >/dev/null 2>&1; then
    date -d "$date_val +$months month" +%Y-%m-%d
  else
    return 1
  fi
}

plan_series_from_id() {
  local pid="$1"
  if [[ "$pid" =~ ^plan-[0-9]{4}-[0-9]{2}-[0-9]{2}-(.+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  else
    printf '\n'
  fi
}

load_plan_rows() {
  "$ROOT_DIR/tools/edit" --base "$base_dir" plan list --format tsv
}

field() {
  local n="$1" line="$2"
  printf '%s\n' "$line" | cut -f"$n"
}

plan_file_path() {
  printf '%s/%s\n' "$base_dir" "${DEFAULT_PLAN_FILE:-plan.tsv}"
}

meta_value_from_tsv_line() {
  local key="$1" line="$2" token
  IFS=$'\t' read -r -a fields <<< "$line"
  for token in "${fields[@]:5}"; do
    if [[ "$token" == "$key="* ]]; then
      printf '%s\n' "${token#*=}"
      return 0
    fi
  done
  printf '\n'
}

plan_id_from_tsv_line() {
  meta_value_from_tsv_line plan_id "$1"
}

raw_plan_line_for_row() {
  local row="$1" pid date_v memo_v from_v to_v amount_v raw raw_pid
  pid="$(field 2 "$row")"
  date_v="$(field 3 "$row")"
  memo_v="$(field 4 "$row")"
  from_v="$(field 5 "$row")"
  to_v="$(field 6 "$row")"
  amount_v="$(field 7 "$row")"

  while IFS= read -r raw || [[ -n "$raw" ]]; do
    [[ -z "$raw" || "${raw:0:1}" == "#" || "${raw:0:1}" == "\\" ]] && continue
    raw_pid="$(plan_id_from_tsv_line "$raw")"
    if [[ -n "$pid" && "$raw_pid" == "$pid" ]]; then
      printf '%s\n' "$raw"
      return 0
    fi
    IFS=$'\t' read -r -a raw_fields <<< "$raw"
    if [[ -z "$pid" && \
          "${raw_fields[0]:-}" == "$date_v" && \
          "${raw_fields[1]:-}" == "$memo_v" && \
          "${raw_fields[2]:-}" == "$from_v" && \
          "${raw_fields[3]:-}" == "$to_v" && \
          "${raw_fields[4]:-}" == "$amount_v" ]]; then
      printf '%s\n' "$raw"
      return 0
    fi
  done < "$(plan_file_path)"
  printf '\n'
}

related_key_for_row() {
  local row="$1" raw pid meta_series pid_series
  raw="$(raw_plan_line_for_row "$row")"
  meta_series="$(meta_value_from_tsv_line series "$raw")"
  if [[ -n "$meta_series" ]]; then
    printf 'series:%s\n' "$meta_series"
    return 0
  fi
  pid="$(field 2 "$row")"
  pid_series="$(plan_series_from_id "$pid")"
  if [[ -n "$pid_series" ]]; then
    printf 'series:%s\n' "$pid_series"
    return 0
  fi
  printf 'exact:%s\t%s\t%s\t%s\n' "$(field 4 "$row")" "$(field 5 "$row")" "$(field 6 "$row")" "$(field 7 "$row")"
}

related_display_for_row() {
  local row="$1" pid
  pid="$(field 2 "$row")"
  [[ -z "$pid" ]] && pid="(missing)"
  printf '%s\t%s\t%s -> %s\t%s\t%s\n' \
    "$(field 3 "$row")" \
    "$(field 4 "$row")" \
    "$(field 5 "$row")" \
    "$(field 6 "$row")" \
    "$(field 7 "$row")" \
    "$pid"
}

if [[ "$preflight" -eq 1 ]]; then
  if [[ ! -x "$ROOT_DIR/tools/edit" ]]; then
    shout "FAIL tools/edit is not executable"
    exit 1
  fi
  if [[ "$(add_months 2026-02-10 1 || true)" != "2026-03-10" ]]; then
    shout "FAIL add_months portability check failed"
    exit 1
  fi
  if load_plan_rows >/dev/null; then
    printf 'OK plan finish replenish preflight passed\n'
    exit 0
  fi
  shout "FAIL plan list failed"
  exit 1
fi

plan_tsv_lines=()
while IFS= read -r _pl; do plan_tsv_lines+=("$_pl"); done < <(load_plan_rows)
if [[ ${#plan_tsv_lines[@]} -eq 0 ]]; then
  shout "No active plans found."
  exit 0
fi

display_lines=()
for line in "${plan_tsv_lines[@]}"; do
  display_lines+=("$(field 9 "$line")")
done

selected_display="$(printf '%s\n' "${display_lines[@]}" | select_line 'select plan to finish' || true)"
if [[ -z "$selected_display" ]]; then
  shout 'Cancelled.'
  exit 0
fi

selected_row=""
for line in "${plan_tsv_lines[@]}"; do
  if [[ "$(field 9 "$line")" == "$selected_display" ]]; then
    selected_row="$line"
    break
  fi
done
if [[ -z "$selected_row" ]]; then
  shout "Failed to match selected display: $selected_display"
  exit 1
fi

plan_number="$(field 1 "$selected_row")"
plan_id="$(field 2 "$selected_row")"
plan_date="$(field 3 "$selected_row")"
plan_memo="$(field 4 "$selected_row")"
plan_from="$(field 5 "$selected_row")"
plan_to="$(field 6 "$selected_row")"
plan_amount="$(field 7 "$selected_row")"
plan_series="$(related_key_for_row "$selected_row")"
if [[ "$plan_series" == series:* ]]; then
  plan_series="${plan_series#series:}"
else
  plan_series=""
fi

today="$(date +%Y-%m-%d)"
actual_date="$(read_tty 'Actual date YYYY-MM-DD' "$today")"

selector_args=()
if [[ -n "$plan_id" ]]; then
  selector_args=(--id "$plan_id")
else
  selector_args=(--index "$plan_number")
fi

finish_cmd=("$ROOT_DIR/tools/edit" --base "$base_dir" plan finish "${selector_args[@]}" --actual-date "$actual_date" --apply)
printf 'Running plan finish...\n' >&2
"${finish_cmd[@]}"

if ! ask_yes_no 'Create or extend a future plan from the finished plan?' 'N'; then
  exit 0
fi

fresh_plan_rows=()
while IFS= read -r _pl; do fresh_plan_rows+=("$_pl"); done < <(load_plan_rows)

selected_related_key="$(related_key_for_row "$selected_row")"
related_lines=()
latest_related_date=""
for line in "${fresh_plan_rows[@]}"; do
  date_f="$(field 3 "$line")"
  # "future" here means still later than the actual finish date. Do not infer fuzzy relations.
  [[ "$date_f" > "$actual_date" ]] || continue
  if [[ "$(related_key_for_row "$line")" == "$selected_related_key" ]]; then
    related_lines+=("$(related_display_for_row "$line")")
    if [[ -z "$latest_related_date" || "$date_f" > "$latest_related_date" ]]; then
      latest_related_date="$date_f"
    fi
  fi
done

if [[ ${#related_lines[@]} -gt 0 ]]; then
  printf 'Related active future plans:\n' >&2
  printf '  date\tmemo\tfrom -> to\tamount\tplan_id\n' >&2
  printf '  %s\n' "${related_lines[@]}" >&2
else
  printf 'No related active future plans found.\n' >&2
fi

replenish_choice="$(cat <<'EOF' | select_line 'replenish mode'
none	do nothing
next	create next after finished plan date
extend	extend after latest related active plan
EOF
)"
replenish_key="${replenish_choice%%$'\t'*}"
case "$replenish_key" in
  none|'') exit 0 ;;
  next) base_plan_date="$plan_date" ;;
  extend)
    if [[ -n "$latest_related_date" ]]; then
      base_plan_date="$latest_related_date"
    else
      base_plan_date="$plan_date"
    fi
    ;;
  *) shout "Unknown replenish mode: $replenish_key"; exit 1 ;;
esac

interval_choice="$(cat <<'EOF' | select_line 'next date rule'
1m	1 month after base date
2m	2 months after base date
manual	enter date manually
EOF
)"
interval_key="${interval_choice%%$'\t'*}"
case "$interval_key" in
  1m) suggested_date="$(add_months "$base_plan_date" 1 || true)" ;;
  2m) suggested_date="$(add_months "$base_plan_date" 2 || true)" ;;
  manual|'') suggested_date='' ;;
  *) shout "Unknown date rule: $interval_key"; exit 1 ;;
esac

next_date="$(read_tty 'Next plan date YYYY-MM-DD' "$suggested_date")"
next_memo="$(read_tty 'Memo/Description' "$plan_memo")"
next_from="$(read_tty 'From account' "$plan_from")"
next_to="$(read_tty 'To account' "$plan_to")"
next_amount="$(read_tty 'Amount' "$plan_amount")"

if [[ -z "$next_date" || -z "$next_from" || -z "$next_to" || -z "$next_amount" ]]; then
  shout 'Cancelled or missing required value.'
  exit 1
fi

candidate_duplicate=0
for line in "${fresh_plan_rows[@]}"; do
  if [[ "$(field 3 "$line")" == "$next_date" && \
        "$(field 4 "$line")" == "$next_memo" && \
        "$(field 5 "$line")" == "$next_from" && \
        "$(field 6 "$line")" == "$next_to" && \
        "$(field 7 "$line")" == "$next_amount" ]]; then
    candidate_duplicate=1
    printf 'Duplicate-looking active plan already exists:\n%s\n' "$(field 9 "$line")" >&2
    break
  fi
done

if [[ "$candidate_duplicate" -eq 1 ]]; then
  if ! ask_yes_no 'Add anyway?' 'N'; then
    exit 0
  fi
fi

plan_add_cmd=(
  "$ROOT_DIR/tools/edit" --base "$base_dir" plan add
  --date "$next_date"
  --memo "$next_memo"
  --from "$next_from"
  --to "$next_to"
  --amount "$next_amount"
)

if [[ -n "$plan_series" ]]; then
  plan_add_cmd+=(--meta "series=$plan_series")
fi

printf 'Creating follow-up plan...\n' >&2
exec "${plan_add_cmd[@]}"
