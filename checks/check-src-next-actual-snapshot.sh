#!/usr/bin/env bash
set -euo pipefail

# Guard the Slice A checked numeric-owner boundary and Outlook fail-closed
# propagation. Detailed behavior lives in the focused BQN test.

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

focused="$(mktemp)"
summary="$(mktemp)"
trap 'rm -f "$focused" "$summary"' EXIT

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

build_at_body="$(awk '/^BuildAt ←/{capture=1} /^Build ←/{capture=0} capture{print}' src_next/actual_snapshot.bqn)"

if grep -qF 'ctx.posting_rows' <<<"$build_at_body" && grep -qF 'tbds.Build' <<<"$build_at_body"; then
  pass "BuildAt uses checked postings and TBDS"
else
  fail "BuildAt checked posting/TBDS owner missing"
fi

if grep -Eq 'ReadLines|•BQN' <<<"$build_at_body"; then
  fail "BuildAt still reads or reparses source amounts"
else
  pass "BuildAt has no source read or amount parser"
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
