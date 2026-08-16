# Test-only fixture for snapshots built from canonical Account Journal evidence.
#
# Production Snapshot ownership starts from already-admitted canonical Account
# evidence. Tests that need a compact in-memory path may admit accounts.journal
# here, then pass that Account observation to the Snapshot owner.

accountAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
empty ← ⟨⟩

EmptyFacts ← {𝕊:
  emptyTable ← {count⇐0,index⇐empty}
  {
    state⇐"error",
    transactions⇐{count⇐0,index⇐empty},
    postings⇐{count⇐0,index⇐empty},
    sources⇐emptyTable,domains⇐emptyTable,accounts⇐emptyTable,layers⇐emptyTable,
    diagnostics⇐empty
  }
}

Build ← {𝕊 accountSource‿rawJournal‿registry:
  accountResult ← accountAdmission.Admit accountSource
  diagnostics ← accountResult.diagnostics
  result ← {state⇐"error",facts⇐EmptyFacts @,diagnostics⇐diagnostics}
  {𝕊:
    built ← snapshot.BuildFromAccounts ⟨accountResult.accounts,rawJournal,registry⟩
    diagnostics ∾↩ built.diagnostics
    result ↩ {state⇐built.state,facts⇐built.facts,diagnostics⇐diagnostics}
  }⍟(accountResult.state≡"ok") @
  result
}

{Build⇐Build}
