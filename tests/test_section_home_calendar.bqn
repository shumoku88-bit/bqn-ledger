#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
section ← •Import "../src/sections/home_calendar.bqn"

lf ← @+10
actualDates ← ⟨"2026-08-11","2026-08-11","2026-08-12"⟩
actualFacts ← {
  state⇐"ok",sources⇐{name⇐⟨"actual.journal"⟩},
  transactions⇐{index⇐↕≠actualDates,date_ordinal⇐dates.Ordinal¨actualDates}
}
planned ← {
  state⇐"ok",
  rows⇐{count⇐2,index⇐↕2,date⇐⟨"2026-08-14","2026-08-26"⟩}
}
issues ← {
  state⇐"ok",
  issues⇐{count⇐2,index⇐↕2,due⇐⟨"2026-08-12","2026-08-26"⟩}
}
cycle ← {state⇐"ok",start⇐"2026-07-01",end_exclusive⇐"2026-08-27"}

result ← section.Build ⟨actualFacts,planned,issues,cycle,"2026-08-12"⟩
"ok" lib.AssertEq result.state
"2026-08-01" lib.AssertEq result.month_start
"2026-09-01" lib.AssertEq result.month_end_exclusive
5 lib.AssertEq result.weekday_start
31 lib.AssertEq result.days.count
⟨6,7⟩ lib.AssertEq ≢result.day_index_grid
⟨¯1,¯1,¯1,¯1,¯1,0,1⟩ lib.AssertEq 0⊏result.day_index_grid
⟨30,¯1,¯1,¯1,¯1,¯1,¯1⟩ lib.AssertEq 5⊏result.day_index_grid

# August 11 has two Actual transactions; August 12 has one Actual plus an Issue due.
2 lib.AssertEq ≠10⊑result.days.actual_indices
1 lib.AssertEq ≠11⊑result.days.actual_indices
1 lib.AssertEq 10⊑result.days.actual_present
1 lib.AssertEq 11⊑result.days.actual_present
1 lib.AssertEq 11⊑result.days.issue_due
1 lib.AssertEq 11⊑result.days.marker_count

# August 14 is a Plan-only marker.
1 lib.AssertEq 13⊑result.days.plan_due
0 lib.AssertEq 13⊑result.days.issue_due
1 lib.AssertEq 13⊑result.days.marker_count

# August 26 is simultaneously Plan due, Issue due, and the final included Cycle day.
1 lib.AssertEq 25⊑result.days.plan_due
1 lib.AssertEq 25⊑result.days.issue_due
1 lib.AssertEq 25⊑result.days.cycle_end
3 lib.AssertEq 25⊑result.days.marker_count
1 lib.AssertEq ≠25⊑result.days.plan_indices
1 lib.AssertEq ≠25⊑result.days.issue_indices

# A neighboring date carries no marker and no Actual evidence.
0 lib.AssertEq 24⊑result.days.actual_present
0 lib.AssertEq 24⊑result.days.marker_count

calendarPolicy ← {
  cycle_end_marker⇐"*",plan_due_marker⇐"$",issue_due_marker⇐"!",multiple_marker⇐"+"
}
markers ← section.Markers ⟨result,calendarPolicy⟩
" " lib.AssertEq 10⊑markers
"!" lib.AssertEq 11⊑markers
"$" lib.AssertEq 13⊑markers
"+" lib.AssertEq 25⊑markers

expectedHuman ← ∾⟨
  "2026-08",lf,
  "Mo  Tu  We  Th  Fr  Sa  Su ",lf,
  "                     1   2 ",lf,
  " 3   4   5   6   7   8   9 ",lf,
  "10  11  12! 13  14$ 15  16 ",lf,
  "17  18  19  20  21  22  23 ",lf,
  "24  25  26+ 27  28  29  30 ",lf,
  "31                         ",lf
⟩
expectedHuman lib.AssertEq section.FormatHuman ⟨result,calendarPolicy⟩

customPolicy ← {
  cycle_end_marker⇐"C",plan_due_marker⇐"P",issue_due_marker⇐"I",multiple_marker⇐"M"
}
customMarkers ← section.Markers ⟨result,customPolicy⟩
"I" lib.AssertEq 11⊑customMarkers
"P" lib.AssertEq 13⊑customMarkers
"M" lib.AssertEq 25⊑customMarkers

badDate ← section.Build ⟨actualFacts,planned,issues,cycle,"2026-02-30"⟩
"error" lib.AssertEq badDate.state
"focus_date_invalid" lib.AssertEq (⊑badDate.diagnostics).code

badActual ← {
  state⇐"ok",sources⇐{name⇐⟨"plan.journal"⟩},
  transactions⇐{index⇐⟨⟩,date_ordinal⇐⟨⟩}
}
badSource ← section.Build ⟨badActual,planned,issues,cycle,"2026-08-12"⟩
"error" lib.AssertEq badSource.state
"actual_facts_invalid" lib.AssertEq (⊑badSource.diagnostics).code

•Out "test_section_home_calendar: ok"
