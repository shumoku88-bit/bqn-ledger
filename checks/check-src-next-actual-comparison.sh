#!/usr/bin/env bash
set -euo pipefail

# Verify the migrated Actual Comparison status, fail-closed output, and explicit
# BuildAt production boundary.

fixture="${1:-fixtures/actual-comparison-numeric-owner-target}"
expected_status="${2:-}"
if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi

out="$(mktemp)"
section="$(mktemp)"
trap 'rm -f "$out" "$section"' EXIT

tools/report-next-summary "$fixture" > "$out"
awk '/^--- SrcNext Actual Comparison ---/{capture=1} capture{print}' "$out" > "$section"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

if grep -qF -- '--- SrcNext Actual Comparison ---' "$section"; then
  pass "Actual Comparison section found"
else
  fail "Actual Comparison section missing"
fi

status="$(awk -F': ' '$1 == "src_next_actual_comparison_status" { print $2; exit }' "$section")"
reason="$(awk -F': ' '$1 == "src_next_actual_comparison_reason" { print $2; exit }' "$section")"
rows="$(grep -c '^src_next_actual_comparison_row:' "$section" || true)"
diagnostics="$(grep -c '^src_next_actual_comparison_diagnostic:' "$section" || true)"

case "$status" in
  ok|unavailable|error) pass "Actual Comparison status is valid: $status" ;;
  insufficient_history) fail "removed status returned: insufficient_history" ;;
  *) fail "Actual Comparison status unexpected: '$status'" ;;
esac

if [ -n "$expected_status" ] && [ "$status" != "$expected_status" ]; then
  fail "Actual Comparison status '$status' does not match expected '$expected_status'"
elif [ -n "$expected_status" ]; then
  pass "Actual Comparison status matches expected: $expected_status"
fi

if [ -n "$reason" ]; then
  pass "Actual Comparison reason present: $reason"
else
  fail "Actual Comparison reason missing or empty"
fi

case "$status" in
  ok)
    if [ "$rows" -gt 0 ]; then pass "ok output has numeric rows"; else fail "ok output has no numeric rows"; fi
    if [ "$reason" != "comparison_active" ]; then fail "ok reason is not comparison_active: $reason"; fi
    ;;
  unavailable)
    if [ "$rows" -eq 0 ]; then pass "unavailable output has no numeric rows"; else fail "unavailable output leaked numeric rows"; fi
    if [ "$reason" = "rejected_actual_evidence" ]; then fail "unavailable collapsed an error reason"; fi
    ;;
  error)
    if [ "$rows" -eq 0 ]; then pass "error output has no numeric rows"; else fail "error output leaked numeric rows"; fi
    if [ "$diagnostics" -gt 0 ]; then pass "error output has source diagnostic"; else fail "error output has no source diagnostic"; fi
    if [ "$reason" != "rejected_actual_evidence" ]; then fail "fixture error reason is not rejected_actual_evidence: $reason"; fi
    ;;
esac

if grep -q 'insufficient_history' "$section"; then
  fail "Actual Comparison output contains removed insufficient_history vocabulary"
else
  pass "removed insufficient_history vocabulary is absent"
fi

if rg -n 'actual_comparison\.Build([ (]|$)' src_next tests >/dev/null; then
  fail "legacy actual_comparison.Build call site remains"
else
  pass "all Actual Comparison call sites use BuildAt"
fi

if [ "$failures" -eq 0 ]; then
  echo "OK: src_next Actual Comparison check passed for fixture: $fixture" >&2
  exit 0
fi

echo "FAILED: $failures Actual Comparison check(s) failed" >&2
exit 1
