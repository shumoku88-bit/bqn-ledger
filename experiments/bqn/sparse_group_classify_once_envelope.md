# Sparse Group classify-once envelope probe

## Question

Can the classify-once grouping kernel from `sparse_group_classify_once.bqn` fit inside the complete public result contract of `src/accounting/sparse_group.bqn` without changing diagnostics, exact reduction, contributor order, or fail-closed publication?

## Architecture gate

The experiment keeps the existing dependency and ownership boundary unchanged:

```text
candidate columns
  → ordered accounting admission
  → grouping and exact reduction
  → fail-closed sparse result
```

Source parsing, canonical Facts, report sections, renderers, editor behavior, UI behavior, and writer ownership remain outside this probe.

## Compared forms

### Production

```text
row axis × column axis
  → rescan all input evidence for each cell
  → exact sum selected coefficients
  → publish sparse groups only when every stage succeeds
```

### Candidate

```text
input evidence
  → row index and column index
  → one row-major cell index
  → Group coefficients and contributors once
  → exact sum occupied groups
  → publish the same sparse result only when every stage succeeds
```

The candidate deliberately reuses `scale.Sum`. It does not replace exact accounting arithmetic with a primitive numeric fold.

## Compared public view

For each result, the probe compares:

- `state`;
- group `count` and `index`;
- `row_index` and `column_index`;
- exact `coefficient` values;
- flattened contributor arrays and their order;
- diagnostic severity, stage, code, message, and order;
- empty groups whenever admission or reduction fails.

The production module is imported directly and serves as the executable reference.

## Observed evidence

GitHub Actions run `30541722731` completed successfully.

The production and candidate views were identical for twelve cases:

1. valid sparse publication with an occupied exact-zero group;
2. valid dense interleaved evidence;
3. empty row axis;
4. zero column axis;
5. exact-sum overflow;
6. misaligned input columns;
7. duplicate row axis;
8. invalid column count;
9. unknown row coordinate;
10. invalid column coordinate;
11. missing contributors;
12. combined invalid input.

### Valid publication

The sparse case retained three occupied groups in row-major order. The first group contained `5` and `¯5`, published coefficient `0`, and retained contributors `p0` then `p2`.

The dense interleaved case published cell order `(0,0)`, `(0,1)`, `(1,0)`, `(1,1)` while retaining the input-relative contributor for each cell.

Empty row and zero-column axes both remained valid and published an empty group namespace.

### Fail-closed reduction

The overflow case returned:

```text
state: error
groups: empty
diagnostic code: group_sum_failed
```

The underlying exact reducer still detected `coefficient_sum_out_of_exact_range`; the sparse-group boundary translated that failure into its existing public diagnostic and published no partial groups.

### Ordered admission

The combined invalid case retained this exact diagnostic order:

```text
group_row_axis_duplicate
group_column_count_invalid
group_row_coordinate_unknown
group_column_index_invalid
group_contributors_missing
```

The final group namespace remained empty. Misalignment continued to gate row, column, and contributor checks exactly as in production.

## What became visible

The public contract is not tied to the rescan algorithm.

It can be viewed as three separable layers:

```text
ordered admission
  owns malformed candidate evidence and diagnostic order

classify/group/reduce kernel
  owns admitted coordinate aggregation and contributor alignment

fail-closed publication
  owns whether a complete group namespace may become visible
```

The classify-once candidate can replace the middle layer while the other two layers remain semantically unchanged.

This is useful beyond performance. It makes the accounting capability easier to expose through a neutral contract to another implementation language or UI because callers need not know whether BQN used repeated masks, Group, or another admitted kernel internally.

## Decision

The classify-once kernel is compatible with the tested production admission and publication envelope.

Production replacement is still not selected automatically. Remaining work before a production slice includes:

- run the candidate through the focused production test portfolio rather than only synthetic comparison cases;
- decide whether to replace only the inner grouping block or introduce a separate private kernel;
- inspect clarity and maintenance cost alongside the structural work reduction;
- characterize larger synthetic scaling without treating benchmark speed as the only criterion;
- preserve the current external `Build` signature and diagnostic contract.

A likely clean production shape is to retain the current `Build` admission and publication owner, replacing only its admitted grouping block. This avoids duplicating diagnostic construction or creating a second public abstraction.

## Files

- `experiments/bqn/sparse_group_classify_once.bqn`
- `experiments/bqn/sparse_group_classify_once.md`
- `experiments/bqn/sparse_group_classify_once_envelope.bqn`
- this note

## Destination

Observed algorithm-envelope experiment. The next finite step is production-test characterization of a private classify-once kernel, not an immediate runtime rewrite.
