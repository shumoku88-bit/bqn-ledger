#!/usr/bin/env bash
set -euo pipefail

# Command-hub browsing latency boundary.
#
# Non-interactive selection prepares the complete report-owned cache
# synchronously for deterministic scripts. Interactive selection opens first
# and refreshes that same cache in the background. Highlight movement only reads
# cache/status files and never starts the report engine. When a default currency
# is available, balances preserves the selected-currency direct-section contract.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export NO_COLOR=1
fixture="${1:-fixtures/editor-golden}"
selected_fixture="${2:-fixtures/demo}"
if [[ ! -d "$fixture" ]]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi
if [[ ! -d "$selected_fixture" ]]; then
  echo "ERROR: selected-currency fixture directory not found: $selected_fixture" >&2
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

section_keys=()
while IFS= read -r key; do
  section_keys+=("$key")
done < <(tools/report-section-metadata | awk -F'\t' 'NR > 1 { print $1 }')

# A non-interactive cold selection prepares every preview body before accepting
# a choice. It must still work when selected balances is unavailable.
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
if [[ -f "$cache_dir/.section-keys" ]] \
  && diff -u <(printf '%s\n' "${section_keys[@]}" all) "$cache_dir/.section-keys" >/dev/null; then
  pass "cache key manifest follows structured report metadata order"
else
  fail "cache key manifest differs from structured report metadata"
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

# Use a canonical fixture with DEFAULT_CURRENCY and the complete production
# policy surface. Prove command-hub balances is byte-identical to the
# specialized direct selected-currency route.
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

tools/report "$selected_fixture" --no-color >"$work_dir/direct-full.out" 2>"$work_dir/direct-full.err"
if cmp -s "$work_dir/direct-full.out" "$selected_cache_dir/all.txt"; then
  pass "command-hub all cache is byte-identical to the direct full report"
else
  fail "command-hub all cache differs from the direct full report"
fi
if python3 - "$selected_cache_dir/balances.txt" "$selected_cache_dir/all.txt" <<'PY'
from pathlib import Path
import sys

section = Path(sys.argv[1]).read_bytes()
full = Path(sys.argv[2]).read_bytes()
if section + b"\n\n" not in full:
    raise SystemExit(1)
PY
then
  pass "full report embeds the canonical selected-currency balances body"
else
  fail "full report does not embed the canonical selected-currency balances body"
fi
report_call_count=$(grep -c '"$ROOT_DIR/tools/report"' tools/command-hub-cache-refresh || true)
if [[ "$report_call_count" -eq 1 ]] && ! grep -q -- '--section balances' tools/command-hub-cache-refresh; then
  pass "cache refresh delegates all section generation to one BQN report route"
else
  fail "cache refresh retains a specialized balances generation route"
fi

invalid_default_base="$work_dir/invalid-default"
cp -R "$selected_fixture" "$invalid_default_base"
python3 - "$invalid_default_base/config.tsv" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
if text.count("DEFAULT_CURRENCY=JPY") != 1:
    raise SystemExit("expected one demo DEFAULT_CURRENCY declaration")
path.write_text(text.replace("DEFAULT_CURRENCY=JPY", "DEFAULT_CURRENCY=XYZ"), encoding="utf-8")
PY
if tools/report "$invalid_default_base" --no-color >"$work_dir/invalid-default.out" 2>"$work_dir/invalid-default.err"; then
  fail "full report silently fell back from an invalid declared currency"
elif grep -qF 'ERROR: unsupported default currency: XYZ' "$work_dir/invalid-default.out"; then
  pass "full report fails closed for an invalid declared currency"
else
  fail "full report invalid-currency failure changed unexpectedly"
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

# Characterize the interactive boundary without terminal automation. A delayed
# test hook proves forced-background mode returns while generation is still in
# progress, exposes an explicit updating preview instead of stale amounts, and
# eventually publishes the complete cache after the caller exits.
async_work="$work_dir/async"
mkdir "$async_work"
async_cache=""
command_hub_slow_refresh() { sleep 2; }
export -f command_hub_slow_refresh
set +e
printf '\n' | \
  BQN_LEDGER_TEST_MODE=1 \
  COMMAND_HUB_CACHE_TEST_BEFORE_BUILD_HOOK=command_hub_slow_refresh \
  COMMAND_HUB_CACHE_REFRESH_MODE=background \
  TMPDIR="$async_work" \
  tools/main-ui.sh --base "$selected_fixture" select \
  >"$work_dir/async.out" 2>"$work_dir/async.err"
async_status=$?
set -e
if [[ "$async_status" -eq 0 ]]; then
  pass "background cold selector returns without waiting for cache generation"
else
  fail "background cold selector exited with status $async_status"
fi
async_cache="$(find "$async_work" -maxdepth 1 -type d -name 'bqn-ledger-cache-*' -print -quit)"
if [[ -n "$async_cache" && -f "$async_cache/.cache-refreshing" && ! -f "$async_cache/.cache-timestamp" ]]; then
  pass "background cold selector leaves refresh running after selector closes"
else
  fail "background cold selector did not expose in-progress cache state"
fi
if [[ -n "$async_cache" ]] \
  && tools/command-hub-preview "$async_cache" snapshot | grep -qF 'Previewを更新中です。'; then
  pass "in-progress preview is explicit and non-stale"
else
  fail "in-progress preview did not report refresh state"
fi
for _ in $(seq 1 200); do
  [[ -n "$async_cache" && -f "$async_cache/.cache-timestamp" && ! -f "$async_cache/.cache-refreshing" ]] && break
  sleep 0.1
done
if [[ -n "$async_cache" && -f "$async_cache/.cache-timestamp" && -f "$async_cache/balances.txt" && ! -f "$async_cache/.cache-refreshing" ]]; then
  pass "background refresh eventually publishes the complete cache"
else
  fail "background refresh did not publish the complete cache"
fi

if [[ "$failures" -eq 0 ]]; then
  echo "OK: command-hub browse-cache checks passed" >&2
  exit 0
fi

echo "FAILED: $failures command-hub browse-cache check(s) failed" >&2
exit 1
