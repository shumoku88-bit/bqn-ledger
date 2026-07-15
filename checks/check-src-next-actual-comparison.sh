#!/usr/bin/env bash
set -euo pipefail

# Verify src_next Actual Comparison section.
# Accepts implemented statuses (ok, unavailable, insufficient_history).
# Rejects legacy placeholders and unexpected statuses.

fixture="${1:-fixtures/actual-comparison-projection-normal}"
expected_status="${2:-}"
if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi

out="$(mktemp)"
trap 'rm -f "$out"' EXIT

tools/report-next-summary "$fixture" > "$out"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

if grep -qF -- '--- SrcNext Actual Comparison ---' "$out"; then
  pass "Actual Comparison section found"
else
  fail "Actual Comparison section missing"
fi

status="$(awk -F': ' '$1 == "src_next_actual_comparison_status" { print $2; exit }' "$out")"
reason="$(awk -F': ' '$1 == "src_next_actual_comparison_reason" { print $2; exit }' "$out")"

case "$status" in
  ok|unavailable|insufficient_history)
    pass "Actual Comparison status is valid: $status" ;;
  not_implemented)
    fail "Actual Comparison still reports legacy placeholder status: '$status'" ;;
  *)
    fail "Actual Comparison status unexpected: '$status'" ;;
esac

if [ -n "$expected_status" ] && [ "$status" != "$expected_status" ]; then
  fail "Actual Comparison status '$status' does not match expected '$expected_status'"
elif [ -n "$expected_status" ]; then
  pass "Actual Comparison status matches expected: $expected_status"
fi

# Reason field should be non-empty and meaningful
if [ -n "$reason" ]; then
  pass "Actual Comparison reason present: $reason"
else
  fail "Actual Comparison reason missing or empty"
fi

if grep -qiE 'actual.comparison.*(matched|parity|production.ready|ready)' "$out"; then
  fail "Actual Comparison output appears to claim parity/readiness"
else
  pass "Actual Comparison does not claim parity/readiness"
fi

if [ "$failures" -eq 0 ]; then
  echo "OK: src_next Actual Comparison check passed for fixture: $fixture" >&2
  exit 0
else
  echo "FAILED: $failures Actual Comparison check(s) failed" >&2
  exit 1
fi
