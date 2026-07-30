# Sparse grouping classify-once probe

## Question

Can the current row × column evidence rescanning shape be restated as one coordinate classification plus BQN Group without changing sparse group order, exact reduction inputs, or contributor order?

The production analogue in `src/accounting/sparse_group.bqn` currently describes each possible output cell and rescans all selected evidence to construct a mask:

```text
for each row
  for each column
    compare every selected item
```

This experiment compares that formulation with:

```text
for each selected item
  resolve row index once
  combine row and column into one cell index
  Group coefficients and contributors by cell index
```

The probe is analysis-only. It does not import into production and does not change accounting, section, renderer, editor, source, or UI ownership.

## Shared boundary

Both formulations receive the same neutral values:

```text
row axis
column count
row coordinate per item
column index per item
exact coefficient per item
source-qualified contributor array per item
```

Both publish the same experimental grouped view:

```text
row indices
column indices
coefficient arrays before reduction
flattened contributor arrays
```

Exact reduction remains owned by `src/ledger/exact_scale.bqn`. The experiment compares the grouped coefficient arrays first, then applies the same `scale.Sum` to both results.

## Classify-once formulation

Each valid item is assigned a row index. A row-major cell index is encoded as:

```text
cell_index = column_count × row_index + column_index
```

BQN Group `⊔` partitions the coefficient and contributor arrays with those cell indices. A final sentinel equal to the total cell count forces Group to represent the complete coordinate range, including trailing empty cells. Occupied cells are selected by group length, not by reduced value.

That last distinction preserves an occupied group whose exact sum is zero.

## Observed result

GitHub Actions run `30540455164` completed successfully.

The row × column rescan and classify-once formulations produced identical grouped views and identical exact-sum views for all admitted cases.

### Sparse input

The sparse case used three rows, three columns, and five selected items. It included:

- two coefficients `5` and `¯5` in the same cell;
- an occupied exact-zero result;
- multiple contributors in one cell;
- one contributor item containing two source references;
- interleaved input order across cells.

Both formulations published row-major occupied coordinates:

```text
(0,0) (1,1) (2,2)
```

with coefficient groups:

```text
⟨5‿¯5, ⟨3⟩, 7‿4⟩
```

and contributor groups:

```text
⟨
  ⟨"p0","p2"⟩,
  ⟨"p3"⟩,
  ⟨"p1","p4","p4b"⟩
⟩
```

The exact sums were `0‿3‿11`. Input-relative contributor order survived Group.

### Dense interleaved input

A complete `2 × 2` input arrived in non-row-major order. Both formulations published the four cells in row-major order while retaining the original item within each group.

### Empty axes

Both an empty row axis with positive column count and a nonempty row axis with zero columns produced the same empty grouped view and empty exact-sum view.

### Exact-sum overflow

The two formulations produced the same coefficient group before reduction. Applying the shared exact sum returned:

```text
state: error
code: coefficient_sum_out_of_exact_range
```

The grouping algorithm therefore did not erase or reinterpret the existing exact-reduction failure.

### Admission dimensions

The probe characterized alignment, column-count validity, row-coordinate membership, column bounds, and contributor presence as independent validation dimensions.

One failed expectation was useful: an unknown row coordinate does not make a valid numeric column index invalid. The validation axes should remain separate even when final publication is fail-closed.

## Structural work shape

For the tiny sparse case, the explicit rescan form describes:

```text
3 rows × 3 columns × 5 items = 45 mask-item comparisons
```

while the classify-once surface assigns five item coordinates before Group.

For the dense case:

```text
2 rows × 2 columns × 4 items = 16 mask-item comparisons
```

versus four item coordinate assignments.

These counts are **not runtime benchmarks**. Group has its own implementation cost, row lookup still has a cost, and household-scale data may make either implementation operationally adequate. The counts describe the visible algorithmic shape: output-cell-driven rescanning versus input-item-driven classification.

## Learning from failed forms

The first CI run exposed BQN right-to-left evaluation again. Writing:

```bqn
SumView expected AssertEq SumView actual
```

did not compare two named sum views. Naming `expectedSums` and `actualSums` made the evidence boundary explicit.

The second CI run reached every grouping case successfully and failed only because the expected validation tuple incorrectly coupled an unknown row with column invalidity. Correcting that expectation preserved validation independence.

## What became visible

The classify-once form expresses the accounting pipeline more directly:

```text
item evidence
→ admitted row and column coordinates
→ one cell coordinate
→ grouped exact-reduction inputs
→ sparse publication
```

It also creates a language-neutral boundary. A future Haskell admission or persistence owner could publish the same coordinate, coefficient, and contributor columns without knowing the BQN grouping implementation. A shell, raylib, HTML, or conversational client would continue to consume neutral section results rather than this internal algorithm.

## What is not yet proven

The experiment does not yet prove a production replacement.

Production adoption must still preserve:

- exact diagnostic codes and ordering;
- fail-closed empty publication on any invalid input or failed sum;
- duplicate row-axis rejection;
- row and column order;
- source-qualified contributor identity;
- current `groups` namespace shape;
- compatibility with `date_category_flow` and other consumers;
- adequate clarity in the production staged form;
- scaling evidence beyond structural operation counts.

The candidate also performs row lookup once per item rather than proving an optimal lookup structure.

## Destination

- observed algorithm experiment: retained;
- production replacement: not selected;
- clean architecture: unchanged and used as a gate;
- clean code pass: deferred until an algorithm is selected;
- next useful probe: characterize the full production admission and publication envelope around the classify-once kernel, or run synthetic scaling comparisons large enough to distinguish implementation overhead from the visible work-shape difference.
