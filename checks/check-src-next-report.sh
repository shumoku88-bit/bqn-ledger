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
section_out="$(mktemp)"
bad_out="$(mktemp)"
bad_err="$(mktemp)"
trap 'rm -f "$out" "$section_out" "$bad_out" "$bad_err"' EXIT

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

if tools/report "$fixture" --section envelopes --no-color >"$section_out" 2>/dev/null; then
  if grep -qF -- '== Envelope & Budget ==' "$section_out"; then
    pass "report --section envelopes contains the envelope header"
  else
    fail "report --section envelopes missing the envelope header"
  fi

  if grep -qF -- '== Planned Payments ==' "$section_out"; then
    fail "report --section envelopes leaked the next section header"
  else
    pass "report --section envelopes stays within one section"
  fi
else
  fail "report --section envelopes failed"
fi

if tools/report "$fixture" --section snapshot --no-color >"$section_out" 2>/dev/null; then
  if grep -qF -- '1. 全体サマリ (Snapshot)' "$section_out"; then
    pass "report --section snapshot contains the snapshot header"
  else
    fail "report --section snapshot missing the snapshot header"
  fi

  if grep -qF -- '== YTD Summary ==' "$section_out"; then
    fail "report --section snapshot leaked the next section header"
  else
    pass "report --section snapshot stays within one section"
  fi
else
  fail "report --section snapshot failed"
fi

if tools/report "$fixture" --section does-not-exist --no-color >"$bad_out" 2>"$bad_err"; then
  fail "report --section does-not-exist unexpectedly succeeded"
else
  pass "report --section does-not-exist fails"
fi

# JSON output verification
json_out="$(mktemp)"
if tools/report "$fixture" --section planned --format json >"$json_out" 2>/dev/null; then
  if grep -qF -- '"open_items":' "$json_out" && grep -qF -- '"open_total":' "$json_out"; then
    pass "report --section planned --format json returns valid JSON"
  else
    fail "report --section planned --format json missing required fields"
  fi
else
  fail "report --section planned --format json failed"
fi
rm -f "$json_out"

if tools/report "$fixture" --section snapshot --format json >"$bad_out" 2>&1; then
  fail "report --section snapshot --format json unexpectedly succeeded"
else
  if grep -qF -- 'ERROR: JSON format not supported for section: snapshot' "$bad_out"; then
    pass "report --section snapshot --format json fails with unsupported error"
  else
    fail "report --section snapshot --format json fails with unexpected error message"
  fi
fi

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
