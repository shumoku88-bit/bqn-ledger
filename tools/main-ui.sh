#!/usr/bin/env bash
set -euo pipefail

# tools/main-ui.sh — daily report entry / small command hub
#
# Default path must be useful for daily browsing:
#   tools/main-ui.sh  -> open the lightweight section selector
# Full report output remains available through `report` / `all`.
#
# Selector-based browsing uses structured report-section metadata for menu labels.
# Section previews and display lazily materialize only the requested section.

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

usage() {
  cat <<'EOF'
Usage:
  tools/main-ui.sh [--base <dir>] [command]

Commands:
  select, --select     Open fzf/gum section selector (default)
  report, all          Show the full report
  snapshot             Show Snapshot section
  issues               Show Issues & Decisions section
  envelopes            Show Envelope & Budget section
  outlook              Show Outlook Dashboard section
  cycle                Show Current Cycle Summary section
  ytd                  Show YTD Summary section
  balances             Show Account Balances section
  trial-balance        Show Trial Balance section
  recent               Show Recent Journal section
  planned              Show Planned Payments section
  daily-trend          Show Daily Trend section
  daily-flow           Show Daily Flow section
  check                 Show Readiness Check section
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

pager_display() {
  if [[ "$IS_TTY" -eq 1 ]] && command -v less >/dev/null 2>&1; then
    less -SRFX
  else
    cat
  fi
}

show_full_report() {
  ensure_ledger_report_base "$base_dir"
  "$ROOT_DIR/tools/report" "$base_dir" --no-color | "$ROOT_DIR/tools/lib/color-filter" | pager_display
}

section_list() {
  "$ROOT_DIR/tools/report-section-metadata" | awk -F'\t' 'NR > 1 { print $1 "\t" $2 }'
  printf 'actions\t→ 仕訳追加・取消\n'
}

show_section_direct() {
  local key="$1" out err status
  out="$(mktemp)"
  err="$(mktemp)"
  trap 'rm -f "$out" "$err"' RETURN
  if "$ROOT_DIR/tools/report" "$base_dir" --section "$key" --no-color >"$out" 2>"$err"; then
    cat "$out" | "$ROOT_DIR/tools/lib/color-filter" | pager_display
  else
    status=$?
    if [[ -s "$out" ]]; then cat "$out" >&2; fi
    if [[ -s "$err" ]]; then cat "$err" >&2; fi
    return "$status"
  fi
}

show_section_cached() {
  local base_abs="$1" cache_dir="$2" source_mtime="$3" key="$4"
  local out err status
  out="$(mktemp)"
  err="$(mktemp)"
  trap 'rm -f "$out" "$err"' RETURN
  if bash "$ROOT_DIR/tools/report-section-cache" "$base_abs" "$cache_dir" "$source_mtime" "$key" >"$out" 2>"$err"; then
    cat "$out" | "$ROOT_DIR/tools/lib/color-filter" | pager_display
  else
    status=$?
    if [[ -s "$out" ]]; then cat "$out" >&2; fi
    if [[ -s "$err" ]]; then cat "$err" >&2; fi
    return "$status"
  fi
}

select_section() {
  local base_abs="$1" cache_dir="$2" source_mtime="$3"
  if command -v fzf >/dev/null 2>&1 && [[ "$IS_TTY" -eq 1 ]]; then
    local preview_win="${FZF_PREVIEW_WINDOW:-}"
    if [[ -z "$preview_win" && -f "$base_dir/config.tsv" ]]; then
      local custom_win
      custom_win=$(awk -F'=' 'tolower($1) == "fzf_preview_window" { print $2 }' "$base_dir/config.tsv" 2>/dev/null || true)
      custom_win=$(echo "${custom_win:-}" | xargs)
      if [[ -n "$custom_win" ]]; then
        preview_win="$custom_win"
      fi
    fi
    preview_win="${preview_win:-right:60%}"

    local preview_cmd
    printf -v preview_cmd '%q %q %q %q %q {1} 2>/dev/null | %q || echo %q' \
      bash "$ROOT_DIR/tools/report-section-cache" "$base_abs" "$cache_dir" "$source_mtime" \
      "$ROOT_DIR/tools/lib/color-filter" '(No preview available)'
    section_list | fzf \
      --prompt='section> ' \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --height=80% \
      --reverse \
      --exit-0 \
      --ansi \
      --preview "$preview_cmd" \
      --preview-window "$preview_win"
  elif command -v gum >/dev/null 2>&1 && [[ "$IS_TTY" -eq 1 ]]; then
    section_list | gum filter "${GUM_FILTER_ARGS[@]}" --placeholder='section / category'
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

    # The selector opens without synchronously constructing every report section.
    # Each preview/display is materialized independently and reused until any
    # report input or src_next module becomes newer than that section's stamp.
    base_abs="$(cd "$base_dir" && pwd)"
    sanitized_path="${base_abs//\//_}"
    cache_dir="${TMPDIR:-/tmp}/bqn-ledger-cache-${sanitized_path}"
    mkdir -p "$cache_dir"

    actual_journal_rel="$(bqn "$ROOT_DIR/src_edit/actual_journal_file_cmd.bqn" "$base_abs")"
    src_files=(
      "$base_abs/accounts.tsv"
      "$base_abs/$actual_journal_rel"
      "$base_abs/plan.tsv"
      "$base_abs/budget_alloc.tsv"
      "$base_abs/cycle.tsv"
    )
    while IFS= read -r -d '' f; do
      src_files+=("$f")
    done < <(find "$ROOT_DIR/src_next" -name "*.bqn" -print0)
    if [[ -f "$base_abs/issues.tsv" ]]; then
      src_files+=("$base_abs/issues.tsv")
    fi
    if [[ -f "$base_abs/config.tsv" ]]; then
      src_files+=("$base_abs/config.tsv")
    fi
    if [[ -f "$ROOT_DIR/config/report_labels.tsv" ]]; then
      src_files+=("$ROOT_DIR/config/report_labels.tsv")
    fi

    max_src_mtime=0
    for f in "${src_files[@]}"; do
      if [[ -f "$f" ]]; then
        if stat -f %m "$f" >/dev/null 2>&1; then
          mtime=$(stat -f %m "$f")
        else
          mtime=$(stat -c %Y "$f")
        fi
        if (( mtime > max_src_mtime )); then
          max_src_mtime=$mtime
        fi
      fi
    done

    selection="$(select_section "$base_abs" "$cache_dir" "$max_src_mtime" || true)"
    [[ -z "$selection" ]] && echo "Cancelled." >&2 && exit 0
    key="${selection%%$'\t'*}"
    case "$key" in
      actions) exec "$ROOT_DIR/tools/add-ui.sh" --base "$base_dir" ;;
      all) show_full_report ;;
      *) show_section_cached "$base_abs" "$cache_dir" "$max_src_mtime" "$key" ;;
    esac
    ;;
  *)
    show_section_direct "$cmd"
    ;;
esac
