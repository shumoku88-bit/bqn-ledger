# Pure all-or-nothing Plan/Budget companion fact admission.
# Inputs are already-read TSV lines, an admitted Account table, and a registry.
# No private/source path, I/O, clock, defaults, or report context are accepted.

admission ← •Import "companion_admission.bqn"
facts ← •Import "facts.bqn"
planSnapshot ← •Import "plan_snapshot.bqn"
empty ← ⟨⟩

budgetPolicy ← {
  source_name⇐"budget_alloc.tsv",layer_name⇐"budget",require_plan_id⇐0,
  known_metadata⇐⟨"currency"⟩
}

EmptyFacts ← {𝕊:
  table ← {count⇐0,index⇐empty}
  {
    state⇐"error",transactions⇐table,postings⇐table,
    sources⇐table,domains⇐table,accounts⇐table,layers⇐table,diagnostics⇐empty
  }
}

Build ← {𝕊 planLines‿budgetLines‿accounts‿registry:
  planResult ← planSnapshot.Build ⟨planLines,accounts,registry⟩
  budgetAdmission ← admission.Admit ⟨budgetLines,budgetPolicy,accounts,registry⟩
  diagnostics ← planResult.diagnostics∾budgetAdmission.diagnostics
  planFacts ← EmptyFacts @
  budgetFacts ← EmptyFacts @
  admissionsOk ← (planResult.state≡"ok") ∧ budgetAdmission.state≡"ok"
  {𝕊:
    projectedBudget ← facts.Project ⟨budgetAdmission,accounts⟩
    diagnostics ∾↩ projectedBudget.diagnostics
    {𝕊:planFacts↩planResult.facts ⋄ budgetFacts↩projectedBudget}⍟(projectedBudget.state≡"ok") @
  }⍟admissionsOk @
  state ← ((planFacts.state≡"ok") ∧ budgetFacts.state≡"ok")⊑"error"‿"ok"
  {state⇐state,plan⇐planFacts,budget⇐budgetFacts,diagnostics⇐diagnostics}
}

{Build⇐Build}
