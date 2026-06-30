# src_edit

Status: current BQN editor subsystem

`src_edit/` is the BQN editor subsystem that powers the daily write path.

- `src_edit` validates edit intent and renders machine-readable write operations.
- `tools/edit-bqn` is the active BQN + shell entry point.
- `tools/edit` is the stable public wrapper.

## Purpose

This directory turns edit intent into validated ledger edit operations.

It is separate from report code on purpose:

```text
src_next/   read source TSV -> derive model/report
src_edit/   receive edit intent -> validate/render edit operation
tools/lib/  safely apply bytes to source TSV
```

The editor subsystem should not make reports, and the report subsystem should not mutate source data.

## Intended command surface

The public surface remains `tools/edit`.
`src_edit/` is called behind that wrapper and preserves the current command shapes:

```text
tools/edit journal add ...
tools/edit journal list --format tsv
tools/edit journal reverse ...
tools/edit account list [--role ROLE]
tools/edit budget add ...
tools/edit plan list --format tsv
tools/edit plan related ... --actual-date YYYY-MM-DD --format tsv
tools/edit plan add ...
tools/edit plan finish ... --apply
tools/edit plan edit ...
tools/edit issue add ...
```

## Responsibility

BQN code here may:

- validate command inputs
- read source TSV files needed to understand an edit
- render candidate TSV rows
- render machine-readable edit operations
- reject invalid dates, amounts, accounts, metadata, and plan selectors

BQN code here must not silently overwrite source TSV files. The shell write layer applies validated output through explicit safe-write helpers.

## Command surface notes

Dispatcher boundary note: see `docs/EDIT_BQN_DISPATCHER.md` for the current shell command groups and extraction rule.

- `account list` is a read-only account candidate export for UI shell wrappers; account role metadata interpretation stays in BQN.
- `journal list` is a read-only journal row export for reverse-selection UI; journal row formatting and empty-column preservation stay in BQN.
- `journal reverse` is handled by `src_edit/journal_reverse_cmd.bqn`; reverse-row validation and APPEND protocol rendering stay in BQN.
- `issue add` has a small dedicated parser because its CLI and new-file semantics differ; its shell handler is split into `tools/lib/edit-bqn-issue.sh`.
- `plan add` owns plan_id generation and duplicate checks.
- `plan list` is byte-parity checked because its TSV output is a UI selection contract.
- `plan related` is read-only and owns recurring-plan relation-key semantics for replenishment UI.
- `plan finish`, `plan edit`, and `journal reverse` use derived edit protocols.
- `plan edit` is handled by `src_edit/plan_edit_cmd.bqn`; line selection, closed-plan rejection, date/amount validation, and REPLACE protocol rendering stay in BQN.

## Safety rule

`tools/edit-bqn` and `src_edit/` are the current daily write path. Keep the boundary small, predictable, and shell-safe.
