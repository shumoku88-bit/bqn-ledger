#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ak ← •Import "../src_next/account_key.bqn"
container ← •Import "../src_next/journal_multi_currency_container_admission_for_test.bqn"
stage1 ← •Import "../src_next/journal_profile_stage1.bqn"

lf ← @+10
tab ← @+9
Raw ← {𝕊 lines: ∾ (lines ∾¨ lf) }
HasCode ← {𝕊 code‿result: ∨´ 0 ∾ {code ≡ 𝕩.code}¨ result.diagnostics }

resolved ← ak.Resolve ⟨
  "assets:bank-jpy" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=JPY",
  "expenses:food-jpy" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=JPY",
  "assets:cash-ils" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=ILS",
  "expenses:food-ils" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=ILS",
  "assets:cash-usd" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=USD",
  "expenses:food-usd" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=USD"
⟩

multiRaw ← Raw ⟨
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
  "  ; event-id: proof-jpy-container-1",
  "  assets:bank-jpy  -1200 JPY",
  "  expenses:food-jpy  1200 JPY",
  "",
  "2026-07-21 * synthetic ILS meal",
  "  ; event-id: proof-ils-container-1",
  "  assets:cash-ils  -12.34 ILS",
  "  expenses:food-ils  12.34 ILS"
⟩

multi ← container.Admit ⟨multiRaw, resolved⟩
"ok" lib.AssertEq multi.state
0 lib.AssertEq ≠ multi.diagnostics
2 lib.AssertEq ≠ multi.declared_domains
"JPY" lib.AssertEq 0 ⊑ multi.declared_domains
"ILS" lib.AssertEq 1 ⊑ multi.declared_domains
2 lib.AssertEq ≠ multi.transactions

jpy ← 0 ⊑ multi.transactions
"proof-jpy-container-1" lib.AssertEq jpy.source_event_id
"JPY" lib.AssertEq jpy.domain
0 lib.AssertEq jpy.calculation_scale
13 lib.AssertEq jpy.source_start_line
2 lib.AssertEq ≠ jpy.postings
15 lib.AssertEq (0 ⊑ jpy.postings).source_line
¯1200 lib.AssertEq (0 ⊑ jpy.postings).normalized_coefficient
1200 lib.AssertEq (1 ⊑ jpy.postings).normalized_coefficient

ils ← 1 ⊑ multi.transactions
"proof-ils-container-1" lib.AssertEq ils.source_event_id
"ILS" lib.AssertEq ils.domain
2 lib.AssertEq ils.calculation_scale
18 lib.AssertEq ils.source_start_line
2 lib.AssertEq ≠ ils.postings
20 lib.AssertEq (0 ⊑ ils.postings).source_line
¯1234 lib.AssertEq (0 ⊑ ils.postings).normalized_coefficient
1234 lib.AssertEq (1 ⊑ ils.postings).normalized_coefficient
"-12.34" lib.AssertEq (0 ⊑ ils.postings).amount_text

# USD is a second generality witness in another multi-currency container.
usdRaw ← Raw ⟨
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
  "2026-07-22 * synthetic JPY transport",
  "  ; event-id: proof-jpy-container-2",
  "  assets:bank-jpy  -500 JPY",
  "  expenses:food-jpy  500 JPY",
  "",
  "2026-07-23 * synthetic USD meal",
  "  ; event-id: proof-usd-container-1",
  "  assets:cash-usd  -7.5 USD",
  "  expenses:food-usd  7.5 USD"
⟩

usdContainer ← container.Admit ⟨usdRaw, resolved⟩
"ok" lib.AssertEq usdContainer.state
0 lib.AssertEq ≠ usdContainer.diagnostics
2 lib.AssertEq ≠ usdContainer.transactions
usd ← 1 ⊑ usdContainer.transactions
"USD" lib.AssertEq usd.domain
1 lib.AssertEq usd.calculation_scale
¯75 lib.AssertEq (0 ⊑ usd.postings).normalized_coefficient
75 lib.AssertEq (1 ⊑ usd.postings).normalized_coefficient

# The unchanged production Stage 1 parser still rejects the raw multi-currency Journal.
production ← stage1.ParseWithProfile ⟨multiRaw, "strict_self_contained"⟩
"error" lib.AssertEq production.state

# An ordinary transaction may not mix JPY and ILS postings.
mixedRaw ← Raw ⟨
  "commodity JPY",
  "",
  "commodity ILS",
  "",
  "account assets:bank-jpy",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-24 * invalid mixed-domain ordinary transaction",
  "  ; event-id: proof-mixed-container-1",
  "  assets:bank-jpy  -100 JPY",
  "  expenses:food-ils  100.00 ILS"
⟩

mixed ← container.Admit ⟨mixedRaw, resolved⟩
"error" lib.AssertEq mixed.state
lib.Assert HasCode ⟨"mixed_domain_ordinary_transaction", mixed⟩
0 lib.AssertEq ≠ mixed.transactions

# A posting domain must be explicitly declared by the Journal container.
undeclaredRaw ← Raw ⟨
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
lib.Assert HasCode ⟨"transaction_domain_undeclared", undeclared⟩

# Declarations themselves remain registry-driven.
unsupportedRaw ← Raw ⟨
  "commodity EUR",
  "",
  "account assets:bank-jpy",
  "",
  "2026-07-24 * unsupported declaration",
  "  assets:bank-jpy  -1 EUR",
  "  assets:bank-jpy  1 EUR"
⟩

unsupported ← container.Admit ⟨unsupportedRaw, resolved⟩
"error" lib.AssertEq unsupported.state
lib.Assert HasCode ⟨"commodity_unsupported", unsupported⟩

•Out "test_journal_multi_currency_container_admission_proof.bqn: OK"
