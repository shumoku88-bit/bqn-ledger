# Sparse Group review observation — 2026-08-11

## Baseline

- repository: `shumoku88-bit/bqn-ledger`
- reviewed main: `33d673dab4177973e536b6af85392c4420b2bc03`
- durable review cursor: `src/accounting/sparse_group.bqn`
- main CI at the review baseline: successful
- open Draft #550 is canonical Household recovery closeout work and does not overlap this accounting owner

## Owner and reachability

`src/accounting/sparse_group.bqn` is the presentation-neutral sparse aggregation owner used by retained accounting kernels including:

- `src/accounting/date_category_flow.bqn`;
- `src/accounting/month_category_flow.bqn`;
- `src/accounting/month_account_movement.bqn`.

Its public surface is one `Build` function. It accepts an explicit row axis, explicit column count, aligned item row/column coordinates, exact coefficients, and contributor cells. It publishes only occupied row-major groups while preserving contributor evidence and exact reduction failure.

## Existing array kernel

The important algorithmic conversion was already completed historically in PR #487. The old row × column rescan was replaced by a private classify-once kernel:

```text
admitted item row / column
  -> encoded row-major cell coordinate
  -> Group coefficients and contributors in parallel
  -> occupied cells
  -> exact Sum per occupied coefficient group
```

That kernel remains the correct owner and should not be rewritten merely to produce a new review change.

## Remaining duplication found in the current owner

The current public admission boundary still performs the row relation twice:

1. `Contains` rescans the explicit row axis for every input row coordinate to diagnose unknown rows;
2. after admission, the private kernel calls a hand-built `IndexOf` for every row coordinate again to obtain the integer row coordinate used by Group.

Both operations answer the same relation question.

The file also retains hand-built equality-mask spellings for `Contains` and `IndexOf`, even though native dyadic Index Of already has the exact useful contract here:

```text
rowAxis ⊐ rowCoordinates
  -> admitted row index
  -> absent bound (≠rowAxis) for unknown coordinates
```

The absent bound is therefore simultaneously the validation sentinel and the coordinate needed by the private integer kernel.

## Selected subtraction

Use one native dyadic Index Of classification at the `Build` boundary and reuse its result for both purposes:

```text
explicit row axis × input row coordinates
  -> one row-index array
  -> absent-bound unknown-row diagnostic
  -> admitted integer row coordinates

row indices × explicit column count + column indices
  -> encoded cell coordinates
  -> Group
```

The private kernel no longer needs opaque row coordinates or the row axis itself; it receives the admitted integer row coordinates and the row count.

The same slice may express column-index validity as one aligned whole-array predicate. It must not move source, report, Section, editor, writer, identity, provenance, or UI ownership.

## Evidence required

Retain the existing focused portfolio for:

- occupied exact-zero groups;
- row-major sparse publication;
- contributor identity and input-relative order;
- empty evidence, empty row axis, and zero columns;
- misalignment;
- duplicate scalar and nested row axes;
- invalid column count;
- unknown row coordinates;
- out-of-range and fractional columns;
- missing contributors;
- exact overflow;
- diagnostic order;
- fail-closed publication.

Add one successful opaque nested-row case so the native Index Of relation is proved for semantic major cells rather than only scalar strings.

## Separate next owner

`sparse_pivot.bqn` remains the next Phase 1 cursor after this review closes. Its current dense-cell classify-once algorithm was already established historically in PR #490, so its review should begin from current evidence rather than repeating that old conversion. A visible remaining candidate is duplicate-coordinate validation, which currently rescans all sparse coordinates per item; that is observation only here and is not part of the Sparse Group change.
