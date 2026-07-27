#!/usr/bin/env bash
set -euo pipefail

# Command-hub browsing latency boundary.
#
# A cold selector prepares the complete report-owned section cache once before
# navigation. fzf previews then read files only, so moving quickly across rows
# never starts one expensive report process per highlighted section. The
# balances preview preserves the selected-currency direct-section contract.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export NO_COLOR=1
fixture="${1:-fixtures/src-next-golden}"
if [[ ! -d "$fixture" ]]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

run_selection() {
  local key="$1" name="$2"
  set +e
  printf '%s\n' "$key" | TMPDIR="$work_dir" tools/main-ui.sh --base "$fixture" select \
    >"$work_dir/$name.out" 2>"$work_dir/$name.err"
  local code=$?
  set -e
  printf '%s\n' "$code" >"$work_dir/$name.code"
}

assert_code() {
  local expected="$1" name="$2"
  local actual
  actual="$(cat "$work_dir/$name.code")"
  if [[ "$actual" = "$expected" ]]; then
    pass "$name exit status is $expected"
  else
    fail "$name exit status was $actual, expected $expected"
  fi
}

section_keys=(
  snapshot issues ytd balances cycle trial-balance envelopes planned recent
  check outlook daily-trend daily-flow actual-comparison debug
)

# A cold selector prepares every preview body before accepting a choice.
run_selection snapshot cold-snapshot
assert_code 0 cold-snapshot
if grep -qF '1. 全体サマリ (Snapshot)' "$work_dir/cold-snapshot.out"; then
  pass "cold command-hub selection renders snapshot"
else
  fail "cold command-hub selection did not render snapshot"
fi

cache_dir=$(find "$work_dir" -maxdepth 1 -type d -name 'bqn-ledger-cache-*' -print -quit)
if [[ -n "$cache_dir" && -f "$cache_dir/.cache-timestamp" ]]; then
  pass "cold selector writes global cache timestamp"
else
  fail "cold selector did not write global cache timestamp"
fi

for key in "${section_keys[@]}"; do
  if [[ -f "$cache_dir/$key.txt" ]]; then
    pass "cold selector prepares $key preview"
  else
    fail "cold selector did not prepare $key preview"
  fi
done
if [[ -f "$cache_dir/all.txt" ]]; then
  pass "cold selector prepares full report cache"
else
  fail "cold selector did not prepare full report cache"
fi

text_count=$(find "$cache_dir" -maxdepth 1 -type f -name '*.txt' | wc -l | tr -d ' ')
expected_count=$((${#section_keys[@]} + 1))
if [[ "$text_count" = "$expected_count" ]]; then
  pass "cold selector builds all $expected_count report cache files once"
else
  fail "cold selector built $text_count report cache files, expected $expected_count"
fi

# Command-hub balances must retain the selected-currency direct route rather
# than the mixed full-report balances body produced by --write-section-cache.
tools/report "$fixture" --section balances --no-color >"$work_dir/direct-balances.out" 2>"$work_dir/direct-balances.err"
cat "$cache_dir/balances.txt" >"$work_dir/cached-balances.out"
printf '\n\n' >>"$work_dir/cached-balances.out"
if cmp -s "$work_dir/direct-balances.out" "$work_dir/cached-balances.out"; then
  pass "command-hub balances cache preserves selected-currency direct bytes"
else
  fail "command-hub balances cache differs from selected-currency direct bytes"
fi
if [[ ! -s "$work_dir/direct-balances.err" ]]; then
  pass "direct balances comparison stderr is empty"
else
  fail "direct balances comparison stderr is not empty"
fi

# A warm selector reuses the complete cache rather than rebuilding it.
snapshot_mtime_before=$(stat -c %Y "$cache_dir/snapshot.txt" 2>/dev/null || stat -f %m "$cache_dir/snapshot.txt")
balances_mtime_before=$(stat -c %Y "$cache_dir/balances.txt" 2>/dev/null || stat -f %m "$cache_dir/balances.txt")
timestamp_before=$(cat "$cache_dir/.cache-timestamp")
sleep 1
run_selection ytd warm-ytd
assert_code 0 warm-ytd
if grep -qF '== YTD Summary ==' "$work_dir/warm-ytd.out"; then
  pass "warm command-hub selection renders YTD"
else
  fail "warm command-hub selection did not render YTD"
fi
snapshot_mtime_after=$(stat -c %Y "$cache_dir/snapshot.txt" 2>/dev/null || stat -f %m "$cache_dir/snapshot.txt")
balances_mtime_after=$(stat -c %Y "$cache_dir/balances.txt" 2>/dev/null || stat -f %m "$cache_dir/balances.txt")
timestamp_after=$(cat "$cache_dir/.cache-timestamp")
if [[ "$snapshot_mtime_after" = "$snapshot_mtime_before" \
   && "$balances_mtime_after" = "$balances_mtime_before" \
   && "$timestamp_after" = "$timestamp_before" ]]; then
  pass "warm selector reuses complete preview cache"
else
  fail "warm selector unexpectedly rebuilt complete preview cache"
fi

if [[ "$failures" -eq 0 ]]; then
  echo "OK: command-hub browse-cache checks passed" >&2
  exit 0
fi

echo "FAILED: $failures command-hub browse-cache check(s) failed" >&2
exit 1
