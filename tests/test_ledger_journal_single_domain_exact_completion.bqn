#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
single ← •Import "../src/ledger/journal_single_domain_admission.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics}
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accounts ← {
  key⇐⟨"Assets:Cash","Expenses:Food"⟩,
  currency⇐⟨"JPY","JPY"⟩
}
prefixLines ← ⟨
  "commodity JPY",
  "",
  "account Assets:Cash",
  "",
  "account Expenses:Food",
  ""
⟩
Admit ← {𝕊 body: single.Admit ⟨Raw prefixLines∾body,accounts,registry⟩}

# Source scales remain evidence while exact normalization uses one calculation
# scale for the admitted transaction.
scaled ← Admit ⟨
  "2026-01-01 * mixed exact scales",
  "  Assets:Cash  -1.2 JPY",
  "  Expenses:Food  1.20 JPY"
⟩
"ok" lib.AssertEq scaled.state
1 lib.AssertEq ≠scaled.transactions
scaledTxn ← ⊑scaled.transactions
2 lib.AssertEq scaledTxn.calculation_scale
⟨¯12,120⟩ lib.AssertEq {𝕩.source_coefficient}¨scaledTxn.postings
⟨1,2⟩ lib.AssertEq {𝕩.source_scale}¨scaledTxn.postings
⟨¯120,120⟩ lib.AssertEq {𝕩.normalized_coefficient}¨scaledTxn.postings

# One elided Posting is inferred as the exact opposite of explicit evidence and
# retains empty source amount text.
elided ← Admit ⟨
  "2026-01-02 * infer one Posting",
  "  Assets:Cash  -1.2 JPY",
  "  Expenses:Food"
⟩
"ok" lib.AssertEq elided.state
elidedTxn ← ⊑elided.transactions
1 lib.AssertEq elidedTxn.calculation_scale
⟨"-1.2",""⟩ lib.AssertEq {𝕩.amount_text}¨elidedTxn.postings
⟨¯12,12⟩ lib.AssertEq {𝕩.source_coefficient}¨elidedTxn.postings
⟨1,1⟩ lib.AssertEq {𝕩.source_scale}¨elidedTxn.postings
⟨¯12,12⟩ lib.AssertEq {𝕩.normalized_coefficient}¨elidedTxn.postings

# More than one elision is transaction-level failure owned by the transaction
# start coordinate.
twoElided ← Admit ⟨
  "2026-01-03 * too many elisions",
  "  Assets:Cash  -1 JPY",
  "  Expenses:Food",
  "  Assets:Cash"
⟩
"error" lib.AssertEq twoElided.state
⟨"posting_elided_multiple"⟩ lib.AssertEq {𝕩.code}¨twoElided.diagnostics
⟨7⟩ lib.AssertEq {𝕩.line}¨twoElided.diagnostics
0 lib.AssertEq ≠twoElided.transactions

# An elided Posting without any explicit balance evidence is row-owned failure.
uninferable ← Admit ⟨
  "2026-01-04 * no explicit evidence",
  "  Assets:Cash"
⟩
"error" lib.AssertEq uninferable.state
⟨"posting_elided_uninferable"⟩ lib.AssertEq {𝕩.code}¨uninferable.diagnostics
⟨8⟩ lib.AssertEq {𝕩.line}¨uninferable.diagnostics
0 lib.AssertEq ≠uninferable.transactions

# Exact explicit evidence that already sums to zero cannot infer a nonzero third
# Posting. The elided source row owns the diagnostic.
zeroInference ← Admit ⟨
  "2026-01-05 * zero inference",
  "  Assets:Cash  -1 JPY",
  "  Expenses:Food  1 JPY",
  "  Assets:Cash"
⟩
"error" lib.AssertEq zeroInference.state
⟨"posting_elided_zero"⟩ lib.AssertEq {𝕩.code}¨zeroInference.diagnostics
⟨10⟩ lib.AssertEq {𝕩.line}¨zeroInference.diagnostics
0 lib.AssertEq ≠zeroInference.transactions

# With no elision, normalized exact coefficients must balance at the transaction
# scale; imbalance remains transaction-start diagnostic ownership.
unbalanced ← Admit ⟨
  "2026-01-06 * unbalanced",
  "  Assets:Cash  -1.0 JPY",
  "  Expenses:Food  2.00 JPY"
⟩
"error" lib.AssertEq unbalanced.state
lib.Assert HasCode ⟨"event_unbalanced",unbalanced.diagnostics⟩
⟨7⟩ lib.AssertEq {𝕩.line}¨unbalanced.diagnostics
0 lib.AssertEq ≠unbalanced.transactions

•Out "test_ledger_journal_single_domain_exact_completion: ok"
