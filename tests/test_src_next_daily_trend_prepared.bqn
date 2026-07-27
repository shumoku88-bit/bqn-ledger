#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
trend_plan ← •Import "../src_next/daily_trend_plan.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"

ctx ← ctx_mod.BuildContext "fixtures/daily-trend-plan-numeric-owner-target"
trend_dates ← ⟨"2026-02-01", "2026-02-03", "2026-02-06", "2026-02-09"⟩
plan_result ← trend_plan.BuildAt ⟨ctx, trend_dates⟩
adapted ← daily_trend.Build ctx

# The numeric boundary receives prepared coordinates and checked reserve
# evidence. It has no base path, source adapter, or broad report context.
prepared ← daily_trend.BuildFromPrepared ⟨
  ctx.cube,
  ctx.resolved,
  ctx.cy,
  adapted.as_of,
  trend_dates,
  plan_result
⟩

adapted.state lib.AssertEq prepared.state
adapted.reason lib.AssertEq prepared.reason
adapted.diagnostics lib.AssertEq prepared.diagnostics
adapted.trend_rows lib.AssertEq prepared.trend_rows
adapted.top_drops lib.AssertEq prepared.top_drops
adapted.obs_days lib.AssertEq prepared.obs_days
adapted.as_of lib.AssertEq prepared.as_of
adapted.header_O lib.AssertEq prepared.header_O
adapted.cycle_start lib.AssertEq prepared.cycle_start
adapted.cycle_end_exclusive lib.AssertEq prepared.cycle_end_exclusive
adapted.cycle_mode lib.AssertEq prepared.cycle_mode

"ok" lib.AssertEq prepared.state
trend_dates lib.AssertEq {0⊑𝕩}¨ prepared.trend_rows
⟨201, 171, 70, 70⟩ lib.AssertEq {2⊑𝕩}¨ prepared.trend_rows
15 lib.AssertEq 3 ⊑ 2 ⊑ prepared.trend_rows

# Prepared plan failure closes the numeric result without resembling zero data.
plan_error ← {
  state⇐"error",
  reason⇐"rejected_plan_evidence",
  diagnostics⇐⟨{source_file⇐"plan.tsv",source_row⇐0,status⇐"invalid_date",date⇐"bad",message⇐"bad"}⟩,
  reserves⇐⟨⟩
}
closed ← daily_trend.BuildFromPrepared ⟨ctx.cube, ctx.resolved, ctx.cy, adapted.as_of, trend_dates, plan_error⟩
"error" lib.AssertEq closed.state
"rejected_plan_evidence" lib.AssertEq closed.reason
0 lib.AssertEq ≠ closed.trend_rows
1 lib.AssertEq ≠ closed.diagnostics

# Invalid cycle handling does not inspect cube, resolution, or plan evidence.
invalidCy ← {start⇐"unavailable",end_exclusive⇐"unavailable",day_count⇐0,mode⇐"unavailable"}
invalid ← daily_trend.BuildFromPrepared ⟨0, 0, invalidCy, "unavailable", ⟨⟩, 0⟩
"error" lib.AssertEq invalid.state
"invalid_trend_coordinate" lib.AssertEq invalid.reason
0 lib.AssertEq ≠ invalid.trend_rows

•Out "test_src_next_daily_trend_prepared.bqn: OK"
