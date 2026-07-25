#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ak ← •Import "../src_next/account_key.bqn"
admission ← •Import "../src_next/journal_supported_single_currency_admission_for_test.bqn"
stage1 ← •Import "../src_next/journal_profile_stage1.bqn"

lf ← @+10
tab ← @+9

Raw ← {𝕊 lines: ∾ lines ∾¨ lf }

HasCode ← {𝕊 code‿result:
  ∨´ 0 ∾ {code ≡ 𝕩.code}¨ result.diagnostics
}

accountLines ← ⟨
  "assets:cash-ils" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=ILS",
  "expenses:food-ils" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=ILS",
  "assets:cash-usd" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=USD",
  "expenses:food-usd" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=USD",
  "assets:bank-jpy" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=JPY"
⟩
resolved ← ak.Resolve accountLines

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
1 lib.AssertEq ≠ ils.transactions
2 lib.AssertEq ≠ ils.normalized_postings
¯1234 lib.AssertEq (0 ⊑ ils.normalized_postings).normalized_coefficient
1234 lib.AssertEq (1 ⊑ ils.normalized_postings).normalized_coefficient
"-12.34" lib.AssertEq (0 ⊑ ils.normalized_postings).amount_text
"proof-ils-1" lib.AssertEq (0 ⊑ ils.transactions).source_event_id
"ILS" lib.AssertEq (0 ⊑ ils.transactions).domain
2 lib.AssertEq (0 ⊑ ils.transactions).calculation_scale

# The production Stage 1 profile remains unchanged and still rejects the ILS witness.
productionIls ← stage1.ParseWithProfile ⟨ilsRaw, "strict_self_contained"⟩
"error" lib.AssertEq productionIls.state
lib.Assert HasCode ⟨"commodity_unsupported", productionIls⟩

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
¯75 lib.AssertEq (0 ⊑ usd.normalized_postings).normalized_coefficient
75 lib.AssertEq (1 ⊑ usd.normalized_postings).normalized_coefficient
"proof-usd-1" lib.AssertEq (0 ⊑ usd.transactions).source_event_id

unsupportedRaw ← Raw ⟨
  "commodity EUR",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-22 * unsupported currency",
  "  assets:cash-ils  -1.00 EUR",
  "  expenses:food-ils  1.00 EUR"
⟩
unsupported ← admission.Admit ⟨unsupportedRaw, resolved⟩
"error" lib.AssertEq unsupported.state
lib.Assert HasCode ⟨"commodity_unsupported", unsupported⟩

precisionRaw ← Raw ⟨
  "commodity ILS",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-22 * excessive precision",
  "  assets:cash-ils  -1.234 ILS",
  "  expenses:food-ils  1.234 ILS"
⟩
precision ← admission.Admit ⟨precisionRaw, resolved⟩
"error" lib.AssertEq precision.state
lib.Assert HasCode ⟨"posting_precision_exceeded", precision⟩

accountMismatchRaw ← Raw ⟨
  "commodity ILS",
  "",
  "account assets:cash-usd",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-22 * account mismatch",
  "  assets:cash-usd  -1.00 ILS",
  "  expenses:food-ils  1.00 ILS"
⟩
accountMismatch ← admission.Admit ⟨accountMismatchRaw, resolved⟩
"error" lib.AssertEq accountMismatch.state
lib.Assert HasCode ⟨"posting_account_currency_mismatch", accountMismatch⟩

postingDomainMismatchRaw ← Raw ⟨
  "commodity ILS",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-22 * posting domain mismatch",
  "  assets:cash-ils  -1.00 USD",
  "  expenses:food-ils  1.00 ILS"
⟩
postingDomainMismatch ← admission.Admit ⟨postingDomainMismatchRaw, resolved⟩
"error" lib.AssertEq postingDomainMismatch.state
lib.Assert HasCode ⟨"posting_domain_mismatch", postingDomainMismatch⟩

unbalancedRaw ← Raw ⟨
  "commodity ILS",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-22 * unbalanced",
  "  assets:cash-ils  -1.00 ILS",
  "  expenses:food-ils  0.99 ILS"
⟩
unbalanced ← admission.Admit ⟨unbalancedRaw, resolved⟩
"error" lib.AssertEq unbalanced.state
lib.Assert HasCode ⟨"event_unbalanced", unbalanced⟩

# Structural validation is still delegated to the unchanged Stage 1 parser.
undeclaredAccountRaw ← Raw ⟨
  "commodity ILS",
  "",
  "account assets:cash-ils",
  "",
  "2026-07-22 * undeclared account",
  "  assets:cash-ils  -1.00 ILS",
  "  expenses:food-ils  1.00 ILS"
⟩
undeclaredAccount ← admission.Admit ⟨undeclaredAccountRaw, resolved⟩
"error" lib.AssertEq undeclaredAccount.state
lib.Assert HasCode ⟨"posting_account_unknown", undeclaredAccount⟩

•Out "test_journal_supported_single_currency_admission_proof.bqn: OK"
