# Editor Go Removal Plan

Status: completed / historical record
Owner: docs
Canonical: no
Exit: archived; Go editor has been successfully retired.

This document records the transition away from the Go editor to the current BQN+shell editor path.
It is no longer a transition plan.

## Current outcome

- `tools/edit` is now the thin public wrapper.
- `tools/edit-bqn` is the active daily write entry point.
- `src_edit` is the BQN editor subsystem.
- Go editor code is no longer part of the daily write path.

## Current docs

- `docs/PRODUCTION_EDITOR_DIRECTION.md`
- `docs/BQN_EDITOR_USAGE.md`
- `src_edit/README.md`

## Historical note

Older transition-specific notes such as `BQN_EDITOR=1`, hybrid dispatcher routing, and `cd editor && go build` are superseded.
Use the archive plans and current editor docs for any remaining history lookup.
