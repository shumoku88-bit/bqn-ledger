#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
io ← •Import "../src/application/source_io.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
budgetAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
householdAdmission ← •Import "../src/ledger/household_policy_admission.bqn"
base ← "fixtures/ledger-facts-phase1-proof/"

accountsResult ← accountsAdmission.Admit •FChars "../"∾base∾"accounts.journal"
"ok" lib.AssertEq accountsResult.state
accounts ← accountsResult.accounts
budget ← budgetAdmission.Admit ⟨•FChars "../"∾base∾"budget.toml",accounts⟩
"ok" lib.AssertEq budget.state
householdRaw ← •FChars "../"∾base∾"household.toml"
household ← householdAdmission.Admit ⟨householdRaw,accounts,budget⟩
"ok" lib.AssertEq household.state
0 lib.AssertEq ≠household.diagnostics
"household.toml" lib.AssertEq household.source_name
0 lib.AssertEq household.money.present
"" lib.AssertEq household.money.primary_commodity
"incomeAnchor" lib.AssertEq household.cycle.definition.mode
"income:salary" lib.AssertEq household.cycle.definition.income_account
⟨"food"⟩ lib.AssertEq household.budget.envelope_id
⟨"budget:food"⟩ lib.AssertEq household.budget.allocation_account_key
⟨"budget:unassigned"⟩ lib.AssertEq household.budget.unassigned_account_keys
⟨"cash"⟩ lib.AssertEq household.daily_target.scope_id
⟨"assets:cash"⟩ lib.AssertEq household.daily_target.account_key

quote ← @+34 ⋄ newline ← @+10
withMoneyRaw ← "[money]"∾⟨newline⟩∾"primary-commodity = "∾⟨quote⟩∾"JPY"∾⟨quote⟩∾⟨newline⟩∾⟨newline⟩∾householdRaw
withMoney ← householdAdmission.Admit ⟨withMoneyRaw,accounts,budget⟩
"ok" lib.AssertEq withMoney.state
0 lib.AssertEq ≠withMoney.diagnostics
1 lib.AssertEq withMoney.money.present
"JPY" lib.AssertEq withMoney.money.primary_commodity

IndexOf ← {𝕊 key: ⊑accounts.key⊐⟨key⟩}
"liquid" lib.AssertEq (IndexOf "assets:cash")⊑household.account_policy.asset_class
"envelope" lib.AssertEq (IndexOf "budget:food")⊑household.account_policy.budget_kind
"dynamic" lib.AssertEq (IndexOf "budget:food")⊑household.account_policy.envelope_role
"daily" lib.AssertEq (IndexOf "budget:food")⊑household.account_policy.budget_group
"variable" lib.AssertEq (IndexOf "expenses:food")⊑household.account_policy.spend_class

•Out "test_ledger_household_policy_admission: ok"
