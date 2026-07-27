#!/usr/bin/env bash
set -euo pipefail

# Command-hub browsing latency boundary.
#
# A cold selector prepares the complete report-owned section cache once before
# navigation. fzf previews then read files only, so moving quickly across rows
# never starts one expensive report process per highlighted section. When a
# default currency is available, balances preserves the selected-currency
# direct-section contract without making other ledgers unable to open the hub.

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
  local base="$1" key="$2" name="$3"
  set +e
  printf '%s\n' "$key" | TMPDIR="$work_dir" tools/main-ui.sh --base "$base" select \
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

cache_dir_for() {
  local base_abs sanitized
  base_abs="$(cd "$1" && pwd)"
  sanitized="${base_abs//\//_}"
  printf '%s/bqn-ledger-cache-%s\n' "$work_dir" "$sanitized"
}

section_keys=(
  snapshot issues ytd balances cycle trial-balance envelopes planned recent
  check outlook daily-trend daily-flow actual-comparison debug
)

# A cold selector prepares every preview body before accepting a choice. It must
# still open when the specialized selected balances route is unavailable.
run_selection "$fixture" snapshot cold-snapshot
assert_code 0 cold-snapshot
if grep -qF '1. 全体サマリ (Snapshot)' "$work_dir/cold-snapshot.out"; then
  pass "cold command-hub selection renders snapshot"
else
  fail "cold command-hub selection did not render snapshot"
fi

cache_dir="$(cache_dir_for "$fixture")"
if [[ -f "$cache_dir/.cache-timestamp" ]]; then
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

# A warm selector reuses the complete cache rather than rebuilding it.
snapshot_mtime_before=$(stat -c %Y "$cache_dir/snapshot.txt" 2>/dev/null || stat -f %m "$cache_dir/snapshot.txt")
balances_mtime_before=$(stat -c %Y "$cache_dir/balances.txt" 2>/dev/null || stat -f %m "$cache_dir/balances.txt")
timestamp_before=$(cat "$cache_dir/.cache-timestamp")
sleep 1
run_selection "$fixture" ytd warm-ytd
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

# Add a controlled default currency and prove the command-hub balances body is
# byte-identical to the specialized direct selected-currency route.
selected_fixture="$work_dir/selected-fixture"
mkdir -p "$selected_fixture"
cp -R "$fixture"/. "$selected_fixture"/
printf 'DEFAULT_CURRENCY=JPY\n' >"$selected_fixture/config.tsv"

run_selection "$selected_fixture" balances selected-cold-balances
assert_code 0 selected-cold-balances
if grep -qF 'Currency view: JPY' "$work_dir/selected-cold-balances.out"; then
  pass "selected-currency command-hub balances renders the default currency view"
else
  fail "selected-currency command-hub balances did not render the default currency view"
fi

selected_cache_dir="$(cache_dir_for "$selected_fixture")"
tools/report "$selected_fixture" --section balances --no-color >"$work_dir/direct-balances.out" 2>"$work_dir/direct-balances.err"
cat "$selected_cache_dir/balances.txt" >"$work_dir/cached-balances.out"
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

selected_balances_mtime_before=$(stat -c %Y "$selected_cache_dir/balances.txt" 2>/dev/null || stat -f %m "$selected_cache_dir/balances.txt")
selected_timestamp_before=$(cat "$selected_cache_dir/.cache-timestamp")
sleep 1
run_selection "$selected_fixture" balances selected-warm-balances
assert_code 0 selected-warm-balances
selected_balances_mtime_after=$(stat -c %Y "$selected_cache_dir/balances.txt" 2>/dev/null || stat -f %m "$selected_cache_dir/balances.txt")
selected_timestamp_after=$(cat "$selected_cache_dir/.cache-timestamp")
if [[ "$selected_balances_mtime_after" = "$selected_balances_mtime_before" \
   && "$selected_timestamp_after" = "$selected_timestamp_before" ]]; then
  pass "warm selected-currency balances preview reuses the complete cache"
else
  fail "warm selected-currency balances preview unexpectedly rebuilt the cache"
fi

if [[ "$failures" -eq 0 ]]; then
  echo "OK: command-hub browse-cache checks passed" >&2
  exit 0
fi

echo "FAILED: $failures command-hub browse-cache check(s) failed" >&2
exit 1
