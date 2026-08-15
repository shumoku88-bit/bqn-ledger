#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
budgetSource ← •Import "../src/application/budget_source_adapter.bqn"
householdSource ← •Import "../src/application/household_source_adapter.bqn"

base ← "fixtures/canonical-household-v1"
accounts ← accountSource.Load base
"ok" lib.AssertEq accounts.state
policy ← budgetSource.LoadPolicy ⟨base,accounts.accounts⟩
"ok" lib.AssertEq policy.state

household ← householdSource.Load ⟨base,accounts.accounts,policy⟩
"ok" lib.AssertEq household.state
0 lib.AssertEq ≠household.diagnostics
"household.toml" lib.AssertEq household.source_name
"incomeAnchor" lib.AssertEq household.cycle.definition.mode
"Income:Salary" lib.AssertEq household.cycle.definition.income_account
⟨"Daily"⟩ lib.AssertEq household.budget.envelope_id
⟨"Budget:Daily"⟩ lib.AssertEq household.budget.allocation_account_key
⟨"bank"⟩ lib.AssertEq household.daily_target.scope_id
⟨"Assets:Bank"⟩ lib.AssertEq household.daily_target.account_key

# Historical Envelope evidence shares the physical household.toml source but is
# not current Household policy. The current-policy projection must therefore
# preserve the same admitted current meaning when history is present.
historyBase ← "fixtures/canonical-household-envelope-history"
withHistory ← householdSource.Load ⟨historyBase,accounts.accounts,policy⟩
"ok" lib.AssertEq withHistory.state
0 lib.AssertEq ≠withHistory.diagnostics
household.cycle.definition lib.AssertEq withHistory.cycle.definition
household.money lib.AssertEq withHistory.money
household.budget lib.AssertEq withHistory.budget
household.daily_target lib.AssertEq withHistory.daily_target
household.account_policy lib.AssertEq withHistory.account_policy

•Out "test_application_household_source_adapter: ok"
