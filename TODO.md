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
- [x] `tui/` reachability and documentation drift: status-only stale directory retired. See `docs/CROSS_CUTTING_FRONTEND_REACHABILITY_AUDIT-2026-08-17.md`.
- [x] Calendar-first Household surface versus older Command Hub / TUI documentation: current spatial + flat-palette frontend portfolio recorded in `docs/PRODUCTION_EDITOR_DIRECTION.md` and the frontend audit.
- [ ] shell action/selection duplication versus `HouseholdSurface.Actions`: spatial and gum frontends now share `tools/household-action`; standalone `add-ui` writer menu remains to review.
- [ ] remaining migration/compatibility residue outside completed canonical Household recovery;
- [ ] checks/tests classification: current law guard, historical characterization, or obsolete topology assumption.

## Current frontend state

Logical frontend authority is:

```text
HouseholdSurface Domain × Operation × Actions
              -> tools/household-action
              -> tools/bl / existing direct owners
```

Both current Household frontends now converge on that route:

- `tools/household-surface`: Calendar-first spatial terminal frontend;
- `tools/household-hub-gum`: optional flat searchable palette.

Nested opaque-line choice remains independently adapter-owned by `tools/lib/ui-choice.sh` (`fzf` / `gum` / `plain`).

`tools/add-ui.sh` remains a writer interaction helper. Its standalone no-mode writer menu is now the next narrower duplication question. Do not replace it by dumping the whole Household action relation: that relation includes read/report actions and uses frontend-neutral logical keys that intentionally differ from writer mode names.

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
standalone tools/add-ui.sh writer-menu duplication
```

Decide whether that no-mode compatibility menu should remain an independent compact writer shortcut or be projected from a smaller current writer-action relation. Explicit `add-ui` modes and direct editor commands are not candidates for removal in this audit.
