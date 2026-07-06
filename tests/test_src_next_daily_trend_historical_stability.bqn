#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"

RowForDate ← {𝕊 rows‿date:
  dates ← {0⊑𝕩}¨ rows
  idx ← ⊑ dates ⊐ ⟨date⟩
  idx ⊑ rows
}

before_ctx ← ctx_mod.BuildContext "fixtures/src-next-daily-trend-stability-before"
after_ctx ← ctx_mod.BuildContext "fixtures/src-next-daily-trend-stability-after"

before_vm ← daily_trend.Build before_ctx
after_vm ← daily_trend.Build after_ctx

"2026-01-03" lib.AssertEq before_vm.as_of
"2026-01-06" lib.AssertEq after_vm.as_of

before_row ← RowForDate ⟨before_vm.trend_rows, "2026-01-02"⟩
after_row ← RowForDate ⟨after_vm.trend_rows, "2026-01-02"⟩

# Historical coordinate and actual liquid state stay the same.
"2026-01-02" lib.AssertEq 0⊑before_row
"2026-01-02" lib.AssertEq 0⊑after_row
100 lib.AssertEq 1⊑before_row
100 lib.AssertEq 1⊑after_row
0 lib.AssertEq 2⊑before_row
0 lib.AssertEq 2⊑after_row
9 lib.AssertEq 4⊑before_row
9 lib.AssertEq 4⊑after_row

# Current behavior: advancing the local latest-journal clock past the
# 2026-01-05 income plan removes that plan from planned_future_income.
# The same historical 2026-01-02 row is therefore recomputed differently.
1000 lib.AssertEq 3⊑before_row
100 lib.AssertEq 3⊑after_row
111 lib.AssertEq 5⊑before_row
11 lib.AssertEq 5⊑after_row

•Out "test_src_next_daily_trend_historical_stability.bqn: OK"
