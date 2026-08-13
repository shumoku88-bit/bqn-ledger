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

recurrenceRaw ← Raw ⟨
  "commodity JPY","","account assets:cash","","account expenses:food","",
  "2026-01-10 recurring plan",
  "    ; plan-id: plan-cycle-1",
  "    ; recur: cycle",
  "    ; anchor: income:salary",
  "    ; offset: 1",
  "    expenses:food 20 JPY",
  "    assets:cash -20 JPY"
⟩
recurrence ← structure.Parse recurrenceRaw
"ok" lib.AssertEq recurrence.state
⟨"plan-id","recur","anchor","offset"⟩ lib.AssertEq {𝕩.key}¨(⊑recurrence.transactions).metadata

retirementRaw ← Raw ⟨
  "commodity JPY","","account assets:cash","","account expenses:food","",
  "2026-01-10 superseded commitment",
  "    ; layer: plan",
  "    ; plan-id: plan-old",
  "    ; superseded-on: 2026-01-05",
  "    ; superseded-by: plan-new",
  "    expenses:food 20 JPY",
  "    assets:cash -20 JPY"
⟩
retirement ← structure.Parse retirementRaw
"ok" lib.AssertEq retirement.state
0 lib.AssertEq ≠retirement.diagnostics
retirementTransaction ← ⊑retirement.transactions
"plan" lib.AssertEq retirementTransaction.layer_name
⟨"layer","plan-id","superseded-on","superseded-by"⟩
  lib.AssertEq {𝕩.key}¨retirementTransaction.metadata
⟨"plan","plan-old","2026-01-05","plan-new"⟩
  lib.AssertEq {𝕩.value}¨retirementTransaction.metadata

cancellationRaw ← Raw ⟨
  "commodity JPY","","account assets:cash","","account expenses:food","",
  "2026-01-10 cancelled commitment",
  "    ; layer: plan",
  "    ; plan-id: plan-cancelled",
  "    ; cancelled-on: 2026-01-06",
  "    expenses:food 20 JPY",
  "    assets:cash -20 JPY"
⟩
cancellation ← structure.Parse cancellationRaw
"ok" lib.AssertEq cancellation.state
⟨"layer","plan-id","cancelled-on"⟩ lib.AssertEq {𝕩.key}¨(⊑cancellation.transactions).metadata

invalidCancelledDateRaw ← Raw ⟨
  "commodity JPY","","account assets:cash","","account expenses:food","",
  "2026-01-10 invalid cancelled date",
  "    ; layer: plan",
  "    ; plan-id: plan-cancelled",
  "    ; cancelled-on: 2026-02-30",
  "    expenses:food 20 JPY",
  "    assets:cash -20 JPY"
⟩
invalidCancelledDate ← structure.Parse invalidCancelledDateRaw
"error" lib.AssertEq invalidCancelledDate.state
lib.Assert HasCode ⟨"metadata_value_invalid",invalidCancelledDate⟩
0 lib.AssertEq ≠invalidCancelledDate.transactions

invalidSupersededDateRaw ← Raw ⟨
  "commodity JPY","","account assets:cash","","account expenses:food","",
  "2026-01-10 invalid superseded date",
  "    ; layer: plan",
  "    ; plan-id: plan-old",
  "    ; superseded-on: 2026-02-30",
  "    ; superseded-by: plan-new",
  "    expenses:food 20 JPY",
  "    assets:cash -20 JPY"
⟩
invalidSupersededDate ← structure.Parse invalidSupersededDateRaw
"error" lib.AssertEq invalidSupersededDate.state
lib.Assert HasCode ⟨"metadata_value_invalid",invalidSupersededDate⟩
0 lib.AssertEq ≠invalidSupersededDate.transactions

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

accountDuplicateRaw ← Raw ⟨
  "commodity JPY","",
  "account assets:cash","",
  "account expenses:food","",
  "account assets:cash","",
  "2026-01-10 * duplicate account declaration",
  "    expenses:food 5 JPY",
  "    assets:cash -5 JPY"
⟩
accountDuplicate ← structure.Parse accountDuplicateRaw
"error" lib.AssertEq accountDuplicate.state
1 lib.AssertEq ≠accountDuplicate.diagnostics
"account_duplicate" lib.AssertEq (⊑accountDuplicate.diagnostics).code
0 lib.AssertEq (⊑accountDuplicate.diagnostics).line
0 lib.AssertEq ≠accountDuplicate.transactions

duplicateRaw ← Raw ⟨
  "commodity JPY","","account assets:cash","","account expenses:food","",
  "2026-01-10 * duplicate metadata",
  "    ; event-id: first",
  "    ; note: between",
  "    ; event-id: second",
  "    expenses:food 5 JPY",
  "    assets:cash -5 JPY"
⟩
duplicate ← structure.Parse duplicateRaw
"error" lib.AssertEq duplicate.state
1 lib.AssertEq ≠duplicate.diagnostics
"metadata_duplicate" lib.AssertEq (⊑duplicate.diagnostics).code
7 lib.AssertEq (⊑duplicate.diagnostics).line
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
