#!/usr/bin/env bash
set -euo pipefail

# check-src-next-snapshot.sh
# Minimal fixture check for the src_next Stage 4a Snapshot observation screen.
# This is an opt-in src_next surface only; production remains bqn main.bqn.

fixture="${1:-fixtures/src-next-golden}"
expected="$fixture/expected/src_next_snapshot.txt"
output="$(mktemp)"
snapshot_actual="$(mktemp)"
trap 'rm -f "$output" "$snapshot_actual"' EXIT

if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi

if [ ! -f "$expected" ]; then
  echo "ERROR: expected snapshot golden not found: $expected" >&2
  exit 2
fi

tools/report-next-summary "$fixture" 2>/dev/null > "$output"

awk '
  /^--- SrcNext Snapshot ---/ { p=1 }
  p { print }
  /^  outlook_daily:/ { if (p) exit }
' "$output" > "$snapshot_actual"

diff -u "$expected" "$snapshot_actual"

required=(
  '--- SrcNext Snapshot ---'
  'as_of:'
  'cycle:'
  'next_income:'
  'remaining_days:'
  'status:'
  'account_totals: src_next/partial'
  'net_worth: 0'
  'daily_remaining:   fallback/current-engine'
  'food_remaining:    fallback/current-engine'
  'flex_remaining:    fallback/current-engine'
  'reserve_remaining: fallback/current-engine'
  'snapshot_base: src_next/tbds'
  'balances: src_next/tbds'
  'net_worth: src_next/tbds'
  'envelopes: fallback/current-engine'
  'outlook_daily: fallback/current-engine'
)

for needle in "${required[@]}"; do
  if ! grep -qF -- "$needle" "$snapshot_actual"; then
    echo "FAIL: snapshot missing required text: $needle" >&2
    exit 1
  fi
done

# Guard against accidentally claiming unavailable daily-use values are implemented.
if grep -Eq '^  (daily_remaining|food_remaining|flex_remaining|reserve_remaining):[[:space:]]*-?[0-9]' "$snapshot_actual"; then
  echo "FAIL: snapshot rendered a numeric living remaining value" >&2
  exit 1
fi

echo "OK: src_next Snapshot fixture check passed for $fixture" >&2
