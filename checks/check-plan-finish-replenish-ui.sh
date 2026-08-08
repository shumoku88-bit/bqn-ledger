#!/usr/bin/env bash
set -euo pipefail

# Verify plan finish replenishment helper stays shell-safe, supports read-only
# preflight, and refuses replenishment unless the selected canonical Plan is closed.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash -n tools/plan-finish-replenish-ui.sh
bash -n tools/lib/plan-finish-workflow.sh
grep -Fq -- '--temporal "$scope" --as-of "$today"' tools/plan-finish-replenish-ui.sh
grep -Fq 'load_plan_rows all' tools/plan-finish-replenish-ui.sh
grep -Fq 'display_lines+=("$(plan_candidate_display "$line")")' tools/plan-finish-replenish-ui.sh
grep -Fq "printf '  内容: %s\\n' \"\$plan_memo\"" tools/plan-finish-replenish-ui.sh
grep -Fq 'trap handle_interrupt INT' tools/plan-finish-replenish-ui.sh
grep -Fq '0) finish_applied=1 ;;' tools/plan-finish-replenish-ui.sh
grep -Fq '130)' tools/add-ui.sh
grep -Fq 'exec "$ROOT_DIR/tools/add-ui.sh" --base "$base_dir"' tools/add-ui.sh

# shellcheck source=tools/lib/plan-finish-workflow.sh
source "$ROOT_DIR/tools/lib/plan-finish-workflow.sh"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
base="$tmp_root/canonical-plan"
cp -R fixtures/canonical-household-v1 "$base"

# The general UI base guard still requires retained Account/Cycle TSV policy until
# their named migration phases. They are prerequisites here, not Plan read owners.
cp fixtures/plan-completion/accounts.tsv "$base/accounts.tsv"
cp fixtures/plan-completion/cycle.tsv "$base/cycle.tsv"

before_plan="$(shasum -a 256 "$base/plan.journal" | awk '{print $1}')"
before_journal="$(shasum -a 256 "$base/actual.journal" | awk '{print $1}')"

run_preflight() {
  local label="$1"
  shift
  out="$("$@" bash tools/plan-finish-replenish-ui.sh --base "$base" --check)"
  if ! grep -qF 'OK plan finish replenish preflight passed' <<< "$out"; then
    echo "FAIL: preflight output mismatch ($label)" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
}

run_preflight default env
run_preflight bqn-editor env BQN_EDITOR=1

after_plan="$(shasum -a 256 "$base/plan.journal" | awk '{print $1}')"
after_journal="$(shasum -a 256 "$base/actual.journal" | awk '{print $1}')"

if [ "$before_plan" != "$after_plan" ]; then
  echo "FAIL: preflight modified plan.journal" >&2
  exit 1
fi
if [ "$before_journal" != "$after_journal" ]; then
  echo "FAIL: preflight modified actual.journal" >&2
  exit 1
fi

# Open canonical Plan: a cancelled/non-applied finish must be distinguishable from success.
if ! plan_finish_plan_id_is_open "$ROOT_DIR/tools/edit" "$base" plan-salary; then
  echo "FAIL: expected salary Plan to be open" >&2
  exit 1
fi

set +e
plan_finish_require_applied "$ROOT_DIR/tools/edit" "$base" plan-salary
open_status=$?
set -e
if [ "$open_status" -ne 130 ]; then
  echo "FAIL: still-open Plan should report cancellation/not-applied status 130, got $open_status" >&2
  exit 1
fi

# Closed canonical Plan: Actual already contains the matching plan-id.
if plan_finish_plan_id_is_open "$ROOT_DIR/tools/edit" "$base" plan-groceries; then
  echo "FAIL: expected groceries Plan to be closed" >&2
  exit 1
fi
if ! plan_finish_require_applied "$ROOT_DIR/tools/edit" "$base" plan-groceries; then
  echo "FAIL: closed Plan should satisfy finish postcondition" >&2
  exit 1
fi

# Missing plan-id must not be confused with a closed Plan.
set +e
plan_finish_require_applied "$ROOT_DIR/tools/edit" "$base" plan-does-not-exist
missing_status=$?
set -e
if [ "$missing_status" -ne 2 ]; then
  echo "FAIL: missing plan-id should report verification error status 2, got $missing_status" >&2
  exit 1
fi

# Query failure must remain a verification error rather than looking closed.
set +e
plan_finish_require_applied false "$base" plan-salary
query_status=$?
set -e
if [ "$query_status" -ne 2 ]; then
  echo "FAIL: plan-list query failure should report verification error status 2, got $query_status" >&2
  exit 1
fi

# Before append, cancellation must return through status 130. After append,
# interruption may only cancel replenishment, not describe the finish as undone.
return_line="$(grep -nF 'return_to_add_menu' tools/plan-finish-replenish-ui.sh | head -n1 | cut -d: -f1)"
finish_applied_line="$(grep -nF '0) finish_applied=1 ;;' tools/plan-finish-replenish-ui.sh | head -n1 | cut -d: -f1)"
replenish_prompt_line="$(grep -nF "Create or extend a future plan from the finished plan?" tools/plan-finish-replenish-ui.sh | head -n1 | cut -d: -f1)"
if [ -z "$return_line" ] || [ -z "$finish_applied_line" ] || [ -z "$replenish_prompt_line" ] || [ "$finish_applied_line" -ge "$replenish_prompt_line" ]; then
  echo "FAIL: Ctrl+C navigation must distinguish pre-apply return from post-apply replenishment cancellation" >&2
  exit 1
fi

# The selected Plan summary must be visible before asking for actual values.
summary_line="$(grep -nF 'show_selected_plan' tools/plan-finish-replenish-ui.sh | tail -n1 | cut -d: -f1)"
actual_date_line="$(grep -nF "actual_date=\"\$(read_tty 'Actual date YYYY-MM-DD'" tools/plan-finish-replenish-ui.sh | head -n1 | cut -d: -f1)"
if [ -z "$summary_line" ] || [ -z "$actual_date_line" ] || [ "$summary_line" -ge "$actual_date_line" ]; then
  echo "FAIL: selected Plan details must be shown before actual date/amount prompts" >&2
  exit 1
fi

# Guard wiring: helper must check the postcondition before the replenish prompt.
require_line="$(grep -nF 'plan_finish_require_applied "$ROOT_DIR/tools/edit" "$base_dir" "$plan_id"' tools/plan-finish-replenish-ui.sh | head -n1 | cut -d: -f1)"
prompt_line="$(grep -nF "Create or extend a future plan from the finished plan?" tools/plan-finish-replenish-ui.sh | head -n1 | cut -d: -f1)"
if [ -z "$require_line" ] || [ -z "$prompt_line" ] || [ "$require_line" -ge "$prompt_line" ]; then
  echo "FAIL: plan finish applied-state guard must run before replenish prompt" >&2
  exit 1
fi

printf 'OK plan finish replenish UI smoke\n'
