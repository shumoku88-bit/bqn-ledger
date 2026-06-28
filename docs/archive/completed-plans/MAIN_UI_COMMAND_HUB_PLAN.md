# Main UI / Command Hub Plan

Status: active plan / Phase 0 partially implemented
Date: 2026-06-27

## Purpose

`tools/main-ui.sh` must become a reliable daily entry point, not a fragile fzf preview script.

Data directory setup is part of this contract. See `docs/DATA_DIR_SETUP.md`.

The first requirement is simple:

```text
When moko runs tools/main-ui.sh with no arguments, the household report must be visible.
If it cannot be shown, the reason must be visible.
```

A UI that passes fixture checks but shows a blank screen in daily use is not acceptable.

## Problem

The current script mixes three responsibilities:

- daily report entry point
- section selector
- fzf/gum preview UI

This makes the most important path depend on the most fragile path. If fzf/gum/preview/stderr handling breaks, moko cannot see the report and cannot make household decisions.

## Boundary

Keep the existing responsibility split:

```text
BQN/tools/report = report calculation and rendering
main-ui.sh       = daily command hub / routing / display entry
add-ui.sh        = write-oriented actions, delegated to tools/edit
fzf/gum          = optional convenience only
```

`main-ui.sh` must not calculate balances, envelopes, plans, or checks itself.

## Target command shape

Phase 0 should make these commands stable:

```sh
tools/main-ui.sh
# show the full report; this is the primary daily path

tools/main-ui.sh report
# same as no arguments

tools/main-ui.sh snapshot
tools/main-ui.sh envelopes
tools/main-ui.sh planned
tools/main-ui.sh check
# show a specific section without requiring fzf/gum

tools/main-ui.sh select
# optional fzf/gum section selector

tools/main-ui.sh add
# delegate to tools/add-ui.sh
```

Names can be adjusted during implementation, but the default behavior should remain: **show the report**.

## Non-goals

Do not start with a full TUI.

Do not introduce a new accounting engine, report parser, or source TSV writer.

Do not make fzf/gum mandatory for seeing the report.

Do not move write responsibilities from `add-ui.sh` / `tools/edit` into `main-ui.sh`.

## Phase plan

### Phase 0: make the daily report path non-fragile

Status: implemented in shell entry points; continue hardening through doctor/preflight.

- `tools/main-ui.sh` with no args displays the full report through `tools/report`.
- `tools/main-ui.sh report` does the same.
- Report build failure prints a visible error and exits non-zero.
- fzf/gum is not used on the default path.
- stale or missing data directories fail before raw BQN traces where possible.

Acceptance criteria:

```sh
tools/main-ui.sh --base fixtures/src-next-golden
```

prints a non-empty report containing at least the Snapshot and Readiness Check sections.

### Phase 1: direct section commands

- Add direct section commands such as `snapshot`, `envelopes`, `planned`, `check`.
- These must work without fzf/gum.
- Section extraction may be temporary, but failures must be visible.

Acceptance criteria:

```sh
tools/main-ui.sh --base fixtures/src-next-golden snapshot
tools/main-ui.sh --base fixtures/src-next-golden envelopes
tools/main-ui.sh --base fixtures/src-next-golden check
```

all print non-empty output.

### Phase 2: optional selector

- Move current fzf/gum behavior under `select` or `--select`.
- Selector preview is convenience only.
- If preview fails, the normal report path must remain unaffected.
- Related issue: `docs/MAIN_UI_SECTION_PREVIEW_CACHE_ISSUE-2026-06-27.md` (temporary section cache preview path).

### Phase 3: small command hub

Add small routing commands only if useful:

```sh
tools/main-ui.sh add    # exec tools/add-ui.sh
tools/main-ui.sh check  # run a chosen check path
tools/main-ui.sh help
```

This is a shell command hub, not a full TUI.

## Check requirements

Add a UI smoke check to `tools/check.sh` when implementation starts.

It should verify the daily entry point, not just ad-hoc stdin paths:

```sh
tools/main-ui.sh --base fixtures/src-next-golden
```

must print a non-empty report.

It should also verify representative direct commands and failure visibility.

## AI work rule

For future pit work, the pass condition is not “some stdout was non-empty”.

The pass condition is:

```text
The command moko normally runs shows the report or shows a clear failure reason.
```

Do not treat fzf/gum preview success as a substitute for the default daily report path.
