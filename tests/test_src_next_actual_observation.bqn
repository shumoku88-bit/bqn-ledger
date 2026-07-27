#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
observation ← •Import "../src_next/actual_observation.bqn"

Cycle ← {𝕊 start‿endExclusive‿dayCount:
  {start⇐start,end_exclusive⇐endExclusive,day_count⇐dayCount}
}

cy ← Cycle ⟨"2026-01-01", "2026-01-05", 4⟩
dates ← ⟨"2026-01-03", "2025-12-31", "2026-01-02", "2026-01-05"⟩
"2026-01-03" lib.AssertEq observation.LatestInDayCountWindowOrStart ⟨dates, cy⟩
"2026-01-03" lib.AssertEq observation.LatestInCycleOrStart ⟨dates, cy⟩
"2026-01-01" lib.AssertEq observation.LatestInDayCountWindowOrStart ⟨⟨⟩, cy⟩
"2026-01-01" lib.AssertEq observation.LatestInCycleOrStart ⟨⟨"2026-01-05"⟩, cy⟩

# The two exported policies intentionally remain separate. Daily Flow/Trend
# own a start+day_count window; Planned Payments/Cycle Summary own explicit
# cycle bounds. An inconsistent synthetic cycle makes that distinction visible.
mismatched ← Cycle ⟨"2026-01-01", "2026-01-05", 2⟩
"2026-01-01" lib.AssertEq observation.LatestInDayCountWindowOrStart ⟨⟨"2026-01-03"⟩, mismatched⟩
"2026-01-03" lib.AssertEq observation.LatestInCycleOrStart ⟨⟨"2026-01-03"⟩, mismatched⟩

unavailable ← Cycle ⟨"unavailable", "unavailable", 0⟩
"unavailable" lib.AssertEq observation.LatestInDayCountWindowOrStart ⟨dates, unavailable⟩
"unavailable" lib.AssertEq observation.LatestInCycleOrStart ⟨dates, unavailable⟩

•Out "test_src_next_actual_observation.bqn: OK"
