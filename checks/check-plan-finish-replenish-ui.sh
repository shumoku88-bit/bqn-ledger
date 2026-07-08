#!/usr/bin/env bash
set -euo pipefail

# Verify plan finish replenishment helper stays shell-safe, supports read-only
# preflight, and refuses replenishment unless the selected plan is explicitly closed.

if [ -f "src_next/report.bqn" ]; then
  ROOT_DIR="$PWD"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
cd "$ROOT_DIR"

bash -n tools/plan-finish-replenish-ui.sh
bash -n tools/lib/plan-finish-workflow.sh

# shellcheck source=tools/lib/plan-finish-workflow.sh
source "$ROOT_DIR/tools/lib/plan-finish-workflow.sh"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
base="$tmp_root/plan-completion"
cp -R fixtures/plan-completion "$base"

before_plan="$(shasum -a 256 "$base/plan.tsv" | awk '{print $1}')"
before_journal="$(shasum -a 256 "$base/journal.tsv" | awk '{print $1}')"

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

after_plan="$(shasum -a 256 "$base/plan.tsv" | awk '{print $1}')"
after_journal="$(shasum -a 256 "$base/journal.tsv" | awk '{print $1}')"

if [ "$before_plan" != "$after_plan" ]; then
  echo "FAIL: preflight modified plan.tsv" >&2
  exit 1
fi
if [ "$before_journal" != "$after_journal" ]; then
  echo "FAIL: preflight modified journal.tsv" >&2
  exit 1
fi

# Open plan: a cancelled/non-applied finish must be distinguishable from success.
if ! plan_finish_plan_id_is_open "$ROOT_DIR/tools/edit" "$base" plan-2026-01-10-phone; then
  echo "FAIL: expected phone plan to be open" >&2
  exit 1
fi

set +e
plan_finish_require_applied "$ROOT_DIR/tools/edit" "$base" plan-2026-01-10-phone
open_status=$?
set -e
if [ "$open_status" -ne 130 ]; then
  echo "FAIL: still-open plan should report cancellation/not-applied status 130, got $open_status" >&2
  exit 1
fi

# Closed plan: the fixture journal already contains the matching plan_id.
if plan_finish_plan_id_is_open "$ROOT_DIR/tools/edit" "$base" plan-2026-01-15-rent; then
  echo "FAIL: expected rent plan to be closed" >&2
  exit 1
fi
if ! plan_finish_require_applied "$ROOT_DIR/tools/edit" "$base" plan-2026-01-15-rent; then
  echo "FAIL: closed plan should satisfy finish postcondition" >&2
  exit 1
fi

# Missing plan_id must not be confused with a closed plan.
set +e
plan_finish_require_applied "$ROOT_DIR/tools/edit" "$base" plan-does-not-exist
missing_status=$?
set -e
if [ "$missing_status" -ne 2 ]; then
  echo "FAIL: missing plan_id should report verification error status 2, got $missing_status" >&2
  exit 1
fi

# Query failure must remain a verification error rather than looking closed.
set +e
plan_finish_require_applied false "$base" plan-2026-01-10-phone
query_status=$?
set -e
if [ "$query_status" -ne 2 ]; then
  echo "FAIL: plan-list query failure should report verification error status 2, got $query_status" >&2
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
