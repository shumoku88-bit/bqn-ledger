# Go Source TSV Editor Design Decisions

Archive status: **historical design decisions digest**
Archived on: 2026-06-22
Source document: `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md`
Current status note: `docs/GO_SOURCE_TSV_EDITOR_DESIGN.status.md`
Current implementation boundary:

```text
docs/GO_EDITOR_NEXT_PLAN.md
```

This file preserves the useful current decisions from the original Go source TSV editor design draft without treating the old draft as implementation approval.

Do not use this file as the current TODO list.

## Reading rule

Use this file to understand historical design decisions about the Go source TSV editor boundary.

Use these files for current implementation work:

```text
docs/GO_EDITOR_NEXT_PLAN.md
docs/SAFE_WORKFLOW_REDESIGN.md
docs/GO_SOURCE_TSV_EDITOR_DESIGN.status.md
```

## Core boundary

```text
BQN = scale
Go  = gloves
```

BQN remains the canonical engine:

- read source TSV files,
- validate source data,
- build Event IR / Projection IR / Canonical Daily Cube,
- calculate balances, envelopes, cycle reports, residual views, and exports.

Go remains a source TSV editor:

- read source TSV files safely,
- preserve rows, comments, empty fields, and metadata,
- show lists / previews / diffs,
- perform approved writes with backup, atomic write, stale checks, and post-write BQN lint,
- never become a second accounting engine.

## Current approved implementation boundary

Approved / implemented now:

- `plan list`
- `plan list --all`
- `plan finish` preview and apply by appending to `journal.tsv`
- `journal add` single-file safe append
- `budget add` single-file safe append
- `tools/add-ui.sh` delegating daily append to Go by default
- fixture/tempdir-based tests

Still planning-only:

- additional source TSV write commands,
- non-append source-of-truth writes,
- multi-file transactions,
- deletion,
- TUI/editor expansion.

## Preserved safety decisions

- Go writes only to source TSV files when an operation is explicitly approved.
- Derived files such as `out/*.tsv`, reports, generated views, and expected outputs are not Go editor targets.
- Single-file writes use preview / confirm, atomic write, backup, stale check, and post-write lint.
- `.backup/` lives under the dataset root.
- Go may do lightweight input-UX checks, but final accounting correctness belongs to BQN lint/check.
- Go must not calculate balances, envelopes, cycle reports, residuals, or Canonical Daily Cube values.

## Preserved plan lifecycle decisions

- `plan_id` is an optional metadata key used to link plan rows and later journal actuals.
- `plan_id` is not a due-date marker.
- If `journal.tsv` contains the same `plan_id`, the plan is considered closed for open-plan views.
- Completed plans remain in `plan.tsv` for history / residual observation.
- `plan.tsv` is not rewritten during current `plan finish --apply`; the approved operation appends to `journal.tsv`.
- Missing `plan_id` rows remain a decision topic, not a reason to mutate data automatically.

## Explicitly not approved

- two-file updates involving both `journal.tsv` and `plan.tsv`,
- deleting rows from `journal.tsv` or `plan.tsv`,
- automatically adding `status=done` or `actual_date=...` to plan rows,
- adopting `plan_status.tsv`,
- adopting `cycle_instances.tsv`,
- making `cycle.tsv` append-only,
- operation-log-based source TSV regeneration,
- collapsing the source TSV set into a single `events.tsv`,
- balance calculation in Go,
- envelope calculation in Go,
- cycle report calculation in Go,
- residual / behavior-drift calculation in Go,
- Canonical Daily Cube reimplementation in Go.

## Remaining decisions

- When, if ever, to legacy/archive the old BQN `add.bqn` path.
- How far Go should read account role metadata for input assistance without making accounting decisions.
- Whether a TUI is needed at all.
- Whether `tview` should be browsing-only or editing-capable.
- Whether TUI editing may write source TSV files.

## Non-goals

- Do not edit source TSV data.
- Do not change BQN canonical engine responsibilities.
- Do not widen Go editor write scope without explicit approval.
- Do not treat the original design draft as current implementation approval.

## Future cleanup

A later docs hygiene pass may either:

1. move the full original design draft to archive if a safe full-file move is practical, or
2. replace `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md` with a short historical stub.

Until then, keep the original draft as long historical design context and use this digest for the current reading path.
