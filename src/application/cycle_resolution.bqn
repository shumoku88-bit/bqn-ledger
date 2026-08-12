# Application-level selection of one admitted Cycle resolver.
# Filesystem access and route policy remain outside this owner.

fixed ← •Import "../accounting/cycle_fixed_resolution.bqn"
calendar ← •Import "../accounting/cycle_calendar_month_resolution.bqn"
income ← •Import "../accounting/cycle_income_anchor_resolution.bqn"
cycleResult ← •Import "../accounting/cycle_result.bqn"
modes ← ⟨"fixed","calendarMonth","incomeAnchor"⟩

WithPlan ← {𝕊 admitted‿observation‿actualFacts‿planFacts:
  mode ← admitted.definition.mode
  modeIndex ← ⊑(mode⊸≡¨modes)⊐1
  modeIndex◶⟨
    {𝕊:fixed.Resolve admitted},
    {𝕊:calendar.Resolve ⟨admitted,observation⟩},
    {𝕊:income.Resolve ⟨admitted,observation,actualFacts,planFacts⟩},
    {𝕊:cycleResult.Error ⟨mode,observation,"cycle_plan_required","incomeAnchor requires Plan facts"⟩}
  ⟩ @
}

{WithPlan⇐WithPlan}
