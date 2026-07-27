#!/usr/bin/env bash
set -euo pipefail

# Guard the Slice A checked numeric-owner boundary and Outlook fail-closed
# propagation. Detailed behavior lives in the focused BQN test.

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

focused="$(mktemp)"
prepared="$(mktemp)"
summary="$(mktemp)"
trap 'rm -f "$focused" "$prepared" "$summary"' EXIT

if bqn tests/test_src_next_actual_snapshot_numeric_owner.bqn >"$focused" 2>&1; then
  pass "focused checked actual snapshot behavior"
else
  cat "$focused" >&2
  fail "focused checked actual snapshot behavior"
fi

if grep -qF 'test_src_next_actual_snapshot_numeric_owner.bqn: OK' "$focused"; then
  pass "focused test completion marker"
else
  fail "focused test completion marker missing"
fi

if bqn tests/test_src_next_actual_snapshot_prepared.bqn >"$prepared" 2>&1; then
  pass "prepared actual snapshot boundary"
else
  cat "$prepared" >&2
  fail "prepared actual snapshot boundary"
fi

if grep -qF 'test_src_next_actual_snapshot_prepared.bqn: OK' "$prepared"; then
  pass "prepared boundary completion marker"
else
  fail "prepared boundary completion marker missing"
fi

if tools/report-next-summary fixtures/actual-snapshot-numeric-owner-target >"$summary" 2>&1; then
  pass "target fixture compact summary renders"
else
  cat "$summary" >&2
  fail "target fixture compact summary failed"
fi

for expected in \
  'src_next_outlook_status: ok' \
  'src_next_outlook_reason: outlook_active'; do
  if grep -qF "$expected" "$summary"; then
    pass "compact Outlook field: $expected"
  else
    fail "compact Outlook field missing: $expected"
  fi
done

if [ "$failures" -eq 0 ]; then
  echo "OK: src_next actual snapshot check passed" >&2
  exit 0
fi

echo "FAILED: $failures actual snapshot check(s) failed" >&2
exit 1
