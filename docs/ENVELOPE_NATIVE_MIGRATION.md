# Envelope-native migration

Status: active migration toward the shared Envelope semantics currently exercised by h-kernel.

## Ownership direction

The canonical physical source set remains unchanged. `household.toml` is one physical source with multiple semantic owners.

Current Household policy and historical Envelope evidence have different lifetimes:

```text
household.toml
  -> current Household policy projection
  -> historical Envelope evidence owner
```

The current-policy owner must not reinterpret or validate historical Expense/Plan routing as current configuration. Conversely, a future historical owner must not reconstruct missing history from current `budget.toml` assignments.

## First boundary change

`src/ledger/household_current_policy_projection.bqn` removes only the explicitly shared historical sections before the existing strict `household_policy_admission.bqn` owner runs:

- `[envelope-history]`
- `[[envelope-history.expense-routing]]`
- `[[envelope-history.fulfillment-routing]]`

Other unknown sections remain visible to the strict current-policy admission and continue to fail closed.

This is source-boundary preparation, not historical routing admission. The historical sections are not yet used to calculate Envelope Consumption in this change.

## Next semantic cutover

The next bounded work is to admit historical Envelope identity and Expense routing from the same raw `household.toml`, qualify Account and Envelope references, then replace `budget.toml` current Expense assignment as the authority for Actual Envelope Consumption.

After that cutover, current Expense assignments may remain only as current operational configuration. Missing historical routing must become attention evidence rather than falling back to current configuration.

Plan fulfillment routing, native Fulfillment/Remaining/Commitment/Headroom, Backing ownership separation, and legacy Budget writer retirement remain later steps. They must be derived from explicit evidence rather than copied mechanically from another engine's implementation shape.
