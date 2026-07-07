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
after_ctx ← ctx_mod.BuildContext "fixtures/src-next-daily-trend-backdated-source-after"

before_vm ← daily_trend.Build before_ctx
after_vm ← daily_trend.Build after_ctx

# The selected cycle C is fixed across the two source snapshots.
"2026-01-01" lib.AssertEq before_ctx.cy.start
"2026-01-01" lib.AssertEq after_ctx.cy.start
"2026-01-11" lib.AssertEq before_ctx.cy.end_exclusive
"2026-01-11" lib.AssertEq after_ctx.cy.end_exclusive

# Local max coordinate L is also fixed. The after source adds only a backdated
# 2026-01-02 Event, below the existing 2026-01-03 frontier.
"2026-01-03" lib.AssertEq before_vm.as_of
"2026-01-03" lib.AssertEq after_vm.as_of

before_dates ← {0⊑𝕩}¨ before_vm.trend_rows
after_dates ← {0⊑𝕩}¨ after_vm.trend_rows

# Row coordinate membership/order stays fixed as well.
before_dates lib.AssertEq after_dates

before_row ← RowForDate ⟨before_vm.trend_rows, "2026-01-02"⟩
after_row ← RowForDate ⟨after_vm.trend_rows, "2026-01-02"⟩

"2026-01-02" lib.AssertEq 0⊑before_row
"2026-01-02" lib.AssertEq 0⊑after_row

# Source snapshot changed under fixed D, L, and C. The backdated liquid spend is
# visible at the same historical row coordinate.
100 lib.AssertEq 1⊑before_row
90 lib.AssertEq 1⊑after_row

# Reserve and row-local denominator remain unchanged in this fixture.
0 lib.AssertEq 2⊑before_row
0 lib.AssertEq 2⊑after_row
9 lib.AssertEq 4⊑before_row
9 lib.AssertEq 4⊑after_row

# The same local L still admits the 2026-01-05 future income plan. Fund/daily
# change only because the current source snapshot now contains the backdated
# actual Event.
1000 lib.AssertEq 3⊑before_row
990 lib.AssertEq 3⊑after_row
111 lib.AssertEq 5⊑before_row
110 lib.AssertEq 5⊑after_row

# Day-variable actual also records the backdated source change.
0 lib.AssertEq 7⊑before_row
10 lib.AssertEq 7⊑after_row

# Characterization conclusion:
#   same D
#   same local L
#   same C
#   same row set
#   different source snapshot
#     -> historical Daily Trend row changes
#
# This does not create a K axis. It proves only that current max-coordinate L is
# not a complete identity for source knowledge state.

•Out "test_src_next_daily_trend_backdated_source_drift.bqn: OK"
