# Canonical Engine Hardening Completed Phases

Archive status: **completed phases digest**
Archived on: 2026-06-22
Source document: `docs/CANONICAL_ENGINE_HARDENING_TODO.md`
Current active remainder note: `docs/CANONICAL_ENGINE_HARDENING_TODO.status.md`
Current task truth: `TODO.md`, `docs/SAFETY_PROFILE.md`

This file is a digest of completed or mostly completed phases from the canonical engine hardening roadmap.

Do not use this file as the current TODO list.

## Reading rule

Use this file to understand completed hardening work.

Use these files for current work:

```text
TODO.md
docs/SAFETY_PROFILE.md
docs/CANONICAL_ENGINE_HARDENING_TODO.status.md
```

The source roadmap is preserved for historical context until it is safely compressed.

## Completed phases

| phase | status | summary |
|---|---|---|
| Phase 1 | completed | Canonical TSV exports were created as machine-readable measurement stakes. |
| Phase 2 | completed | Canonical formulas were documented and connected to export formula IDs. |
| Phase 4 | completed | Report invariant checks and export/report consistency checks were added. |
| Phase 6 | completed | `BuildCube` responsibility was clarified and View layer separation was completed. |
| Phase 9 | completed | Input lint was strengthened for journal-like TSV, envelope, plan, and cycle checks. |
| Phase 10 | completed | Source files were reorganized under `src/`. |

## Mostly completed phases

| phase | status | note |
|---|---|---|
| Phase 3 | mostly completed | Report contracts exist. Some envelope checklist items remain unchecked in the old roadmap, but the phase completion conditions are checked. |
| Phase 5 | mostly completed | Main fixture / golden coverage exists. Additional optional fixture candidates remain listed in the old roadmap. |

## Not archived as completed

- Phase 0: principle / keep.
- Phase 7: debug / provenance remains an active candidate.
- Phase 8: Datalog / Prolog / external reasoning role remains undecided.
- Phase 11: later work.
- Safety Profile invariant mapping remains active work.

## Non-goals

- Do not edit source TSV data.
- Do not change implementation code.
- Do not treat this archive digest as approval to change `BuildCube`.
- Do not mark Safety Profile invariant mapping as completed.
- Do not revive deleted consultation exports.
- Do not treat external reasoning systems as canonical number generators.

## Future cleanup

A later docs hygiene pass may shorten `docs/CANONICAL_ENGINE_HARDENING_TODO.md` into an active remainder document.

Until then, keep the old roadmap as historical context and use this digest only to avoid rereading completed phases as current TODOs.
