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
  -> all 15 existing report sections
  -> human / compact / JSON
  -> atomic cutover
  -> complete deletion of old compatibility runtime
```

This is not a section-reduction campaign and must not recreate the old giant all-report record. Shared records are bounded by source/accounting facts; section-specific results remain local. The destination also includes an array-oriented Select/Join/Group/Pivot layer so current report definitions are disposable and new matrix/list reports do not require ledger-kernel changes.

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

### Current finite slice: Phase 3F Daily Flow Matrix report proof

- [ ] Compose date/category accounting evidence and Pivot output into one section-local MatrixResult including income, dynamic expenses, other, and net.
- [ ] Preserve contributor Posting indices for income, expense, and derived net cells without moving observation policy into Group/Pivot.
- [ ] Match the public current Daily Flow body and its section-specific as-of/empty behavior where evidence is sufficient.
- [ ] Add only the human renderer required by the approved contract; do not add compact/JSON or production routing.

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
