# Edit BQN Handoff

Status: active handoff note
Date: 2026-06-29

This note summarizes the current Go editor removal / BQN editor replacement state for the next pit.

## Current state

- Production `tools/edit` still uses the Go editor.
- Experimental `tools/edit-bqn` exists, supporting append-only commands plus read-only plan listing:

```text
tools/edit-bqn journal add --dry-run
tools/edit-bqn journal add --yes --post-check none
tools/edit-bqn budget add --dry-run
tools/edit-bqn budget add --yes --post-check none
tools/edit-bqn issue add --dry-run
tools/edit-bqn issue add --yes
tools/edit-bqn plan list --format tsv
tools/edit-bqn plan list --all --format tsv
tools/edit-bqn plan list --format text
tools/edit-bqn plan add --dry-run
tools/edit-bqn plan add --yes --post-check none
```

- The narrow path shares parsing/protocol/write handling for `journal add` and `budget add`; `plan add` has a dedicated BQN command because it owns plan_id generation and duplicate checks; `issue add` has a dedicated parser because its CLI and new-file semantics differ. `plan list` is read-only and byte-parity checked because `--format tsv` is a `tools/add-ui.sh` selection contract. Do not grow it into a large dispatcher by copy-paste.
- `src_edit/journal_add_cmd.bqn` / `src_edit/issue_add_cmd.bqn` validate and render append operations for the requested target file.
- Shell applies the append through `tools/lib/safe-write.sh`.

## Protocol

Successful append output from BQN is two lines:

```text
OK	APPEND	<target-file>
<complete TSV row>
```

Rules:

- Line 1 is protocol metadata only.
- Line 2 is the complete TSV payload and must be treated as opaque by shell.
- Validation errors use `ERROR	<message>` and exit non-zero.
- Non-protocol diagnostics must go to stderr.

## Safety currently covered

`checks/check-edit-bqn-journal-add.sh`, `checks/check-edit-bqn-plan-list.sh`, and `checks/check-edit-bqn-plan-add.sh` are connected to `tools/check.sh`.

`check-edit-bqn-journal-add.sh` covers:

- dry-run does not modify target TSVs (`journal.tsv`, `budget_alloc.tsv`, `issues.tsv`)
- dry-run does not create backup files
- positive resulting TSV byte parity with Go editor
- negative fail-closed cases leave target files unchanged or uncreated and create no backup
- stale journal write simulation fails without appending the candidate row

`check-edit-bqn-plan-list.sh` covers:

- Go stdout byte parity for `plan list --format tsv`, `--all --format tsv`, `--format text`, and `--all --format text`
- 9-field TSV shape required by `tools/add-ui.sh`
- read-only protection: no `plan.tsv` changes and no backups
- invalid `--format` fail-closed behavior

`check-edit-bqn-plan-add.sh` covers:

- resulting `plan.tsv` byte parity with Go for generated IDs, explicit IDs, collision suffixes, empty memo slug, and no-trailing-newline append
- dry-run protection: no `plan.tsv` changes and no backups
- negative fail-closed cases for `plan_id` metadata, invalid explicit ID, and unknown account

`tools/edit-bqn journal add` / `budget add` / `plan add` / existing-file `issue add` capture a pre-validation/pre-preview snapshot and write via `safe_append_checked`, which checks the same snapshot before backup creation and again immediately before atomic rename. Missing `issues.tsv` uses `safe_create_checked` to create the header plus candidate row without backup.

## Important boundaries

Do not:

- switch production `tools/edit` yet
- remove Go editor yet
- implement all 8 commands at once
- directly edit source TSV data during pit work
- parse the TSV payload line as protocol fields
- use `EDIT_BQN_TEST_BEFORE_APPEND_HOOK` outside tests

Before adding the next command, keep shared helpers explicit for:

- Go-compatible flag parsing
- BQN command invocation
- protocol parsing
- safe append wiring

## Suggested next steps

1. Design the derived-edit safety boundary for `plan finish` / `plan edit`: exact `oldLine` assertion, stale snapshot, and replace/append operation protocol.
2. Start sketching the black-box `checks/check-editor-parity.sh` harness now that append-only coverage is stable.
3. Implement `plan finish` before `plan edit` / `journal reverse` if keeping the current migration order.

## Related files

- `TODO.md`
- `docs/EDITOR_GO_REMOVAL_PLAN.md`
- `docs/archive/active-plans/GO_BQN_GAP_ALIGNMENT_PLAN.md`
- `src_edit/README.md`
- `tools/edit-bqn`
- `src_edit/journal_add_cmd.bqn`
- `src_edit/plan_list_cmd.bqn`
- `src_edit/plan_add_cmd.bqn`
- `tools/lib/safe-write.sh`
- `checks/check-edit-bqn-journal-add.sh`
- `checks/check-edit-bqn-plan-list.sh`
- `checks/check-edit-bqn-plan-add.sh`
