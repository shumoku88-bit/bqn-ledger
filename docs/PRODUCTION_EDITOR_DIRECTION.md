# Production Editor Direction

## Status

- BQN editor production path is complete for the current daily commands.
- `tools/edit` is the stable public command surface and thin wrapper.
- `tools/edit-bqn` is the active BQN write path.
- `src_edit` is the BQN editor subsystem that validates edit intent and renders write operations.
- `tools/check.sh` includes the current BQN editor checks and unit coverage.

## Decision

- `src_edit` owns edit validation and protocol rendering.
- `tools/edit-bqn` owns daily editor dispatch and machine-readable write protocols.
- `tools/edit` stays as the user-facing shell entrypoint and delegates to `tools/edit-bqn`.
- No Go editor remains in the active daily write path.

## Editor architecture

### `tools/add-ui.sh`
- Responsible for user interaction, mode selection, fzf / gum / numbered fallback, text input, and account selection.
- Calls `tools/edit`.
- Does not own TSV write semantics.

### `tools/edit`
- Public command surface for daily editor operations.
- Preserves CLI compatibility for current commands.
- Delegates immediately to `tools/edit-bqn`.

### `tools/edit-bqn`
- Active BQN + shell editor entry point.
- Applies append and replace operations through validated machine-readable protocols.
- Must stay small and predictable; no ad-hoc business logic.

### `src_edit`
- Parses command-level edit intent.
- Validates date / amount / account / metadata contracts.
- Renders append rows, replace plans, or other edit operations.
- Must not become the report engine.

### `tools/lib/safe-write.sh`
- Responsible for backup, temp files, atomic rename, stale checks, expected old row checks, and post-check invocation.
- Must not own ledger/accounting meaning.

## Command classes

### Append-only
- `journal add`
- `budget add`
- `plan add`
- `issue add`

### Read-only selector
- `plan list`

### Derived append
- `plan finish`
- `journal reverse`

### Exact replace
- `plan edit`

Append-only commands are the lowest-risk path. Derived append and exact replace rely on explicit old-row / line-number safety.

## Safety model

1. Build the candidate row or edit operation.
2. Validate before touching source TSV.
3. Apply through a small shell safe-write function.
4. Run post-checks after write.
5. Keep large corrections visible rather than hiding them behind silent mutation.

BQN should be the place where ledger meaning is checked. Shell should be the place where bytes are moved safely.

## Acceptance criteria

- `tools/add-ui.sh` continues to work for existing interactive modes.
- `tools/edit` command compatibility is preserved for daily commands.
- `tools/check.sh` passes.
- No source TSV format changes are required.
- The daily path stays BQN-centered and shell-safe.

## Language guidance

Use language like:
- production BQN editor path
- stable daily write path
- shell dispatcher with BQN validation
- thin shell wrapper

Avoid language like:
- Go fallback
- legacy daily write path
- experimental main editor path
