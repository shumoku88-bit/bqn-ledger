# Notes and open directions

This file is a lightweight notebook for the current state of `bqn-ledger`. It records useful directions without granting or withholding permission to work.

## Current state

- Native Journal is the production source for Actual transactions.
- `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `issues.tsv` remain companion and configuration sources.
- Journal parsing, Posting IR, complete-source admission, selected-domain JPY/ILS/USD context, and native multi-currency writing are present.
- Travel metadata (`trip-id`, `payment`) and bidirectional JPY/ILS exchange events are supported on their explicit source paths.
- Plan completion keeps currency selection and validation in `plan.tsv` while avoiding redundant `currency` metadata in the Actual Journal.
- Journal metadata categories and cleanup evidence are recorded in `docs/JOURNAL_METADATA_INVENTORY.md`.
- Generic projection ownership and purpose-specific projection documents are design evidence and possible directions, not permission gates.
- Historical plans, audits, and handoffs remain available under `docs/archive/` and in Git history.

## Things worth exploring

- add a privacy-safe read-only count of metadata keys in the selected Journal;
- stop copying plan-only `recur` and `series` metadata into completed Actual transactions;
- test whether explicit `layer: actual` can disappear from an Actual-only Journal without changing behavior;
- simplify the parser allowlist after occurrence evidence distinguishes active keys from historical vocabulary;
- explore exact sparse grouping and purpose-specific projections when they clarify real report questions;
- continue improving selected-currency daily use, travel recording, editor ergonomics, and reports from actual experience;
- compare alternative representations and implementations when they reveal something useful.

These are prompts, not a queue. A new discovery may be more valuable than an item already written here. Contributors and AI may explain tradeoffs, pursue coherent reversible experiments, and change nearby code or documentation when that improves the result.

## Working notes

Add observations, questions, promising experiments, and unfinished threads when that helps the next person understand the landscape. Remove or summarize completed notes during the same task. Git retains the longer history.

Private household data remains under explicit human direction.
