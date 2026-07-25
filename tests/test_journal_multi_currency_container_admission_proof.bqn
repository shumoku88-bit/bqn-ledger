#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ak ← •Import "../src_next/account_key.bqn"
container ← •Import "../src_next/journal_multi_currency_container_admission_for_test.bqn"
stage1 ← •Import "../src_next/journal_profile_stage1.bqn"

lf ← @+10
tab ← @+9
MakeRaw ← {𝕊 lines: ∾ (lines ∾¨ lf) }
HasCode ← {𝕊 code‿result: ∨´ 0 ∾ {code ≡ 𝕩.code}¨ result.diagnostics }

resolved ← ak.Resolve ⟨
  "assets:bank-jpy" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=JPY",
  "expenses:food-jpy" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=JPY",
  "assets:cash-ils" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=ILS",
  "expenses:food-ils" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=ILS",
  "assets:cash-usd" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=USD",
  "expenses:food-usd" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=USD"
⟩

# Separate JPY and ILS ordinary transactions share one raw Journal container.
jpyIlsRaw ← MakeRaw ⟨
  "commodity JPY",
  "",
  "commodity ILS",
  "",
  "account assets:bank-jpy",
  "",
  "account expenses:food-jpy",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-20 * synthetic JPY meal",
  "  ; event-id: proof-jpy-1",
  "  assets:bank-jpy  -800 JPY",
  "  expenses:food-jpy  800 JPY",
  "",
  "2026-07-21 * synthetic ILS meal",
  "  ; event-id: proof-ils-1",
  "  assets:cash-ils  -12.34 ILS",
  "  expenses:food-ils  12.34 ILS"
⟩
jpyIls ← container.Admit ⟨jpyIlsRaw, resolved⟩

"ok" lib.AssertEq jpyIls.state
0 lib.AssertEq ≠ jpyIls.diagnostics
⟨"JPY", "ILS"⟩ lib.AssertEq jpyIls.declared_domains
2 lib.AssertEq ≠ jpyIls.transactions

jpy ← 0 ⊑ jpyIls.transactions
"JPY" lib.AssertEq jpy.domain
0 lib.AssertEq jpy.calculation_scale
"proof-jpy-1" lib.AssertEq jpy.source_event_id
"durable" lib.AssertEq jpy.identity_kind
"2026-07-20" lib.AssertEq jpy.date
"synthetic JPY meal" lib.AssertEq jpy.description
13 lib.AssertEq jpy.source_start_line
16 lib.AssertEq jpy.source_end_line
2 lib.AssertEq ≠ jpy.postings
¯800 lib.AssertEq (0 ⊑ jpy.postings).source_coefficient
800 lib.AssertEq (1 ⊑ jpy.postings).source_coefficient
0 lib.AssertEq (0 ⊑ jpy.postings).source_scale
¯800 lib.AssertEq (0 ⊑ jpy.postings).normalized_coefficient
800 lib.AssertEq (1 ⊑ jpy.postings).normalized_coefficient
"JPY" lib.AssertEq (0 ⊑ jpy.postings).account_currency
"JPY" lib.AssertEq (0 ⊑ jpy.postings).commodity
15 lib.AssertEq (0 ⊑ jpy.postings).source_line
16 lib.AssertEq (1 ⊑ jpy.postings).source_line

ils ← 1 ⊑ jpyIls.transactions
"ILS" lib.AssertEq ils.domain
2 lib.AssertEq ils.calculation_scale
"proof-ils-1" lib.AssertEq ils.source_event_id
"durable" lib.AssertEq ils.identity_kind
"2026-07-21" lib.AssertEq ils.date
"synthetic ILS meal" lib.AssertEq ils.description
18 lib.AssertEq ils.source_start_line
21 lib.AssertEq ils.source_end_line
2 lib.AssertEq ≠ ils.postings
"-12.34" lib.AssertEq (0 ⊑ ils.postings).amount_text
¯1234 lib.AssertEq (0 ⊑ ils.postings).source_coefficient
1234 lib.AssertEq (1 ⊑ ils.postings).source_coefficient
2 lib.AssertEq (0 ⊑ ils.postings).source_scale
¯1234 lib.AssertEq (0 ⊑ ils.postings).normalized_coefficient
1234 lib.AssertEq (1 ⊑ ils.postings).normalized_coefficient
"ILS" lib.AssertEq (0 ⊑ ils.postings).account_currency
"ILS" lib.AssertEq (0 ⊑ ils.postings).commodity
20 lib.AssertEq (0 ⊑ ils.postings).source_line
21 lib.AssertEq (1 ⊑ ils.postings).source_line

# USD is a second registry-driven witness; no ILS-specific implementation branch.
jpyUsdRaw ← MakeRaw ⟨
  "commodity JPY",
  "",
  "commodity USD",
  "",
  "account assets:bank-jpy",
  "",
  "account expenses:food-jpy",
  "",
  "account assets:cash-usd",
  "",
  "account expenses:food-usd",
  "",
  "2026-07-22 * synthetic JPY purchase",
  "  ; event-id: proof-jpy-2",
  "  assets:bank-jpy  -500 JPY",
  "  expenses:food-jpy  500 JPY",
  "",
  "2026-07-23 * synthetic USD purchase",
  "  ; event-id: proof-usd-1",
  "  assets:cash-usd  -7.5 USD",
  "  expenses:food-usd  7.5 USD"
⟩
jpyUsd ← container.Admit ⟨jpyUsdRaw, resolved⟩

"ok" lib.AssertEq jpyUsd.state
0 lib.AssertEq ≠ jpyUsd.diagnostics
⟨"JPY", "USD"⟩ lib.AssertEq jpyUsd.declared_domains
2 lib.AssertEq ≠ jpyUsd.transactions
usd ← 1 ⊑ jpyUsd.transactions
"USD" lib.AssertEq usd.domain
1 lib.AssertEq usd.calculation_scale
"proof-usd-1" lib.AssertEq usd.source_event_id
¯75 lib.AssertEq (0 ⊑ usd.postings).source_coefficient
75 lib.AssertEq (1 ⊑ usd.postings).source_coefficient
1 lib.AssertEq (0 ⊑ usd.postings).source_scale
¯75 lib.AssertEq (0 ⊑ usd.postings).normalized_coefficient
75 lib.AssertEq (1 ⊑ usd.postings).normalized_coefficient
"USD" lib.AssertEq (1 ⊑ usd.postings).account_currency
"USD" lib.AssertEq (1 ⊑ usd.postings).commodity

# One ordinary transaction may not mix currency domains.
mixedRaw ← MakeRaw ⟨
  "commodity JPY",
  "",
  "commodity ILS",
  "",
  "account assets:bank-jpy",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-24 * invalid mixed domain",
  "  assets:bank-jpy  -100 JPY",
  "  expenses:food-ils  100 ILS"
⟩
mixed ← container.Admit ⟨mixedRaw, resolved⟩
"error" lib.AssertEq mixed.state
1 lib.AssertEq ≠ mixed.diagnostics
lib.Assert HasCode ⟨"transaction_domain_count_invalid", mixed⟩
0 lib.AssertEq ≠ mixed.transactions

# A transaction domain must have a Journal commodity declaration.
undeclaredRaw ← MakeRaw ⟨
  "commodity JPY",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-24 * undeclared ILS domain",
  "  assets:cash-ils  -1.00 ILS",
  "  expenses:food-ils  1.00 ILS"
⟩
undeclared ← container.Admit ⟨undeclaredRaw, resolved⟩
"error" lib.AssertEq undeclared.state
1 lib.AssertEq ≠ undeclared.diagnostics
lib.Assert HasCode ⟨"transaction_domain_undeclared", undeclared⟩
0 lib.AssertEq ≠ undeclared.transactions

# Unsupported declarations stop before transaction-specific admission.
unsupportedRaw ← MakeRaw ⟨
  "commodity EUR",
  "",
  "account assets:bank-jpy",
  "",
  "account expenses:food-jpy",
  "",
  "2026-07-24 * unsupported commodity",
  "  assets:bank-jpy  -1.00 EUR",
  "  expenses:food-jpy  1.00 EUR"
⟩
unsupported ← container.Admit ⟨unsupportedRaw, resolved⟩
"error" lib.AssertEq unsupported.state
1 lib.AssertEq ≠ unsupported.diagnostics
lib.Assert HasCode ⟨"commodity_unsupported", unsupported⟩
0 lib.AssertEq ≠ unsupported.transactions

# Malformed posting evidence does not produce a derived domain diagnostic.
malformedRaw ← MakeRaw ⟨
  "commodity JPY",
  "",
  "account assets:bank-jpy",
  "",
  "2026-07-24 * malformed posting",
  "  assets:bank-jpy  -100"
⟩
malformed ← container.Admit ⟨malformedRaw, resolved⟩
"error" lib.AssertEq malformed.state
1 lib.AssertEq ≠ malformed.diagnostics
lib.Assert HasCode ⟨"posting_shape_invalid", malformed⟩
0 lib.AssertEq ≠ malformed.transactions

# A declaration-only Journal has no ordinary transaction to admit.
emptyRaw ← MakeRaw ⟨
  "commodity JPY",
  "",
  "account assets:bank-jpy"
⟩
emptyResult ← container.Admit ⟨emptyRaw, resolved⟩
"error" lib.AssertEq emptyResult.state
1 lib.AssertEq ≠ emptyResult.diagnostics
lib.Assert HasCode ⟨"transaction_missing", emptyResult⟩
0 lib.AssertEq ≠ emptyResult.transactions

# Existing single-currency balance diagnostics are preserved with raw provenance.
unbalancedRaw ← MakeRaw ⟨
  "commodity ILS",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-24 * unbalanced ILS transaction",
  "  assets:cash-ils  -1.00 ILS",
  "  expenses:food-ils  0.99 ILS"
⟩
unbalanced ← container.Admit ⟨unbalancedRaw, resolved⟩
"error" lib.AssertEq unbalanced.state
1 lib.AssertEq ≠ unbalanced.diagnostics
lib.Assert HasCode ⟨"event_unbalanced", unbalanced⟩
7 lib.AssertEq (⊑ unbalanced.diagnostics).line
0 lib.AssertEq ≠ unbalanced.transactions

# Production Stage 1 remains unchanged and rejects the same multi-currency raw Journal.
production ← stage1.ParseWithProfile ⟨jpyIlsRaw, "strict_self_contained"⟩
"error" lib.AssertEq production.state
lib.Assert HasCode ⟨"commodity_unsupported", production⟩

•Out "test_journal_multi_currency_container_admission_proof.bqn: OK"
