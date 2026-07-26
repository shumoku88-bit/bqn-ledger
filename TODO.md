# Notes and open directions

This file is a lightweight notebook for the current state of `bqn-ledger`. It records useful directions without granting or withholding permission to work.

## Current state

- Native Journal is the production source for Actual transactions.
- `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `issues.tsv` remain companion and configuration sources.
- Journal parsing, Posting IR, complete-source admission, selected-domain JPY/ILS/USD context, and native multi-currency writing are present.
- `src_next/selected_domain_context.bqn` composes one selected currency through a flat fail-closed stage sequence: policy, Actual admission, Actual currency proof, non-Actual preparation, context scale, exact normalization, and period views.
- `src_next/projection.bqn` ownership is inventoried in `docs/archive/audits/PROJECTION_BQN_OWNERSHIP_AUDIT-2026-07-26.md`; it is a mixed Posting IR vocabulary shelf rather than a generic projection engine.
- Projection-cleanup P1 is complete: developer-only Posting IR columns, table formatting, and source-balance presentation live in `src_next/developer_inspection.bqn`; `projection.bqn` no longer exports presentation helpers, and the production `tools/report` path is unchanged.
- `src_next/main.bqn` is no longer the implementation owner. It is a temporary compatibility wrapper that imports `developer_inspection.bqn`; current tools and checks use the named entrypoint directly and verify byte-equivalent wrapper behavior.
- Travel metadata (`trip-id`, `payment`) and bidirectional JPY/ILS exchange events are supported on their explicit source paths.
- Plan completion keeps currency selection and validation in `plan.tsv` while avoiding redundant `currency` metadata in the Actual Journal.
- Journal metadata categories and cleanup evidence are recorded in `docs/JOURNAL_METADATA_INVENTORY.md`.
- Canonical Daily Cube and TBDS are purpose-specific views over checked posting facts, not competing source truths.
- `src_next/exact_sparse_grouping.bqn` provides a small deterministic exact grouping kernel with Cube reconstruction, TBDS-like reuse, conservation, and provenance-sidecar evidence.
- `src_next/actual_expense_ranking.bqn` is the first real consumer built directly from checked posting facts: selected-period Actual/debit admission, an explicit expense AccountKey partition derived from resolved account metadata, exact grouping, deterministic ranking, and contributor lookup without Cube or TBDS production ownership.
- Current architecture and code-map documents include the direct checked-facts → sparse grouping → purpose-specific consumer branch alongside Cube and TBDS.
- Historical plans, audits, and handoffs remain available under `docs/archive/` and in Git history.

## Things worth exploring

- next, characterize repository callers, focused-test dependence, documentation promises, and external-clone compatibility for apparently dead `projection.bqn` exports (`ResolveDay`, `RequireArithmeticCurrencyProof`, exported scalar helpers) before removing anything;
- decide at a later stability boundary whether the thin `src_next/main.bqn` compatibility wrapper should be deprecated for a release and then removed; do not restore implementation to it;
- after that, restore direct `date.bqn` ownership, reassess arithmetic-proof authorization, and inventory shared Layer ownership as separate slices rather than one broad refactor;
- add a privacy-safe read-only count of metadata keys in the selected Journal;
- stop copying plan-only `recur` and `series` metadata into completed Actual transactions;
- test whether explicit `layer: actual` can disappear from an Actual-only Journal without changing behavior;
- simplify the parser allowlist after occurrence evidence distinguishes active keys from historical vocabulary;
- run a second independent real query over checked posting facts before extracting broader filter/key/order vocabulary or replacing a production Cube/TBDS accumulation path;
- preserve complete result-contract and diagnostic parity when considering any production materializer replacement;
- separate the remaining JPY compatibility seams in `account_key.bqn`, arithmetic-proof authorization, and the legacy `context.BuildContext` path from registry-generic selected-domain behavior;
- decide whether travel exchange should consume registry precision while keeping allowed currency pairs and trip policy in its own adapter; in particular, make the registry JPY `-1` policy and travel JPY scale `0` relationship explicit;
- continue improving selected-currency daily use, travel recording, editor ergonomics, and reports from actual experience;
- compare alternative representations and implementations when they reveal something useful.

These are prompts, not a queue. A new discovery may be more valuable than an item already written here. Contributors and AI may explain tradeoffs, pursue coherent reversible experiments, and change nearby code or documentation when that improves the result.

## Working notes

For whole-Journal or cross-view grouping, arithmetic domain is a partition/key requirement, not an implicit property of the numeric kernel. Valuation remains separate from source quantity.

The first direct consumer exposed an important boundary: transaction-level `kind` describes a transaction, while expense membership for a posting comes from the posting's AccountKey partition. A multi-posting expense transaction may contain non-expense debit coordinates, so those meanings must not be collapsed.

A flat pipeline is useful only when it preserves first-failure ownership. Later stages must not run after policy, source admission, currency proof, or non-Actual validation fails, and no partial selected context may escape.

Code beauty here means truthful ownership, not maximum file count. P1 moved only the clearest foreign responsibility; later cleanup slices must preserve their own compatibility evidence and must not use the smaller file as permission for a mechanical split.

A compatibility wrapper is not an implementation owner. New code, checks, and docs should name `developer_inspection.bqn`; `main.bqn` may be removed only through an explicit compatibility decision rather than by accidentally letting it grow again.

Add observations, questions, promising experiments, and unfinished threads when that helps the next person understand the landscape. Remove or summarize completed notes during the same task. Git retains the longer history.

Private household data remains under explicit human direction.
