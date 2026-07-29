#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
actual_source ← •Import "../src_next/actual_source.bqn"
daily_flow ← •Import "../src_next/daily_flow.bqn"

ctx ← ctx_mod.BuildContext "fixtures/editor-golden"
dates ← actual_source.DatesFromContext ctx

# The semantic boundary receives no base path or broad report context.
prepared ← daily_flow.BuildFromPrepared ⟨ctx.cube, ctx.resolved, ctx.cy, dates⟩
adapted ← daily_flow.Build ctx

adapted.trend_rows lib.AssertEq prepared.trend_rows
adapted.env_labels lib.AssertEq prepared.env_labels
adapted.as_of lib.AssertEq prepared.as_of
adapted.cycle_start lib.AssertEq prepared.cycle_start
adapted.cycle_end_exclusive lib.AssertEq prepared.cycle_end_exclusive

"2026-06-16" lib.AssertEq prepared.as_of
⟨⟩ lib.AssertEq prepared.env_labels
2 lib.AssertEq ≠ prepared.trend_rows
first ← 0 ⊑ prepared.trend_rows
second ← 1 ⊑ prepared.trend_rows
"2026-06-15" lib.AssertEq > 0 ⊑ first
0 lib.AssertEq 1 ⊑ first
⟨⟩ lib.AssertEq 2 ⊑ first
100 lib.AssertEq 3 ⊑ first
¯100 lib.AssertEq 4 ⊑ first
"2026-06-16" lib.AssertEq > 0 ⊑ second
0 lib.AssertEq 3 ⊑ second
0 lib.AssertEq 4 ⊑ second

# Daily Flow explicitly adds its observation coordinate to the visible rows,
# even when no accepted Actual posting exists on that date.
anchored ← daily_flow.BuildFromPrepared ⟨
  ctx.cube,
  ctx.resolved,
  ctx.cy,
  ⟨"2026-06-18"⟩
⟩
"2026-06-18" lib.AssertEq anchored.as_of
"2026-06-18" lib.AssertEq > 0 ⊑ ¯1 ⊑ anchored.trend_rows

# Invalid cycle handling does not inspect cube/resolution evidence or source.
invalidCy ← {start⇐"unavailable",end_exclusive⇐"unavailable",day_count⇐0}
invalid ← daily_flow.BuildFromPrepared ⟨0, 0, invalidCy, ⟨"2026-06-18"⟩⟩
"unavailable" lib.AssertEq invalid.as_of
0 lib.AssertEq ≠ invalid.trend_rows
0 lib.AssertEq ≠ invalid.env_labels

•Out "test_src_next_daily_flow_prepared.bqn: OK"
