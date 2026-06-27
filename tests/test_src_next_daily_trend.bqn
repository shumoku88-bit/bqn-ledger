#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"

ctx ← ctx_mod.BuildContext "fixtures/src-next-golden"
vm ← daily_trend.Build ctx

"2026-06-16" lib.AssertEq vm.as_of
2 lib.AssertEq vm.obs_days
2 lib.AssertEq ≠ vm.trend_rows

first ← ⊑ vm.trend_rows
second ← 1 ⊑ vm.trend_rows

"2026-06-15" lib.AssertEq 0⊑first
7 lib.AssertEq 4⊑first
0 lib.AssertEq 5⊑first
0 lib.AssertEq 6⊑first

"2026-06-16" lib.AssertEq 0⊑second
6 lib.AssertEq 4⊑second
0 lib.AssertEq 5⊑second
0 lib.AssertEq 6⊑second

text ← daily_trend.Format vm
1 lib.AssertEq ∨´ "--- SrcNext Daily Trend ---"⍷text
1 lib.AssertEq ∨´ "src_next_daily_trend: 2026-06-15 0 0 0 7 0 0 0 0"⍷text
1 lib.AssertEq ∨´ "src_next_daily_trend: 2026-06-16 0 0 0 6 0 0 0 0"⍷text

human ← daily_trend.FormatHuman vm
1 lib.AssertEq ∨´ "== Daily Trend =="⍷human
1 lib.AssertEq ∨´ "liquid"⍷human

•Out "test_src_next_daily_trend.bqn: OK"
