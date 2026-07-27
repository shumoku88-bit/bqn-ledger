#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ak ← •Import "../src_next/account_key.bqn"
admission ← •Import "../src/ledger/journal_complete_admission.bqn"
stage1 ← •Import "../src_next/journal_profile_stage1.bqn"
setup ← •Import "../src_next/currency_setup.bqn"

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
admittedAccounts ← {key⇐resolved.accounts,currency⇐resolved.currencies}
Admit ← {𝕊 raw: admission.Admit ⟨raw,admittedAccounts,setup.registry_value⟩ }

# One production complete-source result contains separate JPY and ILS ordinary
# transactions without manufacturing a Journal-wide arithmetic domain.
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
  "2026-07-25 * synthetic JPY meal",
  "  ; event-id: production-jpy-1",
  "  ; txn-id: source-jpy-1",
  "  assets:bank-jpy  -800 JPY",
  "  expenses:food-jpy  800 JPY",
  "",
  "2026-07-26 * synthetic ILS meal",
  "  ; event-id: production-ils-1",
  "  ; txn-id: source-ils-1",
  "  assets:cash-ils  -12.34 ILS",
  "  expenses:food-ils  12.34 ILS"
⟩
jpyIls ← Admit jpyIlsRaw

"ok" lib.AssertEq jpyIls.state
0 lib.AssertEq ≠ jpyIls.diagnostics
⟨"JPY", "ILS"⟩ lib.AssertEq jpyIls.declared_domains
⟨"assets:bank-jpy","expenses:food-jpy","assets:cash-ils","expenses:food-ils"⟩ lib.AssertEq jpyIls.declared_accounts
2 lib.AssertEq ≠ jpyIls.transactions

jpy ← 0 ⊑ jpyIls.transactions
"JPY" lib.AssertEq jpy.domain
0 lib.AssertEq jpy.calculation_scale
"production-jpy-1" lib.AssertEq jpy.source_event_id
"durable" lib.AssertEq jpy.identity_kind
"source-jpy-1" lib.AssertEq jpy.txn_id
"2026-07-25" lib.AssertEq jpy.date
"synthetic JPY meal" lib.AssertEq jpy.description
13 lib.AssertEq jpy.source_start_line
17 lib.AssertEq jpy.source_end_line
2 lib.AssertEq ≠ jpy.metadata
2 lib.AssertEq ≠ jpy.postings
¯800 lib.AssertEq (0 ⊑ jpy.postings).source_coefficient
800 lib.AssertEq (1 ⊑ jpy.postings).source_coefficient
0 lib.AssertEq (0 ⊑ jpy.postings).source_scale
¯800 lib.AssertEq (0 ⊑ jpy.postings).normalized_coefficient
800 lib.AssertEq (1 ⊑ jpy.postings).normalized_coefficient
"JPY" lib.AssertEq (0 ⊑ jpy.postings).account_currency
"JPY" lib.AssertEq (0 ⊑ jpy.postings).commodity
16 lib.AssertEq (0 ⊑ jpy.postings).source_line
17 lib.AssertEq (1 ⊑ jpy.postings).source_line

ils ← 1 ⊑ jpyIls.transactions
"ILS" lib.AssertEq ils.domain
2 lib.AssertEq ils.calculation_scale
"production-ils-1" lib.AssertEq ils.source_event_id
"durable" lib.AssertEq ils.identity_kind
"source-ils-1" lib.AssertEq ils.txn_id
"2026-07-26" lib.AssertEq ils.date
"synthetic ILS meal" lib.AssertEq ils.description
19 lib.AssertEq ils.source_start_line
23 lib.AssertEq ils.source_end_line
2 lib.AssertEq ≠ ils.metadata
2 lib.AssertEq ≠ ils.postings
"-12.34" lib.AssertEq (0 ⊑ ils.postings).amount_text
¯1234 lib.AssertEq (0 ⊑ ils.postings).source_coefficient
1234 lib.AssertEq (1 ⊑ ils.postings).source_coefficient
2 lib.AssertEq (0 ⊑ ils.postings).source_scale
¯1234 lib.AssertEq (0 ⊑ ils.postings).normalized_coefficient
1234 lib.AssertEq (1 ⊑ ils.postings).normalized_coefficient
"ILS" lib.AssertEq (0 ⊑ ils.postings).account_currency
"ILS" lib.AssertEq (0 ⊑ ils.postings).commodity
22 lib.AssertEq (0 ⊑ ils.postings).source_line
23 lib.AssertEq (1 ⊑ ils.postings).source_line

# USD is a second registry-driven witness. The production owner has no
# ILS-specific branch.
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
  "2026-07-27 * synthetic JPY purchase",
  "  ; event-id: production-jpy-2",
  "  assets:bank-jpy  -500 JPY",
  "  expenses:food-jpy  500 JPY",
  "",
  "2026-07-28 * synthetic USD purchase",
  "  ; event-id: production-usd-1",
  "  assets:cash-usd  -7.5 USD",
  "  expenses:food-usd  7.5 USD"
⟩
jpyUsd ← Admit jpyUsdRaw

"ok" lib.AssertEq jpyUsd.state
0 lib.AssertEq ≠ jpyUsd.diagnostics
⟨"JPY", "USD"⟩ lib.AssertEq jpyUsd.declared_domains
2 lib.AssertEq ≠ jpyUsd.transactions
usd ← 1 ⊑ jpyUsd.transactions
"USD" lib.AssertEq usd.domain
1 lib.AssertEq usd.calculation_scale
"production-usd-1" lib.AssertEq usd.source_event_id
¯75 lib.AssertEq (0 ⊑ usd.postings).source_coefficient
75 lib.AssertEq (1 ⊑ usd.postings).source_coefficient
1 lib.AssertEq (0 ⊑ usd.postings).source_scale
¯75 lib.AssertEq (0 ⊑ usd.postings).normalized_coefficient
75 lib.AssertEq (1 ⊑ usd.postings).normalized_coefficient
"USD" lib.AssertEq (1 ⊑ usd.postings).account_currency
"USD" lib.AssertEq (1 ⊑ usd.postings).commodity

# One later invalid transaction closes the complete source without returning a
# previously admitted transaction as partial success.
partialRaw ← MakeRaw ⟨
  "commodity JPY",
  "",
  "commodity ILS",
  "",
  "account assets:bank-jpy",
  "",
  "account expenses:food-jpy",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-25 * valid first transaction",
  "  ; event-id: partial-valid-1",
  "  assets:bank-jpy  -100 JPY",
  "  expenses:food-jpy  100 JPY",
  "",
  "2026-07-26 * invalid later transaction",
  "  ; event-id: partial-invalid-1",
  "  assets:bank-jpy  -50 JPY",
  "  expenses:food-ils  50 ILS"
⟩
partial ← Admit partialRaw
"error" lib.AssertEq partial.state
lib.Assert HasCode ⟨"transaction_domain_count_invalid", partial⟩
0 lib.AssertEq ≠ partial.transactions

# Durable identity uniqueness is owned by the complete source, not by one
# currency partition.
duplicateIdentityRaw ← MakeRaw ⟨
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
  "2026-07-25 * first durable identity",
  "  ; event-id: duplicate-source-id",
  "  assets:bank-jpy  -100 JPY",
  "  expenses:food-jpy  100 JPY",
  "",
  "2026-07-26 * second durable identity",
  "  ; event-id: duplicate-source-id",
  "  assets:cash-ils  -1.00 ILS",
  "  expenses:food-ils  1.00 ILS"
⟩
duplicateIdentity ← Admit duplicateIdentityRaw
"error" lib.AssertEq duplicateIdentity.state
1 lib.AssertEq ≠ duplicateIdentity.diagnostics
lib.Assert HasCode ⟨"event_id_duplicate", duplicateIdentity⟩
0 lib.AssertEq ≠ duplicateIdentity.transactions

mixedRaw ← MakeRaw ⟨
  "commodity JPY",
  "",
  "commodity ILS",
  "",
  "account assets:bank-jpy",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-25 * invalid mixed domain",
  "  assets:bank-jpy  -100 JPY",
  "  expenses:food-ils  100 ILS"
⟩
mixed ← Admit mixedRaw
"error" lib.AssertEq mixed.state
1 lib.AssertEq ≠ mixed.diagnostics
lib.Assert HasCode ⟨"transaction_domain_count_invalid", mixed⟩
0 lib.AssertEq ≠ mixed.transactions

undeclaredRaw ← MakeRaw ⟨
  "commodity JPY",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-25 * undeclared ILS domain",
  "  assets:cash-ils  -1.00 ILS",
  "  expenses:food-ils  1.00 ILS"
⟩
undeclared ← Admit undeclaredRaw
"error" lib.AssertEq undeclared.state
1 lib.AssertEq ≠ undeclared.diagnostics
lib.Assert HasCode ⟨"transaction_domain_undeclared", undeclared⟩
0 lib.AssertEq ≠ undeclared.transactions

unsupportedRaw ← MakeRaw ⟨
  "commodity EUR",
  "",
  "account assets:bank-jpy",
  "",
  "account expenses:food-jpy",
  "",
  "2026-07-25 * unsupported commodity",
  "  assets:bank-jpy  -1.00 EUR",
  "  expenses:food-jpy  1.00 EUR"
⟩
unsupported ← Admit unsupportedRaw
"error" lib.AssertEq unsupported.state
1 lib.AssertEq ≠ unsupported.diagnostics
lib.Assert HasCode ⟨"commodity_unsupported", unsupported⟩
0 lib.AssertEq ≠ unsupported.transactions

precisionRaw ← MakeRaw ⟨
  "commodity ILS",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-25 * excessive precision",
  "  assets:cash-ils  -1.234 ILS",
  "  expenses:food-ils  1.234 ILS"
⟩
precision ← Admit precisionRaw
"error" lib.AssertEq precision.state
lib.Assert HasCode ⟨"posting_precision_exceeded", precision⟩
0 lib.AssertEq ≠ precision.transactions

accountMismatchRaw ← MakeRaw ⟨
  "commodity ILS",
  "",
  "account assets:cash-usd",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-25 * account currency mismatch",
  "  assets:cash-usd  -1.00 ILS",
  "  expenses:food-ils  1.00 ILS"
⟩
accountMismatch ← Admit accountMismatchRaw
"error" lib.AssertEq accountMismatch.state
lib.Assert HasCode ⟨"posting_account_currency_mismatch", accountMismatch⟩
0 lib.AssertEq ≠ accountMismatch.transactions

malformedRaw ← MakeRaw ⟨
  "commodity JPY",
  "",
  "account assets:bank-jpy",
  "",
  "2026-07-25 * malformed posting",
  "  assets:bank-jpy  -100"
⟩
malformed ← Admit malformedRaw
"error" lib.AssertEq malformed.state
1 lib.AssertEq ≠ malformed.diagnostics
lib.Assert HasCode ⟨"posting_shape_invalid", malformed⟩
0 lib.AssertEq ≠ malformed.transactions

emptyRaw ← MakeRaw ⟨
  "commodity JPY",
  "",
  "account assets:bank-jpy"
⟩
emptyResult ← Admit emptyRaw
"ok" lib.AssertEq emptyResult.state
0 lib.AssertEq ≠ emptyResult.diagnostics
0 lib.AssertEq ≠ emptyResult.transactions
⟨"JPY"⟩ lib.AssertEq emptyResult.declared_domains

zeroRaw ← MakeRaw ⟨
  "commodity ILS",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-25 * zero posting",
  "  assets:cash-ils  0.00 ILS",
  "  expenses:food-ils  0.00 ILS"
⟩
zero ← Admit zeroRaw
"error" lib.AssertEq zero.state
lib.Assert HasCode ⟨"posting_amount_zero", zero⟩
0 lib.AssertEq ≠ zero.transactions

unbalancedRaw ← MakeRaw ⟨
  "commodity ILS",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-25 * unbalanced ILS transaction",
  "  assets:cash-ils  -1.00 ILS",
  "  expenses:food-ils  0.99 ILS"
⟩
unbalanced ← Admit unbalancedRaw
"error" lib.AssertEq unbalanced.state
1 lib.AssertEq ≠ unbalanced.diagnostics
lib.Assert HasCode ⟨"event_unbalanced", unbalanced⟩
7 lib.AssertEq (⊑ unbalanced.diagnostics).line
0 lib.AssertEq ≠ unbalanced.transactions

# Physical-fallback identities and posting identities are reconstructed from
# complete-source line coordinates rather than colliding at partition-local lines.
physicalRaw ← MakeRaw ⟨
  "commodity JPY", "", "commodity ILS", "",
  "account assets:bank-jpy", "", "account expenses:food-jpy", "",
  "account assets:cash-ils", "", "account expenses:food-ils", "",
  "2026-07-25 * physical JPY", "  assets:bank-jpy  -1 JPY", "  expenses:food-jpy  1 JPY", "",
  "2026-07-26 * physical ILS", "  assets:cash-ils  -1 ILS", "  expenses:food-ils  1 ILS"
⟩
physical ← Admit physicalRaw
"ok" lib.AssertEq physical.state
2 lib.AssertEq ≠ physical.transactions
physicalIds ← {𝕩.source_event_id}¨ physical.transactions
2 lib.AssertEq ≠ ⍷ <¨ physicalIds
physicalPostingIds ← ∾ {{<𝕩.posting_id}¨𝕩.postings}¨physical.transactions
4 lib.AssertEq ≠ ⍷ physicalPostingIds

# Existing profiles are not widened by this production owner.
strictMulti ← stage1.ParseWithProfile ⟨jpyIlsRaw, "strict_self_contained"⟩
"error" lib.AssertEq strictMulti.state
lib.Assert HasCode ⟨"commodity_unsupported", strictMulti⟩
historicalMulti ← stage1.ParseWithProfile ⟨jpyIlsRaw, "historical_external_plan"⟩
"error" lib.AssertEq historicalMulti.state
lib.Assert HasCode ⟨"commodity_unsupported", historicalMulti⟩

externalPlanRaw ← MakeRaw ⟨
  "commodity JPY",
  "",
  "account assets:bank-jpy",
  "",
  "account expenses:food-jpy",
  "",
  "2026-07-25 * external historical completion",
  "  ; plan-id: plan-outside-file",
  "  assets:bank-jpy  -100 JPY",
  "  expenses:food-jpy  100 JPY"
⟩
strictExternal ← stage1.ParseWithProfile ⟨externalPlanRaw, "strict_self_contained"⟩
"error" lib.AssertEq strictExternal.state
lib.Assert HasCode ⟨"plan_completion_target_invalid", strictExternal⟩
historicalExternal ← stage1.ParseWithProfile ⟨externalPlanRaw, "historical_external_plan"⟩
"ok" lib.AssertEq historicalExternal.state
0 lib.AssertEq ≠ historicalExternal.diagnostics

•Out "test_journal_complete_source_admission.bqn: OK"
