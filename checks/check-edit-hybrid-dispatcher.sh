#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-edit-hybrid-dispatcher.sh
# Check: edit-hybrid-dispatcher smoke check routing assertions.

# Resolve repo root
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# ── Test state ──
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1" >&2; }

# ── Assert helpers ──
assert_contains() {
  local needle="$1" haystack="$2" label="${3:-}"
  if echo "$haystack" | grep -qF "$needle"; then
    pass
  else
    fail "${label:-assert_contains}: [$needle] not found in trace"
  fi
}

# ── Tests ──

# Test 1: routing for journal add (BQN)
trace1="$(bash -x tools/edit --base data journal add --date 2026-06-30 --memo "test" --from assets:bank --to expenses:食費 --amount 100 --dry-run 2>&1 || true)"
assert_contains "edit-bqn" "$trace1" "journal-add-routed-to-bqn"

# Test 2: routing for plan edit (BQN)
trace2="$(bash -x tools/edit --base data plan edit --index 1 --date 2026-06-30 --dry-run 2>&1 || true)"
assert_contains "edit-bqn" "$trace2" "plan-edit-routed-to-bqn"

# Test 3: routing for plan finish (BQN)
trace3="$(bash -x tools/edit --base data plan finish --index 1 --actual-date 2026-06-29 --dry-run 2>&1 || true)"
assert_contains "edit-bqn" "$trace3" "plan-finish-routed-to-bqn"

# Test 4: routing for journal reverse (BQN)
trace4="$(bash -x tools/edit --base data journal reverse --index 1 --dry-run 2>&1 || true)"
assert_contains "edit-bqn" "$trace4" "journal-reverse-routed-to-bqn"

# Test 5: routing for plan list (BQN)
trace5="$(bash -x tools/edit --base data plan list --format tsv 2>&1 || true)"
assert_contains "edit-bqn" "$trace5" "plan-list-routed-to-bqn"

# Test 6: routing for budget add (BQN)
trace6="$(bash -x tools/edit --base data budget add --date 2026-06-30 --memo "test" --from assets:bank --to expenses:食費 --amount 100 --dry-run 2>&1 || true)"
assert_contains "edit-bqn" "$trace6" "budget-add-routed-to-bqn"

# Test 7: routing for issue add (BQN)
trace7="$(bash -x tools/edit --base data issue add --date 2026-06-30 --title "test" --amount 100 --memo "test" --dry-run 2>&1 || true)"
assert_contains "edit-bqn" "$trace7" "issue-add-routed-to-bqn"

# ── Summary ──
echo "check-edit-hybrid-dispatcher: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
