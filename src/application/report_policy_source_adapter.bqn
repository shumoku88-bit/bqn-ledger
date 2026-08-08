# Effectful read boundary for canonical report.toml.
# Path ownership is fixed by the canonical Household root. Callers cannot select
# an alternate Report policy file or revive legacy manifest configuration.

io ← •Import "source_io.bqn"
admission ← •Import "../ledger/report_policy_admission.bqn"
canonical ← •Import "canonical_household_sources.bqn"

Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Load ← {𝕊 base:
  admission.Admit io.ReadRaw Join ⟨base,canonical.reportPolicy⟩
}

{Load⇐Load}
