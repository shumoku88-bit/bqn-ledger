# edit-bqn dispatcher boundary

Status: current implementation note
Date: 2026-06-30

`tools/edit-bqn` is the BQN-backed editor entry point behind the stable public
`tools/edit` wrapper. It is intentionally a thin shell dispatcher: command-line
syntax, preview/confirmation, and safe-write orchestration live in shell; ledger
validation and TSV row/edit rendering live in `src_edit/*.bqn`.

## Command groups

| Group | Commands | Shell owner | BQN owner |
|---|---|---|---|
| account | `account list` | `tools/edit-bqn` read-only dispatch | `src_edit/account_list_cmd.bqn` |
| journal | `journal add`, `journal reverse` | `tools/edit-bqn` | `src_edit/journal_add_cmd.bqn`, `src_edit/editor_cmd.bqn` |
| budget | `budget add` | `tools/edit-bqn` shared journal-like append path | `src_edit/journal_add_cmd.bqn` |
| plan read | `plan list`, `plan related` | `tools/edit-bqn` read-only dispatch | `src_edit/plan_list_cmd.bqn`, `src_edit/plan_related_cmd.bqn` |
| plan write | `plan add`, `plan finish`, `plan edit` | `tools/edit-bqn` | `src_edit/plan_add_cmd.bqn`, `src_edit/plan_finish_cmd.bqn`, `src_edit/editor_cmd.bqn` |
| issue | `issue add` | `tools/lib/edit-bqn-issue.sh` | `src_edit/issue_add_cmd.bqn` |

## Shell helper boundary

Shared syntax-only helpers live in `tools/lib/edit-bqn-common.sh`:

- option value extraction
- `--post-check` mode validation
- preview mode naming (`confirm` / `dry-run` / `yes`)
- BQN command capture with stderr preservation
- test-only hook invocation by declared shell function name

These helpers must not inspect account names, source TSV business meaning, or
household policy. If a helper needs ledger meaning, move that decision into
`src_edit/` first and consume a machine-readable protocol from shell.

## Module extraction rule

When splitting a command out of `tools/edit-bqn`, extract one small command group
at a time. The extracted module should expose one handler function and continue
to use the same BQN protocol and `tools/lib/safe-write.sh` APIs. Do not create a
second write path.

Current reference extraction: `issue add` → `handle_edit_bqn_issue_add` in
`tools/lib/edit-bqn-issue.sh`.

Current boundary-polishing reference: `tools/add-ui.sh` account candidates use
`tools/edit account list [--role ROLE]` instead of reading `accounts.tsv`
directly.
