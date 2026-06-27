# Generalization Completed Phases

Archive status: **completed phases digest**
Archived on: 2026-06-22
Source document: `docs/GENERALIZATION_TODO.md`
Current status note: `docs/GENERALIZATION_TODO.status.md`
Current task truth: `TODO.md`

This file is a digest of completed or mostly completed phases from the lifestyle-configuration generalization roadmap.

Do not use this file as the current TODO list.

## Reading rule

Use this file to understand completed generalization work.

Use these files for current work:

```text
TODO.md
docs/GENERALIZATION_TODO.md
docs/GENERALIZATION_TODO.status.md
```

## Completed phases

| phase | status | summary |
|---|---|---|
| Phase 1 | completed | Special budget account names were moved into `config.tsv` / config accessors. |
| Phase 2 | completed | `role=` contract, metadata rules, Prefix fallback behavior, and non-Prefix fixture expectations were defined. |
| Phase 3 | completed | Account role resolution was centralized so code does not depend on account-name Prefix checks for role decisions. |
| Phase 4 | completed | Base-aware Context / `--base <dir>` direction was completed according to current `TODO.md` and status notes. |
| Phase 5 | completed | Multiple lifestyle fixtures demonstrate that the same core can handle different account names, cycle modes, and envelope usage. |
| Phase 6 | mostly completed | Real data already has explicit `role=` according to current notes. Prefix fallback removal remains a separate decision. |
| Phase 7 | completed | Data / app directory separation and `--base` support were completed. |
| Phase 8 | completed elsewhere | `src/` directory reorganization is covered by canonical engine hardening history and current repo structure. |

## Remaining decision

Prefix fallback is not archived as completed.

Remaining question:

```text
When, if ever, should Prefix fallback be removed entirely?
```

That decision must be made separately after checking current fixtures, real data, and Safety Profile compatibility.

## Policy kept active

Configuration is for life-policy values, such as account role, cycle mode, envelope mapping, and display-related metadata.

Configuration is not a DSL for arbitrary accounting computation.

Canonical Daily Cube shape and Layer meanings stay fixed unless a separate architecture decision changes them.

## Non-goals

- Do not edit source TSV data.
- Do not change Canonical Daily Cube shape or Layer meaning.
- Do not remove Prefix fallback without a separate explicit decision.
- Do not turn configuration into arbitrary executable accounting rules.
- Do not treat completed generalization phases as current TODO items.

## Future cleanup

A later docs hygiene pass may shorten `docs/GENERALIZATION_TODO.md` into a current decision note centered on:

1. fixed core boundaries,
2. life-policy configuration boundaries,
3. Prefix fallback removal decision,
4. Safety Profile compatibility.
