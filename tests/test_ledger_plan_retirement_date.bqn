#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
planAdmission ← •Import "../src/ledger/plan_journal_admission.bqn"

lf ← @+10
Raw ← {𝕊 lines:∾{𝕩∾⟨lf⟩}¨lines}
HasCode ← {𝕊 code‿diagnostics:∨´0∾{𝕩.code≡code}¨diagnostics}
registry ← (registryBuilder.Build io.ReadLines "config/currencies.tsv").registry
accounts ← (accountsAdmission.Admit Raw ⟨
  "account Assets:Cash","  type: Asset","  commodity: JPY","",
  "account Expenses:Food","  type: Expense","  commodity: JPY"
⟩).accounts

badCancelled ← planAdmission.Admit ⟨Raw ⟨
  "2026-08-20 Invalid cancellation",
  "  ; plan-id: bad-cancel",
  "  ; cancelled-on: 2026-02-30",
  "  Expenses:Food 100 JPY",
  "  Assets:Cash -100 JPY"
⟩,accounts,registry⟩
"error" lib.AssertEq badCancelled.state
lib.Assert HasCode ⟨"plan_retirement_date_invalid",badCancelled.diagnostics⟩

badSuperseded ← planAdmission.Admit ⟨Raw ⟨
  "2026-08-20 Invalid supersession",
  "  ; plan-id: old",
  "  ; superseded-on: 2026-13-01",
  "  ; superseded-by: new",
  "  Expenses:Food 100 JPY",
  "  Assets:Cash -100 JPY","",
  "2026-08-20 Replacement",
  "  ; plan-id: new",
  "  Expenses:Food 80 JPY",
  "  Assets:Cash -80 JPY"
⟩,accounts,registry⟩
"error" lib.AssertEq badSuperseded.state
lib.Assert HasCode ⟨"plan_retirement_date_invalid",badSuperseded.diagnostics⟩

•Out "test_ledger_plan_retirement_date: ok"
