# Read-only application adapter for canonical Household Actual Facts.
#
# Physical basenames are owned by canonical_household_sources.bqn. Account
# admission is owned by account_source_adapter.bqn. Ledger admission/projection
# remains pure in src/ledger/snapshot.bqn.

io ← •Import "source_io.bqn"
sources ← •Import "canonical_household_sources.bqn"
accountSource ← •Import "account_source_adapter.bqn"
snapshot ← •Import "../ledger/snapshot.bqn"

Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}

Load ← {𝕊 base‿registry:
  accountResult ← accountSource.Load base
  result ← {state⇐"error",diagnostics⇐accountResult.diagnostics}
  {𝕊:
    raw ← io.ReadRaw Join ⟨base,sources.actual⟩
    result ↩ snapshot.BuildFromAccounts ⟨accountResult.accounts,raw,registry⟩
  }⍟(accountResult.state≡"ok") @
  result
}

{Load⇐Load}
