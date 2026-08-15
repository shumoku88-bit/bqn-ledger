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
household.cycle.definition.mode lib.AssertEq withHistory.cycle.definition.mode
household.cycle.definition.income_account lib.AssertEq withHistory.cycle.definition.income_account
household.money.present lib.AssertEq withHistory.money.present
household.money.primary_commodity lib.AssertEq withHistory.money.primary_commodity
household.budget.envelope_id lib.AssertEq withHistory.budget.envelope_id
household.budget.allocation_account_key lib.AssertEq withHistory.budget.allocation_account_key
household.budget.unassigned_account_keys lib.AssertEq withHistory.budget.unassigned_account_keys
household.daily_target.scope_id lib.AssertEq withHistory.daily_target.scope_id
household.daily_target.account_key lib.AssertEq withHistory.daily_target.account_key
household.account_policy.asset_class lib.AssertEq withHistory.account_policy.asset_class
household.account_policy.budget_kind lib.AssertEq withHistory.account_policy.budget_kind
household.account_policy.envelope_role lib.AssertEq withHistory.account_policy.envelope_role
household.account_policy.budget_group lib.AssertEq withHistory.account_policy.budget_group
household.account_policy.spend_class lib.AssertEq withHistory.account_policy.spend_class

# The production shared observation reads one household.toml source and admits
# both semantic owners from those bytes. Old fixtures publish explicit absence;
# the expanded fixture publishes stable historical identity/routing evidence.
sharedAbsent ← householdSource.LoadShared ⟨base,accounts.accounts,policy⟩
"ok" lib.AssertEq sharedAbsent.state
0 lib.AssertEq sharedAbsent.history.present
0 lib.AssertEq sharedAbsent.history.registry.count
sharedHistory ← householdSource.LoadShared ⟨historyBase,accounts.accounts,policy⟩
"ok" lib.AssertEq sharedHistory.state
1 lib.AssertEq sharedHistory.history.present
⟨"Daily"⟩ lib.AssertEq sharedHistory.history.registry.id
⟨"Expenses:Groceries"⟩ lib.AssertEq sharedHistory.history.expense_routing.expense_account_key
⟨"managed"⟩ lib.AssertEq sharedHistory.history.expense_routing.route
⟨"Daily"⟩ lib.AssertEq sharedHistory.history.expense_routing.target_id
sharedHistory.current.budget.envelope_id lib.AssertEq withHistory.budget.envelope_id

•Out "test_application_household_source_adapter: ok"
