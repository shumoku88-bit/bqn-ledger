#!/usr/bin/env bash
set -euo pipefail

# tools/main-ui.sh — daily report entry / small command hub
#
# Default path must be boring and reliable:
#   tools/main-ui.sh  -> show the full report through tools/report
# fzf/gum selection is optional and lives under `select` / `--select`.

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
  report, all          Show the full report (default)
  select, --select     Open fzf/gum section selector
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

Default behavior intentionally does not depend on fzf/gum.
EOF
}

base_dir="${LEDGER_DATA_DIR:-$(get_default_base_dir)}"
cmd="report"

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

report_color_args=()
if [[ -n "${NO_COLOR:-}" || ! -t 1 ]]; then
  report_color_args+=(--no-color)
else
  report_color_args+=(--color=always)
fi

show_full_report() {
  ensure_ledger_report_base "$base_dir"
  exec "$ROOT_DIR/tools/report" "$base_dir" "${report_color_args[@]}"
}

build_report_cache() {
  local out="$1" err="$2"
  ensure_ledger_report_base "$base_dir"
  if ! "$ROOT_DIR/tools/report" "$base_dir" --no-color >"$out" 2>"$err"; then
    echo "Report build failed for base: $base_dir" >&2
    cat "$err" >&2
    return 1
  fi
  if [[ ! -s "$out" ]]; then
    echo "Report output is empty for base: $base_dir" >&2
    if [[ -s "$err" ]]; then cat "$err" >&2; fi
    return 1
  fi
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

get_section_marker() {
  case "$1" in
    snapshot) echo "1. 全体サマリ" ;;
    ytd) echo "== YTD Summary ==" ;;
    balances) echo "== Account Balances ==" ;;
    cycle) echo "== Current Cycle Summary ==" ;;
    trial-balance) echo "== Trial Balance" ;;
    envelopes) echo "== Envelope & Budget ==" ;;
    planned) echo "== Planned Payments ==" ;;
    recent) echo "7. 直近の取引" ;;
    check) echo "== Readiness Check ==" ;;
    outlook) echo "== Outlook Dashboard ==" ;;
    daily-trend) echo "== Daily Trend ==" ;;
    actual-comparison) echo "== Actual Comparison ==" ;;
    debug) echo "12. デバッグ" ;;
    *) return 1 ;;
  esac
}

extract_section_from_cache() {
  local key="$1" report_cache="$2" marker

  if [[ "$key" == "all" || "$key" == "report" ]]; then
    cat "$report_cache"
    return 0
  fi

  if ! marker="$(get_section_marker "$key")"; then
    echo "Unknown command/section: $key" >&2
    usage >&2
    return 1
  fi

  awk -v marker="$marker" '
    index($0, marker) > 0 { found=1; print; next }
    found && ($0 ~ /^([0-9]+\. |== )/) { exit }
    found { print }
    END { if (!found) exit 3 }
  ' "$report_cache" || {
    echo "Section marker not found: $key ($marker)" >&2
    return 1
  }
}

show_section() {
  local key="$1" report_cache err_cache
  report_cache="$(mktemp)"
  err_cache="$(mktemp)"
  trap 'rm -f "$report_cache" "$err_cache"' RETURN
  build_report_cache "$report_cache" "$err_cache"
  extract_section_from_cache "$key" "$report_cache"
}

select_section() {
  if command -v fzf >/dev/null 2>&1; then
    local report_cache err_cache preview_cmd
    report_cache="$(mktemp)"
    err_cache="$(mktemp)"
    trap 'rm -f "$report_cache" "$err_cache"' RETURN

    echo "Building report..." >&2
    build_report_cache "$report_cache" "$err_cache"
    export MAIN_UI_REPORT_CACHE="$report_cache"

    preview_cmd='key={1}; file="$MAIN_UI_REPORT_CACHE"; case "$key" in all) cat "$file"; exit ;; snapshot) m="1. 全体サマリ" ;; ytd) m="== YTD Summary ==" ;; balances) m="== Account Balances ==" ;; cycle) m="== Current Cycle Summary ==" ;; trial-balance) m="== Trial Balance" ;; envelopes) m="== Envelope & Budget ==" ;; planned) m="== Planned Payments ==" ;; recent) m="7. 直近の取引" ;; check) m="== Readiness Check ==" ;; outlook) m="== Outlook Dashboard ==" ;; daily-trend) m="== Daily Trend ==" ;; actual-comparison) m="== Actual Comparison ==" ;; debug) m="12. デバッグ" ;; actions) echo "→ Launch add-ui.sh (仕訳追加・予定管理・取消)"; exit ;; esac; awk -v marker="$m" '\''index($0, marker) > 0 { f=1; print; next } f && ($0 ~ /^([0-9]+\. |== )/) { exit } f { print }'\'' "$file"'

    section_list | fzf \
      --prompt='section> ' \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --ansi \
      --height=100% \
      --reverse \
      --exit-0 \
      --preview="$preview_cmd" \
      --preview-window='down:70%' \
      --bind='ctrl-p:change-preview-window(right:80%|down:70%|hidden|)'
  elif command -v gum >/dev/null 2>&1; then
    section_list | gum filter --placeholder='section / category'
  else
    section_list
    printf 'section key> ' >&2
    read -r key
    printf '%s\n' "$key"
  fi
}

case "$cmd" in
  report|all|'')
    show_full_report
    ;;
  add|actions)
    exec "$ROOT_DIR/tools/add-ui.sh" --base "$base_dir"
    ;;
  select|--select)
    selection="$(select_section || true)"
    [[ -z "$selection" ]] && echo "Cancelled." >&2 && exit 0
    key="${selection%%$'\t'*}"
    case "$key" in
      actions) exec "$ROOT_DIR/tools/add-ui.sh" --base "$base_dir" ;;
      all) show_full_report ;;
      *) show_section "$key" ;;
    esac
    ;;
  *)
    show_section "$cmd"
    ;;
esac
