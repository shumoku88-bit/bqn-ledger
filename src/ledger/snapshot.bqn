# Pure canonical ledger snapshot admission.
# Composition supplies already-read source values and registry policy.
# No report, context, Plan/Budget, path, clock, or source I/O is accepted here.

journalAdmission ← •Import "journal_complete_admission.bqn"
facts ← •Import "facts.bqn"
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

BuildFromAccounts ← {𝕊 admittedAccounts‿rawJournal‿registry:
  diagnostics ← empty
  journalResult ← journalAdmission.Admit ⟨rawJournal,admittedAccounts,registry⟩
  diagnostics ∾↩ journalResult.diagnostics
  factResult ← EmptyFacts @
  {𝕊:
    factResult ↩ facts.Project ⟨journalResult,admittedAccounts⟩
    diagnostics ∾↩ factResult.diagnostics
  }⍟(journalResult.state≡"ok") @
  state ← ((journalResult.state≡"ok") ∧ factResult.state≡"ok")⊑"error"‿"ok"
  {state⇐state,facts⇐factResult,diagnostics⇐diagnostics}
}

{BuildFromAccounts⇐BuildFromAccounts}
