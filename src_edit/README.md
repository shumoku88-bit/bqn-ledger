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
3. `issue add`
4. `plan add`

Then add `plan list --format tsv`, because `tools/add-ui.sh plan-finish` and `plan-edit` rely on that exact interface.

## Experimental narrow entry point

`tools/edit-bqn` is the experimental BQN + shell entry point for proving append paths before replacing the Go editor. Current scope is intentionally limited:

```text
tools/edit-bqn journal add --dry-run
tools/edit-bqn journal add --yes --post-check none
tools/edit-bqn budget add --dry-run
tools/edit-bqn budget add --yes --post-check none
tools/edit-bqn issue add --dry-run
tools/edit-bqn issue add --yes
```

The BQN commands (`src_edit/journal_add_cmd.bqn`, `src_edit/issue_add_cmd.bqn`) emit a two-line append protocol:

```text
OK	APPEND	<target-file>
<complete TSV row>
```

Validation errors use `ERROR	<message>` and exit non-zero. The shell dispatcher treats the second line as an opaque TSV payload and applies writes through `tools/lib/safe-write.sh`.

Anti-ad-hoc guard: this narrow path now supports append-only commands through explicit shared boundaries in `tools/edit-bqn`. `journal add` / `budget add` share the journal-like path; `issue add` has a small dedicated parser because its CLI and file creation semantics differ. Do not grow it by copy-pasting branches; before adding `plan add`, review whether another shared boundary is needed.

## Safety rule

Until the dispatcher switch is complete, the existing Go editor remains the authoritative daily write path. Files in `src_edit/` and `tools/edit-bqn` are not production write paths unless a later PR explicitly switches the daily path.
