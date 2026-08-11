# Sparse Pivot review observation — 2026-08-11

## Baseline

- repository: `shumoku88-bit/bqn-ledger`
- base main: `4c50f3ace0b43e50a320a4099a7c2d6ac1e63d95`
- active owner: `src/accounting/sparse_pivot.bqn`
- predecessor `sparse_group.bqn` was merged in PR #641
- no open PR matched `sparse_pivot` before this review

## Existing owner

`sparse_pivot.Build` receives:

- explicit opaque row coordinates;
- explicit opaque column coordinates;
- exact value scale;
- one aligned sparse Group table with row/column integer coordinates, coefficients, and contributor cells.

It publishes one canonical `MatrixResult` through `matrix_result.Build`.

The existing densification algorithm was already classify-once:

```text
sparse (row,column)
  -> encoded occupied cell
  -> Index Of dense row-major cells
  -> Group index or absent bound
  -> dense values / contributors
```

The review therefore does not replace the Pivot algorithm or ownership boundary.

## Remaining procedural residue

Two local forms remained after the earlier classify-once conversion.

### 1. Duplicate coordinate rescan

Duplicate sparse coordinates were detected by visiting every Group item and rescanning the complete row/column arrays for an equal pair.

The semantic object is not an encoded row-major integer because invalid coordinate pairs can collide under an encoding before bounds admission. The truthful duplicate identity is the relation cell:

```text
⟨row_index,column_index⟩
```

These cells can be deduplicated directly with BQN major-cell Deduplicate `⍷` while preserving the existing independent row-invalid, column-invalid, and duplicate diagnostics.

A focused law now fixes the important counterexample: distinct invalid pairs `(1,0)` and `(0,1)` on a 1-column matrix must produce only row/column bound diagnostics, not a false duplicate diagnostic, even though both would encode to cell `1`.

### 2. Dense cell conditional mutation

After `groupLookup` already classified every dense destination as a Group index or the absent bound `groups.count`, the implementation still constructed each destination cell by:

```text
value <- 0
contributors <- empty
if occupied:
  overwrite both
```

The absent bound itself can instead select an appended fill item:

```text
groupLookup ⊏ (groups.coefficient ∾ 0)
groupLookup ⊏ (groups.contributors ∾ ⟨empty⟩)
```

This keeps occupied exact-zero groups distinguishable from missing zero cells because the occupied group retains its contributors while the appended absent cell has none.

## Array model after subtraction

```text
aligned sparse Group columns
  -> relation cells ⟨row,column⟩
  -> Deduplicate duplicate law

admitted sparse coordinates
  -> row-major occupied cell coordinates
  -> Index Of dense cell axis
  -> Group index / absent-bound fill coordinate
  -> parallel value and contributor selection
  -> row-major rows
  -> MatrixResult
```

## Protected contracts

Keep unchanged:

- public `Build` export and result shape;
- group-column alignment diagnostic;
- independent row-bound and column-bound diagnostics;
- duplicate coordinate semantics and diagnostic order;
- MatrixResult-owned duplicate axis and scale admission;
- row/column coordinate order;
- occupied exact-zero evidence versus missing zero fill;
- contributor contents and order;
- empty rows, empty columns, and empty Group behavior;
- fail-closed MatrixResult publication;
- all callers, reports, editor/source/writer authority, identity, and provenance.

## Decision

Retain the owner and classify-once Pivot architecture. Subtract only the duplicate-rescan and cell-level conditional mutation, expressing both from the already available relation/lookup arrays. No generic helper or new abstraction is warranted.
