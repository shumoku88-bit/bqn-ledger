# Editor Go Removal Plan

Status: design scaffold / no runtime behavior change

This document defines the direction for removing the Go editor from the daily write path while preserving the current interactive workflow.

## Goal

Move the daily edit path from:

```text
add-ui.sh / tools/edit -> Go editor -> source TSV
```

toward:

```text
add-ui.sh / tools/edit -> BQN edit intent -> shell safe-write -> source TSV
```

The intended result is not a one-binary application. The intended result is a BQN-centered ledger where shell remains a thin Unix layer for terminal UI and safe file operations.

## Non-goals

- Do not change the source TSV contract in this step.
- Do not change report output in this step.
- Do not replace `tools/add-ui.sh` in this step.
- Do not make BQN perform unchecked direct writes to source TSV files.
- Do not remove the existing Go editor until command compatibility is covered by tests.

## Current split

The current interactive input path already has a useful split:

- `tools/add-ui.sh` handles mode selection, fuzzy selection, text input, and display.
- `tools/edit` delegates to the Go editor for safe TSV append/edit operations.
- BQN handles report and model derivation elsewhere.

This plan keeps the first part stable and replaces the Go editor from underneath the existing `tools/edit` command surface.

## Target responsibility boundary

### `tools/add-ui.sh`

Keeps the existing user-facing interaction:

- mode selection
- account selection
- date selection
- memo and amount input
- fzf / gum / numbered fallback behavior

It should continue to call `tools/edit` rather than learning TSV write details.

### `tools/edit`

Becomes a shell dispatcher with the same CLI shape as the current Go editor.

Required compatibility surface:

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

### `src_edit/`

Owns BQN edit logic:

- parse command-level edit inputs after shell dispatch
- generate candidate TSV rows
- validate date / amount / account / metadata contracts
- generate edit operations or complete candidate file content
- provide machine-readable output for the shell write layer

`src_edit/` must not become the report engine. Report derivation stays outside the editor subsystem.

### `tools/lib/`

Owns shell-level file safety:

- backup
- temporary file creation
- append or replace application
- stale checks where needed
- post-write validation command invocation

Shell should not contain accounting semantics beyond path selection and file safety.

## Safety model

The replacement path should preserve or improve the safety properties of the Go editor:

1. Build the candidate row or edit operation.
2. Validate the candidate before touching source TSV.
3. Apply through a small shell safe-write function.
4. Run post-checks after write.
5. Keep large corrections visible rather than hiding them behind silent mutation.

BQN should be the place where ledger meaning is checked. Shell should be the place where bytes are moved safely.

## Migration phases

### Phase 1: scaffold

- Add `src_edit/` as the BQN editor subsystem boundary.
- Add this plan.
- No behavior change.

### Phase 2: append-only commands

Implement CLI-compatible replacements for low-risk append commands:

- `journal add`
- `budget add`
- `plan add`
- `issue add`

Keep the Go editor available as the fallback until tests cover parity.

### Phase 3: read/list commands

Implement:

- `plan list --format tsv`
- `plan list --format text`

The `--format tsv` output must remain compatible with `tools/add-ui.sh`, including the display field used for plan selection.

### Phase 4: derived edit commands

Implement:

- `plan finish`
- `plan edit`
- `journal reverse`

These commands need stronger parity checks because they derive new source data from existing source rows.

### Phase 5: dispatcher switch

Change `tools/edit` from Go build wrapper to shell dispatcher once all required commands are implemented and checked.

### Phase 6: remove Go requirement

Only after the dispatcher switch is stable:

- remove Go from required dependencies
- update `tools/add-ui.sh --check`
- archive or remove the old `editor/` implementation

## Acceptance criteria for removing Go from daily use

- `tools/add-ui.sh` still works for existing interactive modes.
- `tools/edit` command compatibility is preserved for daily commands.
- `tools/check.sh` passes.
- No source TSV format changes are required.
- README no longer needs Go as a required dependency for normal daily use.
- The Go editor is either archived as legacy or removed after equivalent coverage exists.
