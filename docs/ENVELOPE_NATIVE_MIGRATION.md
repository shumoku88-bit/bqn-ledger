# Envelope-native migration

Status: active migration toward the shared Envelope semantics currently exercised by h-kernel.

## Ownership direction

The canonical physical source set remains unchanged. `household.toml` is one physical source with multiple semantic owners.

Current Household policy and historical Envelope evidence have different lifetimes:

```text
household.toml bytes
  -> current Household policy projection -> current policy admission
  -> historical Envelope projection      -> history admission
```

The current-policy owner must not reinterpret or validate historical Expense/Plan routing as current configuration. Historical routing must not reconstruct missing history from current `budget.toml` assignments.

## Shared source projection

`src/ledger/household_current_policy_projection.bqn` recognizes only the explicit historical section family:

- `[envelope-history]`
- `[[envelope-history.expense-routing]]`
- `[[envelope-history.fulfillment-routing]]`

The two semantic views preserve physical row coordinates by replacing excluded rows with empty rows instead of deleting them. Unrelated unknown sections remain visible to the strict current-policy admission and continue to fail closed.

`src/application/household_source_adapter.bqn` exposes a shared observation that reads canonical `household.toml` once, then admits current policy and historical Envelope evidence from those same bytes. Report Household context carries both results while preserving the existing Plan / Budget policy / Household evaluation and diagnostic order.

## Historical Envelope owner

`src/ledger/envelope_history_admission.bqn` owns source-local historical meaning:

- stable Envelope identities;
- Expense routing effective coordinate, Expense Account key, managed/unmanaged decision, target identity, note, and source row;
- fulfillment routing effective coordinate, PlanId, fulfills/not-target decision, target identity, note, and source row;
- strict route/target shape;
- strict effective-date syntax;
- unique Expense-Account/effective and PlanId/effective coordinates;
- fail-closed publication.

Older canonical fixtures without `[envelope-history]` admit explicit absence with empty history. No routing is invented from current policy.

Account and Plan references deliberately remain source-local keys at this boundary. Their existence and roles belong to later cross-source Household qualification because those identity universes are owned by admitted Account / Plan evidence, not by `household.toml` parsing.

## Next semantic cutover

The next bounded work is to qualify historical references and replace current `budget.toml` Expense assignment as the authority for Actual Envelope Consumption.

This cannot be implemented correctly by resolving one route at the report observation day. Historical routing is effective-dated per Actual evidence day. The current Envelope/Backing owner aggregates Actual movement by Account before routing, which would erase a routing change inside one statement period. The cutover therefore needs to retain or recover the Actual Posting/day relation, join each relevant Expense posting to the effective historical route at that day, then group the routed evidence onto the stable Envelope axis.

After that cutover:

- managed Expense evidence contributes to its historical Envelope;
- explicit unmanaged evidence does not become unassigned routing attention;
- missing routing becomes attention evidence;
- current Expense assignment remains only current operational configuration;
- no missing historical route falls back to current configuration.

Plan fulfillment routing, native Fulfillment/Remaining/Commitment/Headroom, Backing ownership separation, and legacy Budget writer retirement remain later steps. They must be derived from explicit BQN relations rather than copied mechanically from another engine's implementation shape.
