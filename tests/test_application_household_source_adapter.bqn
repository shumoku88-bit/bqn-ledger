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

•Out "test_application_household_source_adapter: ok"
