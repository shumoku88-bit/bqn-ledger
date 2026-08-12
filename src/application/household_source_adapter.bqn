# Effectful read boundary for canonical household.toml.
# Path ownership is fixed by the canonical Household root; callers cannot select
# a fallback or alternate Household policy source.

io ← •Import "source_io.bqn"
admission ← •Import "../ledger/household_policy_admission.bqn"
canonical ← •Import "canonical_household_sources.bqn"

Load ← {𝕊 base‿accounts‿budgetPolicy:
  admission.Admit ⟨io.ReadRaw (io.JoinPath ⟨base,canonical.householdPolicy⟩),accounts,budgetPolicy⟩
}

{Load⇐Load}
