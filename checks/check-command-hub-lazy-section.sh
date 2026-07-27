#!/usr/bin/env bash
set -euo pipefail

# Command-hub selected-report latency boundary.
#
# A cold selector must materialize only the chosen section, not synchronously
# generate the all-section cache before accepting a choice.

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

# Cold selector: choosing snapshot creates only snapshot cache material.
run_selection snapshot cold-snapshot
assert_code 0 cold-snapshot
if grep -qF '1. 全体サマリ (Snapshot)' "$work_dir/cold-snapshot.out"; then
  pass "cold command-hub selection renders snapshot"
else
  fail "cold command-hub selection did not render snapshot"
fi

cache_dir=$(find "$work_dir" -maxdepth 1 -type d -name 'bqn-ledger-cache-*' -print -quit)
if [[ -n "$cache_dir" && -f "$cache_dir/snapshot.txt" && -f "$cache_dir/snapshot.timestamp" ]]; then
  pass "cold selection materializes snapshot body and timestamp"
else
  fail "cold selection did not materialize snapshot cache"
fi

unexpected=(ytd.txt daily-flow.txt actual-comparison.txt all.txt .cache-timestamp)
for name in "${unexpected[@]}"; do
  if [[ -e "$cache_dir/$name" ]]; then
    fail "cold snapshot selection unexpectedly created $name"
  else
    pass "cold snapshot selection does not create $name"
  fi
done

text_count=$(find "$cache_dir" -maxdepth 1 -type f -name '*.txt' | wc -l | tr -d ' ')
if [[ "$text_count" = 1 ]]; then
  pass "cold selector builds exactly one report section"
else
  fail "cold selector built $text_count section text files, expected 1"
fi

# Cached body remains byte-related to the canonical direct selected route.
tools/report "$fixture" --section snapshot --no-color >"$work_dir/direct-snapshot.out" 2>"$work_dir/direct-snapshot.err"
cat "$cache_dir/snapshot.txt" >"$work_dir/cached-plus-print.out"
printf '\n\n' >>"$work_dir/cached-plus-print.out"
if cmp -s "$work_dir/direct-snapshot.out" "$work_dir/cached-plus-print.out"; then
  pass "lazy snapshot cache preserves direct selected bytes"
else
  fail "lazy snapshot cache differs from direct selected bytes"
fi

# Warm selector reuses the selected cache without rewriting it.
snapshot_file_mtime_before=$(stat -c %Y "$cache_dir/snapshot.txt" 2>/dev/null || stat -f %m "$cache_dir/snapshot.txt")
sleep 1
run_selection snapshot warm-snapshot
assert_code 0 warm-snapshot
snapshot_file_mtime_after=$(stat -c %Y "$cache_dir/snapshot.txt" 2>/dev/null || stat -f %m "$cache_dir/snapshot.txt")
if [[ "$snapshot_file_mtime_after" = "$snapshot_file_mtime_before" ]]; then
  pass "warm command-hub selection reuses snapshot cache"
else
  fail "warm command-hub selection rewrote fresh snapshot cache"
fi

# Choosing a second section adds only that section.
run_selection ytd cold-ytd
assert_code 0 cold-ytd
if grep -qF '== YTD Summary ==' "$work_dir/cold-ytd.out"; then
  pass "command-hub selection renders YTD"
else
  fail "command-hub selection did not render YTD"
fi
if [[ -f "$cache_dir/ytd.txt" && -f "$cache_dir/ytd.timestamp" ]]; then
  pass "YTD selection lazily materializes YTD cache"
else
  fail "YTD selection did not materialize YTD cache"
fi
text_count=$(find "$cache_dir" -maxdepth 1 -type f -name '*.txt' | wc -l | tr -d ' ')
if [[ "$text_count" = 2 ]]; then
  pass "two choices produce exactly two section text files"
else
  fail "two choices produced $text_count section text files, expected 2"
fi

if [[ "$failures" -eq 0 ]]; then
  echo "OK: command-hub lazy selected-section checks passed" >&2
  exit 0
fi

echo "FAILED: $failures command-hub lazy selected-section check(s) failed" >&2
exit 1
