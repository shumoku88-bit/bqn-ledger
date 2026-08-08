#!/usr/bin/env bash
set -euo pipefail

# tools/main-ui.sh — daily report entry / small command hub
#
# Report requests come from canonical report.toml plus canonical Household
# evidence. The selector still consumes generated section keys and cache files;
# it never parses report headings or owns accounting coordinates.

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/tools/lib/system-defaults.sh"
source "$ROOT_DIR/tools/lib/theme.sh"
source "$ROOT_DIR/tools/lib/ui-preferences.sh"

usage() {
  cat <<'EOF'
Usage:
  tools/main-ui.sh [--base <dir>] [--domain <commodity>] [--latest YYYY-MM-DD] [command]

Commands:
  select, --select     Open fzf/gum section selector (default)
  report, all          Show the full report
  envelopes            Show Envelope & Backing
  balances             Show Account Balances
  balance-sheet        Show Balance Sheet
  profit-and-loss      Show Profit and Loss
  recent               Show Recent Journal
  planned              Show Planned Payments
  cycle-accounts       Show Current-cycle Accounts
  cycle-comparison     Show Cycle Comparison
  monthly-accounts     Show Monthly Accounts
  daily-flow           Show Daily Flow
  daily-target         Show Daily Target
  issues               Show Issues
  add, actions         Launch tools/add-ui.sh

If --domain is omitted, a single canonical Actual domain is selected. Multiple
admitted domains require an explicit --domain. --latest is primarily useful for
deterministic cache generation and tests; normal operation uses the local day.
EOF
}

base_dir="${LEDGER_DATA_DIR:-$(get_default_base_dir)}"
domain_override="${REPORT_DOMAIN:-}"
latest_override=""
cmd="select"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      [[ $# -ge 2 ]] || { echo "Error: --base requires a directory" >&2; usage >&2; exit 1; }
      base_dir="$2"
      shift 2
      ;;
    --domain)
      [[ $# -ge 2 ]] || { echo "Error: --domain requires a commodity" >&2; usage >&2; exit 1; }
      domain_override="$2"
      shift 2
      ;;
    --latest)
      [[ $# -ge 2 ]] || { echo "Error: --latest requires YYYY-MM-DD" >&2; usage >&2; exit 1; }
      latest_override="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      cmd="$1"
      shift
      [[ $# -eq 0 ]] || { echo "Error: Unexpected argument(s): $*" >&2; usage >&2; exit 1; }
      ;;
  esac
done

IS_TTY=0
if [[ -t 0 && -t 1 ]]; then IS_TTY=1; fi

pager_display() {
  if [[ "$IS_TTY" -eq 1 ]] && command -v less >/dev/null 2>&1; then
    less -SRFX
  else
    cat
  fi
}

base_abs=""
report_domain=""
current_requests_path=""
cleanup_current_requests() {
  [[ -z "$current_requests_path" ]] || rm -f "$current_requests_path"
}
trap cleanup_current_requests EXIT

ensure_report_context() {
  [[ -n "$base_abs" ]] && return 0
  ensure_canonical_report_base "$base_dir"
  base_abs="$(cd "$base_dir" && pwd)"
  if [[ -n "$domain_override" ]]; then
    report_domain="$(bqn "$ROOT_DIR/src/application/report_domain_cli.bqn" "$base_abs" "$domain_override")"
  else
    report_domain="$(bqn "$ROOT_DIR/src/application/report_domain_cli.bqn" "$base_abs")"
  fi

  local presentation_output negative_color
  if ! presentation_output="$(bqn "$ROOT_DIR/src/application/report_presentation_cli.bqn" "$base_abs" 2>&1)"; then
    printf '%s\n' "$presentation_output" >&2
    return 1
  fi
  negative_color="$(awk -F'\t' '$1 == "negative_color" { print $2 }' <<<"$presentation_output")"
  [[ -n "$negative_color" ]] || {
    echo "Error: canonical Report negative color is unavailable" >&2
    return 1
  }
  export REPORT_NEGATIVE_COLOR="$negative_color"
}

ensure_current_requests() {
  [[ -n "$current_requests_path" ]] && return 0
  ensure_report_context
  local candidate args
  candidate="$(mktemp "${TMPDIR:-/tmp}/bqn-ledger-current-requests.XXXXXX")"
  args=("$base_abs" "$report_domain" human)
  [[ -z "$latest_override" ]] || args+=("$latest_override")
  if ! bqn "$ROOT_DIR/src/application/current_report_profile_cli.bqn" "${args[@]}" >"$candidate"; then
    cat "$candidate" >&2
    rm -f "$candidate"
    return 1
  fi
  current_requests_path="$candidate"
}

show_full_report() {
  ensure_report_context
  local args
  args=("$base_abs" "$report_domain" human)
  [[ -z "$latest_override" ]] || args+=("$latest_override")
  "$ROOT_DIR/tools/report-all" "${args[@]}" | "$ROOT_DIR/tools/lib/color-filter" | pager_display
}

section_list() {
  "$ROOT_DIR/tools/report-section-metadata" | awk -F'\t' 'NR > 1 { print $1 "\t" $2 }'
  printf 'actions\t→ 仕訳追加・取消\n'
}

show_section_direct() {
  local key="$1" out err status row
  ensure_current_requests
  row="$(awk -F'\t' -v key="$key" '$1 == key { print; found++ } END { if (found != 1) exit 1 }' "$current_requests_path")" \
    || { echo "Error: current report row is unavailable: $key" >&2; return 1; }
  IFS=$'\t' read -r -a fields <<<"$row"
  out="$(mktemp)"
  err="$(mktemp)"
  trap 'rm -f "$out" "$err"' RETURN
  if "$ROOT_DIR/tools/report" "$base_abs" "${fields[@]}" >"$out" 2>"$err"; then
    cat "$out" | "$ROOT_DIR/tools/lib/color-filter" | pager_display
  else
    status=$?
    [[ ! -s "$out" ]] || cat "$out" >&2
    [[ ! -s "$err" ]] || cat "$err" >&2
    return "$status"
  fi
}

browse_sections_interactive() {
  local cache_dir="${1:-}"
  local keys=() labels=() count=0 i current=0 key label char esc_seq

  while IFS=$'\t' read -r key label; do
    [[ -n "$key" && "$key" != "actions" ]] || continue
    count=$((count + 1))
    keys+=("$key")
    labels+=("$label")
  done < <(section_list)
  [[ $count -gt 0 ]] || return 1

  while true; do
    clear 2>/dev/null || printf '\033[2J\033[H'
    key="${keys[$current]}"
    label="${labels[$current]}"
    printf '==============================================================================--\n' >&2
    printf ' [%d/%d] %s (%s)\n [←/p: 前へ]  [→/n: 次へ]  [Enter: 全画面表示]  [q: メニューへ戻る]\n' "$((current+1))" "$count" "$label" "$key" >&2
    printf '==============================================================================--\n\n' >&2

    if [[ -f "$cache_dir/$key.txt" ]]; then
      cat "$cache_dir/$key.txt" | COLOR_FORCE=1 "$ROOT_DIR/tools/lib/color-filter" >&2
    else
      show_section_direct "$key" >&2
    fi

    if ! IFS= read -rsn1 char </dev/tty; then break; fi
    if [[ "$char" == $'\x1b' ]]; then
      read -rsn2 -t 0.1 esc_seq </dev/tty || esc_seq=""
      case "$esc_seq" in
        "[C"|"[B") current=$(( (current + 1) % count )) ;;
        "[D"|"[A") current=$(( (current - 1 + count) % count )) ;;
      esac
    elif [[ "$char" == "n" || "$char" == "N" || "$char" == "j" ]]; then
      current=$(( (current + 1) % count ))
    elif [[ "$char" == "p" || "$char" == "P" || "$char" == "k" ]]; then
      current=$(( (current - 1 + count) % count ))
    elif [[ "$char" == "q" || "$char" == "Q" ]]; then
      return 0
    elif [[ "$char" == "" ]]; then
      printf '%s\t%s\n' "$key" "$label"
      return 0
    fi
  done
}

select_section() {
  local cache_dir="${1:-}"
  local selector
  selector="$(bl_selector_preference)" || return
  if [[ "${BL_UI_MODE:-}" == "minimal" ]]; then
    selector="plain"
  elif [[ "$IS_TTY" -eq 1 && "$selector" == "auto" ]]; then
    if command -v fzf >/dev/null 2>&1; then selector="fzf"
    elif command -v gum >/dev/null 2>&1; then selector="gum"
    else selector="plain"
    fi
  fi

  if [[ "$IS_TTY" -eq 1 && "$selector" == "fzf" ]]; then
    command -v fzf >/dev/null 2>&1 || { echo "Error: BL_SELECTOR=fzf but fzf is not installed" >&2; return 2; }
    local preview_win
    preview_win="$(bl_fzf_preview_window)" || return
    if [[ -n "$cache_dir" ]]; then
      section_list | fzf --prompt='section> ' --delimiter=$'\t' --with-nth=2.. --height=80% --reverse --exit-0 --ansi \
        --preview "BL_THEME='${BL_THEME:-nord}' COLOR_FORCE=1 '$ROOT_DIR/tools/command-hub-preview' '$cache_dir' {1} | BL_THEME='${BL_THEME:-nord}' COLOR_FORCE=1 '$ROOT_DIR/tools/lib/color-filter'" \
        --preview-window "$preview_win"
    else
      section_list | fzf --prompt='section> ' --delimiter=$'\t' --with-nth=2.. --height=80% --reverse --exit-0
    fi
  elif [[ "$IS_TTY" -eq 1 && "$selector" == "gum" ]]; then
    command -v gum >/dev/null 2>&1 || { echo "Error: BL_SELECTOR=gum but gum is not installed" >&2; return 2; }
    section_list | gum filter "${GUM_FILTER_ARGS[@]}" --placeholder='section / category'
  else
    local keys=() labels=() count=0 i sel_idx key label
    while IFS=$'\t' read -r key label; do
      [[ -n "$key" ]] || continue
      count=$((count + 1))
      keys+=("$key")
      labels+=("$label")
    done < <(section_list)

    printf '\n=== レポート / アクション選択 ===\n' >&2
    printf '  v) ★ 矢印キーで順番にプレビュー閲覧 ([←/→] キー切替)\n' >&2
    for ((i=0; i<count; i++)); do
      printf ' %2d) %s (%s)\n' "$((i+1))" "${labels[i]}" "${keys[i]}" >&2
    done
    printf '  0) キャンセル\n' >&2
    printf '選択 [v/0-%d]> ' "$count" >&2
    read -r sel_idx
    if [[ "$sel_idx" == "v" || "$sel_idx" == "V" ]]; then
      browse_sections_interactive "$cache_dir"
    elif [[ "$sel_idx" =~ ^[0-9]+$ ]] && (( sel_idx >= 1 && sel_idx <= count )); then
      printf '%s\t%s\n' "${keys[sel_idx-1]}" "${labels[sel_idx-1]}"
    else
      for ((i=0; i<count; i++)); do
        if [[ "${keys[i]}" == "$sel_idx" ]]; then
          printf '%s\t%s\n' "${keys[i]}" "${labels[i]}"
          break
        fi
      done
    fi
  fi
}

prepare_cache() {
  ensure_report_context
  local cache_date sanitized_path cache_dir max_src_mtime f mtime key_manifest timestamp_file cache_mtime
  cache_date="${latest_override:-$(date +%Y-%m-%d)}"
  sanitized_path="${base_abs//\//_}"
  cache_dir="${TMPDIR:-/tmp}/bqn-ledger-cache-${sanitized_path}-${report_domain}-${cache_date}"
  mkdir -p "$cache_dir"

  local src_files=(
    "$base_abs/accounts.journal" "$base_abs/actual.journal" "$base_abs/plan.journal" "$base_abs/budget.journal"
    "$base_abs/budget.toml" "$base_abs/household.toml" "$base_abs/report.toml" "$base_abs/issues.tsv"
  )
  while IFS= read -r -d '' f; do src_files+=("$f"); done < <(find "$ROOT_DIR/src" -name "*.bqn" -print0)
  [[ ! -f "$ROOT_DIR/config/report_labels.tsv" ]] || src_files+=("$ROOT_DIR/config/report_labels.tsv")

  max_src_mtime=0
  for f in "${src_files[@]}"; do
    if [[ -f "$f" ]]; then
      if stat -f %m "$f" >/dev/null 2>&1; then mtime=$(stat -f %m "$f"); else mtime=$(stat -c %Y "$f"); fi
      (( mtime <= max_src_mtime )) || max_src_mtime=$mtime
    fi
  done

  local cache_ok=0 cache_key_count cache_has_all key
  timestamp_file="$cache_dir/.cache-timestamp"
  key_manifest="$cache_dir/.section-keys"
  if [[ -f "$timestamp_file" && -f "$key_manifest" && ! -f "$cache_dir/.cache-refreshing" && ! -f "$cache_dir/.cache-error" ]]; then
    cache_mtime=$(cat "$timestamp_file" 2>/dev/null || echo 0)
    if (( cache_mtime >= max_src_mtime )); then
      cache_ok=1; cache_key_count=0; cache_has_all=0
      while IFS= read -r key; do
        cache_key_count=$((cache_key_count + 1))
        [[ "$key" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { cache_ok=0; break; }
        [[ "$key" == "all" ]] && cache_has_all=1
        [[ -f "$cache_dir/$key.txt" ]] || { cache_ok=0; break; }
      done <"$key_manifest"
      [[ "$cache_key_count" -gt 0 && "$cache_has_all" -eq 1 ]] || cache_ok=0
    fi
  fi

  if [[ "$cache_ok" -ne 1 ]]; then
    local refresh_mode="${COMMAND_HUB_CACHE_REFRESH_MODE:-}"
    if [[ -z "$refresh_mode" ]]; then
      if [[ "$IS_TTY" -eq 1 ]]; then refresh_mode="background"; else refresh_mode="synchronous"; fi
    fi
    local refresh_args=("$base_abs" "$cache_dir" "$max_src_mtime" "$report_domain")
    [[ -z "$latest_override" ]] || refresh_args+=("$latest_override")
    case "$refresh_mode" in
      background)
        ( trap '' HUP; exec "$ROOT_DIR/tools/command-hub-cache-refresh" "${refresh_args[@]}" ) </dev/null >"$cache_dir/.refresh.log" 2>&1 &
        for _ in 1 2 3 4 5 6 7 8 9 10; do
          [[ -f "$cache_dir/.cache-refreshing" || -f "$cache_dir/.cache-error" ]] && break
          sleep 0.01
        done
        ;;
      synchronous)
        "$ROOT_DIR/tools/command-hub-cache-refresh" "${refresh_args[@]}" || { echo "Failed to generate report cache" >&2; exit 1; }
        ;;
      *) echo "Error: invalid COMMAND_HUB_CACHE_REFRESH_MODE: $refresh_mode" >&2; exit 2 ;;
    esac
  fi
  printf '%s\n' "$cache_dir"
}

case "$cmd" in
  report|all)
    show_full_report
    ;;
  add|actions)
    exec "$ROOT_DIR/tools/add-ui.sh" --base "$base_dir"
    ;;
  select|--select|'')
    ensure_report_context
    cache_dir="$(prepare_cache)"
    selection="$(select_section "$cache_dir" || true)"
    [[ -n "$selection" ]] || { echo "Cancelled." >&2; exit 0; }
    key="${selection%%$'\t'*}"
    case "$key" in
      actions) exec "$ROOT_DIR/tools/add-ui.sh" --base "$base_dir" ;;
      all) show_full_report ;;
      *)
        if [[ ! -f "$cache_dir/.cache-refreshing" && ! -f "$cache_dir/.cache-error" && -f "$cache_dir/$key.txt" ]]; then
          cat "$cache_dir/$key.txt" | "$ROOT_DIR/tools/lib/color-filter" | pager_display
        else
          show_section_direct "$key"
        fi
        ;;
    esac
    ;;
  *)
    show_section_direct "$cmd"
    ;;
esac
