#!/usr/bin/env bash
set -euo pipefail

# checks/check-report-cache-nested-module-invalidation.sh — verify lazy section-cache invalidation
#
# Asserts that modifying the mtime of any BQN module under src_next (root or
# nested subdirectories) invalidates a materialized command-hub section.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export NO_COLOR=1
fixture="${1:-fixtures/src-next-golden}"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

tmp_dir="$(mktemp -d)"
orig_root_mtime="$(mktemp)"
orig_nested_mtime="$(mktemp)"

root_file="$ROOT_DIR/src_next/report.bqn"
nested_file="$ROOT_DIR/src_next/queries/exact_sparse_grouping.bqn"

touch -r "$root_file" "$orig_root_mtime"
touch -r "$nested_file" "$orig_nested_mtime"

cleanup() {
  touch -r "$orig_root_mtime" "$root_file" 2>/dev/null || true
  touch -r "$orig_nested_mtime" "$nested_file" 2>/dev/null || true
  rm -rf "$tmp_dir" "$orig_root_mtime" "$orig_nested_mtime" 2>/dev/null || true
}
trap cleanup EXIT

run_snapshot_selection() {
  printf 'snapshot\n' | TMPDIR="$tmp_dir" "$ROOT_DIR/tools/main-ui.sh" --base "$fixture" select >/dev/null 2>&1
}

# Step 1: Initial lazy snapshot materialization
run_snapshot_selection
cache_dir=$(find "$tmp_dir" -maxdepth 1 -type d -name 'bqn-ledger-cache-*' -print -quit)
stamp_file="$cache_dir/snapshot.timestamp"

if [[ -z "$cache_dir" || ! -f "$stamp_file" || ! -f "$cache_dir/snapshot.txt" ]]; then
  fail "Initial lazy snapshot cache did not produce snapshot body and timestamp"
  exit 1
fi

t1=$(cat "$stamp_file")

# Step 2: Test root module modification invalidates only when selected again
sleep 1
touch "$root_file"
run_snapshot_selection
t2=$(cat "$stamp_file")

if (( t2 > t1 )); then
  pass "Root BQN module modification invalidates lazy snapshot cache"
else
  fail "Root BQN module modification failed to invalidate lazy snapshot cache (t1=$t1, t2=$t2)"
fi

# Step 3: Test nested BQN module modification invalidates selected cache
sleep 1
touch "$nested_file"
run_snapshot_selection
t3=$(cat "$stamp_file")

if (( t3 > t2 )); then
  pass "Nested BQN module modification invalidates lazy snapshot cache"
else
  fail "Nested BQN module modification failed to invalidate lazy snapshot cache (t2=$t2, t3=$t3)"
fi

if (( failures > 0 )); then
  echo "check-report-cache-nested-module-invalidation: $failures failure(s)" >&2
  exit 1
else
  echo "check-report-cache-nested-module-invalidation: OK"
fi
