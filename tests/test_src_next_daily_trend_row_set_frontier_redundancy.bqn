#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"
proj ← •Import "../src_next/projection.bqn"

Sum0 ← { 0 < ≠𝕩 ? +´𝕩 ; 0 }
CountDate ← {𝕊 dates‿date: Sum0 (date⊸≡¨ dates) }
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

base ← "fixtures/src-next-daily-trend-stability-before"
ctx ← ctx_mod.BuildContext base
vm ← daily_trend.Build ctx

# Characterization A holds C and source S fixed to an ordinary non-empty
# in-cycle journal. Row membership should come only from accepted actual
# projection coordinates.
"2026-01-01" lib.AssertEq ctx.cy.start
"2026-01-11" lib.AssertEq ctx.cy.end_exclusive
"2026-01-03" lib.AssertEq vm.as_of

valid_actual_dates ← ActualCoordinateSet ctx
⟨"2026-01-02", "2026-01-03"⟩ lib.AssertEq valid_actual_dates
1 lib.AssertEq CountDate ⟨valid_actual_dates, "2026-01-03"⟩

row_dates ← {0⊑𝕩}¨ vm.trend_rows
⟨"2026-01-02", "2026-01-03"⟩ lib.AssertEq row_dates
1 lib.AssertEq CountDate ⟨row_dates, vm.as_of⟩
2 lib.AssertEq vm.obs_days

# Narrow conclusion: in this ordinary valid in-cycle fixture, the accepted
# actual row coordinates already match the final Daily Trend row set.

•Out "test_src_next_daily_trend_row_set_frontier_redundancy.bqn: OK"
