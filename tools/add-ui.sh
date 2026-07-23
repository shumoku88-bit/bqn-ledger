#!/usr/bin/env bash
set -euo pipefail

# tools/add-ui.sh — fuzzy transaction adder using fzf/gum
#
# Architecture (Seam Reduction):
#   Bash handles UI, selection, and display.
#   BQN editor handles safe TSV append.
#   Account listing is provided by BQN editor export (`tools/edit account list`).

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# Load shared system defaults helper
source "$ROOT_DIR/tools/lib/system-defaults.sh"

usage() {
  cat <<'EOF'
Usage:
  tools/add-ui.sh [--base <dir>] [--check] [<mode>]

Fuzzy transaction adder for everyday entries.

Modes:
  account-add   アカウント追加 (writes accounts.tsv)
  expense       assets -> expenses  (writes selected actual source)
  multi         native Journal transaction with 2+ signed postings
  move          assets -> assets    (writes selected actual source)
  income        income -> assets    (writes selected actual source)
  budget        budget -> budget    (writes budget_alloc.tsv)
  plan-add      assets -> expenses  (writes plan.tsv)
  plan-edit     date/amount         (edits plan.tsv)
  plan-finish                       (plan -> journal, optional next plan)
  reverse       仕訳取消 (反対仕訳追記)
  issue         Issues & Decisions の追加 (writes issues.tsv)
  issue-close   Issues & Decisions を閉じる (edits issues.tsv)

Append is delegated to tools/edit (BQN editor path).

Options:
  --base <dir>  Use an explicit source TSV base directory
  --check       Read-only preflight; validate data dir, candidates, and editor path
EOF
}

shout() { printf '%s\n' "$*" >&2; }

main() {
base_dir="${LEDGER_DATA_DIR:-$(get_default_base_dir)}"
preflight=0
mode_arg=''
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
    --)
      shift
      if [[ $# -gt 0 ]]; then
        if [[ -n "$mode_arg" ]]; then
          shout "Error: Extra argument: $1"
          usage
          exit 1
        fi
        mode_arg="$1"
        shift
      fi
      if [[ $# -gt 0 ]]; then
        shout "Error: Extra argument: $1"
        usage
        exit 1
      fi
      ;;
    -*) shout "Error: Unknown argument: $1"; usage; exit 1 ;;
    *)
      if [[ -n "$mode_arg" ]]; then
        shout "Error: Extra argument: $1"
        usage
        exit 1
      fi
      mode_arg="$1"
      shift
      ;;
  esac
done

ensure_ledger_report_base "$base_dir"

mode=''
if [[ -n "$mode_arg" ]]; then
  case "$mode_arg" in
    account-add|expense|multi|move|income|budget|plan-add|plan-edit|plan-finish|reverse|issue|issue-close)
      mode="$mode_arg"
      ;;
    *)
      shout "Error: Unknown argument: $mode_arg"
      usage
      exit 1
      ;;
  esac
fi

# ── Account listing (BQN-owned account metadata interpretation) ──

accounts() {
  local role="${1:-}"

  if [[ -n "$role" ]]; then
    "$ROOT_DIR/tools/edit" --base "$base_dir" account list --role "$role"
  else
    "$ROOT_DIR/tools/edit" --base "$base_dir" account list
  fi
}

run_preflight() {
  local failures=0 warnings=0 count role f

  ok() { printf 'PASS %s\n' "$*"; }
  warn_check() { printf 'WARN %s\n' "$*"; warnings=$((warnings + 1)); }
  fail_check() { printf 'FAIL %s\n' "$*"; failures=$((failures + 1)); }

  printf 'add-ui preflight\n'
  printf 'base: %s\n' "$base_dir"

  for f in accounts.tsv cycle.tsv; do
    if [[ -f "$base_dir/$f" ]]; then
      ok "$f"
    else
      fail_check "$f missing"
    fi
  done

  for f in plan.tsv budget_alloc.tsv config.tsv; do
    if [[ -f "$base_dir/$f" ]]; then
      ok "$f"
    else
      warn_check "$f missing; related mode/view may be unavailable"
    fi
  done

  if [[ -x "$ROOT_DIR/tools/edit" ]]; then
    ok "tools/edit wrapper"
  else
    fail_check "tools/edit wrapper is not executable"
  fi

  if [[ -x "$ROOT_DIR/tools/plan-finish-replenish-ui.sh" ]]; then
    ok "tools/plan-finish-replenish-ui.sh"
  else
    fail_check "tools/plan-finish-replenish-ui.sh is not executable"
  fi

  for role in asset expense income; do
    count="$(accounts "$role" | awk 'END { print NR + 0 }')"
    if [[ "$count" -gt 0 ]]; then
      ok "role=$role candidates: $count"
    else
      fail_check "role=$role has no candidates"
    fi
  done

  count="$(accounts budget | awk 'END { print NR + 0 }')"
  if [[ "$count" -gt 0 ]]; then
    ok "role=budget candidates: $count"
  else
    warn_check "role=budget has no candidates; budget mode may be unavailable"
  fi

  if [[ -f "$base_dir/plan.tsv" ]]; then
    if "$ROOT_DIR/tools/edit" --base "$base_dir" plan list --format tsv >/dev/null; then
      ok "tools/edit plan list --format tsv"
    else
      fail_check "tools/edit plan list --format tsv failed"
    fi
  else
    warn_check "skipped plan list check because plan.tsv is missing"
  fi

  if "$ROOT_DIR/tools/edit" --base "$base_dir" issue list --format tsv >/dev/null; then
    ok "tools/edit issue list --format tsv"
  else
    fail_check "tools/edit issue list --format tsv failed"
  fi

  if [[ "$failures" -eq 0 ]]; then
    printf 'OK add-ui preflight passed (%s warning(s))\n' "$warnings"
    return 0
  fi

  printf 'FAILED add-ui preflight: %s failure(s), %s warning(s)\n' "$failures" "$warnings" >&2
  return 1
}

if [[ "$preflight" -eq 1 ]]; then
  run_preflight
  exit $?
fi

# ── UI helpers ──

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
      if ! ans="$(gum input --prompt "${prompt}: " --value "$default" </dev/tty)"; then
        return 130
      fi
    else
      if ! ans="$(gum input --prompt "${prompt}: " </dev/tty)"; then
        return 130
      fi
    fi
  else
    if [[ -n "$default" ]]; then
      printf '%s [%s]: ' "$prompt" "$default" >&2
    else
      printf '%s: ' "$prompt" >&2
    fi
    if ! read -r ans </dev/tty; then
      return 130
    fi
  fi
  if [[ -z "$ans" && -n "$default" ]]; then
    printf '%s\n' "$default"
  else
    printf '%s\n' "$ans"
  fi
}

cancel_ui() {
  shout 'Cancelled.'
  exit 130
}

capture_or_cancel() {
  local __var="$1" __out
  shift
  if ! __out="$("$@")"; then
    cancel_ui
  fi
  printf -v "$__var" '%s' "$__out"
}

select_account() {
  local role="$1" prompt="$2"
  accounts "$role" | select_line "$prompt"
}

select_display_lines() {
  local prompt="$1"
  printf '%s\n' "${display_lines[@]}" | select_line "$prompt"
}

# ── Date handling ──

today="$(date +%Y-%m-%d)"
yesterday="$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d yesterday +%Y-%m-%d)"
tomorrow="$(date -v+1d +%Y-%m-%d 2>/dev/null || date -d tomorrow +%Y-%m-%d)"

choose_date_key() {
  {
    printf 'today\t%s (default)\n' "$today"
    printf 'yesterday\t%s\n' "$yesterday"
    printf 'other\tenter YYYY-MM-DD\n'
  } | select_line 'date'
}

choose_plan_date_key() {
  {
    printf 'tomorrow\t%s (default)\n' "$tomorrow"
    printf 'today\t%s\n' "$today"
    printf 'other\tenter YYYY-MM-DD\n'
  } | select_line 'plan date'
}

choose_plan_list_scope() {
  cat <<'EOF' | select_line 'plan range'
upcoming	今日以降のOPEN予定
overdue	期限超過のOPEN予定
all	すべてのOPEN予定
EOF
}

# ── Mode selection ──

choose_mode() {
  cat <<'EOF' | select_line 'mode'
account-add	アカウント追加
expense	支出 assets -> expenses
multi	複数ポスティング (native Journal)
move	資金移動 assets -> assets
income	収入 income -> assets
budget	予算配賦 budget -> budget
plan-add	予定の追加 assets -> expenses
plan-edit	予定の日付・金額修正
plan-finish	予定の実績化 + 次回予定補充
reverse	仕訳取消 (反対仕訳追記)
issue	Issues & Decisions の追加
issue-close	Issues & Decisions を閉じる
EOF
}

choose_account_role() {
  cat <<'EOF' | select_line 'account role'
asset	資産 (assets:)
liability	負債 (liabilities:)
income	収入 (income:)
expense	費用 (expenses:)
EOF
}

choose_asset_type() {
  cat <<'EOF' | select_line 'asset type'
liquid	日常的に利用可能
savings	貯蓄
invest	投資
none	未指定
EOF
}

choose_issue_close_status() {
  cat <<'EOF' | select_line 'close status'
resolved	resolved: decision made / completed
dropped	dropped: no action / no longer relevant
EOF
}

choose_budget_memo() {
  local selected key memo_value custom line
  local presets_file="$ROOT_DIR/config/ui_budget_memo_presets.tsv"
  local -a lines=()

  if [[ -f "$presets_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -z "$line" || "$line" =~ ^# ]] && continue
      lines+=("$line")
    done < "$presets_file"
  else
    # Keep budget-specific memo vocabulary in config/ui_budget_memo_presets.tsv.
    # Fallback only preserves a generic custom input path.
    lines=($'custom\tenter memo\tcustom')
  fi

  if ! selected="$(
    for line in "${lines[@]}"; do
      local k d
      k="$(printf '%s' "$line" | cut -f1)"
      d="$(printf '%s' "$line" | cut -f2)"
      printf '%s\t%s\n' "$k" "$d"
    done | select_line 'budget memo'
  )"; then
    return 130
  fi

  key="${selected%%$'\t'*}"
  memo_value=""
  for line in "${lines[@]}"; do
    local k
    k="$(printf '%s' "$line" | cut -f1)"
    if [[ "$k" == "$key" ]]; then
      memo_value="$(printf '%s' "$line" | cut -f3)"
      break
    fi
  done

  case "$key" in
    custom)
      if ! custom="$(read_tty 'Budget memo' 'alloc')"; then return 130; fi
      printf '%s\n' "$custom"
      ;;
    *) printf '%s\n' "${memo_value:-$key}" ;;
  esac
}

# ── Meta presets ──

meta_has_key() {
  local key="$1" tokens="${2:-}" token token_key
  for token in $tokens; do
    token_key="${token%%=*}"
    [[ "$token_key" == "$key" ]] && return 0
  done
  return 1
}

choose_meta() {
  local selected key meta_tokens custom
  local presets_file="$ROOT_DIR/config/ui_meta_presets.tsv"
  local -a lines=()

  if [[ -f "$presets_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -z "$line" || "$line" =~ ^# ]] && continue
      lines+=("$line")
    done < "$presets_file"
  else
    # Keep semantic meta presets in config/ui_meta_presets.tsv, not shell.
    # Fallback only preserves the generic empty/custom UI shape.
    lines=(
      $'empty\t(no meta)\t'
      $'custom\tenter key=value tokens\tcustom'
    )
  fi

  if ! selected="$(
    for l in "${lines[@]}"; do
      local k d
      k="$(printf '%s' "$l" | cut -f1)"
      d="$(printf '%s' "$l" | cut -f2)"
      printf '%s\t%s\n' "$k" "$d"
    done | select_line 'meta'
  )"; then
    return 130
  fi

  [[ -z "$selected" ]] && return 130
  key="${selected%%$'\t'*}"

  meta_tokens=""
  for l in "${lines[@]}"; do
    local k
    k="$(printf '%s' "$l" | cut -f1)"
    if [[ "$k" == "$key" ]]; then
      meta_tokens="$(printf '%s' "$l" | cut -f3)"
      break
    fi
  done

  case "$key" in
    empty) printf '\n' ;;
    custom)
      if ! custom="$(read_tty 'Meta key=value tokens' '')"; then return 130; fi
      printf '%s\n' "$custom"
      ;;
    *) printf '%s\n' "$meta_tokens" ;;
  esac
}

# ── Main flow ──

# Make terminal erase UTF-8-aware
if [[ -r /dev/tty ]]; then
  stty iutf8 </dev/tty 2>/dev/null || true
fi

if [[ -z "$mode" ]]; then
  if ! mode_line="$(choose_mode)"; then
    shout 'Cancelled.'
    exit 0
  fi
  if [[ -z "$mode_line" ]]; then
    shout 'Cancelled.'
    exit 0
  fi
  mode="${mode_line%%$'\t'*}"
fi

if [[ "$mode" == 'plan-finish' ]]; then
  exec "$ROOT_DIR/tools/plan-finish-replenish-ui.sh" --base "$base_dir"
fi

memo=''; from=''; to=''; amt=''; meta=''; plan_series=''; postings=(); issue_close_args=()

case "$mode" in
  account-add)
    capture_or_cancel account_role_line choose_account_role
    account_role="${account_role_line%%$'\t'*}"
    case "$account_role" in
      asset) account_prefix='assets:' ;;
      liability) account_prefix='liabilities:' ;;
      income) account_prefix='income:' ;;
      expense) account_prefix='expenses:' ;;
      *) shout "Invalid account role: $account_role"; exit 1 ;;
    esac
    capture_or_cancel account_suffix read_tty 'Account name (namespace is added automatically)' ''
    account_name="${account_prefix}${account_suffix}"
    account_type=''
    if [[ "$account_role" == 'asset' ]]; then
      capture_or_cancel account_type_line choose_asset_type
      account_type="${account_type_line%%$'\t'*}"
      [[ "$account_type" == 'none' ]] && account_type=''
    fi
    ;;
  issue)
    capture_or_cancel title read_tty 'Title/Item' ''
    capture_or_cancel amt read_tty 'Amount (optional JST)' '0'
    capture_or_cancel memo read_tty 'Memo/Details' ''
    ;;
  issue-close)
    issue_tsv_lines=()
    while IFS= read -r _il; do issue_tsv_lines+=("$_il"); done < <("$ROOT_DIR/tools/edit" --base "$base_dir" issue list --format tsv)
    if [[ ${#issue_tsv_lines[@]} -eq 0 ]]; then
      shout "No open issues found."
      exit 0
    fi
    display_lines=()
    for line in "${issue_tsv_lines[@]}"; do
      display_lines+=("$(printf '%s\n' "$line" | cut -f6)")
    done
    capture_or_cancel selected_display select_display_lines 'select issue to close'
    if [[ -z "$selected_display" ]]; then cancel_ui; fi
    selected_row=""
    for line in "${issue_tsv_lines[@]}"; do
      if [[ "$(printf '%s\n' "$line" | cut -f6)" == "$selected_display" ]]; then
        selected_row="$line"; break
      fi
    done
    if [[ -z "$selected_row" ]]; then
      shout "Failed to match selected issue: $selected_display"; exit 1
    fi
    issue_number="$(printf '%s\n' "$selected_row" | cut -f1)"
    capture_or_cancel close_status_line choose_issue_close_status
    close_status="${close_status_line%%$'\t'*}"
    capture_or_cancel decision_memo read_tty 'Decision memo (例: 2026-07-09 解約済み。固定支出/plan化しない。)' ''
    issue_close_args=(--index "$issue_number" --status "$close_status" --decision "$decision_memo")
    ;;
  expense)
    capture_or_cancel memo read_tty 'Memo/Description' ''
    capture_or_cancel from select_account 'asset' 'from asset'
    capture_or_cancel to select_account 'expense' 'to expense'
    capture_or_cancel amt read_tty 'Amount' ''
    capture_or_cancel meta choose_meta
    ;;
  multi)
    capture_or_cancel memo read_tty 'Memo/Description' ''
    capture_or_cancel meta choose_meta
    while true; do
      capture_or_cancel posting_account select_account '' 'posting account'
      capture_or_cancel posting_amount read_tty 'Signed amount (+ increase / - decrease)' ''
      if [[ -z "$posting_account" || -z "$posting_amount" ]]; then
        shout 'Cancelled or missing posting value.'
        exit 1
      fi
      postings+=("$posting_account=$posting_amount")
      if [[ ${#postings[@]} -lt 2 ]]; then
        continue
      fi
      capture_or_cancel add_more read_tty 'Add another posting? (y/N)' 'N'
      case "$add_more" in
        y|Y|yes|YES|Yes) ;;
        *) break ;;
      esac
    done
    ;;
  move)
    capture_or_cancel from select_account 'asset' 'from asset'
    capture_or_cancel to select_account 'asset' 'to asset'
    capture_or_cancel amt read_tty 'Amount' ''
    capture_or_cancel memo read_tty 'Memo/Description' "${from}→${to}"
    capture_or_cancel meta choose_meta
    ;;
  income)
    capture_or_cancel from select_account 'income' 'from income'
    capture_or_cancel to select_account 'asset' 'to asset'
    capture_or_cancel amt read_tty 'Amount' ''
    capture_or_cancel memo read_tty 'Memo/Description' 'income'
    capture_or_cancel meta choose_meta
    ;;
  budget)
    capture_or_cancel memo choose_budget_memo
    capture_or_cancel from select_account 'budget' 'from budget'
    capture_or_cancel to select_account 'budget' 'to budget'
    capture_or_cancel amt read_tty 'Amount' ''
    capture_or_cancel meta choose_meta
    ;;
  plan-add)
    capture_or_cancel memo read_tty 'Memo/Description' ''
    capture_or_cancel from select_account 'asset' 'from asset'
    capture_or_cancel to select_account 'expense' 'to expense'
    capture_or_cancel amt read_tty 'Amount' ''
    capture_or_cancel meta choose_meta
    # UI-only input convenience: add-ui may attach an explicit series= token
    # when the user enters one. Recurring-plan relation semantics and fallback
    # order remain owned by src_edit/plan_related_cmd.bqn, not by this shell UI.
    capture_or_cancel plan_series read_tty 'Series for plan_id (empty: use memo, no spaces)' ''
    if [[ -n "$plan_series" && ! "$plan_series" =~ ^[A-Za-z0-9._-]+$ ]]; then
      shout 'Series must contain only A-Z, a-z, 0-9, dot, underscore, or hyphen.'
      exit 1
    fi
    if [[ -n "$plan_series" ]] && ! meta_has_key 'series' "$meta"; then
      meta="${meta:+$meta }series=$plan_series"
    fi
    ;;
  plan-edit)
    capture_or_cancel plan_scope_line choose_plan_list_scope
    plan_scope="${plan_scope_line%%$'\t'*}"
    plan_list_args=(--format tsv)
    [[ "$plan_scope" != 'all' ]] && plan_list_args+=(--temporal "$plan_scope" --as-of "$today")
    plan_tsv_lines=()
    while IFS= read -r _pl; do plan_tsv_lines+=("$_pl"); done < <("$ROOT_DIR/tools/edit" --base "$base_dir" plan list "${plan_list_args[@]}")
    if [[ ${#plan_tsv_lines[@]} -eq 0 ]]; then
      shout "No active plans found."
      exit 0
    fi
    display_lines=()
    for line in "${plan_tsv_lines[@]}"; do
      display_lines+=("$(printf '%s\n' "$line" | cut -f9)")
    done
    select_prompt="select $plan_scope plan to edit"
    capture_or_cancel selected_display select_display_lines "$select_prompt"
    if [[ -z "$selected_display" ]]; then cancel_ui; fi
    selected_row=""
    for line in "${plan_tsv_lines[@]}"; do
      if [[ "$(printf '%s\n' "$line" | cut -f9)" == "$selected_display" ]]; then
        selected_row="$line"; break
      fi
    done
    if [[ -z "$selected_row" ]]; then
      shout "Failed to match selected display: $selected_display"; exit 1
    fi
    plan_number="$(printf '%s\n' "$selected_row" | cut -f1)"
    plan_id="$(printf '%s\n' "$selected_row" | cut -f2)"
    plan_date="$(printf '%s\n' "$selected_row" | cut -f3)"
    plan_amount="$(printf '%s\n' "$selected_row" | cut -f7)"
    if [[ -n "$plan_id" ]]; then
      plan_selector_args=(--id "$plan_id")
    else
      plan_selector_args=(--index "$plan_number")
    fi
    capture_or_cancel new_plan_date read_tty 'New plan date YYYY-MM-DD' "$plan_date"
    capture_or_cancel new_plan_amount read_tty 'New amount' "$plan_amount"
    plan_edit_args=("${plan_selector_args[@]}")
    [[ "$new_plan_date" != "$plan_date" ]] && plan_edit_args+=(--date "$new_plan_date")
    [[ "$new_plan_amount" != "$plan_amount" ]] && plan_edit_args+=(--amount "$new_plan_amount")
    if [[ ${#plan_edit_args[@]} -eq ${#plan_selector_args[@]} ]]; then
      shout 'No changes entered.'; exit 0
    fi
    ;;
  reverse)
    journal_tsv_lines=()
    while IFS= read -r _jl; do journal_tsv_lines+=("$_jl"); done < <("$ROOT_DIR/tools/edit" --base "$base_dir" journal list --format tsv)
    if [[ ${#journal_tsv_lines[@]} -eq 0 ]]; then
      shout "No journal entries found."; exit 0
    fi
    display_lines=()
    for line in "${journal_tsv_lines[@]}"; do
      display_lines+=("$(printf '%s\n' "$line" | cut -f7)")
    done
    capture_or_cancel selected_display select_display_lines 'select entry to reverse'
    if [[ -z "$selected_display" ]]; then cancel_ui; fi
    selected_row=""
    for line in "${journal_tsv_lines[@]}"; do
      if [[ "$(printf '%s\n' "$line" | cut -f7)" == "$selected_display" ]]; then
        selected_row="$line"; break
      fi
    done
    if [[ -z "$selected_row" ]]; then
      shout "Failed to match selected journal row: $selected_display"; exit 1
    fi
    reverse_index="$(printf '%s\n' "$selected_row" | cut -f1)"
    capture_or_cancel reverse_date read_tty 'Reversal date YYYY-MM-DD (empty=today)' "$today"
    reverse_args=(--index "$reverse_index")
    [[ -n "$reverse_date" && "$reverse_date" != "$today" ]] && reverse_args+=(--date "$reverse_date")
    ;;
  *)
    shout "Unknown mode: $mode"; exit 1 ;;
esac

# ── Date selection (skip for edit/close/reverse modes) ──

if [[ "$mode" != 'account-add' && "$mode" != 'plan-edit' && "$mode" != 'reverse' && "$mode" != 'issue-close' ]]; then
  if [[ "$mode" == 'plan-add' ]]; then
    capture_or_cancel date_line choose_plan_date_key
  else
    capture_or_cancel date_line choose_date_key
  fi
  if [[ -z "$date_line" ]]; then cancel_ui; fi
  date_key="${date_line%%$'\t'*}"
  case "$date_key" in
    today) selected_date="$today" ;;
    yesterday) selected_date="$yesterday" ;;
    tomorrow) selected_date="$tomorrow" ;;
    other) capture_or_cancel selected_date read_tty 'Date YYYY-MM-DD' "$today" ;;
    *) selected_date="$today" ;;
  esac
  if [[ "$mode" == 'multi' ]]; then
    if [[ -z "$memo" || ${#postings[@]} -lt 2 ]]; then
      shout 'Cancelled or missing required multi-posting value.'; exit 1
    fi
  elif [[ "$mode" != 'issue' ]]; then
    if [[ -z "$from" || -z "$to" || -z "$amt" ]]; then
      shout 'Cancelled or missing required value.'; exit 1
    fi
  else
    if [[ -z "$title" ]]; then
      shout 'Cancelled or missing title.'; exit 1
    fi
  fi
fi

# ── Execute via BQN editor ──

if [[ "$mode" == 'account-add' ]]; then
  cmd=(
    "$ROOT_DIR/tools/edit" --base "$base_dir" account add
    --name "$account_name"
    --role "$account_role"
  )
  [[ -n "$account_type" ]] && cmd+=(--type "$account_type")
elif [[ "$mode" == 'plan-edit' ]]; then
  cmd=("$ROOT_DIR/tools/edit" --base "$base_dir" plan edit "${plan_edit_args[@]}")
elif [[ "$mode" == 'reverse' ]]; then
  cmd=("$ROOT_DIR/tools/edit" --base "$base_dir" journal reverse "${reverse_args[@]}")
elif [[ "$mode" == 'multi' ]]; then
  cmd=(
    "$ROOT_DIR/tools/edit" --base "$base_dir" journal multi-add
    --date "$selected_date"
    --description "$memo"
  )
  for posting in "${postings[@]}"; do
    cmd+=(--posting "$posting")
  done
elif [[ "$mode" == 'issue-close' ]]; then
  cmd=("$ROOT_DIR/tools/edit" --base "$base_dir" issue close "${issue_close_args[@]}")
elif [[ "$mode" == 'issue' ]]; then
  cmd=(
    "$ROOT_DIR/tools/edit" --base "$base_dir" issue add
    --date "$selected_date"
    --title "$title"
    --amount "$amt"
    --memo "$memo"
  )
else
  target='journal'
  [[ "$mode" == 'budget' ]] && target='budget'
  [[ "$mode" == 'plan-add' ]] && target='plan'
  cmd=(
    "$ROOT_DIR/tools/edit" --base "$base_dir" "$target" add
    --date "$selected_date"
    --from "$from"
    --to "$to"
    --amount "$amt"
    --memo "$memo"
  )
fi

if [[ "$mode" != 'account-add' && "$mode" != 'plan-edit' && "$mode" != 'reverse' && "$mode" != 'issue' && "$mode" != 'issue-close' && -n "$meta" ]]; then
  for token in $meta; do
    [[ -n "$token" ]] && cmd+=(--meta "$token")
  done
fi

exec "${cmd[@]}"
}

main "$@"
