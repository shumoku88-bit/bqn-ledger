#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
planned ← •Import "../src/sections/planned_payments.bqn"

actualDates ← ⟨"2026-01-01","2026-01-05","2026-01-15","2026-02-05"⟩
actualFacts ← {transactions⇐{date_ordinal⇐dates.Ordinal¨actualDates}}

currentCycle ← {
  start_ordinal⇐dates.Ordinal "2026-01-05",
  end_exclusive_ordinal⇐dates.Ordinal "2026-02-05"
}
"2026-01-15" lib.AssertEq planned.EvidenceObservation ⟨actualFacts,currentCycle⟩

emptyCycle ← {
  start_ordinal⇐dates.Ordinal "2026-03-01",
  end_exclusive_ordinal⇐dates.Ordinal "2026-04-01"
}
"2026-03-01" lib.AssertEq planned.EvidenceObservation ⟨actualFacts,emptyCycle⟩

•Out "test_section_planned_payments_observation: ok"
