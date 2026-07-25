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

jpyIlsRaw ← Raw ⟨
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
  "  ; event-id: container-jpy-1",
  "  assets:bank-jpy  -800 JPY",
  "  expenses:food-jpy  800 JPY",
  "",
  "2026-07-21 * synthetic ILS meal",
  "  ; event-id: container-ils-1",
  "  assets:cash-ils  -12.34 ILS",
  "  expenses:food-ils  12.34 ILS"
⟩

jpyIls ← container.Admit ⟨jpyIlsRaw, resolved⟩
"ok" lib.AssertEq jpyIls.state
0 lib.AssertEq ≠ jpyIls.diagnostics
2 lib.AssertEq ≠ jpyIls.declared_domains
"JPY" lib.AssertEq 0 ⊑ jpyIls.declared_domains
"ILS" lib.AssertEq 1 ⊑ jpyIls.declared_domains
2 lib.AssertEq ≠ jpyIls.transactions
"JPY" lib.AssertEq (0 ⊑ jpyIls.transactions).domain
0 lib.AssertEq (0 ⊑ jpyIls.transactions).calculation_scale
"container-jpy-1" lib.AssertEq (0 ⊑ jpyIls.transactions).source_event_id
"ILS" lib.AssertEq (1 ⊑ jpyIls.transactions).domain
2 lib.AssertEq (1 ⊑ jpyIls.transactions).calculation_scale
"container-ils-1" lib.AssertEq (1 ⊑ jpyIls.transactions).source_event_id
¯800 lib.AssertEq (0 ⊑ (0 ⊑ jpyIls.transactions).postings).normalized_coefficient
800 lib.AssertEq (1 ⊑ (0 ⊑ jpyIls.transactions).postings).normalized_coefficient
¯1234 lib.AssertEq (0 ⊑ (1 ⊑ jpyIls.transactions).postings).normalized_coefficient
1234 lib.AssertEq (1 ⊑ (1 ⊑ jpyIls.transactions).postings).normalized_coefficient
15 lib.AssertEq (0 ⊑ (0 ⊑ jpyIls.transactions).postings).source_line
20 lib.AssertEq (0 ⊑ (1 ⊑ jpyIls.transactions).postings).source_line

production ← stage1.ParseWithProfile ⟨jpyIlsRaw, "strict_self_contained"⟩
"error" lib.AssertEq production.state
lib.Assert HasCode ⟨"commodity_count_invalid", production⟩

jpyUsdRaw ← Raw ⟨
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
  "2026-07-22 * second JPY witness",
  "  assets:bank-jpy  -50 JPY",
  "  expenses:food-jpy  50 JPY",
  "",
  "2026-07-23 * synthetic USD meal",
  "  assets:cash-usd  -7.5 USD",
  "  expenses:food-usd  7.5 USD"
⟩
jpyUsd ← container.Admit ⟨jpyUsdRaw, resolved⟩
"ok" lib.AssertEq jpyUsd.state
2 lib.AssertEq ≠ jpyUsd.transactions
"JPY" lib.AssertEq (0 ⊑ jpyUsd.transactions).domain
"USD" lib.AssertEq (1 ⊑ jpyUsd.transactions).domain
1 lib.AssertEq (1 ⊑ jpyUsd.transactions).calculation_scale
¯75 lib.AssertEq (0 ⊑ (1 ⊑ jpyUsd.transactions).postings).normalized_coefficient
75 lib.AssertEq (1 ⊑ (1 ⊑ jpyUsd.transactions).postings).normalized_coefficient

mixedRaw ← Raw ⟨
  "commodity JPY",
  "",
  "commodity ILS",
  "",
  "account assets:bank-jpy",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-24 * forbidden mixed ordinary transaction",
  "  assets:bank-jpy  -100 JPY",
  "  expenses:food-ils  100 ILS"
⟩
mixed ← container.Admit ⟨mixedRaw, resolved⟩
"error" lib.AssertEq mixed.state
lib.Assert HasCode ⟨"transaction_domain_count_invalid", mixed⟩

undeclaredRaw ← Raw ⟨
  "commodity JPY",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-24 * undeclared ILS transaction",
  "  assets:cash-ils  -1.00 ILS",
  "  expenses:food-ils  1.00 ILS"
⟩
undeclared ← container.Admit ⟨undeclaredRaw, resolved⟩
"error" lib.AssertEq undeclared.state
lib.Assert HasCode ⟨"transaction_domain_undeclared", undeclared⟩

unsupportedRaw ← Raw ⟨
  "commodity JPY",
  "",
  "commodity EUR",
  "",
  "2026-07-24 * unsupported declaration",
  "  assets:bank-jpy  -1 JPY",
  "  expenses:food-jpy  1 JPY"
⟩
unsupported ← container.Admit ⟨unsupportedRaw, resolved⟩
"error" lib.AssertEq unsupported.state
lib.Assert HasCode ⟨"commodity_unsupported", unsupported⟩

•Out "test_journal_multi_currency_container_admission_proof.bqn: OK"