#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx ← •Import "../src_next/context.bqn"
sel ← •Import "../src_next/currency_selection.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab}
MakeSnapshot ← {𝕊 lines:
  {
    sources ⇐ ⟨
      {source_file⇐"journal.tsv", required⇐1, lines⇐lines},
      {source_file⇐"plan.tsv", required⇐0, lines⇐⟨⟩},
      {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐⟨⟩}
    ⟩
  }
}

base ← "fixtures/src-next-currency-mixed-selected"
accountLines ← loader.ReadLines (base ∾ "/accounts.tsv")
resolved ← ak.Resolve accountLines
snapshot ← ctx.LoadPostingSourceSnapshot base
cycleStart ← "2026-07-01"

# The existing no-selector boundary keeps mixed snapshots fail-closed.
noSelector ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨snapshot, resolved, cycleStart⟩
"error" lib.AssertEq noSelector.state
"mixed_currency_domains" lib.AssertEq noSelector.arithmetic_evidence.message
0 lib.AssertEq ≠ noSelector.posting_rows

# Explicit JPY selection reuses exact single-currency arithmetic.
jpy ← sel.Build ⟨snapshot, resolved, cycleStart, "JPY"⟩
"ok" lib.AssertEq jpy.state
"JPY" lib.AssertEq jpy.selected_currency
1 lib.AssertEq ≠ jpy.row_evidence
"proven" lib.AssertEq jpy.arithmetic_currency_proof.state
"JPY" lib.AssertEq jpy.arithmetic_currency_proof.domain
"resolved_single_currency" lib.AssertEq jpy.arithmetic_currency_proof.basis
0 lib.AssertEq jpy.arithmetic_currency_proof.amount_scale
2 lib.AssertEq ≠ jpy.posting_rows
0 lib.AssertEq +´ {𝕩.delta}¨ jpy.posting_rows
jpyDebits ← (({𝕩.side}¨ jpy.posting_rows) ≡¨ <"debit") / jpy.posting_rows
1200 lib.AssertEq (⊑ jpyDebits).delta

# Explicit ILS selection preserves exact decimal coefficients and source order.
ils ← sel.Build ⟨snapshot, resolved, cycleStart, "ILS"⟩
"ok" lib.AssertEq ils.state
"ILS" lib.AssertEq ils.selected_currency
2 lib.AssertEq ≠ ils.row_evidence
1 lib.AssertEq ∧´ ({𝕩.currency}¨ ils.row_evidence) ≡¨ <"ILS"
"proven" lib.AssertEq ils.arithmetic_currency_proof.state
"ILS" lib.AssertEq ils.arithmetic_currency_proof.domain
"resolved_single_currency" lib.AssertEq ils.arithmetic_currency_proof.basis
2 lib.AssertEq ils.arithmetic_currency_proof.amount_scale
4 lib.AssertEq ≠ ils.posting_rows
0 lib.AssertEq +´ {𝕩.delta}¨ ils.posting_rows
ilsDebits ← (({𝕩.side}¨ ils.posting_rows) ≡¨ <"debit") / ils.posting_rows
4250 lib.AssertEq (0 ⊑ ilsDebits).delta
5 lib.AssertEq (1 ⊑ ilsDebits).delta

# A row/account currency mismatch rejects the whole selected projection before
# any Posting IR rows are emitted.
mismatchSnapshot ← MakeSnapshot ⟨
  Line ⟨"2026-07-04", "wrong accounts", "assets:bank", "expenses:food", "7.50", "currency=ILS"⟩
⟩
mismatch ← sel.Build ⟨mismatchSnapshot, resolved, cycleStart, "ILS"⟩
"error" lib.AssertEq mismatch.state
0 lib.AssertEq ≠ mismatch.posting_rows
mismatchDiagnostic ← ⊑ mismatch.diagnostics
"account_currency_mismatch" lib.AssertEq mismatchDiagnostic.code
1 lib.AssertEq ∨´ "from account currency mismatch" ⍷ mismatchDiagnostic.message

# The selector itself is a closed, explicit domain.
unsupported ← sel.Build ⟨snapshot, resolved, cycleStart, "USD"⟩
"error" lib.AssertEq unsupported.state
0 lib.AssertEq ≠ unsupported.posting_rows
"unsupported_selected_currency" lib.AssertEq (⊑ unsupported.diagnostics).code

•Out "test_src_next_currency_selection.bqn: OK"
