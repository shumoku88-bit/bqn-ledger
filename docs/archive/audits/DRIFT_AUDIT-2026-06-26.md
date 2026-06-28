# Docs / Implementation Drift Audit 2026-06-26

Status: in progress / initial findings
Date: 2026-06-26

## Scope

This audit compares current docs, scripts, and implementation after the old engine removal and recent `src_next` work.

Non-goals:

- Do not edit source TSV (`data/journal.tsv`, `data/plan.tsv`, `data/budget_alloc.tsv`, `data/accounts.tsv`).
- Do not fix all drift during the audit.
- Do not widen Go editor write scope.
- Do not delete historical docs during this pass.

## Baseline

| item | result | note |
|---|---|---|
| `rtk git status --short` | non-clean | new audit TODO exists: `docs/DRIFT_AUDIT_TODO-2026-06-26.md` |
| `sqz ./tools/check.sh` | failed | local `sqz` is not an arbitrary command wrapper; it expects subcommands |
| `rtk ./tools/check.sh` | failed | permission denied in this environment |
| `rtk bash ./tools/check.sh` | PASS | all current checks completed |

Current check result:

```text
rtk bash ./tools/check.sh
...
OK
```

## Drift table

| priority | area | doc | implementation | drift | suggested fix |
|---|---|---|---|---|---|
| P1 | check command guidance | `AGENTS.md`, `docs/DRIFT_AUDIT_TODO-2026-06-26.md` | `sqz ./tools/check.sh` failed; `rtk bash ./tools/check.sh` worked | Docs/prompt guidance implies `sqz` can prefix arbitrary commands, but current installed `sqz` is a subcommand CLI. | Prefer `rtk bash ./tools/check.sh` for this repo, or document exact `sqz` usage if there is a wrapper mode. Update the audit TODO suggested command. |
| P1 | check suite trust | `README.md`, `tools/check.sh` comment says Go editor tests are part of checks | `tools/check.sh` runs `(cd editor && go test ./...) >/dev/null 2>&1 || true` | Go test failures are ignored, so docs saying the full check includes Go editor tests can create false confidence. | Decide whether Go tests should be required. If yes, remove `|| true`; if no, docs must say Go tests are best-effort/non-gating. |
| P1 | production entrypoint | `tools/report-next`, `tools/report-next-summary` help/comments | root `main.bqn` is deleted; `tools/report` is production default and calls `src_next/report.bqn` | Wrappers still say `src_next` is experimental and production remains `bqn main.bqn`. | Update wrapper help/comments to say `tools/report` / `src_next/report.bqn` is current default, or retire these wrappers. |
| P1 | current docs map | `README.md` Documentation map | `docs/MAIN_SECTIONS.md` and `docs/REPORT_FIELD_MAP.md` are marked historical/superseded | README presents historical old-engine docs as current docs for `tools/report` / report fields. | Replace with current `src_next/report.bqn` / `docs/AI_CODEMAP.md` / new src_next section map, or mark them historical in README. |
| P1 | agent rules | `AGENTS.md` | old engine removed; `REPORT_FIELD_MAP.md` / `MAIN_SECTIONS.md` historical | AGENTS still says report changes must update old `report_engine` / `main` docs. | Replace with src_next-specific report section documentation rule, or explicitly say old docs are historical. |
| P1 | check path | `AGENTS.md` | check entrypoint is `tools/check.sh`; there is no `checks/check.sh` | AGENTS says run `./checks/check.sh`. | Update to `./tools/check.sh` / `rtk bash ./tools/check.sh`. |
| P1 | BQN-only path wording | `AGENTS.md` | core BQN engine is `src_next/**/*.bqn`; `src/` now only contains check scripts | BQN-only report path says `src/**/*.bqn`, which no longer names the current engine. | Update to `src_next/**/*.bqn` plus `checks/*` only for checks. |
| P2 | active/completed status | `docs/README.md`, `TODO.md`, `docs/OLD_ENGINE_REMOVAL_PLAN.md` | old engine code is removed; TODO says completed; plan file status says in progress; docs README lists it active | Active/completed state is inconsistent. | Mark `OLD_ENGINE_REMOVAL_PLAN.md` completed or move to completed-plan reading path; update docs README active list. |
| P2 | active/completed status | `docs/README.md`, `TODO.md`, `docs/REPORT_SCREEN_REVIEW_LOOP.md` | report screen mock review is completed per TODO and loop doc | docs README still lists report screen review loop under Active. | Move to Done / Current Baseline or Backlog for implementation track. |
| P1 | Canonical Daily Cube contract | `docs/CANONICAL_DAILY_CUBE.md` | current implementation is in `src_next/cube.bqn`, `src_next/context.bqn`, `src_next/report.bqn`; old `report_tx_updates`, `report_engine`, `tools/check-tx-updates.bqn` are gone | Current contract doc still describes old implementation details and old checks. | Rewrite implementation section for `src_next` or add superseded note and create a fresh src_next cube contract. |
| P1 | Safety invariant map | `docs/SAFETY_PROFILE_INVARIANT_MAP.md` | files such as `lint_cli.bqn`, `lint_journal.bqn`, `check-cube-shape.bqn`, `check-forecast-zero.bqn`, `export-section-status.bqn`, `check-section-status.sh` are not present in current `checks/` | The map claims guards that no longer exist, including some main-check integration. This creates false safety confidence. | Re-audit against `tools/check.sh`, `checks/check-src-next-*`, and `tests/test_src_next_*.bqn`; downgrade removed guards to GAP/PARTIAL as needed. |
| P1 | account-axis invariant | `docs/SAFETY_PROFILE_INVARIANT_MAP.md` | `src_next` uses dynamic account count from `accounts.tsv` | Invariant map still says cube shape check covers `256 accounts`. | Replace with dynamic AccountKey axis invariant (`≠accounts`) and current tests. |
| P1 | section status policy | `docs/REPORT_SECTION_STATUS_POLICY.md` | old `src/reports/report_engine.bqn` and `export-section-status.bqn` are gone | Policy doc still describes old implementation path as current partial implementation. | Convert old implementation section to historical note; document current `src_next` status fields/sections if any. |
| P1 | Go editor post-check | `docs/GO_EDITOR_USAGE.md` | `editor/journal.go` runs `bqn src_next/report.bqn <base>` for `--post-check lint`, and `./tools/check.sh` for `full` | Docs say post-write check runs `bqn checks/lint_cli.bqn`. That file no longer exists. | Update Go editor usage to current post-check commands and semantics. |
| P2 | Go editor command list | `docs/GO_EDITOR_USAGE.md`, `docs/GO_EDITOR_NEXT_PLAN.md` | `tools/edit` help includes `journal reverse`; `tools/add-ui.sh` has reverse mode | Usage/plan docs do not include journal reverse in the main command/mode list. | Add `journal reverse` docs and update current allowed write scope. |
| P1 | report section UI | `tools/main-ui.sh`, `src_next/report.bqn`, `docs/REPORT_SCREEN_CANDIDATES.md` | `src_next/report.bqn` prints Trial Balance; candidates say Trial Balance adopted; `tools/main-ui.sh` has no Trial Balance selector | Current main UI cannot select a report section that exists and is adopted. | Add Trial Balance to `tools/main-ui.sh` section list/marker or document that it is intentionally not selectable. |
| P1 | missing tool docs | `docs/AI_CODEMAP.md`, `docs/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md` | `tools/sqz-report` is not present | Docs still describe `tools/sqz-report` as implemented/available. | Remove/update references or restore an equivalent tool intentionally. |
| P2 | repo-index docs | `docs/REPO_INDEX_DESIGN.md`, `docs/REPO_INDEX_IMPLEMENTATION_HANDOFF.md` | old `src/reports/*`, `lint_cli.bqn`, exporter paths are gone | Repo-index design examples and acceptance criteria still target old tree. | Mark as historical or refresh examples to `src_next/` and current checks. |
| P2 | current state reference | `docs/CURRENT_STATE_REFERENCE.md` | old engine removed | This doc still presents old `main.bqn`, `src/reports/exporters/*.bqn`, old checks, and old dataflow as current. | Add superseded status or archive; if still needed, rewrite as historical snapshot. |
| P2 | plan lifecycle wording | `docs/PLAN_ID_LIFECYCLE.md` | current BQN engine is `src_next` modules; no `report_engine.bqn` | BQN responsibility section names `report_engine.bqn` as engine. | Replace with `src_next/planned_payments.bqn`, `src_next/plan_journal_overlap.bqn`, `src_next/context.bqn` as appropriate. |

## Initial interpretation

The biggest drift is not source-data risk from this audit itself; it is **false confidence from docs that describe removed old-engine checks as still guarding current behavior**.

Highest-priority fixes should be:

1. Correct check entrypoints and gating behavior (`tools/check.sh`, AGENTS, README).
2. Correct old-engine references in current entry docs and safety docs.
3. Refresh `CANONICAL_DAILY_CUBE.md` and `SAFETY_PROFILE_INVARIANT_MAP.md` for `src_next`.
4. Update Go editor usage docs for current post-check and `journal reverse`.
5. Decide whether `tools/report-next*` wrappers should remain, and if yes, update their help text.

## Commands used

```bash
rtk git status --short
sqz ./tools/check.sh        # failed: sqz subcommand CLI
rtk ./tools/check.sh        # failed: permission denied
rtk bash ./tools/check.sh   # PASS
find src_next -maxdepth 1 -type f | sort
find checks -maxdepth 1 -type f | sort
find tools -maxdepth 2 -type f | sort
find fixtures -maxdepth 1 -type d | sort
find tests -maxdepth 1 -type f | sort
rg "check-docs-drift|lint_cli|lint_journal|check-cube-shape|check-forecast-zero|forecast-zero|report_tx_updates|report_engine|src/reports|export-section-status|check-section-status|check-tx-updates" README.md AGENTS.md TODO.md docs src src_next tools tests fixtures
rg "post-check|lint_cli|tools/check|report" editor tools/add-ui.sh docs/GO_EDITOR_USAGE.md docs/GO_EDITOR_NEXT_PLAN.md
```
