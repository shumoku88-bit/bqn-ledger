# Effectful read boundary for canonical household.toml.
# Path ownership is fixed by the canonical Household root; callers cannot select
# a fallback or alternate Household policy source. The same physical TOML carries
# current Household policy and historical Envelope evidence as separate semantic
# owners over one source-byte observation.

io ← •Import "source_io.bqn"
admission ← •Import "../ledger/household_policy_admission.bqn"
historyAdmission ← •Import "../ledger/envelope_history_admission.bqn"
projection ← •Import "../ledger/household_current_policy_projection.bqn"
canonical ← •Import "canonical_household_sources.bqn"
empty ← ⟨⟩
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 id:{severity⇐"error",stage⇐"household_source_adapter",code⇐"household_allocation_envelope_history_missing",line⇐0,message⇐"Stable Household allocation Envelope identity is missing from envelope-history.identities: "∾id}}

Read ← {𝕊 base:io.ReadRaw (io.JoinPath ⟨base,canonical.householdPolicy⟩)}
Current ← {𝕊 raw‿accounts‿budgetPolicy:admission.Admit ⟨projection.CurrentPolicy raw,accounts,budgetPolicy⟩}

Load ← {𝕊 base‿accounts‿budgetPolicy:
  Current ⟨Read base,accounts,budgetPolicy⟩
}

LoadShared ← {𝕊 base‿accounts‿budgetPolicy:
  raw ← Read base
  current ← Current ⟨raw,accounts,budgetPolicy⟩
  history ← historyAdmission.Admit raw
  referenceDiagnostics ← empty
  {𝕊:
    missing ← {¬Contains ⟨𝕩,history.registry.id⟩}¨current.budget.envelope_id
    referenceDiagnostics↩Diagnostic¨missing/current.budget.envelope_id
  }⍟((current.state≡"ok") ∧ history.state≡"ok") @
  diagnostics ← current.diagnostics∾history.diagnostics∾referenceDiagnostics
  ok ← (current.state≡"ok") ∧ (history.state≡"ok") ∧ 0=≠referenceDiagnostics
  ok◶⟨
    {𝕊:{state⇐"error",current⇐@,history⇐@,diagnostics⇐diagnostics}},
    {𝕊:{state⇐"ok",current⇐current,history⇐history,diagnostics⇐empty}}
  ⟩ @
}

{Load⇐Load,LoadShared⇐LoadShared}