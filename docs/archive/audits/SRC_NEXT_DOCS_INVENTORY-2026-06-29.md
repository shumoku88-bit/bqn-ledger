# src_next docs inventory 2026-06-29

Status: **inventory / no behavior change**
Date: 2026-06-29

## Purpose

`src_next/` is now the current daily report engine and is reached from the daily command hub (`tools/bl`). Some `src_next` migration documents still describe the older state where `bqn main.bqn` was the production default and `src_next` was observation-only.

This inventory records how to read those documents without rewriting every historical note.

## Current source of truth

For current behavior, read:

1. `docs/SRC_NEXT_CURRENT.md`
2. `README.md`
3. `docs/AI_CODEMAP.md`
4. `docs/ARCHITECTURE.md`
5. `docs/MAINTENANCE.md`

Current entrypoints:

| purpose | current command |
|---|---|
| daily operation hub | `tools/bl` |
| full human report, non-interactive | `tools/report` |
| report section UI | `tools/main-ui.sh` |
| machine summary | `tools/report-next-summary` |
| low-level diagnostic | `tools/report-next` |

## Archive reading rule

`docs/archive/src-next-migration/` is migration history. Any statement in that directory that says one of the following is historical unless repeated in a current doc:

- production default is `bqn main.bqn`
- `src_next` is not the production/default path
- Stage 4b has not started
- Stage 5/default switch is still pending
- household decisions must use `bqn main.bqn`

## Inventory

| file | current reading status | notes |
|---|---|---|
| `SRC_NEXT_STATUS_JA.md` | superseded | Already marked as superseded by `docs/SRC_NEXT_CURRENT.md`. |
| `SRC_NEXT_REPLACEMENT_READINESS.md` | superseded | Already marked as superseded by `docs/SRC_NEXT_CURRENT.md`. |
| `SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md` | historical decision | Records that Stage 4b was explicitly opened in the old migration flow. |
| `SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md` | historical backlog | Later note says Stage 4b started, but older rows still mention no Stage 4b start / `bqn main.bqn`. |
| `SRC_NEXT_STAGE4B_THIRD_DRY_RUN_PLAN.md` | historical dry-run plan | Pre-start plan; read only as trial preparation history. |
| `SRC_NEXT_STAGE4B_THIRD_DRY_RUN_SUMMARY.md` | historical dry-run summary | Public-safe dry-run result. |
| `SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md` | historical policy | Private-log policy from observation-only trial period. |
| `SRC_NEXT_STAGE4B_READINESS_GATE.md` | historical gate | Useful for understanding safety intent, not current default-switch gate. |
| `SRC_NEXT_STAGE4B_START_DECISION_CHECKLIST.md` | historical checklist | Old start checklist; no longer current. |
| `SRC_NEXT_STAGE4B_TRIAL_SCOPE.md` | historical scope | Observation-only scope; not current usage. |
| `SRC_NEXT_STAGE4_TRIAL_LOG.md` | historical template | Old trial log template. |
| `SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md` | historical inventory | Old observation inventory. |
| `SRC_NEXT_REPORT_SECTION_PARITY.md` | historical parity matrix | Useful evidence for why current report exists; not the current report spec. |
| `SRC_NEXT_CURRENT_ENGINE_COMPARISON.md` | historical comparison | Old current-engine comparison record. |
| `SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` | historical procedure | Old comparison procedure based on `bqn main.bqn`. |
| `SRC_NEXT_COMPARISON_RECORD_TEMPLATE.md` | historical template | Old comparison template. |
| `SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` | historical criteria | Old equivalence criteria for migration gates. |
| `SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md` | historical design note | Useful background for snapshot section design. |
| `SRC_NEXT_STAGE3_ENTRYPOINT_CONTRACT.md` | historical entrypoint contract | `tools/report-next` is now diagnostic; daily entry is `tools/bl` / `tools/report`. |
| `SRC_NEXT_GOLDEN_CHECK.md` | historical plus fixture background | Fixture/check context remains useful; production-replacement wording is historical. |
| `SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md` | historical contract background | Current envelope behavior should be checked against implementation/current docs. |
| `SRC_NEXT_INCOME_ANCHOR_CYCLE_CONTRACT.md` | historical implemented contract | Income-anchor implementation history; current cycle behavior lives in code/current docs. |
| `SRC_NEXT_ARCHITECTURE_DESIGN.md` | historical architecture proposal | Superseded by `docs/ARCHITECTURE.md` and current `src_next/` modules. |
| `SRC_NEXT_STAGE4B_IMPLEMENTATION_TODO.md` | historical implementation TODO | Completed/old integration checklist. |
| `PHASE4_BASE_AWARE_CONTEXT_INVESTIGATION.md` | historical investigation | Missing status header; old base-aware context investigation. |

## Recommended follow-up

Small safe follow-ups, if desired:

1. Add a short `README.md` inside `docs/archive/src-next-migration/` pointing to this inventory and `docs/SRC_NEXT_CURRENT.md`.
2. Add superseded status notes to the most misleading high-traffic archived docs (`SRC_NEXT_STAGE4B_READINESS_GATE.md`, `SRC_NEXT_REPORT_SECTION_PARITY.md`, `SRC_NEXT_STAGE3_ENTRYPOINT_CONTRACT.md`).
3. Update active docs that still say "next ledger engine candidate" now that Posting IR / TBDS are current contracts.

No source TSV or production behavior should change as part of this cleanup.
