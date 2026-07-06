#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"

RowForDate ← {𝕊 rows‿date:
  dates ← {0⊑𝕩}¨ rows
  idx ← ⊑ dates ⊐ ⟨date⟩
  idx ⊑ rows
}

base ← "fixtures/src-next-daily-trend-stability-before"

early_ctx ← ctx_mod.BuildContext ⟨base, "2026-01-03"⟩
late_ctx ← ctx_mod.BuildContext ⟨base, "2026-01-06"⟩

# The explicit observation input reaches context and differs as requested.
"2026-01-03" lib.AssertEq early_ctx.as_of
"2026-01-06" lib.AssertEq late_ctx.as_of

early_vm ← daily_trend.Build early_ctx
late_vm ← daily_trend.Build late_ctx

# Current behavior: Daily Trend does not consume ctx.as_of here. It derives its
# own report-local clock from journal data, so both builds expose the same local
# as_of even though the explicit context observation differs.
"2026-01-03" lib.AssertEq early_vm.as_of
"2026-01-03" lib.AssertEq late_vm.as_of

early_row ← RowForDate ⟨early_vm.trend_rows, "2026-01-02"⟩
late_row ← RowForDate ⟨late_vm.trend_rows, "2026-01-02"⟩

# Same source data and same local clock keep the historical row unchanged even
# when the explicit context observation advances past the 2026-01-05 income plan.
"2026-01-02" lib.AssertEq 0⊑early_row
"2026-01-02" lib.AssertEq 0⊑late_row
1000 lib.AssertEq 3⊑early_row
1000 lib.AssertEq 3⊑late_row
111 lib.AssertEq 5⊑early_row
111 lib.AssertEq 5⊑late_row

•Out "test_src_next_daily_trend_explicit_observation_disconnected.bqn: OK"
