#!/usr/bin/env bash
set -euo pipefail

# Check: only src_next/date.bqn may read the system clock.
# All other modules must use date.bqn as the single approved entry point
# for obtaining today's date or any system time.

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

# Collect files in src_next/ that read the clock (excluding date.bqn itself)
clock_files=""
while IFS= read -r f; do
  case "$f" in
    */src_next/date.bqn) continue ;;
  esac
  # •SH with "date" or similar clock commands
  if grep -qE '•SH.*date|Today[[:space:]]*←|•Unix|•BQN.*time|datetime' "$f" 2>/dev/null; then
    clock_files="$clock_files $f"
  fi
done < <(find "$repo_root/src_next" -name '*.bqn' -type f)

if [ -n "$clock_files" ]; then
  for f in $clock_files; do
    fail "direct clock reference outside date.bqn: $f"
  done
else
  pass "no direct clock reference outside src_next/date.bqn"
fi

# Verify date.bqn exists and exports Today
if [ -f "$repo_root/src_next/date.bqn" ]; then
  if grep -q 'Today ←' "$repo_root/src_next/date.bqn"; then
    pass "src_next/date.bqn provides Today as approved clock entry point"
  else
    fail "src_next/date.bqn does not export Today"
  fi
else
  fail "src_next/date.bqn not found"
fi

if [ "$failures" -eq 0 ]; then
  echo "OK: clock boundary invariant holds" >&2
  exit 0
else
  echo "FAILED: $failures clock-boundary check(s) failed" >&2
  exit 1
fi
