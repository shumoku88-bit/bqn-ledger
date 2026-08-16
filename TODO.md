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

- [x] terminal selector/input duplication and UI change locality across active shell surfaces: Household frontends share one logical dispatcher; nested selectors remain opaque physical adapters; writer shortcut membership is parity-checked. See `docs/CROSS_CUTTING_FRONTEND_REACHABILITY_AUDIT-2026-08-17.md`.
- [x] editor/writer ownership from BQN semantic decision through machine operation to safe-write publication. See `docs/CROSS_CUTTING_WRITER_EFFECT_AUDIT-2026-08-17.md`.
- [ ] report/application CLI reachability and repeated effect/protocol boundaries;
- [ ] repository-wide dead-surface and reachability audit, including retained wrappers;
- [x] `experiments/` reachability: promoted action-catalog and sparse classify-once probes retired; current negative evidence retained. See `docs/CROSS_CUTTING_EXPERIMENT_REACHABILITY_AUDIT-2026-08-17.md`.
- [x] `tui/` reachability and documentation drift: status-only stale directory retired. See `docs/CROSS_CUTTING_FRONTEND_REACHABILITY_AUDIT-2026-08-17.md`.
- [x] Calendar-first Household surface versus older Command Hub / TUI documentation: current spatial + flat-palette frontend portfolio recorded in `docs/PRODUCTION_EDITOR_DIRECTION.md` and the frontend audit.
- [x] shell action/selection duplication versus `HouseholdSurface.Actions`: spatial/gum frontends share `tools/household-action`; standalone `add-ui` writer membership is parity-checked against non-Observe command Actions.
- [ ] remaining migration/compatibility residue outside completed canonical Household recovery;
- [ ] checks/tests classification: current law guard, historical characterization, or obsolete topology assumption.

## Current writer state

Active publication follows one recurring boundary:

```text
BQN/application observation
  -> candidate / intent
  -> shell checked publication
  -> mandatory validation
  -> digest-guarded rollback on failure
```

`tools/lib/safe-write.sh` owns the physical primitives. `tools/lib/edit-bqn-common.sh` owns shared protocol application; Plan Add/Edit/Finish, Budget, and Canonical Journal Surface retain dedicated effect wrappers only where they protect stronger observation/fence laws.

The writer audit fixed two Issue-specific exceptions:

- first `issues.tsv` publication is now exclusive and cannot overwrite a concurrent first writer;
- failed Issue append/replace/create post-checks now restore the exact observed bytes or remove the still-owned newly-created file.

Legacy `safe_append`, `safe_rewrite`, and `safe_create_checked` definitions have no active callers and are guarded against reuse. Their definition-level removal belongs to the repository-wide dead-surface cleanup rather than current writer authority.

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
report/application CLI reachability and repeated effect/protocol boundaries
```

Observe active report entrypoints, metadata/route leaves, shell wrappers, and any duplicate protocol/effect owners before editing. Keep report catalog/request/composition meaning in the existing BQN owners.
