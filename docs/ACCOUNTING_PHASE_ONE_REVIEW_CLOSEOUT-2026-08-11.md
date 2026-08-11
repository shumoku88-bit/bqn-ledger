# Accounting Phase 1 review closeout — 2026-08-11

## Status

The `src/accounting/` review inventory is complete on merged main through:

- PR #641, `refactor(accounting): classify sparse Group rows once`;
- PR #642, `refactor(accounting): simplify sparse Pivot coordinate fill`.

Merged main at this closeout baseline is `60ed9848bed340c6fc24109c48d576132ee36ba0`.

The repository-resident review cursor can now move from Phase 1 `src/accounting/` to Phase 2 `src/ledger/`, beginning with `src/ledger/account_admission.bqn`.

## Sparse Group final decision

`src/accounting/sparse_group.bqn` remains the named presentation-neutral sparse grouping owner.

PR #641 removed the final duplicate row-coordinate search around the already classify-once Group kernel:

```text
explicit row axis × input row coordinates
  -> one dyadic Index Of classification
  -> row indices / absent-bound unknown sentinel
  -> encoded row × column cells
  -> Group coefficients and contributors in parallel
  -> exact Sum per occupied cell
```

The same row-coordinate classification now owns both unknown-row admission and the integer coordinate consumed by the private Group kernel. Hand-built equality-mask `Contains` / `IndexOf` helpers were removed. Opaque nested row coordinates are covered by focused evidence.

Keep:

- explicit row-axis and column-count admission;
- diagnostic order and fail-closed publication;
- row-major occupied-cell ordering;
- occupied exact-zero groups;
- contributor order;
- `exact_scale.Sum` as exact reduction owner;
- empty-axis behavior.

The durable observation is `docs/SPARSE_GROUP_REVIEW_OBSERVATION-2026-08-11.md`.

## Sparse Pivot final decision

`src/accounting/sparse_pivot.bqn` remains the named dense MatrixResult construction owner over admitted sparse Group coordinates.

PR #642 retained the existing classify-once Pivot algorithm and removed two remaining procedural forms:

1. per-item whole-Group duplicate-coordinate rescanning;
2. per-dense-cell zero initialization plus conditional mutation.

Duplicate identity is now expressed as relation cells `⟨row_index,column_index⟩` and major-cell Deduplicate `⍷`. This intentionally does not use row-major encoded cells before bounds admission, because distinct invalid coordinate pairs can collide under the encoding.

Dense fill now uses Index Of's absent bound directly:

```text
groupLookup ⊏ (groups.coefficient ∾ 0)
groupLookup ⊏ (groups.contributors ∾ ⟨empty⟩)
```

This preserves the distinction between an occupied exact-zero cell, which retains contributors, and a missing cell, which receives zero plus empty contributors.

Keep:

- independent row-bound, column-bound, and duplicate diagnostics;
- MatrixResult-owned axis/scale admission;
- row-major dense ordering;
- occupied-zero evidence;
- empty rows, empty columns, and empty Group behavior;
- fail-closed MatrixResult publication.

The durable observation is `docs/SPARSE_PIVOT_REVIEW_OBSERVATION-2026-08-11.md`.

## Phase 1 outcome

The accounting review has not attempted total tacit conversion or code golf. Across the phase, the stable direction is now visible:

```text
strict semantic/query admission
  -> explicit accounting axes
  -> classify once
  -> Group / Pivot / Cells / exact reductions
  -> semantic result plus durable evidence
```

Repeated cell scans, mutable append/staging, duplicate result authority, snapshot-local coordinate leaks, hand-built equality lookups, and other structural plumbing were removed where the evidence showed they carried no retained meaning.

Validation and exact-failure boundaries were retained where they own real accounting or publication semantics.

## Qualification

- PR #641 final head CI #2573: SUCCESS;
- PR #641 merged-main CI #2574: SUCCESS;
- PR #642 final head CI #2575: SUCCESS;
- PR #642 was reread on merged main `60ed9848bed340c6fc24109c48d576132ee36ba0` with the final Group/Pivot owners present as intended;
- no public result, source/writer authority, identity, provenance, report, editor, or UI contract was moved by the final Group/Pivot slices.

The Phase 2 review should begin with `src/ledger/account_admission.bqn`, treating admission density as potentially necessary complexity rather than assuming every guard is removable.
