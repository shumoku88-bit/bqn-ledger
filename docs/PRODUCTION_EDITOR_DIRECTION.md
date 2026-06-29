# Production Editor Direction

## Status

- production direction / docs-only
- no runtime behavior change
- no tools/edit switch
- no Go removal
- no source TSV format change

## Decision

- `src_edit` is the future production editor subsystem.
- `tools/edit-bqn` is a staged candidate path before switching `tools/edit`.
- `tools/edit` remains the final public editor command surface.
- The current append-only implementation is not a toy experiment; it is the first production-directed stage.

Note: At this time, `tools/edit-bqn` is not yet the active production write path. The active production write path remains `tools/edit` / Go editor until an explicit switch PR.

## Editor Architecture

### `tools/add-ui.sh`
- Responsible for user interaction, mode selection, fzf / gum / numbered fallback, text input, and account selection.
- Calls `tools/edit`.
- Does not own TSV write semantics.

### `tools/edit`
- The final public command surface.
- Must preserve current command compatibility.
- Will eventually become a shell dispatcher to `src_edit`.
- Must not be switched in this PR.

### `tools/edit-bqn`
- The staged candidate entry point.
- Used to prove the BQN + shell editor path.
- Must not grow ad-hoc branches without design.
- Should be removed, folded, or retired after the `tools/edit` switch is complete.

### `src_edit`
- Validates edit intent.
- Reads source TSV only when needed for edit meaning.
- Renders edit plans or append operations.
- Owners of ledger meaning for edit commands.
- Must not directly write source TSV files.
- Must not become the report engine.

### `tools/lib/safe-write.sh`
- Responsible for backup, temp files, atomic rename, stale checks, expected old row checks for future replace operations, and post-check invocation.
- Must not own ledger/accounting meaning.

## Command Classes

We classify current and future commands as follows:

### Append-Only (Low Risk)
- `journal add`
- `budget add`
- `plan add`
- `issue add`
These commands only append new data, making them lower risk.

### Read-Only Selector
- `plan list`
Provides display fields used for plan selection.

### Derived Append
- `plan finish`
- `journal reverse`
Appends a row derived from an existing row.

### Exact Replace
- `plan edit`
Replaces an existing row.

Append-only commands are lower risk, but derived append and exact replace require a stronger edit plan protocol before implementation.

## Required Next Boundary Before Derived Edits

Before implementing `plan finish`, `plan edit`, or `journal reverse`, we must design the replace/oldLine/edit plan boundary.

This must include:
- Expected target file.
- Expected line number where relevant.
- Expected old row exact match.
- Snapshot token: size / mtime / sha256.
- Stale check before backup.
- Stale check again immediately before rename.
- Backup before write.
- Atomic temp-file rename.
- Post-check behavior.
- Restore suggestion on post-check failure.

## Plan Finish Semantics

`plan finish` must be a derived append, not a `plan.tsv` mutation.

It should:
- Read `plan.tsv`.
- Identify the selected plan row.
- Confirm the source row still matches the expected old row.
- Append a `journal.tsv` row with `plan_id` metadata.
- Not delete or rewrite the plan row.
- Rely on report semantics to treat the plan as completed when a matching journal row exists.

## Journal Reverse Semantics

`journal reverse` must be a derived append.

It should:
- Read the original `journal.tsv` row.
- Confirm the source row still matches the expected old row.
- Append a reversal row to `journal.tsv`.
- Not mutate the original journal row.

## Plan Edit Semantics

`plan edit` is an exact replace.

It should:
- Replace exactly one row in `plan.tsv`.
- Require the line number plus the expected old row exact match.
- Fail closed if the file changed (stale check failure).
- Never replace based only on the line number.

## Production Switch Gate

`tools/edit` must not switch from Go to BQN + shell until all of the following are true:
- Append-only commands are covered.
- `plan list` compatibility is covered.
- Derived append design exists.
- Exact replace design exists.
- `plan finish` has tests.
- `plan edit` has tests.
- `journal reverse` has tests.
- `tools/add-ui.sh` works through `tools/edit` without behavior regression.
- `tools/check.sh` passes.
- README can honestly remove Go from normal daily requirements, or clearly mark Go as legacy/fallback only.

## Language Guidance

Avoid framing `src_edit` as a loose experiment. Use language like:
- Staged production editor path
- Production-directed candidate path
- Future production editor subsystem
- Pre-switch candidate entry point
- Not yet the active production write path

Avoid language like:
- Toy
- Scratch
- Temporary hack
- Experimental editor (as the main identity)

It is acceptable to say `tools/edit-bqn` is not yet production. It is not acceptable to imply `src_edit` has no production destiny.
