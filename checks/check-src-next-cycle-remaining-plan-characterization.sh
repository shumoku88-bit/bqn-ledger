#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-src-next-cycle-remaining-plan-characterization.sh
# Check: cycle-remaining-plan-runtime contract over public characterization fixtures

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
assert_eq() {
  local expected="$1" actual="$2" label="${3:-}"
  if [ "$expected" = "$actual" ]; then
    pass
  else
    fail "${label:-assert_eq}: expected [$expected] got [$actual]"
  fi
}

assert_contains() {
  local pattern="$1" text="$2" label="${3:-}"
  if [[ "$text" == *"$pattern"* ]]; then
    pass
  else
    fail "${label:-assert_contains}: pattern [$pattern] not found in text"
  fi
}

assert_not_contains() {
  local pattern="$1" text="$2" label="${3:-}"
  if [[ "$text" != *"$pattern"* ]]; then
    pass
  else
    fail "${label:-assert_not_contains}: unexpected pattern [$pattern] found in text"
  fi
}

# ── Tests ──

# 1. Run the BQN unit test
echo "Running BQN unit tests..."
if bqn tests/test_src_next_cycle_remaining_plan_characterization.bqn; then
  pass
else
  fail "BQN unit test failed"
fi

# 2. Verify normal summary output through the public query path.
echo "Verifying normal summary output via tools/query..."
plan_expense_remaining=$(bash tools/query fixtures/cycle-remaining-plan-characterization src_next_cycle_plan_expense_remaining)
assert_eq "500" "$plan_expense_remaining" "plan_expense_remaining should be 500"

# 3. Verify invalid dates stop the whole Cycle Summary with source-row reasons.
echo "Verifying controlled invalid-date Cycle Summary error..."
set +e
probe_output=$(bqn checks/probes/cycle-summary-invalid-date.bqn 2>&1)
probe_exit_code=$?
set -e

assert_eq "0" "$probe_exit_code" "invalid-date probe should return controlled output"
assert_contains "src_next_cycle_state: error" "$probe_output" "probe should expose Cycle error state"
assert_contains "src_next_cycle_reason: rejected_plan_evidence" "$probe_output" "probe should expose failure reason"
assert_contains "src_next_cycle_diagnostic_count: 2" "$probe_output" "probe should expose both invalid rows"
assert_contains "src_next_cycle_diagnostic_1_status: invalid_date" "$probe_output" "first invalid row should be identified"
assert_contains "src_next_cycle_diagnostic_2_status: invalid_date" "$probe_output" "second invalid row should be identified"
assert_not_contains "src_next_cycle_income_actual:" "$probe_output" "error output must suppress normal Cycle numbers"
assert_not_contains "src_next_cycle_plan_expense_remaining:" "$probe_output" "error output must suppress remaining amount"

# ── Summary ──
echo "check-src-next-cycle-remaining-plan-characterization: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
