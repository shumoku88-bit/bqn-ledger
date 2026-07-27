# Notes and open directions

This file is a lightweight notebook for the current state of `bqn-ledger`. It records useful directions without granting or withholding permission to work.

## Current state

- Native Journal is the production source for Actual transactions.
- `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `issues.tsv` remain companion and configuration sources.
- Journal parsing, Posting IR, complete-source admission, selected-domain JPY/ILS/USD context, and native multi-currency writing are present.
- `src_next/selected_domain_context.bqn` composes one selected currency through a flat fail-closed stage sequence: policy, Actual admission, Actual currency proof, non-Actual preparation, context scale, exact normalization, and period views.
- `src_next/projection.bqn` ownership is inventoried in `docs/archive/audits/PROJECTION_BQN_OWNERSHIP_AUDIT-2026-07-26.md`; it is a mixed Posting IR vocabulary shelf rather than a generic projection engine.
- Projection-cleanup P1 is complete: developer-only Posting IR columns, table formatting, and source-balance presentation live in `src_next/developer_inspection.bqn`; `projection.bqn` no longer exports presentation helpers, and the production `tools/report` path is unchanged.
- Projection-cleanup P2 characterization is complete in `docs/archive/audits/PROJECTION_COMPATIBILITY_EXPORTS_CHARACTERIZATION-2026-07-26.md`: five compatibility candidates had no repository runtime callers; the implementation slices then separated low-pressure helpers from the proof-wrapper contract seam.
- Projection-cleanup P2a is complete: the dead `ResolveDay`, `IsDigits`, and `IsIntegerText` definitions/exports are gone; `MetaValue` remains private for `TxIdFromMeta`; live cycle-date and arithmetic-proof boundaries are preserved.
- Projection-cleanup P2b is complete: the unused effectful `RequireArithmeticCurrencyProof` wrapper and export are gone; `AuthorizeArithmeticCurrencyProof` and `ArithmeticCurrencyAuthorizationMessage` remain the data-only proof boundary; fatal stdout and exit behavior remain in the outer `context.bqn` compatibility wrapper; and the checked-result contract now describes the implemented runtime rather than the earlier design phase.
- Projection-cleanup P3a is complete: `cycle.bqn` and `actual_snapshot.bqn` now call their existing direct `date.bqn` imports for validation and epoch coordinates, no longer import `projection.bqn`, and the focused date test no longer treats projection forwarding aliases as part of the date contract. Evidence is recorded in `docs/archive/audits/PROJECTION_DATE_OWNERSHIP_P3A-2026-07-26.md`.
- Projection-cleanup P3b is complete: `actual_comparison.bqn` now uses its existing `date.bqn` import for all validation and epoch coordinates and no longer imports `projection.bqn`. Comparison windows, previous-anchor selection, rejected-evidence applicability, TBDS inputs, and report formatting are unchanged. Evidence is recorded in `docs/archive/audits/PROJECTION_DATE_OWNERSHIP_P3B-2026-07-26.md`.
- Projection-cleanup P3c is complete: `ytd_summary.bqn` and `planned_payments.bqn` now import `date.bqn` directly and no longer import `projection.bqn`; YTD range construction, Cube inputs, planned-payment observation boundaries, and compact/human/JSON outputs are unchanged. Evidence is recorded in `docs/archive/audits/PROJECTION_DATE_OWNERSHIP_P3C-2026-07-26.md`.
- Projection-cleanup P3d is complete: `actual_source.bqn` now imports `date.bqn` directly for `PlanIdsInCycle` validation and epoch coordinates and no longer imports `projection.bqn`; Actual Journal selection, admission, completion evidence, income dates, and half-open cycle filtering are unchanged. Evidence is recorded in `docs/archive/audits/PROJECTION_DATE_OWNERSHIP_P3D-2026-07-26.md`.
- Projection-cleanup P3e is complete: `tbds.bqn` now imports `date.bqn` directly for cycle-bound validation and Posting IR day coordinates and no longer imports `projection.bqn`; opening, movement, closing, Layer aggregation, query helpers, and compact output are unchanged. Evidence is recorded in `docs/archive/audits/PROJECTION_DATE_OWNERSHIP_P3E-2026-07-26.md`.
- `checks/check-projection-compatibility-exports.sh` guards the completed P2 boundary and the completed P3a-P3e direct-date groups against regression.
- `src_next/main.bqn` is no longer the implementation owner. It is a temporary compatibility wrapper that imports `developer_inspection.bqn`; current tools and checks use the named entrypoint directly and verify byte-equivalent wrapper behavior.
- `src_next` module topology is recorded in `docs/archive/audits/SRC_NEXT_MODULE_TOPOLOGY_AUDIT-2026-07-26.md`: 71 BQN modules, 69 at root, 276 direct imports, no missing direct target, and no import cycle.
- `tools/src-next-import-graph` and `checks/check-src-next-import-graph.sh` provide repeatable direct-import evidence for future directory migrations.
- After the first migration, `src_next` still has 71 BQN modules: 67 at root and 4 nested under `calc/` or `queries/`; the direct graph remains 276 edges with no missing target or cycle.
- Travel metadata (`trip-id`, `payment`) and bidirectional JPY/ILS exchange events are supported on their explicit source paths.
- Plan completion keeps currency selection and validation in `plan.tsv` while avoiding redundant `currency` metadata in the Actual Journal.
- Journal metadata categories and cleanup evidence are recorded in `docs/JOURNAL_METADATA_INVENTORY.md`.
- Canonical Daily Cube and TBDS are purpose-specific views over checked posting facts, not competing source truths.
- `src_next/queries/exact_sparse_grouping.bqn` provides a small deterministic exact grouping kernel with Cube reconstruction, TBDS-like reuse, conservation, and provenance-sidecar evidence.
- `src_next/queries/actual_expense_ranking.bqn` is the first real consumer built directly from checked posting facts: selected-period Actual/debit admission, an explicit expense AccountKey partition derived from resolved account metadata, exact grouping, deterministic ranking, and contributor lookup without Cube or TBDS production ownership.
- The first bounded directory migration is complete: the ranking and grouping pair now live together under `src_next/queries/`, with no permanent root wrappers.
- Current architecture and code-map documents include the direct checked-facts → sparse grouping → purpose-specific consumer branch alongside Cube and TBDS.
- Historical plans, audits, and handoffs remain available under `docs/archive/` and in Git history.
- YTD unavailable-cycle defect (PR in draft): when `cycle.tsv` contains an unresolvable mode (e.g. `monthly`), `cycle.bqn` resolves `start` and `end_exclusive` to `"unavailable"`. `ytd_summary.Build` now detects this sentinel before calling `date.DaysFromEpoch` and returns an explicit unavailable summary. Adjacent sections (`actual_source`, `outlook_remaining_plan`, `daily_trend`, `daily_flow`) receive parallel guards against low-level date indexing on `"unavailable"` string input. `checks/check-src-next-ytd-unavailable-cycle.sh` locks the regression.

## Things worth exploring

- continue inventorying remaining forwarded-date callers by ownership group: CLI/query views, plan/report computations, and mixed projection-vocabulary modules;
- select a coherent date-only CLI or query-view group before adding direct `date.bqn` imports; `calc/main.bqn` and `snapshot.bqn` should be compared by responsibility rather than mass-rewritten; `daily_flow.bqn` and `daily_trend.bqn` already import `date.bqn` directly and have unavailable-cycle guards as of the ytd unavailable-cycle fix;
- keep mixed modules that also consume `FieldOrEmpty`, Layer constants, proof helpers, or `ResolveDayFromCycle` separate from date-only imports;
- remove the temporary `projection.IsValidDateText` and `projection.DaysFromEpoch` exports only after executable callers and focused tests have migrated;
- reassess the live arithmetic-proof predicate/message ownership after the dead effectful wrapper removal;
- inventory shared Layer ownership as its own slice rather than combining it with date or proof cleanup;
- decide at a later stability boundary whether the thin `src_next/main.bqn` compatibility wrapper should be deprecated for a release and then removed; do not restore implementation to it;
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

Code beauty here means truthful ownership, not maximum file count. P1 moved only the clearest foreign responsibility; P2 then removed compatibility surfaces only after caller and contract evidence. P3 is restoring direct date ownership in coherent caller groups rather than through one mass path rewrite. Already-importing callers, the first report-facing pair, the Actual source hub, and TBDS are complete; CLI/query views and mixed-vocabulary modules remain deliberately separate.

A compatibility wrapper is not an implementation owner. New code, checks, and docs should name `developer_inspection.bqn`; `main.bqn` may be removed only through an explicit compatibility decision rather than by accidentally letting it grow again.

Directory beauty here means truthful neighborhoods, not maximum nesting. Move one coherent low-blast-radius group at a time, keep graph evidence current, and leave high fan-in hubs in place until their ownership is stable.

Add observations, questions, promising experiments, and unfinished threads when that helps the next person understand the landscape. Remove or summarize completed notes during the same task. Git retains the longer history.

Private household data remains under explicit human direction.
