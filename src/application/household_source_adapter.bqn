# Effectful read boundary for canonical household.toml.
# Path ownership is fixed by the canonical Household root; callers cannot select
# a fallback or alternate Household policy source.

io ← •Import "source_io.bqn"
admission ← •Import "../ledger/household_policy_admission.bqn"
canonical ← •Import "canonical_household_sources.bqn"

Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Load ← {𝕊 base‿accounts‿budgetPolicy:
  admission.Admit ⟨io.ReadRaw Join ⟨base,canonical.householdPolicy⟩,accounts,budgetPolicy⟩
}

{Load⇐Load}
