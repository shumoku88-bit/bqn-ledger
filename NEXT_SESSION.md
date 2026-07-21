# Next session

Status: no finite-slice pointer selected
Owner: repository routing
Canonical: no; canonical routing: `TODO.md`
Exit: replace only when a new finite slice is explicitly selected; do not infer one from completed work

## Current state

Journal read-path trial-balance rehearsal and report-context rehearsal are complete as public-synthetic test-only work. Completion records:

- `docs/archive/completed-plans/JOURNAL_READ_PATH_TRIAL_BALANCE_REHEARSAL_PLAN-2026-07-21.md`
- `docs/archive/completed-plans/JOURNAL_READ_PATH_REPORT_CONTEXT_REHEARSAL_PLAN-2026-07-21.md`

The focused test reads the existing public native three-posting Journal fixture directly, preserves three Journal-derived Posting IR rows, passes them through `context.BuildPeriodView` (Rehearsal Context), and proves they successfully connect to `trial_balance.Build` and `balances.Build` (generating identical entries to the legacy TSV projection, as well as executing `balances.Format` and `balances.FormatHuman`). Stage 2A, Stage 2B, Stage 2C, and native three-posting semantic-coordinate parity also remain completed. No next finite Journal, report, or bookkeeping-study slice is selected.

## Still unselected

- production Journal loader or routing;
- writer/editor work;
- TSV-to-Journal conversion;
- shadow read or private-data comparison;
- source-of-truth cutover;
- `BuildContext`, report, Cube, or TBDS production changes;
- `source_row` consumer migration;
- broader parser red-path/rejection parity;
- bidirectional/reverse sync or conflict resolution;
- TSV cleanup or production source changes;
- any later Journal stage.

Return to `TODO.md` and select one finite slice explicitly before implementation.
