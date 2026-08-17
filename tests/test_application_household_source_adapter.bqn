#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
householdSource ← •Import "../src/application/household_source_adapter.bqn"

base ← "fixtures/canonical-household-v1"
accounts ← accountSource.Load base
"ok" lib.AssertEq accounts.state

household ← householdSource.Load ⟨base,accounts.accounts⟩
"ok" lib.AssertEq household.state
0 lib.AssertEq ≠household.diagnostics
"household.toml" lib.AssertEq household.source_name
"incomeAnchor" lib.AssertEq household.cycle.definition.mode
"Income:Salary" lib.AssertEq household.cycle.definition.income_account
⟨"bank"⟩ lib.AssertEq household.daily_target.scope_id
⟨"Assets:Bank"⟩ lib.AssertEq household.daily_target.account_key

# One canonical household.toml observation carries current policy and explicit
# clean-epoch Envelope history as separate semantic owners.
shared ← householdSource.LoadShared ⟨base,accounts.accounts⟩
"ok" lib.AssertEq shared.state
1 lib.AssertEq shared.history.present
⟨"Daily"⟩ lib.AssertEq shared.history.registry.id
⟨"Expenses:Groceries"⟩ lib.AssertEq shared.history.expense_routing.expense_account_key
⟨"managed"⟩ lib.AssertEq shared.history.expense_routing.route
⟨"Daily"⟩ lib.AssertEq shared.history.expense_routing.target_id

•Out "test_application_household_source_adapter: ok"
