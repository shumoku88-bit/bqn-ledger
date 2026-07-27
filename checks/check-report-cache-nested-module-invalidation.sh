#!/usr/bin/env bash
set -euo pipefail

# checks/check-report-cache-nested-module-invalidation.sh — verify section cache invalidation for root and nested BQN modules
#
# Asserts that modifying mtime of any BQN module under src_next (root or nested subdirectories)
# invalidates tools/main-ui.sh section cache.

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

# Step 1: Initial cache generation
TMPDIR="$tmp_dir" "$ROOT_DIR/tools/main-ui.sh" --base "$fixture" select <<< "" >/dev/null 2>&1 || true
cache_dir=$(ls -d "$tmp_dir"/bqn-ledger-cache-* 2>/dev/null | head -1)

if [[ -z "$cache_dir" || ! -f "$cache_dir/.cache-timestamp" ]]; then
  fail "Initial section cache generation failed to produce .cache-timestamp"
  exit 1
fi

t1=$(cat "$cache_dir/.cache-timestamp")

# Step 2: Test root module modification invalidates cache
sleep 1
touch "$root_file"
TMPDIR="$tmp_dir" "$ROOT_DIR/tools/main-ui.sh" --base "$fixture" select <<< "" >/dev/null 2>&1 || true
t2=$(cat "$cache_dir/.cache-timestamp")

if (( t2 > t1 )); then
  pass "Root BQN module modification invalidates section cache"
else
  fail "Root BQN module modification failed to invalidate section cache (t1=$t1, t2=$t2)"
fi

# Step 3: Test nested BQN module modification invalidates cache
sleep 1
touch "$nested_file"
TMPDIR="$tmp_dir" "$ROOT_DIR/tools/main-ui.sh" --base "$fixture" select <<< "" >/dev/null 2>&1 || true
t3=$(cat "$cache_dir/.cache-timestamp")

if (( t3 > t2 )); then
  pass "Nested BQN module modification invalidates section cache"
else
  fail "Nested BQN module modification failed to invalidate section cache (t2=$t2, t3=$t3)"
fi

if (( failures > 0 )); then
  echo "check-report-cache-nested-module-invalidation: $failures failure(s)" >&2
  exit 1
else
  echo "check-report-cache-nested-module-invalidation: OK"
fi
