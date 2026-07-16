#!/usr/bin/env bash
set -euo pipefail

# Guard Daily Trend's checked plan-money owner and D-local completion semantics.

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

focused="$(mktemp)"
summary="$(mktemp)"
trap 'rm -f "$focused" "$summary"' EXIT

if bqn tests/test_src_next_daily_trend_plan_numeric_owner.bqn >"$focused" 2>&1; then
  pass "focused Daily Trend plan numeric-owner behavior"
else
  cat "$focused" >&2
  fail "focused Daily Trend plan numeric-owner behavior"
fi

if grep -qF 'test_src_next_daily_trend_plan_numeric_owner.bqn: OK' "$focused"; then
  pass "focused test completion marker"
else
  fail "focused test completion marker missing"
fi

if grep -qF 'ctx.posting_rows' src_next/daily_trend_plan.bqn \
  && grep -qF 'source_row' src_next/daily_trend_plan.bqn \
  && grep -qF 'overlap.PlanId' src_next/daily_trend_plan.bqn; then
  pass "Posting IR join and source completion evidence are explicit"
else
  fail "checked Posting IR join or completion evidence missing"
fi

if grep -qF '•BQN' src_next/daily_trend_plan.bqn; then
  fail "Daily Trend plan helper reparses a source amount"
else
  pass "Daily Trend plan helper has no source amount parser"
fi

for legacy in 'plan_amts ←' 'amt_str ←' 'open_mask ← IsOpen'; do
  if grep -qF "$legacy" src_next/daily_trend.bqn; then
    fail "legacy Daily Trend amount path survives: $legacy"
  else
    pass "legacy Daily Trend amount path absent: $legacy"
  fi
done

if grep -qF 'trend_plan.BuildAt' src_next/daily_trend.bqn; then
  pass "Daily Trend connects the checked plan helper"
else
  fail "Daily Trend checked plan helper connection missing"
fi

if tools/report-next-summary fixtures/daily-trend-plan-numeric-owner-target >"$summary" 2>&1; then
  pass "target fixture compact summary renders"
else
  cat "$summary" >&2
  fail "target fixture compact summary failed"
fi

for expected in \
  'src_next_daily_trend: 2026-02-01 100 201 ¯51 10 ¯6' \
  'src_next_daily_trend: 2026-02-03 75 171 ¯46 8 ¯6' \
  'src_next_daily_trend: 2026-02-06 35 70 15 5 3' \
  'src_next_daily_trend: 2026-02-09 28 70 ¯42 2 ¯21'; do
  if grep -qF "$expected" "$summary"; then
    pass "fixture Daily Trend row: $expected"
  else
    fail "fixture Daily Trend row missing: $expected"
  fi
done

if [ "$failures" -eq 0 ]; then
  echo "OK: src_next Daily Trend plan numeric-owner check passed" >&2
  exit 0
fi

echo "FAILED: $failures Daily Trend plan numeric-owner check(s) failed" >&2
exit 1
