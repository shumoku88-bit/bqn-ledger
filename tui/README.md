# TUI status

Status: frozen / no current implementation
Date: 2026-06-29

This directory is intentionally a status note, not an active TUI application.

Current daily entrypoints are:

- `tools/bl` — command hub
- `tools/report` — non-interactive human report
- `tools/main-ui.sh` — report section selector/viewer
- `tools/add-ui.sh` — input UI that delegates writes to `tools/edit`
- `tools/edit` — approved Go source TSV editor

## Current decision

Do not build or revive a full-screen TUI as part of routine report/editor work.

If a TUI is explored later, it must start as a thin viewer or CLI wrapper and must preserve the current responsibility split:

- BQN owns source TSV validation, accounting semantics, calculation, reports, and exports.
- Go editor owns safe TSV writes.
- Shell/gum/fzf/UI layers own display, selection, and input assistance only.
- No TUI may write source TSV files directly.

## Related notes

- `docs/archive/active-plans/COMMAND_HUB_DESIGN.md`
- `docs/archive/active-plans/GUM_FZF_COLOR_LAYER_PLAN.md`
- `docs/archive/active-plans/GO_EDITOR_NEXT_PLAN.md`
