# TODO History (2026-07-01)

This document archives completed TODO sections from the main `TODO.md` file, keeping the active checklist focused on current and next work.

---

## Completed: PR #30 Audit Improvement Backlog

Status: complete as of 2026-07-01.

### Batch 1: Safety burrs

- Removed the test-only `eval` hook path from `tools/lib/safe-write.sh`.
- Replaced command-string hook execution with declared shell function hooks checked by `declare -F` and invoked directly.
- Updated `checks/check-safe-replace-line.sh` to verify function hook behavior.
- Added/kept checks to prevent accidental `eval` reintroduction in safe-write paths.

### Batch 2: Loader correctness

- Clarified required vs optional source-file behavior.
- Added coverage for missing optional files.
- Distinguished missing optional files from present-but-unreadable/broken files.
- Introduced strict optional-read behavior through loader helpers such as `ReadLinesOptional`.

### Batch 3: Dispatcher boundary

- Documented `tools/edit-bqn` command groups in `docs/EDIT_BQN_DISPATCHER.md`.
- Extracted shared shell helpers into `tools/lib/edit-bqn-common.sh`.
- Extracted the small `issue add` handler into `tools/lib/edit-bqn-issue.sh`.
- Kept test hooks as declared shell function calls, not `eval`.

### Batch 4: Date spine

- Added `tests/test_src_next_date.bqn` for date contract coverage.
- Centralized date validation/conversion helpers in `src_next/date.bqn`:
  - `IsValidDateText`
  - `DaysFromEpoch`
  - `FromDaysFromEpoch`
  - `AddDays`
- Reduced duplicate date logic in `projection.bqn`, `src_edit/validate.bqn`, and `actual_comparison.bqn`.

### Batch 5: Shell/BQN boundary polishing

- Added `docs/archive/audits/SHELL_BQN_BOUNDARY_AUDIT-2026-06-30.md` to classify shell reads/parses.
- Moved `tools/add-ui.sh` account role candidates from direct `accounts.tsv` parsing to BQN editor export:
  - `tools/edit account list --role ...`
  - backed by `src_edit/account_list_cmd.bqn`.
- Moved `tools/add-ui.sh` reverse selection from direct `journal.tsv` parsing to BQN editor export:
  - `tools/edit journal list --format tsv`
  - backed by `src_edit/journal_list_cmd.bqn`.
- Added `checks/check-edit-bqn-journal-list.sh` for read-only behavior, TSV shape, fail-closed invalid format, and empty memo preservation.

### Batch 6: Report section contract checklist

- Added `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md`.
- Defined a checklist for section identity, data ownership, empty-state behavior, status/diagnostics, labels, machine output, and fixture/check coverage.
- Applied the checklist to one reference section: `planned` / `src_next/planned_payments.bqn`.
- Linked the checklist from `docs/REPORT_CONTRACTS.md`, `docs/README.md`, and `docs/AI_CODEMAP.md`.

### Final verification

- `rtk bash ./tools/check.sh` passed.
- `tools/repo-index --baseline` was refreshed after new files were added.
- Committed as `78b8fd1 refactor: finish PR 30 audit follow-ups`.

---

## Completed: editor boundary cleanup (tools/edit-bqn / add-ui / src_edit)

Status: complete as of 2026-07-01.

Goal: keep the daily write path stable while reducing responsibility drift between shell UI/orchestration and BQN validation/meaning.

Completed decisions and implementation batches:

- Extended the shell/BQN boundary audit with the remaining `tools/edit-bqn` and `tools/add-ui.sh` responsibilities.
- Planned the three write-path families explicitly:
  - append protocol
  - replace protocol
  - read-only export/list protocol
- Extracted BQN-command-independent shell helpers for protocol parsing, preview/confirmation, safe-write orchestration, and post-check display.
- Moved common APPEND handling for journal/budget/plan add, plan finish, journal reverse, and existing issue append paths onto the shared helper.
- Kept `issues.tsv` create-if-missing as the optional-file exception, while aligning backup/write-result/post-check observability.
- Clarified that `tools/add-ui.sh` may attach `series=` as UI-only input convenience; related-plan matching and fallback order remain owned by `src_edit/plan_related_cmd.bqn`.
- Chose BQN narrow command conversion order and implemented the safe first cuts:
  - `src_edit/journal_reverse_cmd.bqn`
  - `src_edit/plan_edit_cmd.bqn`
- Removed the old aggregate `src_edit/editor_cmd.bqn`; current write path is the narrow command set plus shell safe-write helpers.

Verification:

- `rtk bash checks/check-edit-bqn-plan-edit.sh` passed.
- `rtk bash checks/check-edit-bqn-journal-reverse.sh` passed.
- `rtk bash ./tools/check.sh` passed.

---

## Completed: real-data trial safety observation

Status: complete as of 2026-06-30.

- Added `docs/REAL_DATA_TRIAL_SAFETY.md` with sandbox rehearsal, real-data preflight, dry-run, confirmation write, and observation logging guidance.
- Ran sandbox rehearsal for `tools/doctor`, `tools/report`, `tools/add-ui.sh --check`, and editor dry-run behavior.
- Ran read-only real-data preflight for `tools/doctor`, `tools/report`, and `tools/add-ui.sh --check`.
- Performed the first real-data write only after dry-run and human confirmation, using a harmless `real-data-trial-delete-me` entry.
- Observed backup creation, post-check success, and report recovery after human cleanup.
- Ran several temp-copy sandbox writes to observe base dir, backup, post-check, and report drift behavior.
- Closed additional real-data observation as a TODO; future safety improvements should come from actual defects or specific requests.

---

## Completed: plan finish replenishment helper follow-up

Status: complete as of 2026-06-30.

- Verified `tools/plan-finish-replenish-ui.sh` under default and `BQN_EDITOR=1` environments.
- Added/used `checks/check-plan-finish-replenish-ui.sh` preflight coverage.
- Verified replenish/extend behavior in temp sandbox with dry-run-like interaction.
- Confirmed `series=...` inheritance and related-plan resolution order:
  1. explicit `series=` metadata
  2. `plan_id=plan-YYYY-MM-DD-<series>` derived series
  3. exact fallback by memo/from/to/amount
- Implemented related future plan listing before replenishment.
- Kept source TSV schema and low-level `plan finish` / `plan add` behavior unchanged.

---

## Completed / mostly closed: CI and workflow drift stabilization

Status: active guard remains; completed work archived here.

- Kept `checks/check-workflow-drift.sh` as the guard against stale Go/editor assumptions in GitHub Actions workflows.
- Added CBQN policy guard coverage.
- Synced CI CBQN behavior with `docs/CBQN_REPRODUCIBILITY.md`: CI tracks `CBQN_REF: master` and logs the exact commit.
- Active reminder left in `TODO.md`: when workflow/docs/check behavior changes, verify both `tools/check.sh` and GitHub Actions.
