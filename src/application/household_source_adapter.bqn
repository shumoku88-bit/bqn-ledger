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

Read ← {𝕊 base: io.ReadRaw (io.JoinPath ⟨base,canonical.householdPolicy⟩)}
Current ← {𝕊 raw‿accounts: admission.Admit ⟨projection.CurrentPolicy raw,accounts⟩}

Load ← {𝕊 base‿accounts:
  Current ⟨Read base,accounts⟩
}

LoadShared ← {𝕊 base‿accounts:
  raw ← Read base
  current ← Current ⟨raw,accounts⟩
  history ← historyAdmission.Admit raw
  diagnostics ← current.diagnostics ∾ history.diagnostics
  ok ← (current.state≡"ok") ∧ history.state≡"ok"
  ok◶⟨
    {𝕊:{state⇐"error",current⇐@,history⇐@,diagnostics⇐diagnostics}},
    {𝕊:{state⇐"ok",current⇐current,history⇐history,diagnostics⇐empty}}
  ⟩ @
}

{Load⇐Load,LoadShared⇐LoadShared}