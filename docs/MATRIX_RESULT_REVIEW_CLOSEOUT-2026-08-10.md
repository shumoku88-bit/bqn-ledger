# MatrixResult review closeout — 2026-08-10

## Final state

MatrixResult review is complete on merged `main` `459454dbfadccfc6e56dd7d779b93ff48774c12c`.

The retained owner remains:

- `src/accounting/matrix_result.bqn` — canonical presentation-neutral dense MatrixResult construction.

The final successful public shape is:

```text
row_count, column_count
row_index, column_index
row_coordinates, column_coordinates
scale
values[row][column]
contributors[row][column]
```

The owner continues to validate unique opaque axes, nonnegative integer exact scale, row alignment, and value/contributor column alignment. Invalid candidates still publish the canonical empty MatrixResult plus structured diagnostics.

## Merged outcomes

The observation started in PR #609 and produced three coherent subtraction slices:

1. PR #610 removed the hand-written empty MatrixResult shape from `src/sections/monthly_accounts.bqn` and delegated empty construction to the canonical owner.
2. PR #611 removed the remaining hand-written empty MatrixResult shapes from `cycle_accounts`, `cycle_comparison`, and `trial_balance` without adding a new helper or dependency layer.
3. PR #612 removed public `cell_count` after repository reachability showed no production consumer and proved it was exactly derivable from `row_count × column_count`. Empty/error tests now assert both empty axes directly instead of inferring emptiness from zero cells.

This leaves one MatrixResult shape authority and removes one derived public field.

## Retained decisions

KEEP:

- MatrixResult as a separate accounting-result owner rather than folding it into Sparse Pivot or moving it into Sections;
- nested candidate rows during admission so ragged candidates can produce structured column-misalignment diagnostics;
- current Each-based row-width checks under that candidate representation;
- `row_index` and `column_index`, which have live deterministic traversal consumers;
- `row_coordinates` and `column_coordinates` as the semantic opaque axes;
- unique-axis, exact-scale, row-alignment, and column-alignment diagnostics;
- current diagnostic staging until a focused law proves a simpler structure preserves multiply-invalid diagnostic behavior;
- true rank-2 successful publication as a future representation question rather than an automatic refactor.

SUBTRACTED:

- four Section-local copies of the empty MatrixResult record;
- derived public `cell_count`.

## Architectural result

The final dependency remains intentionally asymmetric:

```text
dense semantic arrays --------------------┐
                                          ├→ matrix_result.Build
sparse groups → sparse_pivot materialize -┘
```

MatrixResult owns dense publication. Sparse Pivot owns sparse-coordinate validation and absent-cell materialization. Sections and accounting consumers do not own a second dense result shape.

## Continuation

The normal Phase 1 review cursor advances to:

`src/accounting/month_account_movement.bqn`

That owner already received a prior array-native classify/group/pivot refactor in PR #505 after focused cell semantics were characterized in PR #504. Its current review should therefore begin from ownership, remaining control/plumbing, exact-reconciliation laws, reachability, and change locality rather than presuming another algorithm rewrite is needed.
