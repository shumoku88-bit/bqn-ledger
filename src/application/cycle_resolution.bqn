# Application-level selection of one admitted Cycle resolver.
# Filesystem access and route policy remain outside this owner.

fixed ← •Import "../accounting/cycle_fixed_resolution.bqn"
calendar ← •Import "../accounting/cycle_calendar_month_resolution.bqn"
income ← •Import "../accounting/cycle_income_anchor_resolution.bqn"
cycleResult ← •Import "../accounting/cycle_result.bqn"

WithoutPlan ← {𝕊 admitted‿observation:
  mode ← admitted.definition.mode
  resolved ← cycleResult.Error ⟨mode,observation,"cycle_plan_required","incomeAnchor requires Plan facts"⟩
  {𝕊:resolved↩fixed.Resolve admitted}⍟(mode≡"fixed") @
  {𝕊:resolved↩calendar.Resolve ⟨admitted,observation⟩}⍟(mode≡"calendarMonth") @
  resolved
}
WithPlan ← {𝕊 admitted‿observation‿actualFacts‿planFacts:
  resolved ← WithoutPlan ⟨admitted,observation⟩
  {𝕊:resolved↩income.Resolve ⟨admitted,observation,actualFacts,planFacts⟩}⍟(admitted.definition.mode≡"incomeAnchor") @
  resolved
}

{WithoutPlan⇐WithoutPlan,WithPlan⇐WithPlan}
