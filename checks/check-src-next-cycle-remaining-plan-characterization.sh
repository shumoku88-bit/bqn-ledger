#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-src-next-cycle-remaining-plan-characterization.sh
# Check: cycle-remaining-plan-characterization

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

# ── Tests ──

# 1. Run the BQN unit test
echo "Running BQN unit tests..."
if bqn tests/test_src_next_cycle_remaining_plan_characterization.bqn; then
  pass
else
  fail "BQN unit test failed"
fi

# 2. Verify summary outputs on root fixture using tools/report-next-summary and tools/query
echo "Verifying summary output via tools/query..."
# Query fields
plan_expense_remaining=$(bash tools/query fixtures/cycle-remaining-plan-characterization src_next_cycle_plan_expense_remaining)

assert_eq "500" "$plan_expense_remaining" "plan_expense_remaining should be 500"

# 3. Verify invalid-date crash via out-of-process probe
echo "Verifying invalid-date crash via subprocess..."
probe_output=$(mktemp)
probe_error=$(mktemp)
set +e
bqn checks/probes/cycle-summary-invalid-date.bqn > "$probe_output" 2> "$probe_error"
probe_exit_code=$?
set -e

# Assert non-zero exit code
if [ "$probe_exit_code" -ne 0 ]; then
  pass
else
  fail "Probe did not crash; exited with 0"
fi

# Assert combined output or stderr is non-empty and contains key error markers
combined_output=$(cat "$probe_output" "$probe_error")
if [ -n "$combined_output" ]; then
  pass
else
  fail "Probe output was completely empty"
fi

assert_contains "indexing out-of-bounds" "$combined_output" "Probe error should contain indexing out-of-bounds"
rm -f "$probe_output" "$probe_error"

# ── Summary ──
echo "check-src-next-cycle-remaining-plan-characterization: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
