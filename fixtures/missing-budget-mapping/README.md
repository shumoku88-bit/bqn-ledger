# missing-budget-mapping negative fixture

This is a negative fixture dataset that violates the Safety Subset rules for envelope budgeting.

## Description

According to the [BQN Ledger Safety Subset](../../docs/BQN_LEDGER_SAFETY_SUBSET.md), if envelope budgeting is active (i.e., `budget:*` accounts exist in the dataset), any expense account mapped with `spend_class=variable` MUST explicitly have a `budget=` mapping in `accounts.tsv`.

In this fixture, `expenses:food` has `spend_class=variable` but intentionally lacks a `budget=daily` (or similar) mapping. 

The linter must reject this state and not automatically infer missing mappings to "daily", "flex", or "reserve". It ensures that errors in account definitions are safely caught without assuming intent.
