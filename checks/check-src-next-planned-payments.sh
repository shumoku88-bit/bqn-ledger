#!/usr/bin/env bash
set -euo pipefail

# Verify compact SrcNext Planned Payments format/status vocabulary on fixtures.
# Does not bake in private production amounts. Completion parity is not claimed.

fixture="${1:-fixtures/src-next-golden}"
if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi

out="$(mktemp)"
trap 'rm -f "$out"' EXIT

tools/report-next-summary "$fixture" > "$out" 2>/dev/null

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

if grep -qF -- '--- SrcNext Planned Payments ---' "$out"; then
  pass "Planned Payments section found"
else
  fail "Planned Payments section missing"
fi

count=$(grep -c '^src_next_planned_payment:' "$out" || true)
if [ "$count" -ge 1 ]; then
  pass "Planned Payments line count >= 1 ($count)"
else
  fail "Planned Payments has no lines"
fi

awk '
  /^src_next_planned_payment: \(none\)$/ { next }
  /^src_next_planned_payment: / {
    rest=$0
    sub(/^src_next_planned_payment: /, "", rest)
    if (rest !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2} /) {
      printf("planned line missing date prefix: %s\n", $0) > "/dev/stderr"
      bad=1
    }
    n=split(rest, parts, " ")
    if (n < 6) {
      printf("planned line has too few fields: %s\n", $0) > "/dev/stderr"
      bad=1
    }
    if (parts[2] !~ /^(planned|paid|ambiguous)$/) {
      printf("planned status not in vocabulary: %s\n", $0) > "/dev/stderr"
      bad=1
    }
    if (parts[n] !~ /^(-|¯)?[0-9]+$/) {
      printf("planned amount is not integer: %s\n", $0) > "/dev/stderr"
      bad=1
    }
  }
  END { exit bad ? 1 : 0 }
' "$out" || fail "Planned Payments line format invalid"

if [ "$failures" -eq 0 ]; then
  echo "OK: src_next Planned Payments check passed for fixture: $fixture" >&2
  exit 0
else
  echo "FAILED: $failures Planned Payments check(s) failed" >&2
  exit 1
fi
