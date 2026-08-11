# Test-only compatibility fixture for historical accounts.tsv based snapshots.
#
# Production Snapshot ownership starts from already-admitted canonical Account
# evidence. Older accounting/section fixtures still use accounts.tsv rows; keep
# that qualification convenience here rather than in src/ledger/snapshot.bqn.

accountAdmission ← •Import "../src/ledger/account_admission.bqn"
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

Build ← {𝕊 accountLines‿rawJournal‿registry:
  accountResult ← accountAdmission.Admit ⟨accountLines,registry⟩
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
