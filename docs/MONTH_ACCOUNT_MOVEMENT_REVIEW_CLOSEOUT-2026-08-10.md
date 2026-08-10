# Month Account movement review closeout — 2026-08-10

## Baseline

Final reread is against merged `main` `5a632891546912766672e754d52f268ddc3c989c` after PR #617.

The historical observation remains in `docs/MONTH_ACCOUNT_MOVEMENT_REVIEW_OBSERVATION-2026-08-10.md`. This closeout records the final decisions after the observation, focused laws, production subtraction, and merged-main reread.

## Final retained purpose

`src/accounting/month_account_movement.bqn` remains the pure owner of:

```text
canonical Actual Facts
+ one admitted domain
+ strict half-open calendar-month range
→ dense Month × Account signed movement
+ source-qualified Posting contributors
+ exact Month / Account / grand reconciliation
```

The successful kernel remains visible as:

```text
selected Actual Postings
→ Month / Account coordinates
→ exact scale normalization
→ sparse Group
→ dense Pivot
→ rectangular Month × Account values
→ Month-axis and Account-axis exact reductions
→ independent grand reductions
→ reconciliation
```

No second algorithm rewrite was justified. PR #505 had already removed the old nested cell rescans and exposed the array transformation directly.

Classification: **KEEP the classify → Group → Pivot kernel**.

## Merged subtraction outcomes

### PR #615: local derived-state simplification

PR #615 removed two pieces of structural plumbing without changing accounting meaning:

- guarded mutable amount-scale initialization became `⌈´0∾selectedScales`;
- `totals.balanced` became exactly the retained `Balanced by month` law, `∧´1∾monthTotals=0`.

The independent grand calculations and month-vs-Account reconciliation remain intact. Only the derived extra `grand = 0` predicate was removed from the final boolean.

Classification: **SUBTRACT completed**.

### PR #616: public-surface laws

PR #616 separated two superficially similar duplicate-looking fields before production subtraction.

It proved:

```text
result.scale = result.matrix.scale
```

and:

```text
result.account_keys
= result.matrix.column_coordinates ⊏ Facts.accounts.key
```

These laws established different ownership meanings:

- top-level `scale` is coherent result-wide exact metadata because the Matrix and published Month / Account / grand coefficients all share it;
- the numeric Account axis already belongs to `matrix.column_coordinates`, while stable presentation identity is carried by `account_keys`.

Classification: **KEEP top-level `scale`; numeric Account-axis duplication is removable**.

### PR #617: duplicate top-level Account indices

PR #617 removed top-level `account_indices` from both success and error publication.

The internal `accountIndices` vector remains because it is still genuine kernel data used to:

- classify selected Posting Account coordinates;
- size sparse Group columns;
- provide Pivot column coordinates;
- derive stable `account_keys` from admitted Facts.

The final boundary is therefore:

```text
internal numeric Account axis      = accountIndices
public numeric Matrix axis         = matrix.column_coordinates
public stable Account identity     = account_keys
result-wide exact coefficient scale = scale
```

Classification: **SUBTRACT completed**.

## Final KEEP decisions

Keep:

- Month Account movement as a named accounting use-case owner;
- canonical Actual source/domain/layer admission;
- explicit half-open Month range and dense requested Month axis;
- selected-domain Account order;
- local `IsMonth`, `MonthNumber`, and `MonthLabel` vocabulary;
- exact mixed-scale normalization;
- internal `accountIndices` kernel coordinate axis;
- `sparse_group.Build` and `sparse_pivot.Build`;
- MatrixResult ownership of numeric coordinates, values, contributors, and Matrix scale;
- stable `account_keys` publication;
- result-wide top-level `scale`;
- source-qualified Posting contributors and source order;
- occupied exact-zero versus missing-cell evidence distinction;
- Month totals and Account totals as independent axis reductions;
- both checked grand reductions;
- `matrix_reconciliation_failed` and operation-local exact failure diagnostics;
- public `months`, `matrix`, `totals`, and `account_keys` semantics;
- fail-closed result publication.

## Final SUBTRACT decisions

Completed subtraction:

- guarded mutable amount-scale initialization;
- derived `grand = 0` conjunct inside `totals.balanced`;
- duplicate top-level `account_indices` publication.

Rejected subtraction:

- top-level `scale` is **not** duplicate Matrix-only metadata; it remains the exact scale for the whole published coefficient result.

## Deferred observations

`Contains` and `IndexOf` remain local idioms. Their repetition does not presently justify introducing a generic helper owner.

The nested diagnostic staging also remains. Exact arithmetic failures and reconciliation failures retain operation-local diagnostics, and no focused law has yet shown that flattening the control structure preserves the same failure locality and diagnostic set.

These are cross-cutting observations rather than unfinished Month Account movement work.

## Closeout

The owner has now been observed, characterized, simplified, reread on merged main, and its public surface re-qualified.

The retained architecture is intentionally:

```text
strict query admission
→ explicit semantic coordinates
→ whole-array Group / Pivot accounting kernel
→ independent exact reconciliation
→ small semantic publication
```

Review status: **complete**.

Next normal Phase 1 cursor: `src/accounting/month_category_flow.bqn`.
