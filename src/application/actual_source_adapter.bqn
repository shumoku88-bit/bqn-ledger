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

Load ← {𝕊 base‿registry:
  accountResult ← accountSource.Load base
  result ← {state⇐"error",diagnostics⇐accountResult.diagnostics}
  {𝕊:
    raw ← io.ReadRaw (io.JoinPath ⟨base,sources.actual⟩)
    rootResult ← rootAdmission.Admit ⟨raw,sources.accounts⟩
    result ↩ {state⇐"error",diagnostics⇐rootResult.diagnostics}
    {𝕊: result↩snapshot.BuildFromAccounts ⟨accountResult.accounts,raw,registry⟩}⍟(rootResult.state≡"ok") @
  }⍟(accountResult.state≡"ok") @
  result
}

{Load⇐Load}
