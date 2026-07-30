# MatrixResult Each, Cells, and Rank probe

## Question

Can the MatrixResult column-alignment predicates be stated more directly with Cells or Rank than with Each?

Current runtime owner: `src/accounting/matrix_result.bqn`.

Current expressions:

```bqn
valueColumnsAligned ← ∧´1∾{(≠𝕩)=columnCount}¨values
contributorColumnsAligned ← ∧´1∾{(≠𝕩)=columnCount}¨contributors
```

## Boundaries

Preserved in this probe:

- the predicate asks whether every row has the admitted column count;
- empty row sequences reduce to true through `∧´1∾...`;
- ragged candidate rows remain representable for observation;
- no runtime module imports this experiment.

Intentionally relaxed:

- structured MatrixResult diagnostics are not constructed;
- values and contributors are represented by small synthetic rows;
- no production representation is changed.

## Compared forms

For nested row sequences:

```bqn
HasTwoColumns¨rows
HasTwoColumns˘rows
HasTwoColumns⎉0 rows
```

For true rank-2 arrays:

```bqn
HasTwoColumns¨table
HasTwoColumns˘table
HasTwoColumns⎉1 table
HasTwoColumns⎉¯1 table
```

The probe ran with CBQN in GitHub Actions workflow run `30532900105` on 2026-07-30.

## Observations

### Nested rows with equal lengths

The outer value has shape `⟨2⟩` and rank `1`.

```text
Each predicate: 1‿1
Cells predicate: 0‿0
Rank 0 predicate: 0‿0
```

Each applies the predicate to the two row values and therefore sees their inner lengths. Cells and Rank 0 operate on the outer list's 0-cells. Those cells each have length one, so they do not expose the nested row length.

### Nested rows with unequal lengths

```text
Each predicate: 0‿1
Cells predicate: 0‿0
Rank 0 predicate: 0‿0
```

Each preserves the distinction between the one-column and two-column rows. Cells and Rank 0 cannot express this nested-depth question.

### Empty nested row sequence

Each, Cells, and Rank 0 all produced an empty result. With the existing `∧´1∾...` reduction, all three reduced to true.

The empty case alone therefore does not distinguish the formulations.

### True 2×2 array

The merged table has shape `2‿2` and rank `2`.

```text
Each predicate: 2×2 array of zeroes
Cells predicate: 1‿1
Rank 1 predicate: 1‿1
Rank ¯1 predicate: 1‿1
```

Here the relationship reverses. Each maps over scalar numeric elements and cannot ask a row-length question. Cells and Rank apply directly to rank-1 row cells and state the question naturally.

### True 0×2 array

Cells and Rank returned an empty row-result sequence, and the existing reduction returned true. A true array can preserve both the empty row axis and the known two-column axis as shape `0‿2`.

## Result

**Keep Each in the current production constructor.**

This is not a missed primitive replacement. It is a representation boundary:

- current MatrixResult input is a rank-1 sequence of nested row arrays;
- Each descends through the outer elements and directly owns the current validation question;
- Cells and Rank become direct only after the data is represented as a true rank-2 array.

There is also a safety reason not to merge first and validate later. `Build` is an admission boundary that must accept ragged candidate rows in order to return structured `matrix_*_columns_misaligned` diagnostics. A true rectangular array cannot represent the malformed row lengths that this constructor is responsible for rejecting. Calling Merge before validation would replace a domain diagnostic with a primitive shape error.

## New question revealed

A later probe could examine a two-stage representation:

```text
permissive nested candidate rows
→ structured row/column validation
→ canonical rectangular values and contributors after successful admission
```

That would be a representation and public-contract decision, not a meaning-preserving Each-to-Cells refactor. It would need to characterize contributor cells, empty `0×N` shapes, fills, consumer expectations, and whether canonical MatrixResult publication benefits from true axes.

## Destination

- direct production replacement: parked;
- experiment result: retained;
- next possible work: representation probe, not selected automatically.
