#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
householdAdmission ← •Import "../src/ledger/household_policy_admission.bqn"
currentProjection ← •Import "../src/ledger/household_current_policy_projection.bqn"
base ← "fixtures/ledger-facts-phase1-proof/"

accountsRaw ← •FChars "../"∾base∾"accounts.journal"
accountsResult ← accountsAdmission.Admit accountsRaw
"ok" lib.AssertEq accountsResult.state
accounts ← accountsResult.accounts
householdRaw ← •FChars "../"∾base∾"household.toml"
currentRaw ← currentProjection.CurrentPolicy householdRaw
household ← householdAdmission.Admit ⟨currentRaw,accounts⟩
"ok" lib.AssertEq household.state
0 lib.AssertEq ≠household.diagnostics
"household.toml" lib.AssertEq household.source_name
0 lib.AssertEq household.money.present
"" lib.AssertEq household.money.primary_commodity
"incomeAnchor" lib.AssertEq household.cycle.definition.mode
"income:salary" lib.AssertEq household.cycle.definition.income_account
⟨"cash"⟩ lib.AssertEq household.daily_target.scope_id
⟨"assets:cash"⟩ lib.AssertEq household.daily_target.account_key

quote ← @+34 ⋄ newline ← @+10
withMoneyRaw ← "[money]"∾⟨newline⟩∾"primary-commodity = "∾⟨quote⟩∾"JPY"∾⟨quote⟩∾⟨newline⟩∾⟨newline⟩∾householdRaw
withMoney ← householdAdmission.Admit ⟨currentProjection.CurrentPolicy withMoneyRaw,accounts⟩
"ok" lib.AssertEq withMoney.state
0 lib.AssertEq ≠withMoney.diagnostics
1 lib.AssertEq withMoney.money.present
"JPY" lib.AssertEq withMoney.money.primary_commodity

•Out "test_ledger_household_policy_admission: ok"
