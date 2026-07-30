# Sparse group classify-once candidate against the focused production portfolio

Status: observed experiment

## Question

Can a production-shaped classify-once candidate pass the existing focused sparse-group test body without copying, weakening, or translating that test portfolio?

## Method

The production test remains unchanged at:

```text
tests/test_accounting_sparse_group.bqn
```

`run_sparse_group_candidate_portfolio.sh` verifies that the file contains exactly one import of `src/accounting/sparse_group.bqn`, creates a temporary sibling test file, changes only that import to the analysis-only candidate, runs the test with CBQN, and removes the temporary file.

This means the candidate inherits the same assertions and future additions whenever the focused production test changes. There is no second hand-maintained candidate portfolio.

## Candidate boundary

```text
Build
├─ ordered admission
├─ GroupAdmitted
├─ exact reduction through scale.Sum
└─ fail-closed publication
```

`GroupAdmitted` is private. It receives evidence only after the existing alignment, duplicate-axis, column-count, row-coordinate, column-index, and contributor checks have passed.

Inside the kernel:

```text
item row coordinate
→ row index

row index × column count + column index
→ one cell index

cell indices ⊔ coefficients / contributors
→ aligned occupied groups

occupied coefficient groups
→ scale.Sum
```

The public `Build` namespace and diagnostic contract are unchanged in the candidate.

## Observed result

GitHub Actions run `30542484266` completed successfully.

The unchanged focused test body printed:

```text
test_accounting_sparse_group: ok
sparse_group candidate portfolio: ok
```

The inherited portfolio covers:

- an occupied group whose exact sum is zero;
- row-major sparse publication;
- contributor flattening and input-relative order;
- empty evidence;
- misaligned columns;
- duplicate scalar row coordinates;
- duplicate nested row coordinates;
- unknown row coordinates;
- out-of-range columns;
- fractional columns;
- missing contributor evidence;
- exact-sum overflow with fail-closed groups.

## What this adds beyond the envelope probe

The prior envelope probe compared production and candidate across a deliberately assembled twelve-case matrix. This experiment additionally demonstrates that the candidate satisfies the repository's existing focused production test artifact itself.

The import adapter is deliberately narrow. It fails if the expected production import is missing or duplicated, and it verifies that the temporary file no longer imports production before running.

## Clean architecture result

The public accounting owner does not need to change. The replaceable seam is private:

```text
Build admission
→ admitted grouping kernel
→ Build publication
```

This is compatible with later alternative evidence producers or result consumers because no parser, source, section, renderer, editor, or UI contract enters the kernel.

## Clean algorithm result

The classify-once algorithm now has three layers of evidence:

1. grouped coefficients and contributors match the rescan formulation;
2. the complete diagnostic and fail-closed envelope matches production;
3. the unchanged focused production test body passes against the candidate.

## Clean code implication

A production slice can remain small:

- retain `Build` as the public owner;
- retain existing validation order, diagnostics, `scale.Sum`, result namespace, and fail-closed publication;
- replace only the private row × column rescan block with a named admitted classify-once kernel;
- add focused regression cases only where the current portfolio lacks explicit contract evidence.

The production change should be selected for the clearer evidence pipeline, not because this experiment is a runtime benchmark.

## Decision

The production finite slice is now reasonable to propose. This experiment does not merge or alter production code by itself.
