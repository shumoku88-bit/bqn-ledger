#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
io ← •Import "../src/application/source_io.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
budgetAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
householdAdmission ← •Import "../src/ledger/household_policy_admission.bqn"
currentProjection ← •Import "../src/ledger/household_current_policy_projection.bqn"
base ← "fixtures/ledger-facts-phase1-proof/"

accountsRaw ← •FChars "../"∾base∾"accounts.journal"
accountsResult ← accountsAdmission.Admit accountsRaw
"ok" lib.AssertEq accountsResult.state
accounts ← accountsResult.accounts
budget ← budgetAdmission.Admit ⟨•FChars "../"∾base∾"budget.toml",accounts⟩
"ok" lib.AssertEq budget.state
householdRaw ← •FChars "../"∾base∾"household.toml"
currentRaw ← currentProjection.CurrentPolicy householdRaw
household ← householdAdmission.Admit ⟨currentRaw,accounts,budget⟩
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
Lines ← {𝕊 xs: ∾{𝕩∾⟨newline⟩}¨xs}
Quoted ← {𝕊 text: ⟨quote⟩∾text∾⟨quote⟩}
withMoneyRaw ← "[money]"∾⟨newline⟩∾"primary-commodity = "∾Quoted "JPY"∾⟨newline⟩∾⟨newline⟩∾householdRaw
withMoney ← householdAdmission.Admit ⟨currentProjection.CurrentPolicy withMoneyRaw,accounts,budget⟩
"ok" lib.AssertEq withMoney.state
0 lib.AssertEq ≠withMoney.diagnostics
1 lib.AssertEq withMoney.money.present
"JPY" lib.AssertEq withMoney.money.primary_commodity

# Current Envelope membership and stable allocation coordinates are different
# relations. A retired coordinate remains readable after it leaves budget.toml.
extendedAccountsRaw ← accountsRaw∾Lines ⟨"","account budget:retired","  type: Budget","  commodity: JPY"⟩
extendedAccountsResult ← accountsAdmission.Admit extendedAccountsRaw
"ok" lib.AssertEq extendedAccountsResult.state
extendedAccounts ← extendedAccountsResult.accounts
extendedBudget ← budgetAdmission.Admit ⟨•FChars "../"∾base∾"budget.toml",extendedAccounts⟩
"ok" lib.AssertEq extendedBudget.state
retiredCoordinate ← Lines ⟨"","[[budget.envelopes]]","id = "∾Quoted "retired","allocation-account = "∾Quoted "budget:retired"⟩
withRetired ← householdAdmission.Admit ⟨currentProjection.CurrentPolicy (householdRaw∾retiredCoordinate),extendedAccounts,extendedBudget⟩
"ok" lib.AssertEq withRetired.state
0 lib.AssertEq ≠withRetired.diagnostics
⟨"food","retired"⟩ lib.AssertEq withRetired.budget.envelope_id
⟨"budget:food","budget:retired"⟩ lib.AssertEq withRetired.budget.allocation_account_key
⟨"food"⟩ lib.AssertEq extendedBudget.envelopes.id

IndexOf ← {𝕊 key: ⊑accounts.key⊐⟨key⟩}
"liquid" lib.AssertEq (IndexOf "assets:cash")⊑household.account_policy.asset_class
"envelope" lib.AssertEq (IndexOf "budget:food")⊑household.account_policy.budget_kind
"" lib.AssertEq (IndexOf "budget:food")⊑household.account_policy.envelope_role
"daily" lib.AssertEq (IndexOf "budget:food")⊑household.account_policy.budget_group
"variable" lib.AssertEq (IndexOf "expenses:food")⊑household.account_policy.spend_class

•Out "test_ledger_household_policy_admission: ok"
