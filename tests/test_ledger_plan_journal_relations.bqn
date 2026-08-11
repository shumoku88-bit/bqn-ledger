#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
planAdmission ← •Import "../src/ledger/plan_journal_admission.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state
registry ← registryResult.registry

accountResult ← accountsAdmission.Admit Raw ⟨
  "account Assets:Cash","  type: Asset","  commodity: JPY","",
  "account Expenses:Food","  type: Expense","  commodity: JPY"
⟩
"ok" lib.AssertEq accountResult.state
accounts ← accountResult.accounts

# Transaction-local Plan diagnostics remain in source transaction order. The
# whole-Plan duplicate relation is aggregate-last at line 0.
invalid ← planAdmission.Admit ⟨Raw ⟨
  "2026-08-01 Invalid Plan id",
  "  ; plan-id: plan with spaces",
  "  Expenses:Food  100 JPY",
  "  Assets:Cash","",
  "2026-08-02 Missing Plan id",
  "  Expenses:Food  200 JPY",
  "  Assets:Cash","",
  "2026-08-03 Duplicate first",
  "  ; plan-id: duplicate-plan",
  "  Expenses:Food  300 JPY",
  "  Assets:Cash","",
  "2026-08-04 Duplicate second",
  "  ; plan-id: duplicate-plan",
  "  Expenses:Food  400 JPY",
  "  Assets:Cash"
⟩,accounts,registry⟩
"error" lib.AssertEq invalid.state
⟨"plan_id_invalid","plan_id_missing","plan_id_duplicate"⟩ lib.AssertEq {𝕩.code}¨invalid.diagnostics
⟨1,6,0⟩ lib.AssertEq {𝕩.line}¨invalid.diagnostics
0 lib.AssertEq ≠invalid.transactions
0 lib.AssertEq ≠invalid.declared_domains

# Successful publication remaps Plan relation identity while preserving the
# complete-Journal transaction axis and Posting order.
valid ← planAdmission.Admit ⟨Raw ⟨
  "2026-08-05 First Plan",
  "  ; plan-id: first-plan",
  "  Expenses:Food  500 JPY",
  "  Assets:Cash","",
  "2026-08-06 Second Plan",
  "  ; plan-id: second-plan",
  "  Expenses:Food  600 JPY",
  "  Assets:Cash"
⟩,accounts,registry⟩
"ok" lib.AssertEq valid.state
⟨"first-plan","second-plan"⟩ lib.AssertEq {𝕩.plan_id}¨valid.transactions
⟨"plan.journal:plan_id:first-plan","plan.journal:plan_id:second-plan"⟩ lib.AssertEq {𝕩.source_event_id}¨valid.transactions
⟨"durable_relation","durable_relation"⟩ lib.AssertEq {𝕩.identity_kind}¨valid.transactions
⟨0,1⟩ lib.AssertEq {𝕩.posting_index}¨(⊑valid.transactions).postings
⟨"plan.journal:plan_id:first-plan:0","plan.journal:plan_id:first-plan:1"⟩ lib.AssertEq {𝕩.posting_id}¨(⊑valid.transactions).postings

•Out "test_ledger_plan_journal_relations: ok"
