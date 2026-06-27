# Go Editor Next Plan

Status: read-only plan tools + `journal add`, `journal reverse`, `budget add`, and `plan finish --apply` safe append implemented
Date: 2026-06-20

This note is a short handoff for terminal-based AI assistants and future implementation sessions.
It records the current decision: keep Go editor writes limited to approved single-file append behavior unless moko explicitly approves the next phase.

## Current decision

The initial read-only Go editor and single-file append commands are implemented in `editor/` and exposed through `tools/edit`.

Allowed now:

- `plan list`
- `plan list --all`
- `plan finish` preview and apply
- `plan add` single-file safe append with generated `plan_id`
- `plan edit` existing-row edit limited to open plan `date` / `amount`
- `journal add` single-file safe append
- `journal reverse` single-file safe append of a reversing journal row
- `budget add` single-file safe append
- `tools/add-ui.sh` daily UI delegating to Go safe append by default
- fixture/tempdir-based tests

Still planning-only:

- any additional source TSV write command beyond approved `plan add` and narrow `plan edit` date/amount correction
- any non-append source-of-truth write beyond the approved narrow `plan edit` date/amount correction
- multi-file transactions (modifying both plan.tsv and journal.tsv)
- TUI/editor expansion

The purpose of this note is to make the current implementation boundary visible from the repository.

## Preserved decisions from append-only design note

The old `docs/GO_SOURCE_TSV_EDITOR_APPEND_ONLY_DECISIONS.md` note is now historical. Its current decisions are preserved here.

- Source-of-truth remains the current multiple TSV set: `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `config.tsv`.
- Do not collapse source-of-truth into a single `events.tsv` in the current design.
- Go editor operations may feel event-like, but Go remains a source TSV editor, not a replacement source model.
- `.ops/<timestamp>-<id>.json`, if adopted later, is an operation / recovery record, not source-of-truth.
- `cycle.tsv` is resolver configuration for period views. Do not make `cycle.tsv` append-only.
- `cycle_instances.tsv` is not adopted. If it is reconsidered later, first decide whether it is a cache, override table, or explicit period table.

## Initial planning decisions

These are the current preferred decisions for the next implementation proposal.
They are not an implementation approval by themselves.

```text
implemented = Phase 1 foundation + read-only plan preview + journal/budget/plan add/plan finish safe append + journal reverse safe append + narrow plan date/amount edit
Go source location = editor/
tools/edit = thin wrapper around the Go command
plan list default = open plans only
plan list --all = show open / closed / missing-id rows
missing plan_id = marked, not written automatically
first UI = plain CLI
existing UI = keep fzf/gum wrappers outside Go; tools/add-ui.sh delegates to Go by default
future UI = tview candidate for later browsing-oriented TUI exploration
current implementation restrictions = No TUI / No deletion / no multi-file writes (plan.tsv writes are limited to safe append and open plan date/amount edit)
```

The next planning work should refine the exact acceptance criteria for any write-capable phase before implementing it.

## Core boundary

```text
BQN = scale
Go  = gloves
```

BQN remains the canonical engine:

- read source TSV files
- validate source data
- build Event IR / Projection IR / Canonical Daily Cube
- calculate balances, envelopes, cycle reports, residual views, and exports

Go is only a source TSV editor candidate:

- read source TSV files safely
- preserve rows, comments, empty fields, and metadata
- show lists / previews / diffs
- perform dry-run operations
- later, possibly perform atomic single-file writes with backup and stale checks
- call BQN lint/check after approved writes

Go must not become a second accounting engine.

## Related documents

- `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md`
- `docs/archive/completed-plans/GO_SOURCE_TSV_EDITOR_APPEND_ONLY_DECISIONS.md`
- `docs/GO_EDITOR_FIRST_IMPLEMENTATION_ACCEPTANCE.md`
- `docs/GO_EDITOR_SINGLE_FILE_APPEND_ACCEPTANCE.md`
- `docs/SAFE_WORKFLOW_REDESIGN.md`
- `docs/PHASE4_BASE_AWARE_CONTEXT_HANDOFF.md`

## Phase candidates

### Historical phase: TSV safety foundation + read-only plan tools

Implemented scope:

- Go project skeleton in `editor/`
- TSV reader with line numbers, comments, blank lines, empty-field preservation, content hash, and stale check helper
- fixture/tempdir-based tests
- `tools/edit` wrapper
- `plan list`
- `plan finish` preview-only
- open/closed detection using `plan_id`
- proposed journal row preview only

This phase did not write `journal.tsv` or `plan.tsv`.

### Implemented write phase: single-file append for journal/budget/plan finish

Acceptance criteria: `docs/GO_EDITOR_SINGLE_FILE_APPEND_ACCEPTANCE.md`

Implemented scope:

- `journal add` safe append
- `journal reverse` safe append using the same safety infrastructure
- `budget add` safe append using the same safety infrastructure
- `plan finish --apply` safe append to `journal.tsv`
- `plan.tsv` remains untouched (dynamic closed detection using `plan_id` existence in `journal.tsv`)
- preview + confirm default
- `--dry-run`
- `--yes`
- `--post-check lint|none|full` with `lint` default
- atomic write
- `.backup/` creation
- stale check before write
- post-write BQN lint by default

This phase still must not implement multi-file transactions (modifying both plan.tsv and journal.tsv).

### Current daily UI handoff

`tools/add-ui.sh` now keeps the familiar fzf/gum/numbered-prompt UI and delegates the final append to `tools/edit` by default.

- `expense` / `move` / `income` write `journal.tsv` through `tools/edit journal add`
- `reverse` writes a reversing row to `journal.tsv` through `tools/edit journal reverse`
- `budget` writes `budget_alloc.tsv` through `tools/edit budget add`
- `plan-add` writes `plan.tsv` through `tools/edit plan add`
- `plan-edit` edits open plan date/amount through `tools/edit plan edit`
- `ADD_UI_BACKEND=bqn tools/add-ui.sh` is a temporary legacy fallback; unsupported plan modes fall back to Go

### Next candidate: operation hardening

Possible scope only after explicit approval:

- operate `tools/add-ui.sh` for a while
- add more fixture coverage if daily use reveals gaps
- keep two-file plan completion (mutating plan.tsv) disabled

### Later UI phase

Possible UI candidates:

- plain CLI
- existing `fzf` / `gum` wrapper flow
- Go TUI using `tview`

Current preference: start with plain CLI and keep `fzf` / `gum` wrappers outside Go. Treat `tview` as a candidate for later UI exploration, not as part of the first implementation gate.

## Explicitly forbidden for now

Do not implement:

- two-file updates involving both `journal.tsv` and `plan.tsv` (e.g. updating plan.tsv row in-place while writing journal.tsv)
- deleting rows from `plan.tsv`
- deleting rows from `journal.tsv`
- broad `plan.tsv` row editing beyond the approved open-plan `date` / `amount` correction command
- automatically adding `status=done` or `actual_date=...` to plan rows
- adopting `plan_status.tsv`
- adopting `cycle_instances.tsv`
- making `cycle.tsv` append-only
- operation-log-based source TSV regeneration
- collapsing the source TSV set into a single `events.tsv`
- balance calculation in Go
- envelope calculation in Go
- cycle report calculation in Go
- residual / behavior-drift calculation in Go
- Canonical Daily Cube reimplementation in Go

## Plan lifecycle decisions to preserve

Current accepted direction:

- `plan_id` is an optional metadata key, intended to be generated and carried by a future Go editor.
- `plan_id` should normally be attached when a plan row is created, even if the scheduled payment date has not arrived yet.
- `plan_id` is not a marker that the payment date has arrived; it is a stable link tag between a declared plan and its later actual journal row.
- future unpaid plans with `plan_id` are normal open plans.
- future unpaid plans without `plan_id` are still valid plan rows, but they are missing the link tag needed for safe completion detection.
- naming rule: `plan-YYYY-MM-DD-<series>`
- on collision, append `-02`, `-03`, and so on
- existing `plan.tsv` rows are backfill candidates because the recording period is still short
- `plan_open` and `plan_all` are separate concepts
- if `journal.tsv` contains the same `plan_id`, that plan is excluded from `plan_open`
- completed plans remain in `plan.tsv` for residual/history observation

Still to decide:

- how to generate `plan_id` when `series` is missing
- whether missing `plan_id` rows are merely marked or blocked from finish preview
- exact candidate ID display format for missing `plan_id` rows

## UI decisions still open

`tview` is a valid candidate, but it should not be smuggled into the first implementation.

Decide later:

- whether a TUI is needed at all
- whether `tview` should be used only for browsing or also for editing
- whether TUI editing is allowed to write source TSV files
- how TUI confirmation differs from CLI confirmation
- whether mobile/terminal constraints make TUI worth the complexity

Default for now:

```text
first implementation = plain CLI
existing UI = fzf/gum wrappers stay outside Go
future UI = tview candidate, not approved yet
```

## Test requirements before broader write-capable implementation

Already covered for the read-only phase:

- preview no mutation
- empty field preservation through TSV split
- comment / blank-line recognition
- metadata preservation and plan-only metadata stripping
- plan_id open/closed detection
- `plan finish preview` output
- obvious plan row validation errors

Already covered for `journal add` / `budget add` safe append:

- dry-run no mutation
- validation rejection
- empty memo / five-field row preservation
- metadata order preservation
- trailing and non-trailing newline append boundaries
- confirmation cancel no mutation
- backup creation
- injected pre-rename failure
- stale check refusal
- post-check invocation and failure reporting

Before any broader write-capable implementation starts, define fixture tests for the target command with the same safety properties.

All write tests must run against copied fixtures or temporary directories, not real data.

## Implementation gate

Broader write-capable implementation may begin only after a future explicit approval says which exact phase is allowed.

Minimum approval wording should say something like:

```text
Approve Go editor <next write command> only.
No plan finish apply.
No deletion.
No TUI.
```

Until then, terminal AI should treat broader write-capable work as a planning track, not an implementation task.
