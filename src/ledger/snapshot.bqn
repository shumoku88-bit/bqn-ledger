# Pure canonical ledger snapshot admission.
# Composition supplies already-read account lines, raw Journal text, and registry.
# No report, context, Plan/Budget, path, clock, or source I/O is accepted here.

accountAdmission ← •Import "account_admission.bqn"
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

Build ← {𝕊 accountLines‿rawJournal‿registry:
  diagnostics ← empty
  accountResult ← accountAdmission.Admit ⟨accountLines,registry⟩
  diagnostics ∾↩ accountResult.diagnostics
  journalResult ← {state⇐"error",declared_domains⇐empty,transactions⇐empty,diagnostics⇐empty}
  factResult ← EmptyFacts @
  {𝕊:
    journalResult ↩ journalAdmission.Admit ⟨rawJournal,accountResult.accounts,registry⟩
    diagnostics ∾↩ journalResult.diagnostics
    {𝕊:
      factResult ↩ facts.Project ⟨journalResult,accountResult.accounts⟩
      diagnostics ∾↩ factResult.diagnostics
    }⍟(journalResult.state≡"ok") @
  }⍟(accountResult.state≡"ok") @
  state ← ((accountResult.state≡"ok") ∧ (journalResult.state≡"ok") ∧ factResult.state≡"ok")⊑"error"‿"ok"
  {
    state⇐state,
    facts⇐factResult,
    diagnostics⇐diagnostics
  }
}

{Build⇐Build}
