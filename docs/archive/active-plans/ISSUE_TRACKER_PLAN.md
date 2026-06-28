# Issue & Decision Tracker Plan

Status: planning / awaiting feedback  
Date: 2026-06-28  

This note describes the implementation of a lightweight issue and decision tracker for `bqn-ledger`.
It introduces a new source file `issues.tsv` to record financial pending items, decision logs, and subscription review statuses without polluting the core accounting ledger.

## Motivation

Household financial management often requires tracking pending decisions:
- "Should I keep my Amazon Prime subscription?" (due next month, cost 5,900 JST)
- "Should I migrate to a cheaper Wi-Fi plan?" (under consideration)
- "Whether to include future item X in the plan?"

Keeping these in a structured TSV file (`issues.tsv`) allows:
- Keeping them visible on daily reports (e.g., in the Snapshot or a dedicated section).
- Archiving old decisions (`status=resolved` or `status=dropped`) to preserve a history of financial decisions.
- Avoiding pollution of `journal.tsv` or `plan.tsv` with unconfirmed, date-less, or amount-less textual notes.

## Data Design (`issues.tsv`)

The new source file will be `<base>/issues.tsv`.

Format: Tab-separated values (TSV) with a header line.

Columns:
1. **`date`**: Creation date or target decision deadline (YYYY-MM-DD)
2. **`status`**: `open` / `resolved` (decision made) / `dropped` (cancelled/ignored)
3. **`title`**: Concise title of the issue (e.g., "Amazon Prime Review")
4. **`amount`**: Potential JST amount involved (e.g., `5900`, or `0` if not applicable)
5. **`memo`**: Detailed context (e.g., "Annual subscription due. Plan to move to monthly or cancel?")

Example:
```tsv
date	status	title	amount	memo
2026-06-28	open	Amazon Prime Review	5900	Keep annual subscription or cancel?
2026-06-28	resolved	Gym membership cancellation	0	Cancelled on 2026-06-25 to save cost.
```

## BQN Accounting Engine Changes

1. **Loader (`src_next/loader.bqn`)**:
   - Add loader logic for `issues.tsv`.
   - If the file is missing, it should fail-soft (default to empty rows) or warning/skipped to preserve backwards compatibility for bases without issues.
2. **Report Section (`src_next/report.bqn`)**:
   - Add a new section `issues` (labels: `懸案事項・意思決定`).
   - Only show `status=open` items in the active list.
   - For each item, display: `[date] title (amount) - memo`.
   - Update `--list-sections` in `report.bqn` and section mappings.

## Presentation Layer & UI Changes

1. **Main UI (`tools/main-ui.sh`)**:
   - Add `issues` to the `section_list` so it can be queried directly via `tools/main-ui.sh issues` and visible in `fzf` preview.
   - Add `issues.tsv` to the file watch list (`src_files`) in the cache hit detection logic.
2. **Command Hub (`tools/bl`)**:
   - Add `issues.tsv` to the `edit` subcommand file list so the user can quickly open and edit issues in `$EDITOR`.

## Verification Plan

- Create `fixtures/basic/issues.tsv` for golden verification.
- Update `check-src-next-golden.sh` or section verification scripts.
- Run `tools/check.sh` to ensure it passes all devtools/engine checks.
