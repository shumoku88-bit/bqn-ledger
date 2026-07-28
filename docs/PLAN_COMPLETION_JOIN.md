# Canonical Plan completion Join

Status: Phase 3H capability proof

Owner: `src/accounting/plan_completion_join.bqn`

Shared provenance helper: `src/accounting/fact_reference.bqn`

## Boundary

The Join accepts only:

```text
Plan Facts
Actual Facts
selected Plan Transaction indices
selected Actual Transaction indices
```

Selection is explicit because period membership is a use-case/section policy. The Join does not read cycle definitions, choose an observation, reload either source, parse TSV/Journal rows, or format a report.

Only nonempty canonical `plan_id` is a relationship key. There is no five-field fallback and no memo/date/amount inference.

## Result

Successful output has one aligned row per selected Plan Transaction and preserves:

- source-qualified durable Plan Transaction reference;
- Plan date, currency, exact coefficient/scale, and from/to Account direction;
- Plan debit/credit Posting contributors;
- every matching Actual Transaction reference and date;
- each Actual transaction's own currency and exact debit coefficient/scale;
- Actual debit/credit Account arrays and Posting contributors;
- per-completion currency and direction comparison flags;
- selected Actual relationship references that do not match a selected Plan.

Amounts from separate Actual transactions or currency domains are never added. Consumers receive exact evidence and must decide whether a non-completed relation is displayable.

## Relationship states

Each Plan row has exactly one state:

- `open`: no selected Actual Transaction has its `plan_id`;
- `completed`: exactly one valid Actual Transaction matches;
- `duplicate`: multiple matching Actual Transactions have the same date, currency, exact amount, scale, and Account directions;
- `ambiguous`: multiple matching Actual Transactions disagree on at least one of those coordinates.

Duplicate and ambiguous evidence remains visible as relationship state, but is not collapsed into `completed` and is never summed.

Malformed Fact sources, duplicate selection coordinates, missing/duplicate selected Plan identity, or invalid exact direction evidence produce an overall `error`. Error results contain no partial rows, counts, or unmatched references.

A selected Actual `plan_id` without a selected Plan is retained in `unmatched_actual_references`; this is not automatically invalid because period selection or retained historical completions can legitimately omit the Plan row.

## Current-runtime comparison

The strict public proof fixture has one in-cycle Plan and one in-cycle Actual completion:

```text
plan_id             plan  actual  state
plan-food-2026-01     25      20  completed
```

`tests/test_accounting_plan_completion_join.bqn` derives explicit half-open period selections and proves the canonical result, source-qualified Transaction/Posting provenance, mixed admitted scales in ILS, open selection, identical duplicate, conflicting ambiguity, unmatched Actual references, and fail-closed invalid coordinates. `checks/check-ledger-facts-phase1-proof-fixture.sh` runs that proof beside current Planned JSON assertions for the same public fixture.

The destination intentionally differs from legacy compatibility outside strict evidence:

- missing Plan IDs are rejected by companion admission rather than receiving five-field identity;
- duplicate Actual completions are not exact-any-match `paid` plus summed amount;
- conflicting completions are explicit `ambiguous` evidence;
- source-local indices are never compared across Plan and Actual.

These differences are readiness constraints for the later section cutover, not hidden compatibility behavior inside the Join.
