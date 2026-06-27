#!/usr/bin/env bash
set -euo pipefail

# Verify src_next human-readable Stage 4 report surface.
# This is observation-only; production remains bqn main.bqn.

fixture="${1:-fixtures/src-next-golden}"
if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi

out="$(mktemp)"
trap 'rm -f "$out"' EXIT

bqn src_next/report.bqn "$fixture" > "$out"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

sections=(
  '1. 全体サマリ (Snapshot)'
  '== YTD Summary =='
  '== Account Balances =='
  '== Current Cycle Summary =='
  '== Envelope & Budget =='
  '== Planned Payments =='
  '7. 直近の取引 (Recent Journal)'
  '== Readiness Check =='
  '== Outlook Dashboard =='
  '== Daily Trend =='
  '== Actual Comparison =='
  '12. デバッグ・由来 (Debug & Provenance)'
)

for section in "${sections[@]}"; do
  if grep -qF -- "$section" "$out"; then
    pass "human report contains: $section"
  else
    fail "human report missing: $section"
  fi
done

if grep -qiE '(production.ready|default switch|replacement ready)' "$out"; then
  fail "human report appears to claim production readiness"
else
  pass "human report does not claim production readiness"
fi

if [ "$failures" -eq 0 ]; then
  echo "OK: src_next human report check passed for fixture: $fixture" >&2
  exit 0
else
  echo "FAILED: $failures src_next human report check(s) failed" >&2
  exit 1
fi
