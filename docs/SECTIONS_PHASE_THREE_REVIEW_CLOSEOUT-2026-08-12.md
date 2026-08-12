# Sections Phase 3 review closeout — 2026-08-12

## Final state

The dense-array review of every production BQN owner listed under Phase 3 `src/sections/` is complete.

Final runtime main before this closeout: `46d54649519ff048644cb85f56eadee231d69a52`.

The phase did not force one renderer pattern onto every Section. Instead, each owner was reviewed for the smallest representation that keeps its semantic axis visible while preserving accounting ownership, exactness, evidence, diagnostics, and public destination text.

## Main outcomes

Three useful Section families emerged.

### Shared-table publication owners

Sections that already derive semantic rows and delegate layout to `text.RenderTable` now expose their publication structure directly:

```text
semantic row axis
  -> shared table block
heading / table / summary blocks
  -> one final flatten
```

This applies to Account Balances, Balance Sheet, Cycle Accounts, Cycle Comparison, Daily Flow, Issues, Monthly Accounts, Profit and Loss, Daily Target, and Envelope & Backing in the places where a shared table is the correct owner.

The Section remains responsible for semantic labels and block composition. `text.RenderTable` remains responsible for shared width, alignment, and separator mechanics.

### Custom row-text owners

Recent Journal and Trial Balance intentionally retain custom destination shapes. Their row construction now exposes complete row/line cells before one flatten rather than growing output text through mutable append state.

Recent Journal also replaced its mutable comma join with an index-axis transform followed by one flatten.

### Planned Payments relation owner

Planned Payments required more than renderer cleanup.

The completed Plan/Actual validation order remains source/relation ordered, but open Plans are now exposed explicitly:

```text
joined rows
  -> open mask
  -> openIndices
  -> candidate semantic rows
```

Candidate rows are no longer appended conditionally while traversing all joined rows. Selected currency identity uses BQN Deduplicate directly. Exact normalization and summation remain staged because those guards protect genuine arithmetic failure boundaries.

## Important guard lesson

The review deliberately did not turn "remove mutation" into a mechanical rule.

The first Planned Payments publication rewrite eagerly evaluated an optional empty `RenderTable` and failed. The final form keeps the overdue and future table construction behind `⍟` guards. Those guards are not incidental procedural residue: they preserve the lifetime of optional publication and prevent invalid/unneeded table evaluation.

Likewise, exact normalization/summation guards and diagnostic publication boundaries remain local where the operation can fail.

A second concrete BQN lesson came from Account Balances: multiline expressions ending a physical line with `∾` can become an unintended train. Reviewed renderers therefore use explicit line or chunk vectors followed by flattening when composition crosses physical lines.

## Merged review changes

- PR #684 — Account Balances: exposed row/line axes while preserving its section-specific divider and Human/Compact/JSON destinations.
- PR #685 — Balance Sheet: derived statement rows and publication blocks while retaining shared table ownership.
- PR #686 — Cycle Accounts + Cycle Comparison: exposed row/table/summary publication blocks as one coherent cycle renderer family.
- PR #687 — Daily Flow + Issues + Monthly Accounts + Profit and Loss: removed simple shared-table string accumulation and preserved `(none)` publication semantics.
- PR #688 — Recent Journal + Trial Balance: exposed custom Human/Compact row-line axes and structural joining.
- PR #689 — Daily Target + Envelope & Backing: exposed evidence publication blocks; Envelope JSON remained unchanged.
- PR #690 — Planned Payments: exposed the open Plan relation, direct Deduplicate currency identity, row-line publication, and retained meaningful exact/lazy guards.

All implementation PRs were qualified by the repository full check and the existing focused destination goldens before merge.

## Protected contracts

Phase 3 retained:

- accounting responsibility in `src/accounting/` rather than duplicating formulas in Sections;
- exact decimal and scale semantics;
- MatrixResult axes and evidence alignment;
- Plan completion identity and provenance;
- diagnostic ordering and fail-closed behavior;
- cycle and observation semantics;
- shared renderer ownership where already appropriate;
- byte-for-byte Human / Compact / JSON destination contracts covered by focused tests and checked-in goldens.

## Phase boundary

Phase 3 is complete.

The next normal review cursor is the first Phase 4 report owner:

```text
src/report/catalog.bqn
```

Phase 4 should begin by asking whether report catalog/request/composition/rendering boundaries still carry duplicated section knowledge, repeated traversal, or publication plumbing. It should not pull Section semantics into generic report machinery merely to reduce line count.
