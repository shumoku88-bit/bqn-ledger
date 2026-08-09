# Production Editor Direction

Status: current policy / architecture direction
Owner: editor
Canonical: yes
Exit: revise if the production write-path ownership changes.

## Status

- BQN editor production path is complete for current daily commands in both explicit TSV compatibility mode and native Journal mode.
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
- Responsible for current user interaction, mode selection, optional fzf / gum / numbered adapters, text input, and account selection.
- Calls `tools/edit`.
- Does not own Journal/TSV write semantics.
- Its selector implementation is replaceable; editor intent and machine-readable results must remain usable by a future UI without reproducing BQN validation or shell publication logic.

### `tools/plan-finish-replenish-ui.sh`
- Optional interactive helper for the recurring-plan workflow.
- Finishes a selected plan through `tools/edit plan finish`, then optionally creates the follow-up plan through `tools/edit plan add`.
- Displays related open future plans using `tools/edit plan related`; the BQN editor owns relation-key semantics.
- Must not parse source TSV metadata itself, change low-level source TSV contracts, or own accounting semantics.

### `tools/edit`
- Public command surface for daily editor operations.
- Preserves CLI compatibility for current commands.
- Delegates immediately to `tools/edit-bqn`.

### `tools/edit-bqn`
- Active BQN + shell editor entry point.
- Applies append and replace operations through validated machine-readable protocols.
- `journal add/multi-add/list/reverse` and `plan finish` target the BQN-resolved `ACTUAL_JOURNAL_FILE`; there is no Actual TSV route, dual write, or fallback.
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
- `account add`
- `journal add`（Journal modeではnative transaction block）
- `travel friend add` (dedicated pending source event; no journal projection)
- `travel exchange add` (dedicated two-amount source event; no journal projection or rate)
- `budget add`
- `plan add`
- `issue add`

### Read-only selector
- `plan list`
- `plan related`

### Derived append
- `plan finish`（Journal modeでは`plan-id`付きnative actual transaction）
- `plan budget-sync`（完了済み `plan_id` に対する確認付き・冪等な execution-envelope companion）
- `journal reverse`

### Interactive orchestration
- `tools/plan-finish-replenish-ui.sh` composes `plan finish` and `plan add` for replenishment; it is not a new write primitive.

### Exact replace
- `plan edit`

Append-only commands are the lowest-risk path. `plan budget-sync` は journal actual を巻き戻さず、budget companion が未適用なら `BUDGET_SYNC_PENDING` として再試行可能にする recoverable saga です。Optional travel source first-write uses exclusive staged creation rather than production bootstrap or parent-directory creation. Derived append and exact replace rely on explicit old-row / line-number safety.

## Safety model

1. Build the candidate row or edit operation.
2. Validate before touching source TSV.
3. Apply through a small shell safe-write function.
4. Run post-checks after write.
5. Keep large corrections visible rather than hiding them behind silent mutation.

BQN should be the place where ledger meaning is checked. Shell should be the place where bytes are moved safely.

## UI replaceability

`fzf`, `gum`, and numbered prompts are current delivery choices, not editor architecture. UI modernization may replace or remove one of these adapters after comparing daily usability, dependency cost, preview behavior, cancellation, and failure visibility. Such a change must consume existing typed or machine-readable editor/report surfaces and must not become a second source parser, accounting owner, or writer.

Selector replacement is separate from accounting-kernel simplification. Kernel work should preserve a neutral boundary; UI implementation should be reviewed as its own coherent change when the main queue reaches the relevant command owners, unless a concrete UI defect needs an earlier isolated fix.

## Acceptance criteria

- Existing qualified daily operations remain reachable through at least one documented interactive path and through their direct command surfaces.
- `tools/edit` command compatibility is preserved for daily commands.
- `tools/check.sh` passes.
- No canonical source format change is required merely to replace a UI adapter.
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
