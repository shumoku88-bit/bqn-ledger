#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"
proj ← •Import "../src_next/projection.bqn"
loader ← •Import "../src_next/loader.bqn"

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

base ← "fixtures/src-next-unknown-account"
ctx ← ctx_mod.BuildContext base
vm ← daily_trend.Build ctx

# Characterization C holds C and source S fixed while choosing a reachable
# disagreement case: journal.tsv has an in-cycle row whose account is unknown.
# LatestActualDateInCycle reads journal dates directly, but cube.valid_rows
# rejects the unknown-account projection rows.
"2026-06-15" lib.AssertEq ctx.cy.start
"2026-06-22" lib.AssertEq ctx.cy.end_exclusive

journal_dates ← {⊑ loader.SplitTsvKeepEmpty 𝕩}¨ loader.ReadLines (base ∾ "/journal.tsv")
⟨"2026-06-15", "2026-06-16"⟩ lib.AssertEq journal_dates

valid_actual_dates ← ActualCoordinateSet ctx
⟨"2026-06-15"⟩ lib.AssertEq valid_actual_dates
0 lib.AssertEq CountDate ⟨valid_actual_dates, "2026-06-16"⟩

2 lib.AssertEq ctx.cube.skipped_count
2 lib.AssertEq ctx.cube.skipped_summary.unknown_account
"2026-06-16" lib.AssertEq vm.as_of

row_dates ← {0⊑𝕩}¨ vm.trend_rows
⟨"2026-06-15"⟩ lib.AssertEq row_dates
0 lib.AssertEq CountDate ⟨row_dates, "2026-06-16"⟩
1 lib.AssertEq vm.obs_days

# Narrow conclusion: in this reachable producer-disagreement fixture, the
# frontier producer still reports 2026-06-16 as L/as_of while the accepted
# actual projection coordinates only yield the 2026-06-15 row. Rejected
# 2026-06-16 stays out of row membership.

•Out "test_src_next_daily_trend_frontier_valid_row_disagreement.bqn: OK"
