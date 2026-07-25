#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ak ← •Import "../src_next/account_key.bqn"
admission ← •Import "../src_next/journal_supported_single_currency_admission_for_test.bqn"
stage1 ← •Import "../src_next/journal_profile_stage1.bqn"

lf ← @+10
tab ← @+9
Raw ← {𝕊 lines: ∾ (lines ∾¨ lf) }
HasCode ← {𝕊 code‿result: ∨´ 0 ∾ {code ≡ 𝕩.code}¨ result.diagnostics }

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
1 lib.AssertEq ≠ ils.transactions
"proof-ils-1" lib.AssertEq (0 ⊑ ils.transactions).source_event_id
"durable" lib.AssertEq (0 ⊑ ils.transactions).identity_kind
"2026-07-20" lib.AssertEq (0 ⊑ ils.transactions).date
"synthetic ILS meal" lib.AssertEq (0 ⊑ ils.transactions).description
"actual" lib.AssertEq (0 ⊑ ils.transactions).layer_name
"ILS" lib.AssertEq (0 ⊑ ils.transactions).domain
2 lib.AssertEq (0 ⊑ ils.transactions).calculation_scale
2 lib.AssertEq ≠ (0 ⊑ ils.transactions).postings
"-12.34" lib.AssertEq (0 ⊑ (0 ⊑ ils.transactions).postings).amount_text

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
1 lib.AssertEq ≠ usd.transactions
"proof-usd-1" lib.AssertEq (0 ⊑ usd.transactions).source_event_id
"USD" lib.AssertEq (0 ⊑ usd.transactions).domain

# The unchanged production profile still rejects raw non-JPY evidence.
productionIls ← stage1.ParseWithProfile ⟨ilsRaw, "strict_self_contained"⟩
"error" lib.AssertEq productionIls.state
lib.Assert HasCode ⟨"commodity_unsupported", productionIls⟩

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

multipleCommodityRaw ← Raw ⟨
  "commodity ILS",
  "",
  "commodity USD"
⟩
multipleCommodity ← admission.Admit ⟨multipleCommodityRaw, resolved⟩
"error" lib.AssertEq multipleCommodity.state
lib.Assert HasCode ⟨"commodity_domain_count_invalid", multipleCommodity⟩

# The semantic account registry knows both accounts, but the Journal declaration
# surface omits one. The unchanged Stage 1 structural parser must reject it.
undeclaredRaw ← Raw ⟨
  "commodity ILS",
  "",
  "account assets:cash-ils",
  "",
  "2026-07-22 * undeclared account",
  "  assets:cash-ils  -1.00 ILS",
  "  expenses:food-ils  1.00 ILS"
⟩
undeclared ← admission.Admit ⟨undeclaredRaw, resolved⟩
"error" lib.AssertEq undeclared.state
lib.Assert HasCode ⟨"posting_account_unknown", undeclared⟩

•Out "test_journal_supported_single_currency_admission_proof.bqn: OK"
