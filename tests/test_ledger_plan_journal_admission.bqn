#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
planAdmission ← •Import "../src/ledger/plan_journal_admission.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics}

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state
registry ← registryResult.registry

accountRaw ← Raw ⟨
  "account Assets:Cash","  type: Asset","  commodity: JPY","",
  "account Assets:Bank","  type: Asset","  commodity: JPY","",
  "account Expenses:Food","  type: Expense","  commodity: JPY","",
  "account Expenses:Books","  type: Expense","  commodity: JPY"
⟩
accountResult ← accountsAdmission.Admit accountRaw
"ok" lib.AssertEq accountResult.state
accounts ← accountResult.accounts

validRaw ← Raw ⟨
  "2026-08-08 Wi-Fi payment",
  "  ; plan-id: plan-wifi",
  "  ; note: unrelated metadata remains unrelated",
  "  Expenses:Food  200 JPY",
  "  Assets:Cash",
  "",
  "2026-08-12 Shared purchase",
  "  ; plan-id: plan-shared",
  "  ; daily-target-id: shared-current",
  "  Expenses:Food   600 JPY",
  "  Expenses:Books  400 JPY",
  "  Assets:Cash    -1000 JPY"
⟩
valid ← planAdmission.Admit ⟨validRaw,accounts,registry⟩
"ok" lib.AssertEq valid.state
0 lib.AssertEq ≠valid.diagnostics
"plan.journal" lib.AssertEq valid.source_name
⟨"plan"⟩ lib.AssertEq valid.declared_layers
2 lib.AssertEq ≠valid.transactions
⟨"plan-wifi","plan-shared"⟩ lib.AssertEq {𝕩.plan_id}¨valid.transactions
⟨"durable_relation","durable_relation"⟩ lib.AssertEq {𝕩.identity_kind}¨valid.transactions
⟨"plan.journal:plan_id:plan-wifi","plan.journal:plan_id:plan-shared"⟩ lib.AssertEq {𝕩.source_event_id}¨valid.transactions
⟨"plan","plan"⟩ lib.AssertEq {𝕩.layer_name}¨valid.transactions
⟨"",""⟩ lib.AssertEq {𝕩.status_marker}¨valid.transactions
⟨2,3⟩ lib.AssertEq {≠𝕩.postings}¨valid.transactions
⟨"plan.journal:plan_id:plan-wifi:0","plan.journal:plan_id:plan-wifi:1"⟩ lib.AssertEq {𝕩.posting_id}¨(⊑valid.transactions).postings
⟨"plan-id","daily-target-id"⟩ lib.AssertEq {𝕩.key}¨(1⊑valid.transactions).metadata

missing ← planAdmission.Admit ⟨Raw ⟨
  "2026-08-08 Missing identity",
  "  Expenses:Food  200 JPY",
  "  Assets:Cash"
⟩,accounts,registry⟩
"error" lib.AssertEq missing.state
lib.Assert HasCode ⟨"plan_id_missing",missing.diagnostics⟩

invalid ← planAdmission.Admit ⟨Raw ⟨
  "2026-08-08 Invalid identity",
  "  ; plan-id: plan with spaces",
  "  Expenses:Food  200 JPY",
  "  Assets:Cash"
⟩,accounts,registry⟩
"error" lib.AssertEq invalid.state
lib.Assert HasCode ⟨"plan_id_invalid",invalid.diagnostics⟩

duplicate ← planAdmission.Admit ⟨Raw ⟨
  "2026-08-08 First",
  "  ; plan-id: duplicate-plan",
  "  Expenses:Food  200 JPY",
  "  Assets:Cash","",
  "2026-08-09 Second",
  "  ; plan-id: duplicate-plan",
  "  Expenses:Books  300 JPY",
  "  Assets:Cash"
⟩,accounts,registry⟩
"error" lib.AssertEq duplicate.state
lib.Assert HasCode ⟨"plan_id_duplicate",duplicate.diagnostics⟩

•Out "test_ledger_plan_journal_admission: ok"
