# Effectful read boundary for canonical report.toml.
# Path ownership is fixed by the canonical Household root. Callers cannot select
# an alternate Report policy file or revive legacy manifest configuration.

io ← •Import "source_io.bqn"
admission ← •Import "../ledger/report_policy_admission.bqn"
canonical ← •Import "canonical_household_sources.bqn"

Load ← {𝕊 base:
  admission.Admit io.ReadRaw (io.JoinPath ⟨base,canonical.reportPolicy⟩)
}

{Load⇐Load}
