# Budget Source Adapter review observation — 2026-08-12

## Owner

`src/application/budget_source_adapter.bqn`

## Decision

Retain the production adapter unchanged.

The owner deliberately exposes two capability lifetimes:

```text
LoadPolicy:
  admitted Accounts + budget.toml -> Budget policy

Load:
  canonical Accounts
    -> budget.journal bytes
    -> canonical root topology
    -> Budget movement admission + Budget policy admission
    -> Fact projection when both admissions succeed
```

`LoadPolicy` must remain independently callable because Household policy consumers need Budget policy even when Budget movement evidence is irrelevant or invalid. The focused test now proves this with a policy-only fixture that contains `budget.toml` and deliberately no `budget.journal`.

The combined `Load` intentionally evaluates movement and policy admission together after the canonical Budget root is admitted, aggregates their diagnostics, and projects Facts only when both are successful. Those gates therefore protect capability lifetime and fail-closed publication rather than incidental control flow.

The new focused test also protects the successful combined shape: one canonical Budget transaction, two Postings, and the admitted backing-pool/envelope policy.

## Protected ownership

- `canonical_household_sources.bqn` owns Budget Journal and policy basenames.
- `account_source_adapter.bqn` owns canonical Account admission.
- `canonical_journal_root_admission.bqn` owns Budget root include topology.
- `budget_journal_admission.bqn` owns Budget movement admission.
- `budget_policy_admission.bqn` owns Budget policy admission.
- `facts.bqn` owns projection from admitted Budget evidence to Facts.
- `budget_source_adapter.bqn` owns the application-level capability sequencing and independent `LoadPolicy` surface.

No generic combined source-loader abstraction is introduced, and no eager read is added across the independent Budget policy boundary.
