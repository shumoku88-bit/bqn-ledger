# Notes and open directions

This is the lightweight queue for current work. Completed implementation history belongs in Git and `docs/archive/`.

## Current state

- Native Journal is the sole production Actual source; companion sources are `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `issues.tsv`.
- Daily human reporting runs through `tools/report` → `src_next/report.bqn`; compact output uses `tools/report-next-summary` → `src_next/summary.bqn`.
- Production routing remains `src_next`, now 71 BQN modules and 12,407 physical lines; canonical admission/fact ownership is under `src/ledger`, while temporary context row adapters remain until report consumers migrate. All report sections remain available.
- Canonical Daily Cube, TBDS, and purpose-specific sparse consumers remain views over checked posting facts, not competing source truths.
- The current runtime still contains dual context/admission routes, historical transaction/proof fallbacks, compatibility exports, test seams, and historical entrypoint names.
- Current reporting remains production until a separately verified ledger-facts engine passes the cutover gate.

## Selected work: ledger-facts report engine migration

The active roadmap is [`docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`](docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md).

Goal:

```text
strict source snapshot and admission
  -> canonical transaction/posting facts
  -> narrow accounting capabilities
  -> retained report portfolio (Matrix / List / Card / Statement)
  -> approved human / compact / JSON surfaces
  -> atomic cutover
  -> complete deletion of retired reports and old compatibility runtime
```

The approved portfolio reset is [`docs/REPORT_PORTFOLIO_DECISION.md`](docs/REPORT_PORTFOLIO_DECISION.md). Useful accounting questions are retained; old section count, names, order, and every output surface are not. Shared records remain bounded by source/accounting facts, section-specific results remain local, and no giant all-report record or premature query DSL is introduced.

### Completed finite slice: Phase 0A report construction inventory

[`docs/REPORT_CONSTRUCTION_INVENTORY.md`](docs/REPORT_CONSTRUCTION_INVENTORY.md) classifies all 15 sections by facts, filters, axes, measures, joins, time/currency policy, result shape, output surface, and compatibility pressure.

- [x] Classified every section as Matrix, List, Card, hybrid, or custom semantic Build.
- [x] Selected Trial Balance and Daily Flow as materially different real Matrix/Pivot proofs.
- [x] Selected a monthly expense matrix with contributor posting IDs as the novel extensibility gate.
- [x] Confirmed that transaction facts must remain first-class and that Outlook/Envelope/Trend/Comparison must not be forced into a universal Pivot spec.

### Completed finite slice: Phase 0B runtime compatibility inventory

[`docs/RUNTIME_COMPATIBILITY_INVENTORY.md`](docs/RUNTIME_COMPATIBILITY_INVENTORY.md) classifies 37 known runtime/source/API candidates and assigns prerequisites, canonical replacements, and deletion phases.

- [x] Inventoried dual contexts, alternate transaction carriers, source-loading fallback, projection/API shelves, test seams, historical entrypoints, and report compatibility fields.
- [x] Distinguished runtime compatibility from canonical empty-source, physical identity, diagnostics, config defaults, and offline migration behavior.
- [x] Assigned every known compatibility candidate to Phase 1, 2, 3, 4, 5, or final Phase 7 eradication.
- [x] Proposed strict decisions for report/account/row currency, Plan identity, role metadata, source path, event identity, empty source, and cycle observation.

### Completed finite slice: Phase 0C contract and readiness review

- [x] Captured and approved human, compact, JSON, metadata, cache, CLI, diagnostic, and exit-status parity (`docs/REPORT_OUTPUT_MIGRATION_CONTRACT.md`).
- [x] Inventoried every recognized `src_next` export/caller and 37 compatibility candidates with deletion gates.
- [x] Approved all strict-source requirements and audited public fixture readiness.
- [x] Defined private audit/write authorization without reading private data.
- [x] Added the strict public synthetic Phase 1 proof fixture and recorded topology/size/source-read/timing characterization (`docs/PHASE0_REPORT_ENGINE_CHARACTERIZATION.md`).
- [x] Completed Phase 0 without creating `src/`, a new context, or copied section modules.

### Completed finite slice: Phase 1A canonical fact schema proof

- [x] Defined minimal Transaction Facts, Posting Facts, Account/Domain/Layer tables, and projection diagnostics (`docs/LEDGER_FACT_SCHEMA.md`).
- [x] Projected successful complete admission without destination imports of historical parser, context, report, source I/O, or clock.
- [x] Proved aligned columns, split transaction identity, exact JPY coefficients/scale, event metadata, source lines, account/domain joins, per-transaction zero sum, and declaration-only empty Actual.
- [x] Kept the proof readonly and independent from Plan/Budget/report construction.
- [x] Compared canonical facts with the public fixture's current Trial Balance/Recent/Daily Flow/Balances/Plan evidence.
- [x] Did not copy a section, create a universal context, or add a textual query DSL.

### Completed finite slice: Phase 1B strict admission ownership

- [x] Replace complete admission's transient `historical_external_plan` structural parser dependency with `src/ledger/journal_transaction_structure.bqn`.
- [x] Preserve first-failure diagnostics, no-partial-result behavior, exact decimals, posting side, metadata, physical/durable identity, declared-account proof, and source lines.
- [x] Prove declaration-only and JPY/ILS/USD single-domain transactions, including multi-posting and precision rejection, through the canonical structure owner.
- [x] Move exact-decimal parsing/range ownership and all runtime/editor/test callers to `src/ledger/exact_decimal.bqn`; leave no old path.
- [x] Move the pure currency registry and prove strict aligned account admission with required supported currency and unclassified-role diagnostics.
- [x] Connect raw Journal plus strict Account admission to `src/ledger/facts.bqn` through pure `src/ledger/snapshot.bqn`, with no destination import of `src_next`.
- [x] Move complete/single-domain admission ownership and all runtime/editor/tool callers together; physically delete old paths and leave no forwarding wrapper.

### Completed finite slice: Phase 1C fact sufficiency and reader migration

- [x] Mapped every existing report/editor Actual requirement to canonical facts, diagnostics, another source family, or a narrow capability (`docs/ACTUAL_FACT_SUFFICIENCY.md`).
- [x] Added source-ordered typed transaction rows and exact coefficient/scale formatting without section-named fields.
- [x] Migrated Journal list/reverse and base-oriented completion readers from historical `delta` parsing to canonical Facts.
- [x] Migrated ordinary context/cycle production evidence to complete admission and deleted the runtime historical fallback; only explicit offline/test characterization users remain.
- [x] Kept Plan/Budget admission, Pivot, and Trial Balance replacement out of the reader-focused slice.

### Completed finite slice: Phase 2A strict companion admission

- [x] Defined aligned Plan and Budget transaction/posting facts from the strict public proof fixture.
- [x] Required explicit supported row currency and exact Account currency agreement.
- [x] Required durable, unique `plan_id` for Plan relationships; added no five-field fallback.
- [x] Preserved one-based source row, exact coefficient/scale/text, strict date, memo, closed metadata, and relationship identity with no partial result.
- [x] Deferred a logical Source table/index until Actual/Plan/Budget facts first share a query consumer.
- [x] Did not inspect or migrate private sources.

### Completed finite slice: Phase 2B strict cycle/config boundary

- [x] Inventoried public fixture fields consumed from config.tsv and cycle.tsv; separated source coordinates, report policy, and unresolved cycle definition.
- [x] Defined pure strict config/cycle admission with mandatory supported default currency and valid date/range/account/day coordinates.
- [x] Proved valid empty optional facts independently from explicit config/cycle definitions without fabricated transaction evidence.
- [x] Moved empty-domain policy back to source admission; generic fact projection now requires Domain only when transactions exist.
- [x] Kept broad public-fixture migration and all private source inspection out of this slice.

### Completed finite slice: Phase 3A selected-domain period capability

- [x] Defined a pure selected-domain/layer Posting Facts partition over one canonical fact result.
- [x] Derived opening, period debit/credit movement, movement, and closing per Account with exact scale and contributor Posting indices.
- [x] Proved full-period and nonzero-opening public Trial Balance values without Cube, TBDS, context, or a section module.
- [x] Kept formatting, runtime routing, shared Source table, and private source work out of the capability slice.

### Completed finite slice: Phase 3B date/category grouping proof

- [x] Derived selected-domain period income/expense postings by strict date ordinal and explicit Account role/metadata.
- [x] Produced deterministic sparse date/category groups with exact totals and contributor Posting indices.
- [x] Proved the public Daily Flow dynamic `food`/`other` axes without Cube, context, or section formatting.
- [x] Compared Account-period and date/category grouping; shared only exact arithmetic because grouping policies still differ materially.

### Completed finite slice: Phase 3C month/category extensibility gate

- [x] Reused presentation-neutral date/category evidence to group by calendar month × dynamic expense category.
- [x] Preserved exact totals and original contributor Posting indices for every sparse month/category coordinate.
- [x] Proved two months, multiple categories, multiple contributors, and mixed scales with public synthetic facts.
- [x] Extracted only explicit row-axis × bounded-column deterministic sparse Group, demonstrated identically by date/month consumers.

### Completed finite slice: Phase 3D sparse Pivot and MatrixResult

- [x] Materialized date/category and month/category sparse groups through one deterministic dense Pivot without category policy.
- [x] Preserved contributor Posting indices per dense cell and distinguished absent zero cells from explicit zero groups.
- [x] Defined the narrow presentation-neutral MatrixResult coordinates used by both consumers.
- [x] Kept labels, signs, observation/as-of policy, formatting, runtime routing, and private sources outside Pivot.

### Completed finite slice: Phase 3E Trial Balance Matrix report proof

- [x] Composed dense Account-period state directly through the canonical MatrixResult constructor without copying formulas or forcing a sparse Pivot round-trip.
- [x] Compared every Account row, opening/debit/credit/closing value, total, period coordinate, zero-sum status, and normalized human bytes with the public current report.
- [x] Added deterministic human/compact formatting from one result; correctly omitted unsupported Trial Balance JSON.
- [x] Kept production routing, cache/full composition, and broad all-report context out of the proof slice.

### Completed finite slice: Phase 3F Daily Flow Matrix report proof

- [x] Composed date/category accounting evidence and genuine sparse Pivot output into one MatrixResult with income, dynamic expenses, other, and net.
- [x] Preserved contributor Posting indices for income, expense, and derived net cells without moving observation policy into Group/Pivot.
- [x] Matched public Daily Flow semantics, deterministic destination bytes, explicit latest observation, and valid empty Actual period-start zero behavior.
- [x] Added only the human renderer required by contract; no compact/JSON or production routing.
- [x] Made empty source layers explicit in canonical admission/Facts for Actual, Plan, and Budget rather than patching Daily Flow.

### Completed finite slice: Phase 3G pure cycle resolution

- [x] Resolved admitted fixed definitions without source reload, observation, or hidden clock.
- [x] Resolved calendarMonth from explicit valid as-of with month-safe admitted start_day.
- [x] Resolved incomeAnchor from admitted Actual/Plan facts, explicit income Account, observation frontier, and durable source-qualified contributors.
- [x] Returned unavailable/error states without fabricated period, sentinel date, or numeric zero.
- [x] Split modes by their actual evidence requirements instead of introducing a universal cycle context.
- [x] Added the deferred Source table/index only when the first Actual+Plan consumer required it.
- [x] Rejected nonzero historical offset rather than silently ignoring or speculating about unsupported semantics.

### Completed finite slice: Phase 3H canonical Plan completion Join

- [x] Joined explicitly selected Plan and Actual Transaction Facts only by durable `plan_id`, with source-qualified Transaction/Posting contributors.
- [x] Preserved each source's exact coefficients/scales, currencies, and Account directions without five-field identity fallback or cross-source addition.
- [x] Distinguished open, completed, identical duplicate, conflicting ambiguous, unmatched, and invalid evidence; invalid results publish no partial rows.
- [x] Compared planned `25` / actual `20` / completed semantics with current Planned JSON on the strict public fixture.
- [x] Shared only Source validation and durable Fact references after two real cross-source consumers agreed.
- [x] Kept selection policy, source I/O, formatting, production routing, and private source work outside the Join.

### Completed finite slice: Phase 3I destination Planned Payments section

- [x] Composed resolved cycle, explicit Plan/Actual period selections, completion Join, and explicit latest-or-start observation without a report context.
- [x] Derived future/due/overdue/completed display state and refused duplicate, ambiguous, currency-mismatched, or direction-mismatched completion evidence.
- [x] Preserved current strict-fixture human/JSON semantics and added deterministic human/compact/JSON destination goldens.
- [x] Kept category labels, exact single-domain open total, temporal policy, and rendering section-local.
- [x] Emitted only the approved destination compact `ledger_planned_payment` name; no dual key or forwarding renderer.
- [x] Left production routing unchanged.

### Decision checkpoint: destination report portfolio reset

- [x] Replaced the requirement to preserve all 15 sections with a minimum portfolio of Envelope & Backing, Account Balances, Recent Journal, Planned Payments, Issues, three Account matrices, and Daily Target.
- [x] Classified current sections as retain/rebuild, merge/replace, operational diagnostic, or removable.
- [x] Kept canonical Facts/accounting capabilities durable while treating Trial Balance and Daily Flow as reusable proofs rather than mandatory final routes.
- [x] Kept current production unchanged and retained atomic deletion/no-alias/private-data boundaries.

### Completed finite slice: Portfolio contract P1

- [x] Selected the nine final destination keys, order, and human/compact/JSON support.
- [x] Defined exact axes, measures, signs, windows, observation, currency, empty/error, and provenance for Current-cycle, Cycle Comparison, and Monthly Account matrices.
- [x] Defined Envelope entitlement/consumption/refund/Plan reserve, signed total, positive backing requirement, funding surplus, and separate Budget reconciliation.
- [x] Selected conservative Daily Target arithmetic with explicit target date and per-obligation reservation provenance; future income does not inflate P1 safe capacity.
- [x] Mapped every old section plus shared catalog/cache/compact/query/JSON/UI/check consumer families to migration or atomic removal.
- [x] Selected retained implementation order without resuming old-section parity work.

### Completed finite slice: Portfolio P2 Account Balances

- [x] Derived exact Actual closing through explicit observation for every Account in one selected domain, including zero-posting Accounts.
- [x] Preserved source-qualified Posting contributors and rejected unknown domain, invalid observation, wrong Facts, normalization failure, or exact overflow without partial rows.
- [x] Built the retained `balances` one-column Matrix/List result and one human/compact/JSON semantic owner.
- [x] Proved JPY history, ILS mixed scales, USD valid empty Actual, deterministic Account order, zero-sum, and observation sensitivity on public synthetic evidence.
- [x] Extracted JSON text construction only after Planned Payments and Account Balances agreed on the operation; Planned JSON bytes remain stable.
- [x] Compared retained nonzero Balance semantics while intentionally showing zero Accounts and excluding implicit-domain compatibility.
- [x] Left production routing, compact key replacement, old-owner deletion, filesystem composition, and private sources outside this proof slice.

### Completed finite slice: Portfolio P3 Recent Journal

- [x] Built a newest-first source-ordered Actual Transaction List directly from canonical Facts with explicit positive limit.
- [x] Preserved multi-posting debit/credit Account arrays, exact debit total, domain, durable Transaction reference, and separate Posting contributors.
- [x] Returned valid empty List for empty Actual and failed closed on wrong source, invalid limit, lane/scale inconsistency, or exact overflow.
- [x] Implemented retained `recent` human/compact result with tab-delimited `ledger_recent_journal`; JSON remains unsupported.
- [x] Matched strict public newest-first semantics including the split Transaction without old context/transaction/report owners.
- [x] Extracted plain table rendering only after Planned Payments and Recent Journal agreed; existing Planned bytes remain stable.

### Completed finite slice: Portfolio P4 Current-cycle Accounts

- [x] Composed resolved cycle, explicit observation, and canonical Account-period capability into retained `cycle-accounts`.
- [x] Included every selected-domain Account with opening/debit/credit/movement/closing and source-qualified provenance.
- [x] Kept credit signed negative and validated movement/closing arithmetic plus exact zero-sum totals.
- [x] Proved partial/full cycle, empty Actual, JPY/ILS/USD, invalid/outside/mismatched observation, unavailable cycle, and deterministic order.
- [x] Implemented human-only retained Matrix without reviving Cycle Summary or Trial Balance routes.

### Completed finite slice: Portfolio P5 Monthly Accounts

- [x] Built dense Month × Account signed Actual movement over strict explicit month coordinates.
- [x] Included every requested month and admitted Account, preserving empty rows and zero cells.
- [x] Preserved source-qualified cell contributors and independently reconciled month/Account/grand totals.
- [x] Proved JPY/ILS/USD, mixed scale, empty month/Actual, invalid range/domain, and deterministic axes.
- [x] Implemented human-only output without month-end balance, debit/credit submatrices, or YTD Cards.

### Completed finite slice: Portfolio P6 Cycle Comparison

- [x] Compared two explicit accounted windows under `aligned_elapsed | complete_cycles` without period search.
- [x] Derived all-Account current movement, baseline movement, and exact difference with scale normalization.
- [x] Preserved separate source-qualified window evidence plus difference union/evidence coordinates.
- [x] Proved equal elapsed windows, complete 31/28-day cycles, unavailable baseline, mixed scale, empty Actual, and invalid policy/window combinations.
- [x] Implemented human-only Matrix without old Actual Comparison ratios, lanes, or statuses.

### Completed finite slice: Portfolio P7 Envelope & Backing

Quality completion is governed by [`docs/DESTINATION_QUALITY_GATE.md`](docs/DESTINATION_QUALITY_GATE.md); every P7 dimension is green.

- [x] Refactored into named validation, ownership, prepared-evidence, per-envelope, aggregate-backing, and publication stages.
- [x] Composed strict Budget/Actual/Plan Facts, explicit horizon/observation, completion Join, and admitted envelope/funding ownership.
- [x] Kept entitlement, consumption, refunds, ledger remaining, open Plan reserve, and post-Plan headroom distinct.
- [x] Kept funding, signed claims, positive requirement, surplus, Budget unassigned, and reconciliation as separate evidence systems.
- [x] Preserved source-qualified contributors and rejected invalid ownership/domain/range, completion conflict, and normalization overflow.
- [x] Proved overspent, under-backed, open/completed Plan, refund, empty Plan, and human/compact/JSON Statement surfaces.

### Completed finite slice: Portfolio P8 Daily Target

- [x] Composed explicit observation/target, selected assets, open obligations, and per-obligation reservation provenance.
- [x] Deducted each obligation exactly once and excluded future income from the accepted input boundary.
- [x] Preserved assets, gross obligations, already excluded, deduction, capacity, remaining days, target, and shortfall as separate exact coordinates.
- [x] Treated deficit as successful evidence and rejected ownership/date/provenance/range conflicts and overflow.
- [x] Proved funded, deficit, reservation, empty/overdue obligations, mixed scales, and human/compact surfaces without JSON.

### Completed finite slice: Portfolio P9 Issues

- [x] Defined strict source-ordered admission with durable identity, status, optional date, category/title, optional exact amount/currency, details, and source reference.
- [x] Kept Issues outside accounting Facts and documented atomic editor migration to the same admission owner without a fallback parser.
- [x] Built an open-by-default List; absent/header-only evidence is valid empty and invalid admission publishes no partial rows.
- [x] Implemented human-only output with deterministic public proof and no report-text parsing contract.
- [x] Passed the destination quality gate; all nine retained report proofs are now complete.

### Current finite slice: Portfolio P10 Composition and cutover preparation

- [ ] Build pure one-request-at-a-time destination composition over already-read source snapshots, explicit time/domain/limit/ownership coordinates, and the static nine-key catalog.
- [ ] Add destination CLI routing and explicit unsupported-surface errors without changing production `tools/report` yet.
- [ ] Prove full/catalog/individual public fixture behavior, deterministic clock injection, cache manifest, and import boundaries.
- [ ] Reconcile operational `check`/`debug` ownership with `tools/ledger-check` and `tools/ledger-inspect` before old routes are removed.
- [ ] Inventory external compact/query/cache consumers with moko before deleting old keys, then prepare one atomic cutover diff.
- [ ] Keep private-source readiness under separate explicit authorization; do not inspect or rewrite user data in this public composition slice.

Phase 0 exit evidence is `docs/PHASE0_REPORT_ENGINE_CHARACTERIZATION.md`: every observable report capability has an owner, every compatibility path has a deletion gate, and no undecided fallback is permitted in the destination fact schema.

## Migration rules

- Keep the current daily report usable at every merged checkpoint.
- New code must never accept an old context or historical transaction shape.
- New code may not import old report code.
- Move modules with all callers and leave no forwarding wrapper at the old path.
- Replace a section across human, compact, JSON, cache, query, tests, and docs in one slice, then delete its old implementation.
- Migrate source data rather than carrying a fallback into the destination runtime.
- Apply private-data migration only under explicit human direction, with preview, backup, and stale checks.
- Final cutover deletes `src_next`, old entrypoints, fallback parsers/proofs, compatibility delegates, `ForTest` aliases, and `_for_test` production modules.
- Git is rollback; compatibility wrappers are not rollback.

## Standing work outside the selected migration

- Keep improving daily editor safety and ergonomics from actual use.
- Treat migration/cleanup tools for historical source data separately from production runtime compatibility.
- Do not add FX conversion, mixed-domain totals, a universal Cube, or a generic query DSL without a separate concrete decision.
- Do not modify or publish canonical private household data without explicit human direction.

## Working principles

- Arithmetic domain is an explicit partition/key requirement, not an implicit property of numeric grouping.
- Transaction metadata is not posting-level account classification.
- Native multi-posting transactions are never flattened back into a two-account source row.
- Share admitted evidence and proven accounting capabilities, not all-report semantic results.
- A section core receives narrow prepared evidence and an explicit observation; it does not read source files or the system clock.
- Flat stages preserve first-failure ownership and return no partial admitted result.
- Code and directory beauty mean truthful ownership, not maximum splitting or nesting.
