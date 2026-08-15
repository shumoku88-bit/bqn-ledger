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

Account and Plan references deliberately remain source-local keys at this boundary. Their existence and roles belong to cross-source Household qualification because those identity universes are owned by admitted Account / Plan evidence, not by `household.toml` parsing.

## Actual Consumption cutover

Historical Expense routing now owns Actual Envelope Consumption.

`src/accounting/envelope_consumption.bqn` keeps the Actual Posting/day axis until each Expense posting has been joined to the effective historical route. Only then are managed postings grouped onto the stable Envelope identity axis. This preserves routing changes inside one statement period instead of erasing them through Account-first aggregation.

The Consumption observation keeps three explicit lanes:

- managed Expense evidence contributes to its historical Envelope;
- explicit unmanaged evidence remains separate from routing attention;
- missing routing remains explicit unrouted attention evidence.

Refunds use the same Posting-day historical route as charges. Posting provenance and route source rows remain attached to the resulting observation. Missing historical routing never falls back to current `budget.toml` Expense assignments.

Envelope/Backing consumes only the managed lane for Actual Consumption arithmetic and retains the full Consumption observation, including unrouted and unmanaged evidence. Current `budget.toml` Expense assignment remains temporarily in Envelope/Backing only as the compatibility authority for open Plan reserve, not for Actual evidence.

## Next semantic cutover

The next bounded work is Plan fulfillment routing and the removal of current Plan-destination/Expense-assignment authority from Envelope claims.

That work must preserve stable PlanId evidence and distinguish open commitment from completed fulfillment. Native Fulfillment/Remaining/Commitment/Headroom, Backing ownership separation, and legacy Budget writer retirement remain later steps. They must be derived from explicit BQN relations rather than copied mechanically from another engine's implementation shape.
