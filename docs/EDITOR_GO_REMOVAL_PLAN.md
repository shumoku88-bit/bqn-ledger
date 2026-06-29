# Editor Go Removal Plan

Status: design scaffold / no runtime behavior change

This document defines the direction for removing the Go editor from the daily write path while preserving the current interactive workflow.

## Direction and Scope

For the complete architectural direction, responsibility boundaries, command classes, and the production switch gate, see [PRODUCTION_EDITOR_DIRECTION.md](PRODUCTION_EDITOR_DIRECTION.md).

The primary goal of this transition is not merely removing Go. Rather, the goal is to make BQN the editor meaning layer while shell remains the safe write layer. Go removal is a consequence of production editor readiness, not the primary design goal.

Production editor contract: see `docs/PRODUCTION_EDITOR_DESIGN.md` for the responsibility boundary, command classes, Edit Plan Protocol v1, exact replace safety, and production switch gate.

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

## Expected lightness

This direction may make daily input lighter, but only if the replacement stays small.

The current `tools/edit` wrapper builds the Go editor before executing it:

```text
cd editor && go build -o tools/edit.bin .
```

Removing that step should reduce the startup cost of daily edit commands and remove the Go toolchain from normal daily use.

The intended lightness gains are:

- no `go build` during each `tools/edit` invocation
- fewer required daily dependencies
- a thinner command path for append-style edits
- a clearer BQN-centered project shape for BQN users

This is not automatic. The BQN + shell replacement must avoid becoming heavier than the Go editor it replaces.

Keep the replacement path small:

- invoke BQN at most once per edit command where practical
- avoid repeatedly rereading the same TSV files in one command
- keep shell focused on dispatch and file safety
- keep accounting validation in BQN rather than spreading it across many shell fragments
- keep heavy checks for explicit check commands, not every small append

The target is a lighter daily path, not a larger shell system wearing a BQN hat.

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

## Narrow implementation gate

After the first BQN + shell prototype, the next implementation step must stay narrower than full editor replacement.

Do not switch production `tools/edit` yet. Keep it on the Go editor until the BQN path proves at least one end-to-end safe append with tests.

The first implementation gate is:

```text
tools/edit-bqn journal add --dry-run
```

then:

```text
tools/edit-bqn journal add --yes --post-check none
```

Rules for this gate:

- `tools/edit` remains the Go fallback.
- `tools/edit-bqn` is the experimental BQN + shell entry point.
- Only `journal add` is in scope for the first end-to-end write.
- Bash parses the Go-compatible flags and passes normalized edit intent to BQN.
- BQN validates and renders an append operation.
- BQN errors must exit non-zero.
- BQN output must separate protocol metadata from TSV payload.
- `tools/lib/safe-write.sh` applies the append with backup, temp-file + atomic rename, and stale detection before rename.
- `--dry-run` must not create a backup or modify source TSV.
- Parity is measured first by resulting TSV bytes, then by exit codes, then by stdout/stderr compatibility.

The append protocol is line-oriented and must avoid mixing status and TSV fields in one tab-separated line:

```text
OK	APPEND	journal.tsv
<complete TSV row>
```

Protocol rules:

- Line 1 is protocol metadata only.
- Line 2 is the complete TSV row payload. It may contain tabs, so the shell dispatcher must treat it as an opaque payload line.
- Validation errors are a single `ERROR	<message>` line and must exit non-zero.
- Non-protocol diagnostics go to stderr.

This gate prevents the replacement from becoming a large BQN editor black box before the smallest daily write path is trustworthy.

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
