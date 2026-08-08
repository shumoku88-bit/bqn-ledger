# Test-only constructor for genuine canonical Budget Facts.
# Callers supply Budget Journal text; this helper never converts retained TSV rows.

admission ← •Import "../src/ledger/budget_journal_admission.bqn"
facts ← •Import "../src/ledger/facts.bqn"

Build ← {𝕊 raw‿accounts‿registry:
  admitted ← admission.Admit ⟨raw,accounts,registry⟩
  result ← {state⇐"error",facts⇐@,diagnostics⇐admitted.diagnostics}
  {𝕊:
    projected ← facts.Project ⟨admitted,accounts⟩
    result↩{state⇐projected.state,facts⇐projected,diagnostics⇐projected.diagnostics}
  }⍟(admitted.state≡"ok") @
  result
}

{Build⇐Build}
