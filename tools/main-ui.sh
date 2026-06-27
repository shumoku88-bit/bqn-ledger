#!/usr/bin/env bash
set -euo pipefail

# tools/main-ui.sh — fzf/gum section selector for src_next report
#
# Caches the full report output so section switching is instant.

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

get_default_base_dir() {
  local defaults_file="config/system_defaults.tsv"
  local fallback="data"
  if [[ -f "$defaults_file" ]]; then
    local val
    val=$(awk -F'\t' '$1 == "DEFAULT_BASE_DIR" { print $2 }' "$defaults_file")
    if [[ -n "$val" ]]; then
      printf '%s\n' "$val"
      return 0
    fi
  fi
  printf '%s\n' "$fallback"
}

base_dir="${LEDGER_DATA_DIR:-$(get_default_base_dir)}"

report_color_args=()
if [[ -n "${NO_COLOR:-}" || ! -t 1 ]]; then
  report_color_args+=(--no-color)
else
  report_color_args+=(--color=always)
fi

# Section list
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
  esac
}

select_section() {
  if [[ ! -t 0 ]]; then
    read -r key
    printf '%s\n' "$key"
    return
  fi

  if command -v fzf >/dev/null 2>&1; then
    # Build full report once and cache it
    local report_cache
    report_cache="$(mktemp)"
    trap 'rm -f "$report_cache"' EXIT

    echo "Building report..." >&2
    bqn src_next/report.bqn "$base_dir" "${report_color_args[@]}" > "$report_cache" 2>/dev/null

    # preview just greps from cached report — instant on section switch
    local preview_cmd
    preview_cmd='key={1}; case "$key" in all) cat '"$report_cache"' ;; snapshot) m="1. 全体サマリ" ;; ytd) m="== YTD Summary ==" ;; balances) m="== Account Balances ==" ;; cycle) m="== Current Cycle Summary ==" ;; trial-balance) m="== Trial Balance" ;; envelopes) m="== Envelope & Budget ==" ;; planned) m="== Planned Payments ==" ;; recent) m="7. 直近の取引" ;; check) m="== Readiness Check ==" ;; outlook) m="== Outlook Dashboard ==" ;; daily-trend) m="== Daily Trend ==" ;; actual-comparison) m="== Actual Comparison ==" ;; debug) m="12. デバッグ" ;; actions) echo "→ Launch add-ui.sh (仕訳追加・予定管理・取消)" ;; esac; awk -v marker="$m" '\''$0 ~ marker { f=1; print; next } f && ($0 ~ /^[0-9]+\. / || $0 ~ /^== /) { exit } f { print }'\'' '"$report_cache"''

    section_list | fzf \
      --prompt='section> ' \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --ansi \
      --height=100% \
      --reverse \
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

selection="$(select_section || true)"
[[ -z "$selection" ]] && echo "Cancelled." >&2 && exit 0

key="${selection%%$'\t'*}"

if [[ "$key" == "actions" ]]; then
  exec "$ROOT_DIR/tools/add-ui.sh" --base "$base_dir"
fi

if [[ "$key" == "all" || -z "$key" ]]; then
  exec bqn src_next/report.bqn "$base_dir" "${report_color_args[@]}"
fi

marker="$(get_section_marker "$key")"
if [[ -z "$marker" ]]; then
  echo "Unknown section: $key" >&2
  exit 1
fi

bqn src_next/report.bqn "$base_dir" "${report_color_args[@]}" | awk -v m="$marker" '
  $0 ~ m { found=1; print; next }
  found && ($0 ~ /^[0-9]+\. / || $0 ~ /^== /) { exit }
  found { print }
'
