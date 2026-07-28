# Month × dynamic category grouping and sparse Group extraction

Status: Phase 3C extensibility gate
Owners: `src/accounting/month_category_flow.bqn`, `src/accounting/sparse_group.bqn`

## Extensibility proof

`month_category_flow.Build` accepts the same explicit Facts/domain/layer/period query as date/category flow. It composes the presentation-neutral date/category capability, maps strict admitted dates to `YYYY-MM`, and rolls sparse expense evidence into calendar month × category coordinates.

It does not re-read sources, traverse report context, infer categories, import Cube/TBDS, or carry the full prepared date result in its output. It preserves:

- dynamic category order and identity;
- one exact scale;
- deterministic month/category order;
- exact signed coefficients;
- original contributor Posting Fact indices;
- fail-closed empty output.

The public synthetic proof contains two months, `food` and `other`, multiple postings in one month/category, and mixed source scales. At result scale 1 it proves:

```text
2026-01 × food   = 100   contributors 0
2026-01 × other  = 50    contributors 2
2026-02 × food   = 225   contributors 4,6
2026-02 × other  = 70    contributors 8
```

The existing strict Actual fixture also rolls three daily expense groups into January totals `food=30`, `other=5` without losing Posting contributors.

## Extracted Group capability

Date/category and month/category now both require the identical operation:

```text
explicit row axis
+ bounded column indices
+ exact coefficient per selected item
+ contributor indices per selected item
→ deterministic sparse row/column groups
```

That operation is extracted as:

```text
sparse_group.Build ⟨
  rowAxis,
  columnCount,
  rowCoordinatePerItem,
  columnIndexPerItem,
  coefficientPerItem,
  contributorIndicesPerItem
⟩
```

The result is a presentation-neutral aligned table of `row_index`, `column_index`, exact `coefficient`, and flattened `contributors`. Groups are emitted in explicit row-axis order then column-index order. A coordinate with contributors remains present when its sum is zero.

The Group owner validates aligned inputs, unique row coordinates, bounded columns, known row coordinates, nonempty contributor evidence, and exact sums. Invalid input returns no groups.

## Deliberately not extracted

No universal Select/Join/Pivot or report Result type is introduced in this slice:

- date axes come from selected transaction dates;
- month axes are a calendar rollup;
- category classification remains explicit Account metadata policy;
- Account-period grouping includes opening state and zero Accounts;
- income/net measures are not expense-group coordinates.

Only the operation demonstrated identically by two real consumers became shared vocabulary. A later MatrixResult/Pivot capability may consume sparse groups, but it must not absorb category or observation policy.

## Proof

- `tests/test_accounting_date_category_flow.bqn`
- `tests/test_accounting_month_category_flow.bqn`
- `tests/test_accounting_sparse_group.bqn`

The generic Group test includes zero-sum contributor retention, empty input, structural errors, coordinate errors, and exact-range failure.
