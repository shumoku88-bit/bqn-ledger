# Gum/Fzf Color Layer Plan

Status: Phase 1 implemented as tools/bl / Phase 2 pending  
Date: 2026-06-28

This note describes a small terminal presentation layer for `bqn-ledger` using shell, `gum`, and `fzf`.

The goal is not to build a full TUI. The goal is to make daily use easier while preserving the plain-text, BQN-powered, source-TSV-centered shape of the project.

## Product feel

Target feel:

```text
open-back terminal layer
small shell doorway
plain output remains canonical
color is presentation only
```

The UI should feel like a light handle attached to the existing tools, not a new application shell that hides the ledger.

## Motivation

Current daily use already has these ingredients:

- `tools/report` for the human report
- `tools/main-ui.sh` for daily report/section selection
- `tools/add-ui.sh` for input assistance
- `tools/edit` for safe Go-backed source TSV editing paths
- `tools/check.sh` for validation
- optional `gum` / `fzf` for interactive terminal flows

The next small product step is to make those entry points feel more comfortable and more legible without moving accounting meaning into the UI layer.

## Non-goals

This plan does not approve:

- a full-screen TUI
- a `tview` application
- a new database
- a new source-of-truth file
- direct source TSV mutation by the command hub
- accounting calculation in shell
- accounting calculation in Go UI code
- ANSI color in golden fixtures or machine outputs
- hiding TSV files from normal user inspection

## Boundary

```text
TSV source data
  -> BQN report / check / export
  -> plain terminal output
  -> optional shell/gum/fzf presentation layer
```

The presentation layer may decorate output, select commands, and show previews.
It must not become a ledger engine.

Allowed responsibilities:

- route to existing tools
- show a small menu
- call `tools/report`
- call `tools/main-ui.sh select` or equivalent section selection
- call `tools/add-ui.sh`
- call `tools/edit` subcommands
- call `tools/check.sh`
- open TSV files in `$EDITOR`
- display read-only previews
- add ANSI color only for terminal presentation

Forbidden responsibilities:

- calculate balances
- calculate envelopes
- calculate cycle reports
- parse or reinterpret the Canonical Daily Cube
- update `journal.tsv`, `plan.tsv`, or `budget_alloc.tsv` directly
- delete source TSV rows
- treat colorized output as canonical data
- make `gum` or `fzf` required for non-interactive use

## Color policy

Color is a display layer, not a data layer.

Recommended contract:

```text
tools/report                 plain by default
tools/report --color=never   no ANSI
tools/report --color=auto    ANSI only when stdout is a terminal
tools/report --color=always  ANSI for terminal piping / preview use
```

If this is too much for the first implementation, keep `tools/report` plain and add a separate wrapper:

```text
tools/report-pretty
```

In either shape:

- source TSV files remain plain
- BQN machine outputs remain plain
- fixture golden outputs remain plain unless a fixture is explicitly about color stripping
- checks compare plain output
- `NO_COLOR` should disable presentation color
- color should be minimal and semantic

Suggested color categories:

```text
heading
selection
ok
warning
error
diff-add
diff-remove
muted metadata
```

Avoid turning reports into a rainbow dashboard. The report should still be readable when copied into a plain text file.

## Gum/fzf responsibilities

`gum` is useful for:

- menu selection
- confirmation prompts
- simple styled headings
- success/warning/error messages
- small tables or boxes when they do not obscure the underlying output

`fzf` is useful for:

- fuzzy report section selection
- account selection
- plan selection
- previewing a read-only report section or TSV excerpt

Rules:

- `fzf --ansi` may be used for colorized previews
- previews must be read-only
- preview commands should be bounded and predictable
- absence of `fzf` must fall back to `gum` or plain numbered selection when possible
- absence of both `gum` and `fzf` must not break direct CLI subcommands

## Proposed command hub shape

The existing command hub design remains the parent plan.
This color layer is a presentation subtrack.

Possible future shape:

```sh
# interactive menu
tools/hub

# direct commands stay scriptable
tools/hub report
tools/hub report --color=auto
tools/hub section
tools/hub add
tools/hub plan
tools/hub check
tools/hub edit journal
tools/hub edit plan
```

The command name is still undecided. Until then, docs may use `tools/hub` as a placeholder.

## Implementation sequence

### Phase 0: docs only

- record this plan
- keep TUI frozen
- keep source TSV mutation out of the hub
- decide whether color is a wrapper or a `--color` flag

### Phase 1: read-only presentation prototype

Allowed first prototype:

- menu for report / section / check / edit-open
- section selection via `fzf` when available
- plain fallback when `fzf` and `gum` are missing
- colorized headings and statuses only
- no source TSV writes by the hub

Suggested files:

```text
tools/hub                 shell launcher candidate
tools/report-pretty       optional presentation wrapper candidate
tools/color-filter        optional ANSI decoration helper candidate
```

### Phase 2: safe action routing

Only after Phase 1 is stable:

- route `add` to existing `tools/add-ui.sh`
- route `plan list` / `plan finish` to existing `tools/edit` commands
- show preflight and diff where existing tools support it

The hub still must not implement writes itself.

### Phase 3: optional polish

- compact help screen
- consistent labels
- small semantic palette
- improved `fzf` previews
- editor shortcuts for source TSV inspection

## Acceptance criteria for a future implementation PR

A future implementation PR should prove:

- `tools/report` plain output remains stable, or any color mode is opt-in/auto only
- `tools/report-next-summary` remains plain machine output
- `tools/check.sh` passes
- direct non-interactive commands work without `gum` and `fzf`
- source TSV files are not written by the hub
- no full TUI dependency is introduced
- docs say which outputs are canonical and which are presentation-only

## Approval gate

This document is not implementation approval.

A future approval should say something like:

```text
Approve a shell/gum/fzf presentation prototype.
Docs-only plan already exists.
No full TUI.
No source TSV mutation by the hub.
Plain report/check/export output remains canonical.
```
