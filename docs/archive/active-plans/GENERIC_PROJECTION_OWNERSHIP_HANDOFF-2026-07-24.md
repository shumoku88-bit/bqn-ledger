# Generic projection ownership handoff — 2026-07-24

Status: historical checkpoint / PR #354 merged
Owner: architecture / projection / workflow
Canonical: no
Exit: keep as historical evidence or delete when no longer useful

## Purpose

This document preserves the stopping point before PR #354 was merged. The resume sequence, selection language, and authorization language below are historical workflow evidence and do not direct current work.

## Repository checkpoint

- Repository: `shumoku88-bit/bqn-ledger`
- Base branch: `main`
- Base main SHA at branch creation: `aa010ef9c7d1bdc3c871ef0f240c087164d97ddb`
- Working branch: `docs/generic-projection-ownership-inventory`
- Draft PR: #354, `docs: inventory generic projection ownership`
- Pre-handoff PR head: `1d9499b19bcbbf14a5eda027a2665096ebc18486`
- Pre-handoff check: GitHub Actions `check` run #1223 completed successfully
- PR state before this handoff commit: open, Draft, mergeable

## Completed in this slice

1. Verified that the obsolete routing branches had been deleted and that no earlier open PR remained.
2. Inspected current ownership across:
   - checked Posting IR production;
   - Day, AccountKey, and Layer coordinate production;
   - selected-period Cube admission and skipped evidence;
   - exact accumulation and dense materialization;
   - TBDS opening, movement, and closing construction;
   - direct Cube, Cube-evidence, and TBDS consumers.
3. Added the completed docs-only audit:
   - `docs/archive/audits/GENERIC_PROJECTION_OWNERSHIP_INVENTORY-2026-07-24.md`
4. Updated `TODO.md` so the A0 inventory is routed as completed and all follow-up slices remain unselected.
5. Opened Draft PR #354.
6. Confirmed the final pre-handoff diff contained only the two intended Markdown files.

## Main findings to preserve

- `projection.bqn` is currently a Posting IR vocabulary, coordinate-helper, authorization, and diagnostic module. It is not the current generic accumulation owner.
- Direct dense `ctx.cube.cube` numeric consumption is concentrated in `daily_trend.bqn` and `daily_flow.bqn`.
- Balance and period-state consumers primarily use TBDS.
- Exact filter/key/sum patterns are repeated in `cube.bqn`, `tbds.bqn`, and section-local calculations.
- Cube admission and TBDS admission cannot be collapsed casually. A row before the selected period is skipped by the period Cube but may be opening-balance evidence in TBDS.
- Dense Cube cells and TBDS rows summarize contributor identity. Checked Posting IR remains the evidence-bearing surface.
- The current evidence does not support beginning with a universal Cube, generic admission framework, projection DSL, or broad module extraction.

## Leading next candidate, still unselected

### A1 exact sparse grouping characterization

A separately selected test-only slice may test:

```text
exact keys + exact values
  -> duplicate-key accumulation
  -> exact grouped sparse facts
```

Required boundaries:

- public synthetic facts only;
- I/O-free pure BQN;
- explicit empty-input behavior;
- duplicate-coordinate accumulation;
- negative values;
- exact total conservation;
- no production integration;
- no change to `cube.Materialize`;
- no movement of existing `Sum0` consumers;
- no admission, provenance, dense shape, Layer, currency, or valuation work in the same slice.

A1 is a recommendation from the inventory, not selected work.

## Other unselected alternatives

- A3 docs-only classification of every `cube.Materialize` result field.
- B0 docs-only commodity and valuation ownership inventory.

Only one finite slice should be selected after the current PR is resolved.

## Explicitly not done

- PR #354 was not marked Ready.
- PR #354 was not merged or closed.
- The working branch was not deleted.
- No runtime, fixture, source-data, Cube, TBDS, Posting IR, report, currency, valuation, editor, or CI file was changed.
- No generic module was implemented.
- No production composition or compatibility proof was started.
- No A1, A2, A3, A4, A5, B0, or other follow-up was selected.

## Repository hygiene note

Two accidental temporary dotfiles were briefly created and deleted on the working branch before PR creation. They do not appear in the PR diff. Because PR #354 is expected to use Squash merge if accepted, those intermediate commits should not enter main history as separate commits.

## Resume sequence

1. Fetch PR #354 and confirm it is still open and Draft unless the user changed it.
2. Confirm the current PR head and compare it with `main`.
3. Confirm changed files are limited to:
   - `TODO.md`;
   - `docs/archive/audits/GENERIC_PROJECTION_OWNERSHIP_INVENTORY-2026-07-24.md`;
   - this handoff document.
4. Confirm the latest workflow run for the current PR head completed successfully.
5. Review the ownership audit and TODO routing. Do not infer implementation authorization from the design intake or this handoff.
6. Decide whether PR #354 should be marked Ready and Squash merged.
7. After merge, verify the new main SHA and main checks before deleting the branch.
8. Select at most one next finite slice through `TODO.md`.
9. If A1 is selected, create a new branch and focused test-only plan. Do not continue implementation on PR #354.

## Stop condition

Work intentionally stops here with PR #354 left as a Draft review checkpoint.
