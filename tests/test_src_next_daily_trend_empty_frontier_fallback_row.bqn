#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"
proj ← •Import "../src_next/projection.bqn"

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

base ← "fixtures/src-next-empty-projection"
ctx ← ctx_mod.BuildContext base
vm ← daily_trend.Build ctx

# Characterization B holds C and source S fixed to an empty journal fixture.
# There are no valid actual coordinates; this observes whether
# LatestActualDateInCycle's cycle.start fallback contributes the final row.
"2026-06-15" lib.AssertEq ctx.cy.start
"2026-06-22" lib.AssertEq ctx.cy.end_exclusive
⟨⟩ lib.AssertEq ActualCoordinateSet ctx

# Current fallback L is cycle.start.
"2026-06-15" lib.AssertEq vm.as_of

row_dates ← {0⊑𝕩}¨ vm.trend_rows
⟨"2026-06-15"⟩ lib.AssertEq row_dates
1 lib.AssertEq vm.obs_days

row ← 0⊑vm.trend_rows
"2026-06-15" lib.AssertEq 0⊑row
0 lib.AssertEq 1⊑row  # liquid
0 lib.AssertEq 2⊑row  # reserve
0 lib.AssertEq 3⊑row  # fund
7 lib.AssertEq 4⊑row  # days_left to C.end_exclusive
0 lib.AssertEq 5⊑row  # daily
0 lib.AssertEq 7⊑row  # day variable spend
0 lib.AssertEq 8⊑row  # day saving
0 lib.AssertEq 9⊑row  # day fixed spend

# Narrow conclusion: in this empty/fallback fixture, cycle.start fallback L
# contributes a synthetic row coordinate. This does not decide whether that row
# is correct product behavior.

•Out "test_src_next_daily_trend_empty_frontier_fallback_row.bqn: OK"
