#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ak ← •Import "../src_next/account_key.bqn"
admission ← •Import "../src_next/journal_supported_single_currency_admission_for_test.bqn"

lf ← @+10
tab ← @+9
Raw ← {𝕊 lines: ∾ (lines ∾¨ lf) }

resolved ← ak.Resolve ⟨
  "assets:cash-ils" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=ILS",
  "expenses:food-ils" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=ILS",
  "assets:cash-usd" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=USD",
  "expenses:food-usd" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=USD"
⟩

ilsRaw ← Raw ⟨
  "commodity ILS",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-20 * synthetic ILS meal",
  "  ; event-id: proof-ils-1",
  "  assets:cash-ils  -12.34 ILS",
  "  expenses:food-ils  12.34 ILS"
⟩
ils ← admission.Admit ⟨ilsRaw, resolved⟩

"ok" lib.AssertEq ils.state
"ILS" lib.AssertEq ils.domain
2 lib.AssertEq ils.calculation_scale
0 lib.AssertEq ≠ ils.diagnostics
1 lib.AssertEq ≠ ils.transaction_starts
2 lib.AssertEq ≠ ils.normalized_postings
¯1234 lib.AssertEq (0 ⊑ ils.normalized_postings).source_coefficient
1234 lib.AssertEq (1 ⊑ ils.normalized_postings).source_coefficient
¯1234 lib.AssertEq (0 ⊑ ils.normalized_postings).normalized_coefficient
1234 lib.AssertEq (1 ⊑ ils.normalized_postings).normalized_coefficient
2 lib.AssertEq (0 ⊑ ils.normalized_postings).source_scale
2 lib.AssertEq (1 ⊑ ils.normalized_postings).source_scale
"ILS" lib.AssertEq (0 ⊑ ils.normalized_postings).commodity
"ILS" lib.AssertEq (1 ⊑ ils.normalized_postings).account_currency

usdRaw ← Raw ⟨
  "commodity USD",
  "",
  "account assets:cash-usd",
  "",
  "account expenses:food-usd",
  "",
  "2026-07-21 * synthetic USD meal",
  "  ; event-id: proof-usd-1",
  "  assets:cash-usd  -7.5 USD",
  "  expenses:food-usd  7.5 USD"
⟩
usd ← admission.Admit ⟨usdRaw, resolved⟩

"ok" lib.AssertEq usd.state
"USD" lib.AssertEq usd.domain
1 lib.AssertEq usd.calculation_scale
0 lib.AssertEq ≠ usd.diagnostics
2 lib.AssertEq ≠ usd.normalized_postings
¯75 lib.AssertEq (0 ⊑ usd.normalized_postings).normalized_coefficient
75 lib.AssertEq (1 ⊑ usd.normalized_postings).normalized_coefficient

•Out "test_journal_supported_single_currency_admission_proof.bqn: ILS USD NORMALIZATION OK"
