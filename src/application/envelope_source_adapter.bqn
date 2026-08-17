# Read-only application adapter for canonical envelope.toml.

io ← •Import "source_io.bqn"
sources ← •Import "canonical_household_sources.bqn"
policyAdmission ← •Import "../ledger/envelope_policy_admission.bqn"

LoadPolicy ← {𝕊 base‿accounts:
  policyAdmission.Admit ⟨io.ReadRaw (io.JoinPath ⟨base,sources.envelopePolicy⟩),accounts⟩
}

{LoadPolicy⇐LoadPolicy}
