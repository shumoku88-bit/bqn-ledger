# Edit BQN Handoff

Status: active handoff note
Date: 2026-06-29

This note summarizes the current Go editor removal / BQN editor replacement state for the next pit.

## Current state

- Production `tools/edit` still uses the Go editor.
- Experimental `tools/edit-bqn` exists, but only supports:

```text
tools/edit-bqn journal add --dry-run
tools/edit-bqn journal add --yes --post-check none
```

- The narrow path is intentionally command-specific for now. Do not grow it into a large dispatcher by copy-paste.
- `src_edit/journal_add_cmd.bqn` validates and renders the append operation.
- Shell applies the append through `tools/lib/safe-write.sh`.

## Protocol

Successful append output from BQN is two lines:

```text
OK	APPEND	journal.tsv
<complete TSV row>
```

Rules:

- Line 1 is protocol metadata only.
- Line 2 is the complete TSV payload and must be treated as opaque by shell.
- Validation errors use `ERROR	<message>` and exit non-zero.
- Non-protocol diagnostics must go to stderr.

## Safety currently covered

`checks/check-edit-bqn-journal-add.sh` is connected to `tools/check.sh` and covers:

- dry-run does not modify `journal.tsv`
- dry-run does not create backup files
- positive resulting TSV byte parity with Go editor
- negative fail-closed cases leave `journal.tsv` unchanged and create no backup
- stale write simulation fails without appending the candidate row

`tools/edit-bqn journal add` captures a pre-validation/pre-preview snapshot and writes via `safe_append_checked`, which checks the same snapshot before backup creation and again immediately before atomic rename.

## Important boundaries

Do not:

- switch production `tools/edit` yet
- remove Go editor yet
- implement all 8 commands at once
- directly edit source TSV data during pit work
- parse the TSV payload line as protocol fields
- use `EDIT_BQN_TEST_BEFORE_APPEND_HOOK` outside tests

Before adding a second command, decide whether to extract shared helpers for:

- Go-compatible flag parsing
- BQN command invocation
- protocol parsing
- safe append wiring

## Suggested next steps

1. Add more positive `journal add` parity cases:
   - empty memo
   - multiple `--meta`
   - Japanese memo/account values
   - append to a file without trailing newline
2. Then consider `budget add` as the next append-only command.
3. Before `plan edit` / `plan finish`, design a replace API with exact `oldLine` assertion.

## Related files

- `TODO.md`
- `docs/EDITOR_GO_REMOVAL_PLAN.md`
- `docs/archive/active-plans/GO_BQN_GAP_ALIGNMENT_PLAN.md`
- `src_edit/README.md`
- `tools/edit-bqn`
- `src_edit/journal_add_cmd.bqn`
- `tools/lib/safe-write.sh`
- `checks/check-edit-bqn-journal-add.sh`
