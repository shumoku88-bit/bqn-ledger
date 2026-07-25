# Notes and open directions

This file is a lightweight notebook for the current state of `bqn-ledger`. It records useful directions without granting or withholding permission to work.

## Current state

- Actual transactions use the configured native Journal as their production source.
- `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `issues.tsv` remain companion and configuration sources.
- Journal parsing, Posting IR, production complete-source admission, and the Stage 2A currency-proof carrier are present.
- The current report path still treats ordinary production arithmetic and selected balances as JPY-only.
- Journal metadata is inventoried in `docs/JOURNAL_METADATA_INVENTORY.md`; the parser allowlist currently combines structural links, human evidence, duplicated structural markers, copied plan metadata, and historical compatibility vocabulary.
- Historical implementation plans and completion records remain available under `docs/archive/` and in Git history.

## Things worth exploring

- test whether `currency: JPY` and `layer: actual` can disappear from native Actual transactions without changing behavior;
- stop copying plan-only `recur` and `series` metadata into completed Actual transactions;
- add a privacy-safe read-only count of metadata keys in the selected Journal;
- simplify the parser allowlist after real occurrence evidence distinguishes active keys from historical vocabulary;
- compose context for one explicitly selected currency at a time;
- widen native Journal writing while preserving per-transaction currency meaning;
- improve report projections without forcing every question through one Cube shape;
- compare alternative representations and implementations when they reveal something useful;
- improve the daily-use editor, reports, and diagnostics from actual experience.

These are prompts, not a queue. New discoveries may be more valuable than items already written here.

## Working notes

Add observations, questions, promising experiments, and unfinished threads here when that helps the next person understand the landscape. Completed work may simply be removed or summarized. Git retains the longer history.
