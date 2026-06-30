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
