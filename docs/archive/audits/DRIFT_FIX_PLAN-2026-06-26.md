# Docs / Implementation Drift Fix Plan 2026-06-26

Status: completed / Batch 1-6 applied
Date: 2026-06-26
Source audit: `docs/DRIFT_AUDIT-2026-06-26.md`

## Goal

Fix the highest-risk docs/implementation drift found by the 2026-06-26 audit, without touching source TSV.

Priority is to remove false confidence and wrong work instructions before doing larger docs hygiene.

## Non-goals

- Do not edit `data/journal.tsv`, `data/plan.tsv`, `data/budget_alloc.tsv`, or `data/accounts.tsv`.
- Do not widen Go editor write scope.
- Do not rewrite all historical docs in one pass.
- Do not delete archive / historical docs during this fix plan.
- Do not install new tools.

## Acceptance criteria

- P1 drift items from `docs/DRIFT_AUDIT-2026-06-26.md` are either fixed or explicitly downgraded with rationale.
- `rtk bash ./tools/check.sh` passes after code/script changes.
- If only docs are changed, at minimum `rtk git diff` is reviewed.
- Source TSV files remain untouched.

---

## Batch 1: command/check truth and entrypoint truth

Purpose: prevent pit from running the wrong command or trusting checks that are not actually gating.

- [x] Fix check command guidance.
  - Docs currently imply `sqz <command>` works as a prefix.
  - Current local `sqz` is stdin/subcommand based; `rtk bash ./tools/check.sh` is the working command.
  - Updated active guidance to prefer `rtk bash ./tools/check.sh` and document `sqz compress` pipe usage.
- [x] Decide Go test gating in `tools/check.sh`.
  - Applied Option A: removed `|| true` so Go editor tests are required.
  - Added an explicit dependency-linter legacy exception for the current `outlook.bqn` → `envelope_computation.bqn` coupling so the existing code path is visible and the test suite can gate again.
- [x] Fix `AGENTS.md` check path.
  - Current drift: `./checks/check.sh` does not exist.
  - Target: `./tools/check.sh`, usually via `rtk bash ./tools/check.sh` in pit environments.
- [x] Fix BQN-only path wording in `AGENTS.md`.
  - Current engine path is `src_next/**/*.bqn`.
  - `src/` now contains checks, not the canonical engine.
- [x] Fix `tools/report-next` and `tools/report-next-summary` help/comments.
  - Root `main.bqn` is deleted.
  - Production default is `tools/report` / `src_next/report.bqn`.

Check result:

```bash
rtk bash -lc 'cd editor && go test ./...'
rtk bash ./tools/check.sh
```

Both passed after Batch 1 changes.

## Batch 2: current entry docs and historical docs boundary

Purpose: stop current docs from sending readers to old-engine maps as if they are current.

- [x] Update `README.md` Documentation map.
  - `docs/MAIN_SECTIONS.md` and `docs/REPORT_FIELD_MAP.md` are historical/superseded.
  - Do not present them as current `tools/report` / `src_next` section docs.
- [x] Update `AGENTS.md` report-change rule.
  - Replace old `report_engine` / `main` update rule with a `src_next/report.bqn` / current section docs rule.
  - If no current section map exists, say to update `docs/AI_CODEMAP.md` and create/update a src_next section map as part of the change.
- [x] Reconcile old-engine plan status.
  - `TODO.md` says completed.
  - `docs/OLD_ENGINE_REMOVAL_PLAN.md` says in progress.
  - `docs/README.md` lists it as Active.
  - Target: mark old engine removal completed and move it out of Active.
- [x] Reconcile report screen review status.
  - `TODO.md` and `docs/REPORT_SCREEN_REVIEW_LOOP.md` say mock review completed.
  - `docs/README.md` still lists it Active.
  - Target: move to Done / Current Baseline or implementation backlog wording.

Suggested check:

```bash
rtk git diff -- README.md AGENTS.md TODO.md docs/README.md docs/OLD_ENGINE_REMOVAL_PLAN.md
```

## Batch 3: Safety / Cube docs false-confidence cleanup

Purpose: remove references to removed old-engine checks that imply invariants are guarded when they may not be.

- [x] Refresh `docs/CANONICAL_DAILY_CUBE.md` implementation section.
  - Replaced old implementation references with current `src_next` modules/checks.
  - Preserved the core contract: `Day × Account × Layer`, dynamic account count, 4 layers.
- [x] Re-audit `docs/SAFETY_PROFILE_INVARIANT_MAP.md` against current files.
  - Current check inventory is `tools/check.sh`, `checks/check-src-next-*`, and `tests/test_src_next_*.bqn`.
  - Removed old-engine guards are now explicitly described as historical/non-current.
- [x] Replace `256 accounts` invariant wording with dynamic account-axis wording.
- [x] Update `docs/REPORT_SECTION_STATUS_POLICY.md` implementation status.
  - Old implementation path is historical.
  - Current `src_next` section status behavior is documented as partial / section-specific key-value output.

Suggested check:

```bash
rg "report_tx_updates|report_engine|check-tx-updates|lint_cli|lint_journal|check-cube-shape|check-forecast-zero|export-section-status|check-section-status|256 accounts" docs/CANONICAL_DAILY_CUBE.md docs/SAFETY_PROFILE_INVARIANT_MAP.md docs/REPORT_SECTION_STATUS_POLICY.md
```

## Batch 4: Go editor usage truth

Purpose: keep write-capable tool docs aligned with actual safety behavior.

- [x] Update `docs/GO_EDITOR_USAGE.md` post-check description.
  - Current implementation for `--post-check lint`: `bqn src_next/report.bqn <base>`.
  - Current implementation for `--post-check full`: `./tools/check.sh`.
  - `checks/lint_cli.bqn` no longer exists.
- [x] Document `journal reverse` in `docs/GO_EDITOR_USAGE.md`.
  - Include `--id <txn_id>` and `--index <number>` forms.
  - Mention that it appends a reversing journal row through the same safe append path.
- [x] Update `docs/GO_EDITOR_NEXT_PLAN.md` current allowed scope to include `journal reverse`.
- [x] Confirm `tools/add-ui.sh` reverse mode is documented in `docs/GO_EDITOR_USAGE.md` daily mode list.

Suggested check:

```bash
rtk bash -lc 'cd editor && go test ./...'
rtk bash ./tools/check.sh
```

## Batch 5: UI/report command drift

Purpose: keep user-facing report navigation aligned with actual report output.

- [x] Decide Trial Balance in `tools/main-ui.sh`.
  - `src_next/report.bqn` prints Trial Balance.
  - `docs/REPORT_SCREEN_CANDIDATES.md` says Trial Balance adopted.
  - Added a `trial-balance` selector and marker.
- [x] Review `tools/report-next` and `tools/report-next-summary` names.
  - Updated help text in Batch 1 so they are diagnostic wrappers over current `src_next`, not experimental replacement for deleted `main.bqn`.

Suggested check:

```bash
rtk bash ./tools/check.sh
```

## Batch 6: missing/deleted helper docs

Purpose: stop docs from advertising tools that no longer exist.

- [x] Update or remove current references to `tools/sqz-report`.
  - `docs/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md` now marks `tools/sqz-report` as historical/removed from the current tree.
  - Actual file is absent.
- [x] Decide whether `sqz-report` is intentionally deleted, replaced by another command, or should be restored in a separate tool-only task.
  - Current decision: treat as removed; use `tools/report-next-summary`, `rtk`, or `sqz compress` pipe usage. Restoration requires a separate tool-only task.
- [x] Mark repo-index design examples that refer to old `src/reports/*` as historical, or refresh them to current `src_next` paths.
  - Added stale-example notes to `docs/REPO_INDEX_DESIGN.md` and `docs/REPO_INDEX_IMPLEMENTATION_HANDOFF.md`.

Suggested check:

```bash
rg "sqz-report|src/reports|lint_cli|export-report-numbers" docs/AI_CODEMAP.md docs/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md docs/REPO_INDEX_DESIGN.md docs/REPO_INDEX_IMPLEMENTATION_HANDOFF.md
```

---

## Recommended order

1. Batch 1
2. Batch 2
3. Batch 4
4. Batch 5
5. Batch 3
6. Batch 6

Rationale:

- Batch 1 and 2 fix the instructions pit follows before touching anything else.
- Batch 4 concerns write-capable tooling, so it is high safety value.
- Batch 5 is small and user-facing.
- Batch 3 is important but may be larger because invariant maps need careful re-audit.
- Batch 6 may require decisions about deleted helper tools and historical design docs.
