# Sparse Pivot and MatrixResult

Status: Phase 3D capability proof
Owner: `src/accounting/sparse_pivot.bqn`

## Boundary

`sparse_pivot.Build ⟨rowCoordinates,columnCoordinates,valueScale,sparseGroups⟩` converts one deterministic sparse Group table into a dense presentation-neutral matrix.

It does not know:

- date, month, Account, category, section, or report names;
- how coordinates were selected or joined;
- accounting sign/display precision policy;
- labels, localization, formatting, observation/as-of, or source paths;
- Facts, context, Cube, or TBDS.

Axis coordinates are opaque admitted values supplied by the caller. The Pivot uses only bounded row/column indices from the shared sparse Group contract.

## MatrixResult

A successful result contains:

```text
row_count, column_count, cell_count
row_index, column_index
row_coordinates, column_coordinates
scale
values[row][column]
contributors[row][column]
```

Absent sparse coordinates become exact coefficient `0` with empty contributors. An explicitly grouped zero remains value `0` but retains its contributor Posting indices. This distinction is required for accounting provenance.

The Pivot validates unique axes, nonnegative integer scale, aligned sparse columns, bounded integer coordinates, and at most one sparse item per cell. Invalid input returns an empty MatrixResult and diagnostics.

## Two-consumer proof

Date/category flow supplies:

```text
rows:    strict transaction date ordinals
columns: dynamic category coordinates
values:  [[0,0], [20,0], [10,5]]
```

Month/category flow supplies:

```text
rows:    [2026-01, 2026-02]
columns: [food, other]
values:  [[100,50], [225,70]] at scale 1
```

Both preserve contributor indices in every dense cell and use the same Pivot without forwarding wrappers or report-specific fields.

## Deliberate limits

Pivot does not aggregate duplicates; `sparse_group.bqn` owns exact Group semantics. Pivot does not compute totals or add measures such as income/net/opening/closing. Those are accounting-result composition concerns. It also does not format absent cells, negate expenses for display, or attach human labels.

This keeps `Group` and `Pivot` composable while preventing a universal report context from forming.

## Proof

- `tests/test_accounting_sparse_pivot.bqn`
- Pivot assertions in `tests/test_accounting_date_category_flow.bqn`
- Pivot assertions in `tests/test_accounting_month_category_flow.bqn`
