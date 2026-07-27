# Ledger-facts report engine migration roadmap

Status: active implementation roadmap
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Current production remains: `tools/report` → `src_next/report.bqn` until the cutover gate passes

## 1. Goal

Keep every current report capability while replacing the current report engine with one based on canonical admitted ledger facts and narrow report queries. Report definitions must remain disposable: after migration, all 15 current sections can be removed without changing ledger admission, accounting facts, or the report-construction kernel, and new reports can be assembled from array-oriented query parts.

The destination is not another all-report hub:

```text
source files
  -> one source snapshot
  -> strict admission
  -> canonical transaction/posting facts
  -> narrow accounting capabilities
  -> section-specific result
  -> human / compact / JSON renderer
```

The migration is complete only when the old runtime, old import paths, fallback transaction shapes, compatibility wrappers, and compatibility-only tests have been physically removed. Git and archived documents preserve history; production code does not.

## 2. Scope

All current human section keys remain capabilities:

```text
snapshot
issues
ytd
balances
cycle
trial-balance
envelopes
planned
recent
check
outlook
daily-trend
daily-flow
actual-comparison
debug
```

The migration also covers:

- the full human report;
- direct selected-section output;
- section metadata and canonical order;
- section cache generation and invalidation;
- the compact machine summary and `tools/query` consumers;
- supported section JSON output;
- developer inspection;
- editor reads that consume the same admitted Journal facts;
- source provenance, diagnostics, exit status, zero/unavailable distinction, and fail-closed behavior.

This roadmap does not authorize changing canonical household data without explicit human direction.

## 3. Non-goals

- Do not reduce the report list to make migration easier.
- Do not create a universal 100-field report record.
- Do not make Cube or TBDS the sole representation of every accounting question.
- Do not invent a generic query DSL before concrete report queries demonstrate common vocabulary.
- Do not add FX conversion, a reporting-currency total, or mixed-domain arithmetic.
- Do not rewrite the editor and report engine simultaneously.
- Do not preserve an old API merely because a historical test names it.
- Do not create old-path forwarding modules after moving code.

## 4. Destination boundaries

### 4.1 Source snapshot

The only effectful reader produces a bounded record determined by source files, not report sections:

```text
config
account lines
Actual Journal raw text
plan lines
budget allocation lines
cycle lines
issue lines
source identities
```

Adding a report must not add a field to this record. Metadata/list-sections requests must not read household source files.

### 4.2 Canonical admitted evidence

The canonical accounting carrier is fixed by the ledger domain:

```text
resolved accounts
admitted transactions
admitted postings
admitted plan evidence
admitted budget evidence
issues
source diagnostics and provenance
```

Actual uses complete admission only. The canonical transaction fact preserves transaction identity and metadata; the posting fact preserves exact amount, domain, account, source identity, and transaction identity. Native multi-posting transactions are never flattened back into a two-account row.

The complete-admission shape already carries the required foundation: date, description, layer, plan identity, metadata, domain, exact normalized coefficient, account key, source line, transaction ID, and posting ID. Phase 1 must prove coverage for every report before this statement becomes the new runtime contract.

### 4.3 Narrow accounting capabilities

Shared modules may own only stable accounting meanings with multiple real callers, for example:

- explicit date/domain/layer/account masks;
- period selection;
- opening/movement/closing;
- exact grouping;
- transaction/posting joins;
- completion evidence;
- cycle resolution from admitted evidence;
- Cube and TBDS as optional materialized views.

A capability must not return fields named for unrelated report sections.

### 4.4 Array-oriented report construction

Canonical facts are columnar arrays, not one heterogeneous matrix. A posting fact set exposes aligned columns such as:

```text
posting_id
transaction_index
date_ordinal
account_index
layer_index
domain_index
coefficient
scale
side
source_index
```

Transaction metadata, account metadata, and source provenance remain side tables joined through explicit indices. A query selects one arithmetic domain/scale or partitions by domain before aggregation; it never adds unrelated currencies.

The reusable report-construction vocabulary is intentionally small:

```text
Select      facts + explicit predicates -> row mask / selected indices
Join        selected facts + indexed side table -> prepared columns
Group       keys + exact values -> sparse deterministic groups
Pivot       row keys + column keys + measures -> report matrix
Period      facts + interval -> opening / movement / closing
Contribute  result cells/groups -> source posting indices
Sort        explicit keys/measures -> deterministic order
```

Conceptually, a balance by account is an incidence-matrix operation such as `Accountᵀ × selected_amounts`; implementation may use sparse grouping rather than allocate a dense one-hot matrix. Dense Day × Account × Layer materialization remains an optional view, not the mandatory query representation.

The construction layer has two extension modes:

1. **Declarative matrix/list reports** — a spec supplies source facts, filters, row axis, column axis, measures, ordering, totals, and presentation labels.
2. **Custom semantic reports** — a pure BQN Build function composes narrow capabilities for stateful or policy-heavy questions such as completion timing, Envelope backing, or Outlook.

A declarative spec may produce one of a few small presentation-neutral result shapes rather than a universal report record:

```text
MatrixResult: row keys/labels, column keys/labels, cells, availability mask, contributors, diagnostics
ListResult:   ordered typed columns, contributors, diagnostics
CardResult:   named scalar values/states, contributors, diagnostics
```

Zero, unavailable, rejected evidence, and not-applicable remain distinct. Every numeric cell can retain contributor posting indices for inspection.

The initial API is ordinary BQN data/functions. A textual query language or user config syntax is added only after at least two real reports prove the same spec vocabulary. Adding a report must not require changing admission or canonical fact schemas.

### 4.5 Section boundary

Each section owns a pure semantic build and its renderers:

```text
Build(narrow prepared evidence, explicit options) -> section result
FormatHuman(section result)                       -> text
FormatCompact(section result)                     -> text, when supported
FormatJson(section result)                        -> JSON, when supported
```

Rules:

- no source paths or `base` in semantic Build;
- no `loader`, source resolver, config reader, or system clock in a section core;
- no source amount-text parsing after admission;
- no context-field fallback;
- no test-only alias for a private compatibility shape;
- renderer input is the section result, not a global context;
- section-local time policy remains local when its meaning is not identical to another section.

### 4.6 Composition root

One small composition root owns routing only:

- section key and order;
- section builder function;
- supported render formats;
- CLI dispatch;
- full-report/cache iteration.

It does not own accounting calculations and does not build an all-section semantic record. Full report generation builds and renders each section from explicit shared evidence; direct section generation builds only the selected section.

### 4.7 Dependency direction

```text
CLI / composition
  -> sections
  -> accounting capabilities
  -> admitted evidence
  -> source admission
```

Forbidden dependencies:

```text
ledger/admission -> report section
accounting capability -> report composition
new runtime -> src_next compatibility module
renderer -> source loader
section A -> section B renderer or ViewModel
```

A composite report such as Outlook may consume a lower-level accounting capability also used by Snapshot, but must not consume Snapshot's renderer or broad report ViewModel.

## 5. Destination source layout

The final production path is `src/`, not another indefinitely named `next` tree. Directories are created only as code moves; do not create an empty skeleton.

Expected ownership neighborhoods are:

```text
src/source/       source snapshot and path policy
src/ledger/       strict admission and canonical facts
src/accounting/   period, grouping, cycle, Cube/TBDS, completion capabilities
src/sections/     section-specific Build and render functions
src/report/       static catalog, routing, cache/full composition
src/cli/          report, summary, and inspection entrypoints
```

This is an ownership target, not authorization to split every current file mechanically. A module moves only with all repository callers, tests, and docs; no wrapper remains at its previous path.

`src_edit/` remains a separate write-side boundary but must import the same final strict ledger admission modules instead of `src_next` compatibility APIs.

## 6. What “no compatibility code remains” means

At final exit, production runtime has none of the following:

- `src_next/` or imports targeting it;
- complete-or-historical transaction carriers;
- `historical_external_plan` report parsing;
- `legacy_compatibility` or `empty_source_compatibility` arithmetic proof paths;
- missing-currency, missing-default-currency, or historical balances fallback branches;
- broad `Build`, `BuildAt`, tuple, context, and prepared aliases for the same semantic operation;
- `ForTest` exports or production modules named `_for_test`;
- projection/cube delegate shelves that only preserve old import names;
- source-loading fallback inside a context helper;
- five-field plan identity fallback, if the Phase 0 data decision requires explicit durable plan identity;
- old report entrypoint wrappers and historical names retained as aliases;
- checks whose purpose is to require a compatibility wrapper to exist.

Historical words may remain in archived documents, migration tools, and fixtures that test explicit rejection or one-time data cleanup. They must not remain on the production read/report path.

Compatibility is classified by behavior and dependency, not by blind text search. Phase 0 records every candidate as one of:

```text
DELETE_RUNTIME_COMPATIBILITY
MIGRATE_SOURCE_DATA_THEN_DELETE
KEEP_CANONICAL_DOMAIN_BEHAVIOR
KEEP_OFFLINE_MIGRATION_TOOL
ARCHIVE_ONLY
```

## 7. Migration rules

1. Current daily report remains usable at every merged checkpoint.
2. New code never accepts an old context or historical transaction shape.
3. A temporary bridge must be named in the active slice and deleted by that slice's exit; no open-ended adapter is allowed.
4. New code may be called by old code during strangler migration; new code must never import old report code.
5. When a module is moved, update all callers and delete the old path in the same change.
6. When a section is replaced, switch human, compact, JSON, cache, tests, and docs together, then delete the replaced implementation.
7. Do not keep both old and new implementations after parity is established.
8. Output parity must be implemented through canonical facts, not by reproducing an invalid fallback. Migrate data or approve an explicit contract change instead.
9. Private-data migration is previewed, backed up, stale-checked, and run only under explicit human direction.
10. Every phase ends with a caller/export/dead-file inventory and current-document cleanup.

## 8. Phases

### Phase 0 — Contract and compatibility inventory

No production architecture changes begin before this phase is complete.

- [x] Capture all 15 human sections, order, first-line markers, full-report boundaries, cache keys, compact blocks, JSON schemas, exit codes, and supported CLI options.
- [x] Identify which outputs require byte parity and which require semantic/schema parity.
- [x] Inventory every `src_next` export and all callers across `src_next`, `src_edit`, `tools`, `checks`, and `tests`.
- [x] Inventory every runtime fallback, alias, wrapper, alternate transaction shape, test seam, and historical entrypoint.
- [x] Classify each compatibility candidate using the five categories in section 6.
- [x] Decide strict source requirements: `DEFAULT_CURRENCY`, source currency metadata, plan identity, cycle requirements, and empty-source behavior.
- [x] Record required one-time source migrations before removing each fallback.
- [x] Add public synthetic parity fixtures without copying private household values (`fixtures/ledger-facts-phase1-proof/`).
- [x] Record current import graph, module/export count, source reads, and report timings as characterization, not pass thresholds (`docs/PHASE0_REPORT_ENGINE_CHARACTERIZATION.md`).

Exit:

- every current observable report contract has an owner;
- every compatibility path has a deletion gate;
- no undecided fallback is allowed into the new ledger schema.

### Phase 1 — Prove the canonical complete-admission schema

- [x] Define transaction and posting fact schemas with exact domain, scale, identity, and source provenance (`docs/LEDGER_FACT_SCHEMA.md`).
- [ ] Project complete admitted Actual transactions into those facts without a historical parser.
- [ ] Prove multi-posting, declaration-only, JPY/ILS/USD single-domain, metadata, plan completion, and source-line behavior.
- [ ] Prove that every report-required fact can be derived from complete admission or name the missing canonical field.
- [ ] Extend complete admission only for real canonical evidence; do not add report fields.
- [ ] Make editor read commands consume the same admitted transaction facts where applicable.
- [ ] Add fail-closed tests for invalid, mixed, unsupported, duplicate, and empty evidence.

Exit:

- one Actual transaction shape is sufficient for reports and editor reads;
- new code has no dependency on `journal_profile_stage1` or `historical_external_plan`.

### Phase 2 — Make companion sources strict

- [ ] Admit plan and budget sources into exact, domain-proven posting evidence.
- [ ] Require explicit source/account currency according to the Phase 0 decision.
- [ ] Resolve plan completion with one canonical identity rule.
- [ ] Resolve accounts and source metadata once per source snapshot.
- [ ] Keep issues as non-accounting facts rather than forcing them into Posting IR.
- [ ] Build readonly audit tools for source rows that require migration.
- [ ] Migrate public fixtures.
- [ ] Preview and apply private source migration only under explicit human direction.
- [ ] Delete each fallback immediately after all supported sources satisfy its replacement contract.

Exit:

- canonical facts contain no legacy proof basis or identity fallback;
- valid empty sources remain explicit, domain-safe states rather than compatibility exceptions.

### Phase 3 — Establish accounting capabilities

Implement only capabilities required by the report migration:

- [ ] selected-domain posting partition;
- [ ] ledger-wide and period views;
- [ ] opening/movement/closing;
- [ ] exact account/date grouping;
- [ ] cycle resolution from admitted facts;
- [ ] completion and transaction metadata joins;
- [ ] Cube/TBDS construction where they remain useful;
- [ ] source-order/provenance access for reports that require it;
- [ ] composable selection masks over typed fact columns;
- [ ] deterministic sparse grouping with contributor indices;
- [ ] row-axis/column-axis pivot construction;
- [ ] MatrixResult, ListResult, and CardResult presentation-neutral shapes.

For each capability:

- [ ] use explicit inputs and one result shape;
- [ ] preserve first-failure diagnostics and no-partial-result behavior;
- [ ] prove at least two identical consumers before extracting generic vocabulary;
- [ ] forbid section-named fields;
- [ ] compare against current public fixture results;
- [ ] move coherent existing modules to `src/accounting/` with all callers and no old-path wrapper.

Report-construction proof:

- [ ] implement two materially different real matrix/list reports through the same Select/Group/Pivot vocabulary;
- [ ] implement one report that retains contributor posting indices;
- [ ] implement one synthetic report not present in the current 15-section catalog without changing admission, fact schema, or accounting kernel;
- [ ] prove selected-domain exactness and deterministic row/column ordering;
- [ ] prove unavailable/rejected cells cannot silently become numeric zero.

Exit:

- sections can be implemented without `BuildContext`;
- ordinary tabular reports can be expressed as specs over canonical facts;
- policy-heavy reports can compose custom pure Build functions without extending a global record;
- no universal report result or premature textual query DSL has been introduced.

### Phase 4 — Migrate report sections by dependency cohort

Each section slice must replace all of its public surfaces and delete the superseded implementation in the same slice.

#### Cohort A: direct evidence and diagnostics

```text
issues
recent
check
debug
trial-balance
```

#### Cohort B: balances and periods

```text
balances
snapshot
ytd
cycle
actual-comparison
```

#### Cohort C: plan and budget

```text
planned
envelopes
```

#### Cohort D: temporal composite reports

```text
daily-flow
daily-trend
outlook
```

The order inside a cohort follows the actual dependency graph. A shared capability migrates before its consumers; a renderer never becomes a shared capability.

Per-section checklist:

- [ ] classify the section as declarative Matrix/List/Card or custom semantic Build;
- [ ] list exact canonical fact/capability inputs;
- [ ] define one pure semantic result;
- [ ] implement human, compact, and JSON renderers from that result as applicable;
- [ ] preserve section-local observation and absence policy;
- [ ] compare retained output contracts on positive, empty, and invalid fixtures;
- [ ] switch direct, full, cache, compact, JSON, and query consumers together;
- [ ] delete the old module, adapters, focused compatibility checks, and stale docs;
- [ ] verify no other section imports the migrated section's ViewModel or renderer.

Exit:

- all 15 sections are built from canonical facts and narrow capabilities;
- no section reads source files or an old context.

### Phase 5 — Replace report composition and entrypoints

- [ ] Create one static section catalog and one runtime route mapping.
- [ ] Generate list-sections and metadata without household source reads.
- [ ] Build only the selected section for direct human/JSON requests.
- [ ] Iterate all sections for full report and cache without constructing an all-section semantic record.
- [ ] Generate compact output from registered compact renderers in canonical order.
- [ ] Capture system today once and pass explicit section observations.
- [ ] Preserve Outlook's explicit override as a section option, not a report-wide implicit clock.
- [ ] Make cache publication delete retired/unmanifested files and publish the manifest/timestamp atomically.
- [ ] Introduce canonical entrypoint names (`tools/report`, `tools/report-summary`, and a plainly named inspection tool).
- [ ] Update Command Hub, `tools/query`, editor diagnostics, and maintenance scripts.

Exit:

- report composition owns routing only;
- old historical entrypoint names have no supported caller.

### Phase 6 — Shadow verification and operational cutover

- [ ] Run old and new engines independently on every public report fixture.
- [ ] Compare byte-contract outputs, structured schemas, diagnostics, and exit status.
- [ ] Explain every approved difference in the current contract, not a compatibility adapter.
- [ ] Verify source read counts and selected-section execution behavior.
- [ ] Add and remove a temporary novel report definition without changing source admission, canonical facts, accounting capabilities, or unrelated section modules.
- [ ] Run readonly private-data shadow comparison under explicit human direction.
- [ ] Exercise daily use for an agreed observation period without changing the canonical source through the new report path.
- [ ] Verify editor preview/list workflows against the canonical admitted facts.
- [ ] Prepare a single reversible cutover commit and rollback command.

Exit:

- moko explicitly accepts the new report output and cutover;
- no unexplained monetary, status, ordering, or absence difference remains.

### Phase 7 — Atomic cutover and compatibility eradication

In the cutover change:

- [ ] route `tools/report`, Command Hub, cache, summary, query, and inspection to `src/`;
- [ ] update `src_edit` imports to final strict ledger modules;
- [ ] remove old entrypoint wrappers instead of forwarding them;
- [ ] delete `src_next/` after the last caller moves;
- [ ] delete historical report/summary tool names instead of aliasing them;
- [ ] delete compatibility source parsers, proof paths, delegates, context wrappers, `ForTest` aliases, and `_for_test` production modules;
- [ ] delete checks that require old compatibility behavior;
- [ ] delete or rewrite fixtures whose sole purpose was preserving a removed fallback;
- [ ] invalidate old cache generation and remove unmanifested cached section files;
- [ ] update README, architecture, code map, contracts, maintenance, setup, release, and extension docs;
- [ ] archive this roadmap and shorten `TODO.md` after verification.

No compatibility deletion is deferred past this phase.

### Phase 8 — Final absence audit

- [ ] `src_next/` does not exist.
- [ ] No production, editor, tool, check, or test import targets `src_next`.
- [ ] No old report entrypoint wrapper exists.
- [ ] No runtime complete-or-historical carrier or historical parser fallback exists.
- [ ] No runtime `legacy_compatibility`/`empty_source_compatibility` arithmetic basis exists.
- [ ] No production `ForTest` export or `_for_test` module exists.
- [ ] No compatibility-only projection/cube/context delegate exists.
- [ ] Every public export has a repository caller or a documented external contract.
- [ ] Import graph has no missing target or cycle and respects the dependency direction in section 4.7.
- [ ] Every retained report section is reachable through the canonical catalog and has no duplicate implementation.
- [ ] Deleting every section definition would leave source admission, canonical facts, and accounting/report-construction kernels intact.
- [ ] A new matrix report can be added with one report definition, focused tests, and optional catalog registration, without editing the ledger kernel.
- [ ] Full `tools/check.sh`, focused negative admission checks, report parity checks, cache checks, and `git diff --check` pass.
- [ ] Current docs describe only the final runtime; historical design remains under `docs/archive/`.

## 9. Phase completion record

Every merged phase/slice records:

```text
slice:
canonical capability added:
old runtime/code deleted:
compatibility candidates closed:
report surfaces switched:
source-data prerequisite:
behavior/parity evidence:
module/export/line delta:
remaining temporary bridge and mandatory deletion phase:
checks:
```

A slice with a new bridge but no named deletion phase is incomplete.

## 10. Stop and rollback rules

Stop the migration slice when:

- canonical facts cannot represent a required report meaning without a section-specific field;
- new code needs to import an old context or formatter;
- output parity can only be achieved through an unexplained fallback;
- currency/domain proof becomes implicit;
- a private source migration would be required without explicit human approval;
- a supposedly shared query has only one real consumer;
- the old implementation cannot be deleted after its replacement is switched.

Rollback uses Git and the still-working previous `tools/report` commit. Do not preserve rollback by leaving production wrappers in the new tree.

## 11. First finite slice

The first implementation slice is Phase 0 only: produce the contract/compatibility inventory and strict-source decision table. Do not create `src/`, copy section modules, or add a new context until that inventory is reviewed.
