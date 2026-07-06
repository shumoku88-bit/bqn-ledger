#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"

RowForDate ← {𝕊 rows‿date:
  dates ← {0⊑𝕩}¨ rows
  idx ← ⊑ dates ⊐ ⟨date⟩
  idx ⊑ rows
}

before_ctx ← ctx_mod.BuildContext "fixtures/src-next-daily-trend-reserve-before"
after_ctx ← ctx_mod.BuildContext "fixtures/src-next-daily-trend-reserve-after"

before_vm ← daily_trend.Build before_ctx
after_vm ← daily_trend.Build after_ctx

"2026-01-03" lib.AssertEq before_vm.as_of
"2026-01-06" lib.AssertEq after_vm.as_of

before_row ← RowForDate ⟨before_vm.trend_rows, "2026-01-02"⟩
after_row ← RowForDate ⟨after_vm.trend_rows, "2026-01-02"⟩

# Same historical coordinate, liquid state, and coordinate-local denominator.
"2026-01-02" lib.AssertEq 0⊑before_row
"2026-01-02" lib.AssertEq 0⊑after_row
1000 lib.AssertEq 1⊑before_row
1000 lib.AssertEq 1⊑after_row
9 lib.AssertEq 4⊑before_row
9 lib.AssertEq 4⊑after_row

# Current behavior: ordinary 5-field plan rows receive a non-empty fallback
# identity from PlanId. The later unrelated journal Event advances the local
# clock but does not match that plan identity, so reserve stays open.
300 lib.AssertEq 2⊑before_row
300 lib.AssertEq 2⊑after_row

•Out "test_src_next_daily_trend_reserve_clock_dependency.bqn: OK"
