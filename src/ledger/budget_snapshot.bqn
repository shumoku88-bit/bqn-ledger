# Pure strict Budget TSV Fact admission retained until canonical budget.journal Phase 4.
# Input is already-read budget_alloc.tsv lines, an admitted Account table, and
# registry policy. Plan meaning is intentionally absent from this owner.

admission ← •Import "companion_admission.bqn"
facts ← •Import "facts.bqn"
empty ← ⟨⟩
policy ← {
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
Build ← {𝕊 lines‿accounts‿registry:
  admitted ← admission.Admit ⟨lines,policy,accounts,registry⟩
  projected ← EmptyFacts @ ⋄ diagnostics ← admitted.diagnostics
  {𝕊:projected↩facts.Project ⟨admitted,accounts⟩ ⋄ diagnostics∾↩projected.diagnostics}⍟(admitted.state≡"ok") @
  {state⇐projected.state,facts⇐projected,diagnostics⇐diagnostics}
}

{Build⇐Build}
