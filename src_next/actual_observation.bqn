# actual_observation.bqn
# Pure shared policies for deriving a compatibility observation coordinate from
# prepared Actual dates. Only behavior proven identical across consumers lives
# here; explicit absence, invalid-date, source-order, and open-ended frontier
# policies remain with their owning report modules.

dt ← •Import "date.bqn"

LatestInDayWindowOr ← {𝕊 dates‿startDn‿endDn‿fallback:
  out ← fallback
  {𝕊:
    InWindow ← {𝕊 dateText:
      dn ← dt.DaysFromEpoch dateText
      (dn ≥ startDn) ∧ (dn < endDn)
    }
    inDates ← (InWindow¨dates) / dates
    {𝕊: out ↩ ¯1 ⊑ ∧ inDates}⍟(0 < ≠ inDates) @
  }⍟(0 < ≠ dates) @
  out
}

# Daily Flow and Daily Trend historically define the upper bound from
# start+day_count and fall back to cycle.start.
LatestInDayCountWindowOrStart ← {𝕊 dates‿cy:
  available ← (cy.start ≢ "unavailable") ∧ (cy.day_count > 0)
  out ← cy.start
  {𝕊:
    startDn ← dt.DaysFromEpoch cy.start
    out ↩ LatestInDayWindowOr ⟨dates, startDn, startDn + cy.day_count, cy.start⟩
  }⍟available @
  out
}

# Planned Payments and Cycle Summary use the explicit half-open cycle bounds
# and fall back to cycle.start.
LatestInCycleOrStart ← {𝕊 dates‿cy:
  available ← (cy.start ≢ "unavailable") ∧ (cy.end_exclusive ≢ "unavailable") ∧ (cy.day_count > 0)
  out ← cy.start
  {𝕊:
    out ↩ LatestInDayWindowOr ⟨dates, dt.DaysFromEpoch cy.start, dt.DaysFromEpoch cy.end_exclusive, cy.start⟩
  }⍟available @
  out
}

{
  LatestInDayCountWindowOrStart ⇐ LatestInDayCountWindowOrStart,
  LatestInCycleOrStart ⇐ LatestInCycleOrStart
}
