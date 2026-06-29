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

Start with the smallest safe surfaces before derived edits:

1. `journal add`
2. `budget add`
3. `issue add`
4. `plan list --format tsv` / `--format text` — read-only, but `tools/add-ui.sh plan-finish` and `plan-edit` rely on the exact 9-field TSV interface
5. `plan add`

Append-only commands are now covered in the experimental path. Next move to derived edits (`plan finish`, `plan edit`, `journal reverse`) after exact replace/oldLine safety is designed.

## Experimental narrow entry point

`tools/edit-bqn` is the experimental BQN + shell entry point for proving append paths before replacing the Go editor. Current scope is intentionally limited:

```text
tools/edit-bqn journal add --dry-run
tools/edit-bqn journal add --yes --post-check none
tools/edit-bqn budget add --dry-run
tools/edit-bqn budget add --yes --post-check none
tools/edit-bqn issue add --dry-run
tools/edit-bqn issue add --yes
tools/edit-bqn plan list --format tsv
tools/edit-bqn plan list --all --format tsv
tools/edit-bqn plan add --dry-run
tools/edit-bqn plan add --yes --post-check none
```

The BQN append commands (`src_edit/journal_add_cmd.bqn`, `src_edit/issue_add_cmd.bqn`, `src_edit/plan_add_cmd.bqn`) emit a two-line append protocol:

```text
OK	APPEND	<target-file>
<complete TSV row>
```

Validation errors use `ERROR	<message>` and exit non-zero. The shell dispatcher treats the second line as an opaque TSV payload and applies writes through `tools/lib/safe-write.sh`.

Anti-ad-hoc guard: this narrow path now supports append-only commands through explicit shared boundaries in `tools/edit-bqn`, plus read-only `plan list`. `journal add` / `budget add` share the journal-like path; `plan add` has a dedicated BQN command because it owns plan_id generation and duplicate checks; `issue add` has a small dedicated parser because its CLI and new-file semantics differ. `plan list` is byte-parity checked against Go because its TSV output is a UI selection contract. Do not grow it by copy-pasting branches; before derived edits, design the replace/oldLine boundary.

## Safety rule

Until the dispatcher switch is complete, the existing Go editor remains the authoritative daily write path. Files in `src_edit/` and `tools/edit-bqn` are not production write paths unless a later PR explicitly switches the daily path.
