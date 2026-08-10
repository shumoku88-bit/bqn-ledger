# Fact reference review observation — 2026-08-10

## Baseline

The review began on `main` `0f33d6044f186acbf9185f97690872b76d376b1f` after the Envelope Backing review closed in PR #603.

PR #604 recorded the initial ownership and subtraction observation before production changed. At that point the three-function module lived at `src/accounting/fact_reference.bqn` even though its concern was generic Facts identity/provenance rather than accounting calculation.

The completed sequence is now:

1. PR #605 moved the unchanged owner to `src/ledger/fact_reference.bqn`, updated all ten direct production importers and active owner-path documents, and removed the retired accounting path without a compatibility shim;
2. PR #606 added a focused direct law for source qualification and durable Transaction/Posting identity;
3. PR #607 simplified `SourceIs` under that law;
4. the final retained owner was reread on merged `main` `478b870a9eb0a32a4c34bf2271fc1f605c1929f6`.

The architecture review is therefore complete.

## Retained owner shape

`src/ledger/fact_reference.bqn` is a small dependency-free ledger identity/provenance owner with three public functions:

```text
SourceIs     Facts × source name -> boolean
Transaction  Facts × snapshot-local Transaction index -> {source, transaction_id}
Posting      Facts × snapshot-local Posting index     -> {source, posting_id}
```

It performs no accounting arithmetic, period selection, grouping, report policy, rendering, I/O, source parsing, selection, bounds checking, or diagnostic publication.

`Transaction` and `Posting` deliberately translate snapshot-local numeric coordinates into durable source-qualified evidence. Their record shapes remain centralized here rather than reconstructed by consumers.

## Facts source-axis contract

`src/ledger/facts.bqn` owns the source axis. Successful Facts have exactly one admitted source name. Error Facts may still retain that source name if a later diagnostic is raised after source admission.

The source relation must therefore prove both:

1. the Facts value is successful;
2. its complete source-name axis is exactly the expected singleton.

The final `SourceIs` expresses those two facts directly:

```bqn
SourceIs ← {𝕊 facts‿sourceName:
  (facts.state≡"ok") ∧ (facts.sources.name≡⟨sourceName⟩)
}
```

Exact vector equality carries both singleton shape and name equality. No separate count check, first-element extraction, mutable local, or conditional execution remains.

## Direct consumer graph

The owner has ten direct production importers across three architectural layers.

Accounting:

- `src/accounting/account_balance.bqn`
- `src/accounting/cycle_account_period.bqn`
- `src/accounting/cycle_income_anchor_resolution.bqn`
- `src/accounting/envelope_backing.bqn`
- `src/accounting/month_account_movement.bqn`
- `src/accounting/plan_completion_join.bqn`
- `src/accounting/profit_and_loss.bqn`
- `src/accounting/recent_transactions.bqn`

Section:

- `src/sections/planned_payments.bqn`

Application:

- `src/application/household_daily_scope.bqn`

All ten import the ledger owner. No consumer API changed during the move or subtraction.

The consumers select canonical Facts coordinates themselves and use this owner only for source qualification and durable evidence publication. That boundary remains intentionally narrow.

## Ownership decision: MOVE applied

`TODO.md` defines `src/ledger/` as owning admission, Facts, exact values, identity, and provenance. Fact reference operates only on generic Facts structure and is consumed directly by Section and Application code as well as Accounting.

Keeping it under `src/accounting/` therefore made higher layers depend on the accounting directory for a non-accounting identity/provenance concern.

The retained owner is:

```text
src/ledger/fact_reference.bqn
```

The move in PR #605 preserved behavior and left one authority path only.

Classification: **MOVE applied and retained**.

## `Transaction` / `Posting` decision: KEEP

The two reference constructors carry a real domain transition:

```text
snapshot-local coordinate -> source-qualified durable identity
```

Plural APIs would enlarge the public surface without removing responsibility. A kind-parameterized generic `Reference` helper would erase useful Transaction/Posting vocabulary.

No duplicate production owner for the `{source, transaction_id}` or `{source, posting_id}` shapes was found during the review.

Classification: **KEEP**.

## `SourceIs` decision: SUBTRACT applied

The pre-review implementation used:

- mutable local `ok`;
- conditional execution;
- explicit `sources.count=1` topology;
- first-element extraction before source comparison.

PR #606 first established the local law:

1. successful Facts + expected singleton source -> true;
2. successful Facts + different singleton source -> false;
3. successful Facts + empty source axis -> false;
4. successful Facts + multiple source names -> false;
5. error Facts + expected singleton source -> false;
6. `Transaction` publishes source plus durable `transaction_id` rather than the numeric coordinate;
7. `Posting` publishes source plus durable `posting_id` rather than the numeric coordinate.

PR #607 then replaced the implementation topology with the direct successful-state plus singleton-vector relation while leaving the law unchanged.

Full repository qualification and coverage passed on the PR head before merge, and the final owner was reread on merged `main` `478b870a9eb0a32a4c34bf2271fc1f605c1929f6`.

Classification: **SUBTRACT applied**.

## Final classification

`src/ledger/fact_reference.bqn` is the retained ledger identity/provenance owner.

Final decisions:

- ownership: **MOVE applied**;
- `Transaction`: **KEEP**;
- `Posting`: **KEEP**;
- `SourceIs`: **SUBTRACT applied**;
- compatibility path under `src/accounting/`: **REMOVE applied**.

The owner is review-complete on current merged evidence. `TODO.md` may mark it checked and return the normal architecture cursor to `src/accounting/matrix_result.bqn`.