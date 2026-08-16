# BQN review queue

## Current status

The 2026-08-17 owner-by-owner production BQN review and its cross-cutting re-baseline are complete.

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

Cross-cutting audits:

- frontend/action reachability: `docs/CROSS_CUTTING_FRONTEND_REACHABILITY_AUDIT-2026-08-17.md`
- writer/effect ownership: `docs/CROSS_CUTTING_WRITER_EFFECT_AUDIT-2026-08-17.md`
- report/application CLI: `docs/CROSS_CUTTING_REPORT_CLI_AUDIT-2026-08-17.md`
- experiments: `docs/CROSS_CUTTING_EXPERIMENT_REACHABILITY_AUDIT-2026-08-17.md`
- dead surfaces/reachability: `docs/CROSS_CUTTING_DEAD_SURFACE_AUDIT-2026-08-17.md`
- compatibility/history: `docs/CROSS_CUTTING_COMPATIBILITY_AUDIT-2026-08-17.md`
- checks/tests: `docs/CROSS_CUTTING_CHECK_TEST_CLASSIFICATION_AUDIT-2026-08-17.md`

There is no active review cursor from this re-baseline. A future material change should reopen the lane whose responsibility changed rather than treating this completion marker as review of future code.

## Completed cross-cutting queue

- [x] terminal selector/input duplication and UI change locality across active shell surfaces;
- [x] editor/writer ownership from BQN semantic decision through machine operation to safe-write publication;
- [x] report/application CLI reachability and repeated effect/protocol boundaries;
- [x] repository-wide dead-surface and reachability audit, including retained wrappers;
- [x] `experiments/` reachability and promotion/negative-evidence classification;
- [x] `tui/` reachability and documentation drift;
- [x] Calendar-first Household surface versus older Command Hub / TUI documentation;
- [x] shell action/selection duplication versus `HouseholdSurface.Actions`;
- [x] remaining migration/compatibility residue outside completed canonical Household recovery;
- [x] checks/tests classification: full-suite law, transitive law, standalone characterization, duplicate characterization, or obsolete topology evidence.

## Final qualification model

`tools/check.sh` is the qualification authority.

Evidence is now classified by responsibility and reachability rather than by filename:

```text
full-suite current law guard
transitive current law guard
standalone characterization
retired duplicate characterization
retired migration/topology characterization
```

Current examples:

- Identity Inventory CLI/privacy and JSON clock-independence are direct full-suite guards;
- repository-index integrity remains a transitive guard owned by devtools qualification;
- the large Phase-1 proof fixture remains deliberate standalone characterization;
- duplicate `check-bqn-eval.sh` is retired because devtool positive/negative checks own that law;
- retired Budget-style, legacy ILS vertical-slice, report-label/src_next, and old Hub UI-smoke checks no longer masquerade as current evidence.

`tools/coverage` is now a qualification evidence inventory rather than a fixed pseudo-coverage map. It does not call transitive/integration-tested modules “untested”.

## Stable boundaries reached by this re-baseline

```text
canonical/admitted meaning
        BQN/application owners
                |
                v
logical actions / candidate intent / report requests
                |
                v
bounded shell frontend / process / publication effects
                |
                v
mandatory observation and guarded rollback
```

The review also established these repository rules:

- promoted executable experiments retire once production owns their laws;
- useful negative experiment evidence may remain;
- old names do not imply dead reachability;
- retired source topology does not return as hidden fallback or characterization authority;
- current bounded compatibility is retained when active admitted evidence still requires it;
- tests are kept or retired by what they prove and how they are reached.

## Continuation contract

A fresh session should:

1. verify actual remote `main`, open PRs, relevant heads, and CI;
2. identify the concrete responsibility changed by new work;
3. reopen only the relevant owner/cross-cutting lane;
4. distinguish current law from historical evidence before editing;
5. prefer retirement of dead compatibility/runtime surfaces over polishing them into permanent architecture;
6. keep canonical accounting meaning, exact arithmetic, identity, provenance, writer safety, and current historical evidence unchanged unless a concrete defect requires otherwise;
7. record durable decisions in repository docs when a lane is reopened.

## Current cursor

```text
none — re-baseline complete
```
