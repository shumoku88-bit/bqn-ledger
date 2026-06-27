#!/usr/bin/env bash
set -euo pipefail

# tools/main-ui.sh — daily report entry / small command hub
#
# Default path must be useful for daily browsing:
#   tools/main-ui.sh  -> open the lightweight section selector
# Full report output remains available through `report` / `all`.
#
# Selector-based section extraction uses report.bqn --list-sections for marker mapping,
# so section headers can change in BQN without breaking menu browsing.

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

usage() {
  cat <<'EOF'
Usage:
  tools/main-ui.sh [--base <dir>] [command]

Commands:
  select, --select     Open fzf/gum section selector (default)
  report, all          Show the full report
  snapshot             Show Snapshot section
  envelopes            Show Envelope & Budget section
  outlook              Show Outlook Dashboard section
  cycle                Show Current Cycle Summary section
  ytd                  Show YTD Summary section
  balances             Show Account Balances section
  trial-balance        Show Trial Balance section
  recent               Show Recent Journal section
  planned              Show Planned Payments section
  daily-trend          Show Daily Trend section
  check                Show Readiness Check section
  actual-comparison    Show Actual Comparison section
  debug                Show Debug & Provenance section
  add, actions         Launch tools/add-ui.sh

Default behavior intentionally opens the lightweight selector.
EOF
}

base_dir="${LEDGER_DATA_DIR:-$(get_default_base_dir)}"
cmd="select"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      if [[ $# -lt 2 ]]; then
        echo "Error: --base requires a directory" >&2
        usage >&2
        exit 1
      fi
      base_dir="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      cmd="$1"
      shift
      if [[ $# -gt 0 ]]; then
        echo "Error: Unexpected argument(s): $*" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done
# Record whether both stdin and stdout are connected to a terminal at startup.
# This preserves the interactive check state even when we execute select_section
# inside a command substitution (which redirects stdout and makes [[ -t 1 ]] false).
IS_TTY=0
if [[ -t 0 && -t 1 ]]; then
  IS_TTY=1
fi

show_full_report() {
  ensure_ledger_report_base "$base_dir"
  "$ROOT_DIR/tools/report" "$base_dir" --no-color | "$ROOT_DIR/tools/lib/color-filter"
}

section_list() {
  cat <<'EOF'
snapshot	全体サマリ
envelopes	封筒・予算残高
outlook	見通し・日割り
cycle	今サイクル集計
ytd	年初来サマリ
balances	口座残高一覧
trial-balance	試算表
recent	直近の取引
planned	予定支払い
daily-trend	日割り推移
check	データチェック
actual-comparison	前期比較
debug	デバッグ
all	全セクション
actions	→ 仕訳追加・取消
EOF
}

show_section_direct() {
  local key="$1" out err status
  out="$(mktemp)"
  err="$(mktemp)"
  trap 'rm -f "$out" "$err"' RETURN
  if "$ROOT_DIR/tools/report" "$base_dir" --section "$key" --no-color >"$out" 2>"$err"; then
    cat "$out" | "$ROOT_DIR/tools/lib/color-filter"
  else
    status=$?
    if [[ -s "$out" ]]; then cat "$out" >&2; fi
    if [[ -s "$err" ]]; then cat "$err" >&2; fi
    return "$status"
  fi
}

select_section() {
  local cache_dir="${1:-}"
  if command -v fzf >/dev/null 2>&1 && [[ "$IS_TTY" -eq 1 ]]; then
    if [[ -n "$cache_dir" ]]; then
      section_list | fzf \
        --prompt='section> ' \
        --delimiter=$'\t' \
        --with-nth=2.. \
        --height=80% \
        --reverse \
        --exit-0 \
        --ansi \
        --preview "cat '$cache_dir'/{1}.txt 2>/dev/null | '$ROOT_DIR/tools/lib/color-filter' || echo '(No preview available)'" \
        --preview-window 'right:60%'
    else
      section_list | fzf \
        --prompt='section> ' \
        --delimiter=$'\t' \
        --with-nth=2.. \
        --height=80% \
        --reverse \
        --exit-0
    fi
  elif command -v gum >/dev/null 2>&1 && [[ "$IS_TTY" -eq 1 ]]; then
    section_list | gum filter --placeholder='section / category'
  else
    section_list >&2
    printf 'section key> ' >&2
    read -r key
    printf '%s\n' "$key"
  fi
}

case "$cmd" in
  report|all)
    show_full_report
    ;;
  add|actions)
    exec "$ROOT_DIR/tools/add-ui.sh" --base "$base_dir"
    ;;
  select|--select|'')
    ensure_ledger_report_base "$base_dir"
    cache_dir="$(mktemp -d)"
    trap 'rm -rf "$cache_dir"' EXIT

    if ! "$ROOT_DIR/tools/report" "$base_dir" --write-section-cache "$cache_dir" --no-color >/dev/null; then
      echo "Failed to generate report cache" >&2
      exit 1
    fi

    selection="$(select_section "$cache_dir" || true)"
    [[ -z "$selection" ]] && echo "Cancelled." >&2 && exit 0
    key="${selection%%$'\t'*}"
    case "$key" in
      actions) exec "$ROOT_DIR/tools/add-ui.sh" --base "$base_dir" ;;
      all) show_full_report ;;
      *)
        if [[ -f "$cache_dir/$key.txt" ]]; then
          cat "$cache_dir/$key.txt" | "$ROOT_DIR/tools/lib/color-filter"
        else
          echo "Error: cached file not found for $key" >&2
          exit 1
        fi
        ;;
    esac
    ;;
  *)
    show_section_direct "$cmd"
    ;;
esac
