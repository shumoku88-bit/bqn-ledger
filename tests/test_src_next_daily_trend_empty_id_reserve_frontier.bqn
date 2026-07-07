#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"
overlap ← •Import "../src_next/plan_journal_overlap.bqn"
proj ← •Import "../src_next/projection.bqn"
loader ← •Import "../src_next/loader.bqn"

UniqueSortedDates ← {𝕊 dates:
  dns ← proj.DaysFromEpoch¨ dates
  ord ← ⍋ dns
  sorted_dates ← ord ⊏ dates
  sorted_dns ← ord ⊏ dns
  keep ← (sorted_dns ⊐ sorted_dns) = ↕ ≠ sorted_dns
  keep / sorted_dates
}
ActualCoordinateSet ← {𝕊 ctx:
  rows ← ctx.cube.valid_rows
  actual_rows ← (0 = {𝕩.layer_index}¨ rows) / rows
  UniqueSortedDates {𝕩.date}¨ actual_rows
}
RowForDate ← {𝕊 rows‿date:
  dates ← {0⊑𝕩}¨ rows
  idx ← ⊑ dates ⊐ ⟨date⟩
  idx ⊑ rows
}

before_base ← "fixtures/src-next-daily-trend-empty-id-reserve-before"
after_base ← "fixtures/src-next-daily-trend-empty-id-reserve-after"

before_ctx ← ctx_mod.BuildContext before_base
after_ctx ← ctx_mod.BuildContext after_base
before_vm ← daily_trend.Build before_ctx
after_vm ← daily_trend.Build after_ctx

# Cycle, plan row, and accepted actual coordinates stay fixed while raw L moves.
"2026-01-01" lib.AssertEq before_ctx.cy.start
"2026-01-01" lib.AssertEq after_ctx.cy.start
"2026-01-11" lib.AssertEq before_ctx.cy.end_exclusive
"2026-01-11" lib.AssertEq after_ctx.cy.end_exclusive

before_plan_line ← ⊑ loader.ReadLinesOptional (before_base ∾ "/plan.tsv")
after_plan_line ← ⊑ loader.ReadLinesOptional (after_base ∾ "/plan.tsv")
before_plan_line lib.AssertEq after_plan_line
"2026-01-05future_fixedassets:cashexpenses:fixed300" lib.AssertEq overlap.PlanId before_plan_line
"2026-01-05future_fixedassets:cashexpenses:fixed300" lib.AssertEq overlap.PlanId after_plan_line
⟨"2026-01-05", "future_fixed", "assets:cash", "expenses:fixed", "300"⟩ lib.AssertEq 5↑ loader.SplitTsvKeepEmpty before_plan_line
⟨"2026-01-05", "future_fixed", "assets:cash", "expenses:fixed", "300"⟩ lib.AssertEq 5↑ loader.SplitTsvKeepEmpty after_plan_line

0 lib.AssertEq before_ctx.cube.skipped_count
0 lib.AssertEq before_ctx.cube.skipped_summary.unknown_account
2 lib.AssertEq after_ctx.cube.skipped_count
2 lib.AssertEq after_ctx.cube.skipped_summary.unknown_account

before_actual_dates ← ActualCoordinateSet before_ctx
after_actual_dates ← ActualCoordinateSet after_ctx
⟨"2026-01-02", "2026-01-03"⟩ lib.AssertEq before_actual_dates
⟨"2026-01-02", "2026-01-03"⟩ lib.AssertEq after_actual_dates
before_actual_dates lib.AssertEq after_actual_dates

"2026-01-03" lib.AssertEq before_vm.as_of
"2026-01-06" lib.AssertEq after_vm.as_of

before_row_dates ← {0⊑𝕩}¨ before_vm.trend_rows
after_row_dates ← {0⊑𝕩}¨ after_vm.trend_rows
⟨"2026-01-02", "2026-01-03"⟩ lib.AssertEq before_row_dates
⟨"2026-01-02", "2026-01-03"⟩ lib.AssertEq after_row_dates
before_row_dates lib.AssertEq after_row_dates
2 lib.AssertEq before_vm.obs_days
2 lib.AssertEq after_vm.obs_days

before_row ← RowForDate ⟨before_vm.trend_rows, "2026-01-02"⟩
after_row ← RowForDate ⟨after_vm.trend_rows, "2026-01-02"⟩
"2026-01-02" lib.AssertEq 0⊑before_row
"2026-01-02" lib.AssertEq 0⊑after_row
1000 lib.AssertEq 1⊑before_row
1000 lib.AssertEq 1⊑after_row
300 lib.AssertEq 2⊑before_row
300 lib.AssertEq 2⊑after_row
9 lib.AssertEq 4⊑before_row
9 lib.AssertEq 4⊑after_row

# Mechanical consequence only: fund/daily/delta move once reserve changes.

•Out "test_src_next_daily_trend_empty_id_reserve_frontier.bqn: OK"
