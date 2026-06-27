# Missing Budget Mapping Failure Fixture

Tests detection of expense accounts with `spend_class=variable` but NO `budget=` mapping when budget accounts exist.

## Description

`expenses:food` has `spend_class=variable` but intentionally lacks `budget=food` in accounts.tsv.
`budget:food` and `budget:spent` exist, so envelope computation is active, but the mapping is broken.

## Expected behavior

- The engine does NOT crash.
- The expense is tracked under `budget_group_missing`.
- `src_next_household_metadata_missing_budget_count: 1`
- `src_next_household_metadata_missing_budget_accounts: expenses:food`
- `src_next_household_policy_expense_accounts_with_budget: 0`
- `src_next_household_policy_actual_budget_group_missing_total: 5000`
