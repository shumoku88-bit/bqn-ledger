# Read-only application adapter for canonical Household Actual Facts.
#
# Physical basenames are owned by canonical_household_sources.bqn. Account
# admission is owned by account_source_adapter.bqn. Canonical Journal-root include
# topology is checked before pure Ledger admission/projection.

io ← •Import "source_io.bqn"
sources ← •Import "canonical_household_sources.bqn"
accountSource ← •Import "account_source_adapter.bqn"
rootAdmission ← •Import "../ledger/canonical_journal_root_admission.bqn"
snapshot ← •Import "../ledger/snapshot.bqn"

# Use one already-admitted Account observation when a wider application lifetime
# needs several canonical sources interpreted against the same Account Registry.
LoadFromAccounts ← {𝕊 base‿accounts‿registry:
  raw ← io.ReadRaw (io.JoinPath ⟨base,sources.actual⟩)
  rootResult ← rootAdmission.Admit ⟨raw,sources.accounts⟩
  (rootResult.state≡"ok")◶⟨
    {𝕊:{state⇐"error",diagnostics⇐rootResult.diagnostics}},
    {𝕊:snapshot.BuildFromAccounts ⟨accounts,raw,registry⟩}
  ⟩ @
}

Load ← {𝕊 base‿registry:
  accountResult ← accountSource.Load base
  (accountResult.state≡"ok")◶⟨
    {𝕊:{state⇐"error",diagnostics⇐accountResult.diagnostics}},
    {𝕊:LoadFromAccounts ⟨base,accountResult.accounts,registry⟩}
  ⟩ @
}

{Load⇐Load,LoadFromAccounts⇐LoadFromAccounts}
