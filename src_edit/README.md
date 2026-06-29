# src_edit

Status: scaffold only / not used by production commands yet

`src_edit/` is the future BQN editor subsystem for replacing the current Go editor while keeping the existing daily interactive workflow.

## Purpose

This directory is for BQN code that turns edit intent into validated ledger edit operations.

It is separate from report code on purpose:

```text
src_next/   read source TSV -> derive model/report
src_edit/   receive edit intent -> validate/render edit operation
tools/lib/  safely apply bytes to source TSV
```

The editor subsystem should not make reports, and the report subsystem should not mutate source data.

## Intended command surface

The public surface remains `tools/edit`. `src_edit/` should be called behind that wrapper and should preserve the current command shapes:

```text
tools/edit journal add ...
tools/edit journal reverse ...
tools/edit budget add ...
tools/edit plan list --format tsv
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

## First implementation target

Start with append-only commands before derived edits:

1. `journal add`
2. `budget add`
3. `plan add`
4. `issue add`

Then add `plan list --format tsv`, because `tools/add-ui.sh plan-finish` and `plan-edit` rely on that exact interface.

## Safety rule

Until the dispatcher switch is complete, the existing Go editor remains the authoritative daily write path. Files in `src_edit/` are not production write paths unless a later PR explicitly wires them in.
