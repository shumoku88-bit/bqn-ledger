#!/usr/bin/env bash
set -euo pipefail

# tools/plan-finish-replenish-ui.sh
#
# Interactive helper for a common daily workflow:
#   1. finish one open plan into the configured native Journal
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
# shellcheck source=tools/lib/plan-finish-workflow.sh
source "$ROOT_DIR/tools/lib/plan-finish-workflow.sh"

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

choose_plan_list_scope() {
  cat <<'EOF' | select_line 'plan range'
upcoming	今日以降のOPEN予定
overdue	期限超過のOPEN予定
all	すべてのOPEN予定
EOF
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

load_plan_rows() {
  local scope="${1:-${plan_scope:-all}}"
  local args=(--format tsv)
  if [[ "$scope" != 'all' ]]; then
    args+=(--temporal "$scope" --as-of "$today")
  fi
  "$ROOT_DIR/tools/edit" --base "$base_dir" plan list "${args[@]}"
}

field() {
  local n="$1" line="$2"
  printf '%s\n' "$line" | cut -f"$n"
}

load_related_rows() {
  local selector=(--index "$plan_number")
  if [[ -n "$plan_id" ]]; then
    selector=(--id "$plan_id")
  fi
  "$ROOT_DIR/tools/edit" --base "$base_dir" plan related "${selector[@]}" --actual-date "$actual_date" --format tsv
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

today="$(date +%Y-%m-%d)"
plan_scope_line="$(choose_plan_list_scope || true)"
if [[ -z "$plan_scope_line" ]]; then
  shout 'Cancelled.'
  exit 0
fi
plan_scope="${plan_scope_line%%$'\t'*}"

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

selected_display="$(printf '%s\n' "${display_lines[@]}" | select_line "select $plan_scope plan to finish" || true)"
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
plan_series=""

actual_date="$(read_tty 'Actual date YYYY-MM-DD' "$today")"
actual_amount="$(read_tty 'Actual amount' "$plan_amount")"

selector_args=()
if [[ -n "$plan_id" ]]; then
  selector_args=(--id "$plan_id")
else
  selector_args=(--index "$plan_number")
fi

finish_cmd=("$ROOT_DIR/tools/edit" --base "$base_dir" plan finish "${selector_args[@]}" --actual-date "$actual_date" --actual-amount "$actual_amount" --apply)
printf 'Running plan finish...\n' >&2
"${finish_cmd[@]}"

finish_verify_status=0
plan_finish_require_applied "$ROOT_DIR/tools/edit" "$base_dir" "$plan_id" || finish_verify_status=$?
case "$finish_verify_status" in
  0) ;;
  130)
    shout 'Plan finish was not applied; skipping follow-up replenishment.'
    exit 130
    ;;
  *)
    shout "Failed to verify plan finish postcondition (status=$finish_verify_status)."
    exit "$finish_verify_status"
    ;;
esac

printf 'Checking execution-envelope budget linkage...\n' >&2
if ! "$ROOT_DIR/tools/edit" --base "$base_dir" plan budget-sync --id "$plan_id"; then
  shout "BUDGET_SYNC_PENDING: journal actual is committed; retry with: tools/edit --base '$base_dir' plan budget-sync --id '$plan_id'"
  exit 1
fi

if ! ask_yes_no 'Create or extend a future plan from the finished plan?' 'N'; then
  exit 0
fi

fresh_plan_rows=()
# Duplicate prevention must inspect every open plan, not only the selected picker range.
while IFS= read -r _pl; do fresh_plan_rows+=("$_pl"); done < <(load_plan_rows all)

related_lines=()
latest_related_date=""
related_out=()
while IFS= read -r _rel; do related_out+=("$_rel"); done < <(load_related_rows)
for line in "${related_out[@]}"; do
  kind="$(field 1 "$line")"
  case "$kind" in
    KEY)
      relation_kind="$(field 2 "$line")"
      relation_value="$(field 3 "$line")"
      if [[ "$relation_kind" == "series" ]]; then
        plan_series="$relation_value"
      fi
      ;;
    ROW)
      date_f="$(field 2 "$line")"
      related_lines+=("$(field 2 "$line")	$(field 3 "$line")	$(field 4 "$line") -> $(field 5 "$line")	$(field 6 "$line")	$(field 7 "$line")")
      if [[ -z "$latest_related_date" || "$date_f" > "$latest_related_date" ]]; then
        latest_related_date="$date_f"
      fi
      ;;
  esac
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
