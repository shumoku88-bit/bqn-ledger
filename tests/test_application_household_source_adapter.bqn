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
⟨"Budget:Opening"⟩ lib.AssertEq household.budget.opening_account_keys
⟨"Budget:Unassigned"⟩ lib.AssertEq household.budget.unassigned_account_keys
⟨"bank"⟩ lib.AssertEq household.daily_target.scope_id
⟨"Assets:Bank"⟩ lib.AssertEq household.daily_target.account_key

# One canonical household.toml observation carries current policy and explicit
# clean-epoch Envelope history as separate semantic owners. No migration-era
# duplicate Household fixture or AccountPolicy projection is involved.
shared ← householdSource.LoadShared ⟨base,accounts.accounts,policy⟩
"ok" lib.AssertEq shared.state
1 lib.AssertEq shared.history.present
⟨"Daily"⟩ lib.AssertEq shared.history.registry.id
⟨"Expenses:Groceries"⟩ lib.AssertEq shared.history.expense_routing.expense_account_key
⟨"managed"⟩ lib.AssertEq shared.history.expense_routing.route
⟨"Daily"⟩ lib.AssertEq shared.history.expense_routing.target_id
shared.current.budget.envelope_id lib.AssertEq household.budget.envelope_id
shared.current.budget.allocation_account_key lib.AssertEq household.budget.allocation_account_key
shared.current.budget.opening_account_keys lib.AssertEq household.budget.opening_account_keys
shared.current.budget.unassigned_account_keys lib.AssertEq household.budget.unassigned_account_keys

# A stable allocation coordinate may outlive current budget.toml membership, but
# once historical Envelope evidence is present its identity must remain in the
# stable history registry. This fails closed before production composition.
retiredBase ← "fixtures/canonical-household-retired-coordinate"
retiredAccounts ← accountSource.Load retiredBase
"ok" lib.AssertEq retiredAccounts.state
retiredPolicy ← budgetSource.LoadPolicy ⟨retiredBase,retiredAccounts.accounts⟩
"ok" lib.AssertEq retiredPolicy.state
missingHistory ← householdSource.LoadShared ⟨retiredBase,retiredAccounts.accounts,retiredPolicy⟩
"error" lib.AssertEq missingHistory.state
1 lib.AssertEq ≠missingHistory.diagnostics
"household_allocation_envelope_history_missing" lib.AssertEq (⊑missingHistory.diagnostics).code

•Out "test_application_household_source_adapter: ok"
