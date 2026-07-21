# Next session

Status: no finite-slice pointer selected
Owner: repository routing
Canonical: no; canonical routing: `TODO.md`
Exit: replace only when a new finite slice is explicitly selected; do not infer one from completed work

## Current state

Journal read-path trial-balance rehearsal, report-context rehearsal, and read-only source carrier rehearsal are complete as public-synthetic test-only work. Completion records:

- `docs/archive/completed-plans/JOURNAL_READ_PATH_TRIAL_BALANCE_REHEARSAL_PLAN-2026-07-21.md`
- `docs/archive/completed-plans/JOURNAL_READ_PATH_REPORT_CONTEXT_REHEARSAL_PLAN-2026-07-21.md`
- `docs/archive/completed-plans/JOURNAL_READ_ONLY_SOURCE_CARRIER_REHEARSAL_PLAN-2026-07-21.md`

The focused tests verify that:
1. The parser and Stage 2A adapter successfully build Posting IR rows from public synthetic Journal lines.
2. The read-only carrier module isolates parsing and adaptation under a single boundary, retains the caller-provided source identity only at the carrier result level, and preserves Stage 2A Posting IR rows unchanged.
3. Downstream Trial Balance and Balances report builders accept these rows and maintain legacy TSV parity evidence.

No next finite Journal, report, or bookkeeping-study slice is selected.

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
