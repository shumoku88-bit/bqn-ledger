# BQN review queue

## Current status

The owner-by-owner production BQN review is complete as of 2026-08-17.

Reviewed production roots:

```text
src/
src_edit/
tools/  (*.bqn)
```

Phase closeouts:

- Phase 1 `src/accounting/`: `docs/ACCOUNTING_PHASE_ONE_REVIEW_CLOSEOUT-2026-08-11.md`
- Phase 2 `src/ledger/`: `docs/LEDGER_PHASE_TWO_REVIEW_CLOSEOUT-2026-08-12.md`
- Phase 3 `src/sections/`: `docs/SECTIONS_PHASE_THREE_REVIEW_CLOSEOUT-2026-08-12.md`
- Phase 4 `src/report/`: `docs/REPORT_PHASE_FOUR_REVIEW_CLOSEOUT-2026-08-12.md`
- Phase 5 `src/application/`: `docs/APPLICATION_PHASE_FIVE_REVIEW_CLOSEOUT-2026-08-12.md`
- Phase 6 `src/editor/` + `src_edit/`: `docs/EDITOR_PHASE_SIX_CLOSEOUT-2026-08-17.md`
- Phase 7 remaining production BQN: `docs/PRODUCTION_BQN_PHASE_SEVEN_CLOSEOUT-2026-08-17.md`

There is no active production `.bqn` cursor. A future material production-BQN change should explicitly reopen the relevant review lane; this completion marker does not review future code automatically.

## Current review lane

The next work is cross-cutting repository observation rather than another semantic-owner pass.

- [ ] terminal selector/input duplication and UI change locality across active shell surfaces;
- [ ] editor/writer ownership from BQN semantic decision through machine operation to safe-write publication;
- [ ] report/application CLI reachability and repeated effect/protocol boundaries;
- [ ] repository-wide dead-surface and reachability audit, including retained wrappers;
- [x] `experiments/` reachability: promoted action-catalog and sparse classify-once probes retired; current negative evidence retained. See `docs/CROSS_CUTTING_EXPERIMENT_REACHABILITY_AUDIT-2026-08-17.md`.
- [ ] `tui/` reachability and documentation drift;
- [ ] Calendar-first Household surface versus older Command Hub / TUI documentation;
- [ ] gum and shell action/selection duplication versus `HouseholdSurface.Actions`;
- [ ] remaining migration/compatibility residue outside completed canonical Household recovery;
- [ ] checks/tests classification: current law guard, historical characterization, or obsolete topology assumption.

## Current experiment state

`experiments/bqn/` now retains only the Cells/Rank matrix-result experiment and its note as negative evidence. Its conclusion still matches current `src/accounting/matrix_result.bqn`: the alternative preserves behavior but obscures a small fixed-field assembly.

Promoted experiments are no longer executable second implementations. Git history and the cross-cutting audit document retain their evidence.

## Continuation contract

A fresh session should:

1. verify actual remote `main`, open PRs, relevant heads, and CI;
2. read the closeout/audit document for the lane being revisited;
3. observe reachability and ownership before editing;
4. distinguish current law from historical evidence;
5. prefer retirement of dead compatibility/runtime surfaces over polishing them into permanent architecture;
6. keep canonical accounting meaning, exact arithmetic, identity, provenance, and writer safety unchanged unless a concrete defect requires otherwise;
7. record durable decisions in repository docs before ending the lane.

## Current cursor

```text
tui/README.md + active tools/bl/add-ui path + Calendar-first surface documentation
```

Observe before editing: keep live frontend adapters distinct from stale architectural descriptions. After documentation/reachability is aligned, inspect shell-owned action/selection duplication against `HouseholdSurface.Actions`.
