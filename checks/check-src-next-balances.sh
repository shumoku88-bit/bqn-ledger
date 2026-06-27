#!/usr/bin/env bash
set -euo pipefail

# Verify compact SrcNext Balances format on fixtures.

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

if grep -qF -- '--- SrcNext Balances ---' "$out"; then
  pass "Balances section found"
else
  fail "Balances section missing"
fi

count=$(grep -c '^src_next_balance:' "$out" || true)
if [ "$count" -ge 1 ]; then
  pass "Balances line count >= 1 ($count)"
else
  fail "Balances has no lines"
fi

awk '
  /^src_next_balance: / {
    rest=$0
    sub(/^src_next_balance: /, "", rest)
    n=split(rest, parts, " ")
    if (n < 2) {
      printf("malformed balance line: %s\n", $0) > "/dev/stderr"
      bad=1
    } else if (parts[n] !~ /^(-|¯)?[0-9]+$/) {
      printf("balance amount is not integer: %s\n", $0) > "/dev/stderr"
      bad=1
    }
  }
  END { exit bad ? 1 : 0 }
' "$out" || fail "Balances line format invalid"

if [ "$failures" -eq 0 ]; then
  echo "OK: src_next Balances check passed for fixture: $fixture" >&2
  exit 0
else
  echo "FAILED: $failures Balances check(s) failed" >&2
  exit 1
fi
