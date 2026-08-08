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
household ← householdAdmission.Admit ⟨•FChars "../"∾base∾"household.toml",accounts,budget⟩
"ok" lib.AssertEq household.state
0 lib.AssertEq ≠household.diagnostics
"household.toml" lib.AssertEq household.source_name
"incomeAnchor" lib.AssertEq household.cycle.definition.mode
"income:salary" lib.AssertEq household.cycle.definition.income_account
⟨"food"⟩ lib.AssertEq household.budget.envelope_id
⟨"budget:food"⟩ lib.AssertEq household.budget.allocation_account_key
⟨"budget:unassigned"⟩ lib.AssertEq household.budget.unassigned_account_keys
⟨"cash"⟩ lib.AssertEq household.daily_target.scope_id
⟨"assets:cash"⟩ lib.AssertEq household.daily_target.account_key

IndexOf ← {𝕊 key: ⊑accounts.key⊐⟨key⟩}
"liquid" lib.AssertEq (IndexOf "assets:cash")⊑household.account_policy.asset_class
"envelope" lib.AssertEq (IndexOf "budget:food")⊑household.account_policy.budget_kind
"dynamic" lib.AssertEq (IndexOf "budget:food")⊑household.account_policy.envelope_role
"daily" lib.AssertEq (IndexOf "budget:food")⊑household.account_policy.budget_group
"variable" lib.AssertEq (IndexOf "expenses:food")⊑household.account_policy.spend_class

•Out "test_ledger_household_policy_admission: ok"
