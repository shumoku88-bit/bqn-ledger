#!/usr/bin/env bash
set -euo pipefail

# Check: budget:* accounts must never carry nonzero Actual layer totals.
# budget accounts are virtual tracking buckets; actual money movements
# belong in real accounts (assets, expenses, income, equity).

base="${1:-fixtures/basic}"
if [ ! -d "$base" ]; then
  echo "ERROR: base directory not found: $base" >&2
  exit 2
fi

output="$(mktemp)"
trap 'rm -f "$output"' EXIT

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

bqn src_next/main.bqn "$base" > "$output" 2>/dev/null

# Section: nonzero actual account totals
# If any budget:* account appears here, it carries nonzero actual totals — invariant broken.
in_section=0
while IFS= read -r line; do
  if [ "$in_section" -eq 1 ]; then
    # Exit section on empty line or next section header
    case "$line" in
      ""|"---"*) break ;;
    esac
    if echo "$line" | grep -qF 'budget:'; then
      fail "budget account with nonzero actual total: $line"
    fi
  fi
  if echo "$line" | grep -qF 'nonzero actual account totals:'; then
    in_section=1
  fi
done < "$output"

if [ "$failures" -eq 0 ]; then
  echo "OK: budget:* Actual layer zero invariant holds for base: $base" >&2
  exit 0
else
  echo "FAILED: $failures budget-actual-zero check(s) failed for base: $base" >&2
  exit 1
fi
