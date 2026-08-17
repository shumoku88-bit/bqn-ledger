# Read-only application adapter for canonical entitlement.journal.

io ← •Import "source_io.bqn"
sources ← •Import "canonical_household_sources.bqn"
entitlementAdmission ← •Import "../ledger/entitlement_journal_admission.bqn"

Load ← {𝕊 base‿envelopeHistory‿registry:
  raw ← io.ReadRaw (io.JoinPath ⟨base,sources.entitlement⟩)
  entitlementAdmission.Admit ⟨raw,envelopeHistory,registry⟩
}

{Load⇐Load}
