# Notes and open directions

This file is a lightweight notebook for the current state of `bqn-ledger`. It records useful directions without granting or withholding permission to work.

## Current state

- Actual transactions use the configured native Journal as their production source.
- `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `issues.tsv` remain companion and configuration sources.
- Journal parsing, Posting IR, production complete-source admission, and the Stage 2A currency-proof carrier are present.
- The current report path still treats ordinary production arithmetic and selected balances as JPY-only.
- Historical implementation plans and completion records remain available under `docs/archive/` and in Git history.

## Things worth exploring

- simplify Journal metadata and remove values that can be reconstructed;
- compose context for one explicitly selected currency at a time;
- widen native Journal writing while preserving per-transaction currency meaning;
- improve report projections without forcing every question through one Cube shape;
- make documentation easier to navigate and less authoritative;
- compare alternative representations and implementations when they reveal something useful;
- improve the daily-use editor, reports, and diagnostics from actual experience.

These are prompts, not a queue. New discoveries may be more valuable than items already written here.

## Working notes

Add observations, questions, promising experiments, and unfinished threads here when that helps the next person understand the landscape. Completed work may simply be removed or summarized. Git retains the longer history.
