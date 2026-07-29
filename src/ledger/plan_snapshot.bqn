# Pure strict Plan-only Fact admission for consumers that do not require Budget evidence.

admission ← •Import "companion_admission.bqn"
facts ← •Import "facts.bqn"
empty ← ⟨⟩
policy ← {
  source_name⇐"plan.tsv",layer_name⇐"plan",require_plan_id⇐1,
  known_metadata⇐⟨"currency","plan_id","recur","series","anchor","offset","cashflow"⟩
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
  {state⇐(projected.state≡"ok")⊑"error"‿"ok",facts⇐projected,diagnostics⇐diagnostics}
}

{Build⇐Build}
