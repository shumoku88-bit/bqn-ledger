#!/usr/bin/env bash
set -euo pipefail

# Verify compact SrcNext Recent Journal format on fixtures.
# Does not bake in private production amounts.

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

if grep -qF -- '--- SrcNext Recent Journal ---' "$out"; then
  pass "Recent Journal section found"
else
  fail "Recent Journal section missing"
fi

count=$(grep -c '^src_next_recent_journal:' "$out" || true)
if [ "$count" -ge 1 ] && [ "$count" -le 10 ]; then
  pass "Recent Journal line count in range 1..10 ($count)"
else
  fail "Recent Journal line count out of range: $count"
fi

awk '
  /^src_next_recent_journal: \(none\)$/ { next }
  /^src_next_recent_journal: / {
    rest=$0
    sub(/^src_next_recent_journal: /, "", rest)
    if (rest !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2} /) {
      printf("recent line missing date prefix: %s\n", $0) > "/dev/stderr"
      bad=1
    }
    if (rest !~ / -> /) {
      printf("recent line missing from/to arrow: %s\n", $0) > "/dev/stderr"
      bad=1
    }
    n=split(rest, parts, " ")
    if (parts[n] !~ /^(-|¯)?[0-9]+$/) {
      printf("recent amount is not integer: %s\n", $0) > "/dev/stderr"
      bad=1
    }
  }
  END { exit bad ? 1 : 0 }
' "$out" || fail "Recent Journal line format invalid"

if [ "$failures" -eq 0 ]; then
  echo "OK: src_next Recent Journal check passed for fixture: $fixture" >&2
  exit 0
else
  echo "FAILED: $failures Recent Journal check(s) failed" >&2
  exit 1
fi
