# Effectful read boundary for canonical household.toml.
# Path ownership is fixed by the canonical Household root; callers cannot select
# a fallback or alternate Household policy source. The same physical TOML also
# carries historical Envelope evidence, so the current-policy owner receives
# only its explicit projection rather than claiming that historical meaning.

io ← •Import "source_io.bqn"
admission ← •Import "../ledger/household_policy_admission.bqn"
projection ← •Import "../ledger/household_current_policy_projection.bqn"
canonical ← •Import "canonical_household_sources.bqn"

Load ← {𝕊 base‿accounts‿budgetPolicy:
  raw ← io.ReadRaw (io.JoinPath ⟨base,canonical.householdPolicy⟩)
  admission.Admit ⟨projection.CurrentPolicy raw,accounts,budgetPolicy⟩
}

{Load⇐Load}
