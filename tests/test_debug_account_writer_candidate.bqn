#!/usr/bin/env bqn

io ← •Import "../src/application/source_io.bqn"
admission ← •Import "../src/ledger/account_journal_admission.bqn"

lf ← @+10
raw ← io.ReadRaw "fixtures/canonical-household-v1/accounts.journal"
block ← "account Income:Friend-Settlement"∾⟨lf⟩∾"  type: Income"∾⟨lf⟩∾"  commodity: JPY"
candidate ← raw
{𝕊:candidate∾↩⟨lf⟩}⍟((0<≠candidate) ∧ lf≠¯1↑candidate) @
candidate∾↩block∾⟨lf⟩
checked ← admission.Admit candidate
{𝕊:
  •Out "::error file=tests/test_debug_account_writer_candidate.bqn::candidate rejected: "∾•Fmt {𝕩.code}¨checked.diagnostics
  •Exit 1
}⍟(checked.state≢"ok") @
{𝕊:
  •Out "::error file=tests/test_debug_account_writer_candidate.bqn::candidate count mismatch: "∾•Fmt checked.accounts.count
  •Exit 1
}⍟(7≠checked.accounts.count) @
{𝕊:
  •Out "::error file=tests/test_debug_account_writer_candidate.bqn::candidate last Account mismatch: "∾•Fmt ¯1↑checked.accounts.key
  •Exit 1
}⍟("Income:Friend-Settlement"≢¯1⊑checked.accounts.key) @

•Out "test_debug_account_writer_candidate: ok"
