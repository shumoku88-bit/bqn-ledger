# Pure all-or-nothing legacy Plan/Budget companion Fact admission.
# Retained only for tests and unmigrated callers while production Plan reads move
# to canonical plan.journal. Budget admission is owned by budget_snapshot.bqn.

planSnapshot ← •Import "plan_snapshot.bqn"
budgetSnapshot ← •Import "budget_snapshot.bqn"
empty ← ⟨⟩

EmptyFacts ← {𝕊:
  table ← {count⇐0,index⇐empty}
  {
    state⇐"error",transactions⇐table,postings⇐table,
    sources⇐table,domains⇐table,accounts⇐table,layers⇐table,diagnostics⇐empty
  }
}

Build ← {𝕊 planLines‿budgetLines‿accounts‿registry:
  planResult ← planSnapshot.Build ⟨planLines,accounts,registry⟩
  budgetResult ← budgetSnapshot.Build ⟨budgetLines,accounts,registry⟩
  diagnostics ← planResult.diagnostics∾budgetResult.diagnostics
  planFacts ← EmptyFacts @
  budgetFacts ← EmptyFacts @
  {𝕊:
    planFacts↩planResult.facts
    budgetFacts↩budgetResult.facts
  }⍟((planResult.state≡"ok") ∧ budgetResult.state≡"ok") @
  state ← ((planFacts.state≡"ok") ∧ budgetFacts.state≡"ok")⊑"error"‿"ok"
  {state⇐state,plan⇐planFacts,budget⇐budgetFacts,diagnostics⇐diagnostics}
}

{Build⇐Build}
