#!/usr/bin/env bash
set -euo pipefail

# tools/main-ui.sh — daily report entry / small command hub
#
# Default path must be useful for daily browsing:
#   tools/main-ui.sh  -> open the lightweight section selector
# Full report output remains available through `report` / `all`.
#
# Section extraction uses report.bqn --list-sections for marker mapping,
# so section headers can change in BQN without breaking direct section commands.

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

report_color_args=()
if [[ -n "${NO_COLOR:-}" || ! -t 1 ]]; then
  report_color_args+=(--no-color)
else
  report_color_args+=(--color=always)
fi

# ── Section map: loaded dynamically from report.bqn --list-sections ──

# Load section key→marker mapping from BQN report.
# Sets global SECTION_MAP (assoc array: key→marker) and SECTION_KEYS (ordered list).
load_section_map() {
  local base="$1" tsv_file key marker
  declare -gA SECTION_MAP=()
  declare -ga SECTION_KEYS=()
  local count=0

  tsv_file="$(mktemp)"

  if ! "$ROOT_DIR/tools/report" "$base" --list-sections --no-color >"$tsv_file" 2>/dev/null; then
    rm -f "$tsv_file"
    echo "Failed to load section map from report" >&2
    return 1
  fi

  while IFS=$'\t' read -r key marker; do
    [[ -z "$key" ]] && continue
    SECTION_MAP["$key"]="$marker"
    SECTION_KEYS+=("$key")
    count=$((count + 1))
  done < "$tsv_file"
  rm -f "$tsv_file"

  if [[ "$count" -eq 0 ]]; then
    echo "Failed to load section map: no sections found" >&2
    return 1
  fi
}

# get the next section key in order (empty if last)
get_next_section_key() {
  local current="$1" found=0 k
  for k in "${SECTION_KEYS[@]}"; do
    if [[ "$found" -eq 1 ]]; then
      echo "$k"
      return 0
    fi
    if [[ "$k" == "$current" ]]; then
      found=1
    fi
  done
  return 1
}

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

# Extract a section from the cached report using dynamically-loaded markers.
# Uses the next section's marker as the stop boundary (or EOF for the last section).
extract_section_from_cache() {
  local key="$1" report_cache="$2" marker next_marker next_key

  if [[ "$key" == "all" || "$key" == "report" ]]; then
    cat "$report_cache"
    return 0
  fi

  marker="${SECTION_MAP[$key]:-}"
  if [[ -z "$marker" ]]; then
    echo "Unknown command/section: $key" >&2
    usage >&2
    return 1
  fi

  if next_key="$(get_next_section_key "$key")"; then
    next_marker="${SECTION_MAP[$next_key]}"
    awk -v marker="$marker" -v next_marker="$next_marker" '
      index($0, marker) > 0 { found=1; print; next }
      found && index($0, next_marker) > 0 { exit }
      found { print }
      END { if (!found) exit 3 }
    ' "$report_cache"
  else
    # Last section: print from marker to EOF
    awk -v marker="$marker" '
      index($0, marker) > 0 { found=1; print; next }
      found { print }
      END { if (!found) exit 3 }
    ' "$report_cache"
  fi || {
    echo "Section marker not found: $key ($marker)" >&2
    return 1
  }
}

show_section() {
  local key="$1" report_cache err_cache
  report_cache="$(mktemp)"
  err_cache="$(mktemp)"
  trap 'rm -f "$report_cache" "$err_cache"' RETURN
  load_section_map "$base_dir" || return 1
  build_report_cache "$report_cache" "$err_cache"
  extract_section_from_cache "$key" "$report_cache"
}

select_section() {
  if command -v fzf >/dev/null 2>&1 && [[ -t 0 && -t 1 ]]; then
    section_list | fzf \
      --prompt='section> ' \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --height=80% \
      --reverse \
      --exit-0
  elif command -v gum >/dev/null 2>&1 && [[ -t 0 && -t 1 ]]; then
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
