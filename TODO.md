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
- [ ] `experiments/` reachability: classify active experiment, historical evidence, or removable residue;
- [ ] `tui/` reachability and documentation drift;
- [ ] Calendar-first Household surface versus older Command Hub / TUI documentation;
- [ ] gum and shell action/selection duplication versus `HouseholdSurface.Actions`;
- [ ] remaining migration/compatibility residue outside completed canonical Household recovery;
- [ ] checks/tests classification: current law guard, historical characterization, or obsolete topology assumption.

## Known starting observations

Re-verify these against actual remote state before acting:

- `tui/README.md` has historically described a frozen TUI and older Command Hub shape and may now be stale.
- `experiments/bqn/add_ui_action_catalog.*` explored shell action declarations as a BQN relation; current `HouseholdSurface.Actions` may have superseded that experiment.
- dedicated checks/workflows around completed experiments may now be historical residue rather than active product gates.

Do not delete or rewrite these surfaces from memory. Observe current consumers and reachability first.

## Continuation contract

A fresh session should:

1. verify actual remote `main`, open PRs, relevant heads, and CI;
2. read the closeout document for the lane being revisited;
3. observe reachability and ownership before editing;
4. distinguish current law from historical evidence;
5. prefer retirement of dead compatibility/runtime surfaces over polishing them into permanent architecture;
6. keep canonical accounting meaning, exact arithmetic, identity, provenance, and writer safety unchanged unless a concrete defect requires otherwise;
7. record durable decisions in repository docs before ending the lane.

## Current cursor

```text
cross-cutting shell / UI / experiments / documentation reachability audit
```
