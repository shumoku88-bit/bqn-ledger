# Test-only constructor for genuine admitted Budget movements and their generic
# Facts projection. Callers supply Budget Journal text; no retained TSV conversion.

admission ← •Import "../src/ledger/budget_journal_admission.bqn"
facts ← •Import "../src/ledger/facts.bqn"

Build ← {𝕊 raw‿accounts‿registry:
  admitted ← admission.Admit ⟨raw,accounts,registry⟩
  result ← {state⇐"error",movements⇐@,facts⇐@,diagnostics⇐admitted.diagnostics}
  {𝕊:
    projected ← facts.Project ⟨admitted,accounts⟩
    result↩{state⇐projected.state,movements⇐admitted,facts⇐projected,diagnostics⇐projected.diagnostics}
  }⍟(admitted.state≡"ok") @
  result
}

{Build⇐Build}
