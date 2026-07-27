#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
structure ← •Import "../src/ledger/journal_transaction_structure.bqn"
lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
HasCode ← {𝕊 code‿result: ∨´0∾{𝕩.code≡code}¨result.diagnostics}

validRaw ← Raw ⟨
  "commodity JPY","","account assets:cash","","account expenses:food","",
  "2026-01-10 * completed external plan",
  "    ; event-id: event-food-1",
  "    ; plan-id: plan-food-1",
  "    ; currency: ILS",
  "    expenses:food 20 JPY",
  "    assets:cash -20 JPY"
⟩
valid ← structure.Parse validRaw
"ok" lib.AssertEq valid.state
0 lib.AssertEq ≠valid.diagnostics
1 lib.AssertEq ≠valid.transactions
transaction ← ⊑valid.transactions
"event-food-1" lib.AssertEq transaction.source_event_id
"durable" lib.AssertEq transaction.identity_kind
"2026-01-10" lib.AssertEq transaction.date
"completed external plan" lib.AssertEq transaction.description
"actual" lib.AssertEq transaction.layer_name
"plan-food-1" lib.AssertEq transaction.plan_id
7 lib.AssertEq transaction.source_start_line
12 lib.AssertEq transaction.source_end_line
⟨"event-id","plan-id","currency"⟩ lib.AssertEq {𝕩.key}¨transaction.metadata
⟨"debit","credit"⟩ lib.AssertEq {𝕩.side}¨transaction.postings
⟨"event-food-1:0","event-food-1:1"⟩ lib.AssertEq {𝕩.posting_id}¨transaction.postings
0 lib.AssertEq +´{𝕩.delta}¨transaction.postings

physicalRaw ← Raw ⟨
  "commodity JPY","","account assets:cash","","account expenses:food","",
  "2026-01-11 ! physical identity",
  "    expenses:food 5 JPY",
  "    assets:cash -5 JPY"
⟩
physical ← structure.Parse physicalRaw
"ok" lib.AssertEq physical.state
"physical_fallback" lib.AssertEq (⊑physical.transactions).identity_kind
"stage0-line-7" lib.AssertEq (⊑physical.transactions).source_event_id

duplicateRaw ← Raw ⟨
  "commodity JPY","","account assets:cash","","account expenses:food","",
  "2026-01-10 * duplicate metadata",
  "    ; event-id: first",
  "    ; event-id: second",
  "    expenses:food 5 JPY",
  "    assets:cash -5 JPY"
⟩
duplicate ← structure.Parse duplicateRaw
"error" lib.AssertEq duplicate.state
lib.Assert HasCode ⟨"metadata_duplicate",duplicate⟩
0 lib.AssertEq ≠duplicate.transactions

unbalancedRaw ← Raw ⟨
  "commodity JPY","","account assets:cash","","account expenses:food","",
  "2026-01-10 * unbalanced",
  "    expenses:food 5 JPY",
  "    assets:cash -4 JPY"
⟩
unbalanced ← structure.Parse unbalancedRaw
"error" lib.AssertEq unbalanced.state
lib.Assert HasCode ⟨"event_unbalanced",unbalanced⟩
0 lib.AssertEq ≠unbalanced.transactions

unsupportedRaw ← Raw ⟨
  "commodity JPY","","account assets:cash","","account expenses:food","",
  "2026-01-10 * unsupported metadata",
  "    ; include: another.journal",
  "    expenses:food 5 JPY",
  "    assets:cash -5 JPY"
⟩
unsupported ← structure.Parse unsupportedRaw
"error" lib.AssertEq unsupported.state
lib.Assert HasCode ⟨"metadata_unsupported",unsupported⟩
0 lib.AssertEq ≠unsupported.transactions

•Out "test_ledger_journal_transaction_structure: ok"
