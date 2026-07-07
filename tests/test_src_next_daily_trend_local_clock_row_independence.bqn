#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"

RowForDate ← {𝕊 rows‿date:
  dates ← {0⊑𝕩}¨ rows
  idx ← ⊑ dates ⊐ ⟨date⟩
  idx ⊑ rows
}

observation ← "2026-01-03"
before_base ← "fixtures/src-next-daily-trend-stability-before"
after_base ← "fixtures/src-next-daily-trend-stability-after"

before_ctx ← ctx_mod.BuildContext ⟨before_base, observation⟩
after_ctx ← ctx_mod.BuildContext ⟨after_base, observation⟩

# Hold the explicit context observation fixed across both source states.
observation lib.AssertEq before_ctx.as_of
observation lib.AssertEq after_ctx.as_of

before_vm ← daily_trend.Build before_ctx
after_vm ← daily_trend.Build after_ctx

# The section-level local frontier still moves in this slice.
"2026-01-03" lib.AssertEq before_vm.as_of
"2026-01-06" lib.AssertEq after_vm.as_of

before_row ← RowForDate ⟨before_vm.trend_rows, "2026-01-02"⟩
after_row ← RowForDate ⟨after_vm.trend_rows, "2026-01-02"⟩

"2026-01-02" lib.AssertEq 0⊑before_row
"2026-01-02" lib.AssertEq 0⊑after_row
100 lib.AssertEq 1⊑before_row
100 lib.AssertEq 1⊑after_row
0 lib.AssertEq 2⊑before_row
0 lib.AssertEq 2⊑after_row
9 lib.AssertEq 4⊑before_row
9 lib.AssertEq 4⊑after_row

# Selected behavior: row-local future income is tied to D. The unrelated later
# Event may move section-level L, but it no longer removes the 2026-01-05 income
# plan from the 2026-01-02 row.
1000 lib.AssertEq 3⊑before_row
1000 lib.AssertEq 3⊑after_row
111 lib.AssertEq 5⊑before_row
111 lib.AssertEq 5⊑after_row

•Out "test_src_next_daily_trend_local_clock_row_independence.bqn: OK"
