#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
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
⟨"budget:opening"⟩ lib.AssertEq household.budget.opening_account_keys
⟨"budget:unassigned"⟩ lib.AssertEq household.budget.unassigned_account_keys
⟨"cash"⟩ lib.AssertEq household.daily_target.scope_id
⟨"assets:cash"⟩ lib.AssertEq household.daily_target.account_key

quote ← @+34 ⋄ newline ← @+10
withMoneyRaw ← "[money]"∾⟨newline⟩∾"primary-commodity = "∾⟨quote⟩∾"JPY"∾⟨quote⟩∾⟨newline⟩∾⟨newline⟩∾householdRaw
withMoney ← householdAdmission.Admit ⟨currentProjection.CurrentPolicy withMoneyRaw,accounts,budget⟩
"ok" lib.AssertEq withMoney.state
0 lib.AssertEq ≠withMoney.diagnostics
1 lib.AssertEq withMoney.money.present
"JPY" lib.AssertEq withMoney.money.primary_commodity

# Current Envelope membership and stable allocation coordinates are different
# relations. The retired-coordinate fixture keeps Daily current in budget.toml
# while household.toml retains both Daily and Retired allocation coordinates.
retiredBase ← "../fixtures/canonical-household-retired-coordinate/"
retiredAccountsResult ← accountsAdmission.Admit (•FChars retiredBase∾"accounts.journal")
"ok" lib.AssertEq retiredAccountsResult.state
retiredBudget ← budgetAdmission.Admit ⟨•FChars retiredBase∾"budget.toml",retiredAccountsResult.accounts⟩
"ok" lib.AssertEq retiredBudget.state
retiredHouseholdRaw ← •FChars retiredBase∾"household.toml"
withRetired ← householdAdmission.Admit ⟨currentProjection.CurrentPolicy retiredHouseholdRaw,retiredAccountsResult.accounts,retiredBudget⟩
"ok" lib.AssertEq withRetired.state
0 lib.AssertEq ≠withRetired.diagnostics
⟨"Daily","Retired"⟩ lib.AssertEq withRetired.budget.envelope_id
⟨"Budget:Daily","Budget:Retired"⟩ lib.AssertEq withRetired.budget.allocation_account_key
⟨"Budget:Opening"⟩ lib.AssertEq withRetired.budget.opening_account_keys
⟨"Budget:Unassigned"⟩ lib.AssertEq withRetired.budget.unassigned_account_keys
⟨"Daily"⟩ lib.AssertEq retiredBudget.envelopes.id

•Out "test_ledger_household_policy_admission: ok"
