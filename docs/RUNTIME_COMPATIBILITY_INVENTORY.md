# Runtime compatibility and deletion inventory

Status: Phase 0B current evidence
Owner: ledger-facts report migration
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`
Scope: production, editor, tools, checks, and tests at `b5cdcc6`

## Purpose

Identify every known runtime compatibility route that can contaminate the destination ledger-facts design. Each candidate is classified and given a prerequisite, replacement, and mandatory deletion phase.

This inventory does not treat every occurrence of “legacy” or “fallback” as obsolete. Historical-data cleanup tools, valid empty-source behavior, optional physical source identity, and diagnostic observations are different from production compatibility routing.

## Classification

- `DELETE_RUNTIME_COMPATIBILITY` — replace callers and physically delete the route/API/module.
- `MIGRATE_SOURCE_DATA_THEN_DELETE` — source must become explicit before runtime support is deleted.
- `KEEP_CANONICAL_DOMAIN_BEHAVIOR` — behavior is part of the destination accounting/product contract, even if current naming is historical.
- `KEEP_OFFLINE_MIGRATION_TOOL` — not on the report/read runtime; retain only as an explicit migration/cleanup command.
- `ARCHIVE_ONLY` — no destination runtime caller; remove code/tests and rely on Git/archive history.

## Point-in-time topology evidence

```text
src_next modules:        75
root modules:            71
nested modules:           4
direct internal imports: 286
import cycles:             0
missing imports:           0
```

High-pressure surfaces observed by repository-wide search:

```text
BuildContext:                 77 references / 47 files
ForTest symbols:              60 references / 14 files
projection.bqn direct import:  7 runtime modules
report-next-summary name:     42 references / 26 files
actual_source.LoadTransactions: 0 (symbol deleted)
actual_source.LoadTransactionRows: 2 editor callers + completion adapter
actual_source.CompletionEvidence: 6 plan editor commands on canonical facts
```

These counts are characterization. Final deletion is proved by absence and caller migration, not by preserving the counts.

## A. Runtime source/context topology

### C01 — `src_next/` as the production ownership tree

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current callers: production report/summary/inspection, editor imports, tools, checks, tests, and docs.
- Current behavior: the once-candidate tree is now production and contains both canonical foundations and migration shelves.
- Destination: ownership-based modules under `src/`; `src_edit/` imports final strict ledger modules.
- Prerequisite: all canonical modules and all 15 sections migrated; canonical entrypoints accepted.
- Delete: Phase 7. The directory must not exist after cutover; no old-path forwarding modules.

### C02 — ordinary `context.BuildContext`

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current callers: report, compact summary, developer inspection, envelope calculator, `src_edit/journal_validate_cmd.bqn`, characterization tools, checks, and many focused tests.
- Current behavior:
  - builds one broad context containing cycle, accounts, posting rows, Cube, TBDS, issues, historical Actual transactions, and proof state;
  - uses the historical parser for production posting rows;
  - exposes many source/projection construction helpers.
- Destination: one strict source snapshot and admitted fact set; sections receive narrow facts/capabilities.
- Prerequisite: Phases 1–4 replace actual admission, companion admission, period views, and all section callers.
- Delete: last production caller in Phase 4; module/path removed in Phase 7.

### C03 — `selected_domain_context`

- Classification: `KEEP_CANONICAL_DOMAIN_BEHAVIOR`
- Current callers: selected Balances, selected-domain sparse query test, direct tests, and characterization.
- Canonical behavior to keep:
  - one explicit registry-supported domain;
  - complete Actual admission;
  - exact context-local normalization;
  - no partial result or mixed-domain total;
  - flat first-failure stages.
- Compatibility to delete:
  - separate context object competing with ordinary `BuildContext`;
  - old path/name and prepared wrapper shape;
  - source adapters duplicated with the canonical ledger loader.
- Destination: selected-domain partition and normalization capabilities under `src/ledger`/`src/accounting`.
- Delete/move: behavior established in Phases 1–3; old module removed with all callers, no wrapper.

### C04 — dual ordinary/selected Balances routes

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current callers: direct Balances dispatch, full report, cache, JSON, compact summary.
- Current behavior: direct/default selected human Balances uses strict complete admission; missing `DEFAULT_CURRENCY` full/cache and JSON can use the ordinary JPY compatibility body.
- Destination: one selected-domain Balances result used by human, compact, JSON, full, and cache.
- Source prerequisite: C16 (`DEFAULT_CURRENCY`) complete.
- Delete: Balances migration in Phase 4.

### C05 — `actual_source.LoadTransactions` historical parser route — closed

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Closed in Phase 1C: the symbol and historical parser route were deleted.
- Replacement: Journal list/reverse and base-oriented completion readers consume `LoadTransactionRows`, derived from canonical complete admission and Transaction/Posting Facts.
- Characterization tests that intentionally exercise the retired Posting IR adapter import the archived-shape parser explicitly; production `actual_source` does not.

### C06 — `actual_source.LoadCycleEvidence` complete-or-historical carrier — runtime fallback closed

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Phase 1C: production `LoadCycleEvidence` now fails closed on canonical complete admission and never invokes `historical_external_plan`; ordinary `BuildContext` also carries complete transactions.
- Remaining cleanup: remove the `complete` discriminator and legacy interpretation branch after focused cycle characterization is rewritten around canonical facts in Phase 3.
- Destination: cycle always consumes canonical complete admitted facts.

### C07 — context-field fallback loaders in `actual_source`

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current paths:
  - `DatesFromContext` falls back to base loading;
  - `CompletionEvidenceFromContext` falls back to canonical base-oriented completion when prepared transactions are absent;
  - report helpers accept focused mock contexts with missing fields.
- Destination: explicit transaction/date/completion arguments; tests construct canonical facts directly.
- Prerequisite: section and editor callers migrated to narrow inputs.
- Delete: per-consumer in Phase 4; final absence in Phase 7.

### C08 — cycle source-loading and alternate-carrier API shelf

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current exports:
  - `ReadCycle(base | ⟨base,as_of⟩)`;
  - `ReadCycleFromActualEvidence` / `At`;
  - `ReadCycleFromAdmittedTransactions`.
- Current callers: ordinary context, selected context, TBDS/tests/characterization, shadow context.
- Canonical behavior to keep: fixed, incomeAnchor, and calendarMonth period semantics with explicit observation and admitted evidence.
- Destination: one shared resolved-period shape with mode-specific pure resolvers, so fixed/calendar modes do not accept unused Facts and incomeAnchor accepts explicit Actual/Plan evidence only.
- Progress: destination fixed/calendarMonth/incomeAnchor proof is complete under `src/accounting`; unavailable/error never becomes a sentinel period, and nonzero ignored offset is rejected.
- Remaining prerequisite: move runtime callers to strict source/use-case composition.
- Delete: old source-loading/carrier adapters with their final runtime callers; no forwarding resolver remains.

### C09 — `actual_source.ResolveRelativePath` `base/data/` path fallback

- Classification: `MIGRATE_SOURCE_DATA_THEN_DELETE`
- Current callers: context, selected context, tests, characterization.
- Current behavior: if `<base>/<file>` is missing and `<base>/data/<file>` exists, silently rewrites the relative path.
- Destination: configured safe basename resolved in exactly one documented base directory.
- Prerequisite: audit public fixtures and private configured base layout; relocate/configure only under explicit human direction.
- Delete: Phase 1 source snapshot cutover.

### C10 — report-local source reads and amount parsing

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current examples:
  - Cycle/Planned/Envelope/Outlook read Plan or Budget lines;
  - Actual Comparison reads `cycle.tsv`;
  - Readiness reads source counts;
  - Envelope parses allocation amount text;
  - Plan rows parse amount text and identity.
- Destination: source snapshot reads once; strict companion admission produces canonical facts and metadata.
- Prerequisite: Phase 2 plan/budget/config/cycle admission.
- Delete: each section slice in Phase 4.

### C11 — test-only Journal shadow/read carriers in production tree

- Classification: `ARCHIVE_ONLY`
- Current modules include:
  - `journal_shadow_context.bqn` (no runtime/test caller outside historical docs/index);
  - `journal_read_only_source_carrier.bqn` (focused rehearsal tests);
  - `journal_posting_identity_provenance_stage2b.bqn` (focused characterization tests).
- Destination: canonical complete fact tests cover source identity, provenance, and report information boundaries directly.
- Prerequisite: Phase 1 fact-schema tests replace unique safety evidence.
- Delete: Phase 1 or Phase 7 at latest; do not move as compatibility modules.

## B. Source-data compatibility

### C12 — missing Account currency defaults to JPY

- Classification: `MIGRATE_SOURCE_DATA_THEN_DELETE`
- Current owner: `account_key.CurrencyFromMeta` defaults to `JPY`; compatibility proof also assumes JPY for missing evidence.
- Current callers: all account resolution and ordinary report paths.
- Destination: every arithmetic account has explicit supported `currency=` evidence; AccountKey remains `(account,currency)`.
- Prerequisite: readonly audit; public fixture migration; private account migration with preview/backup under explicit direction.
- Delete: Phase 2. Missing currency becomes fail-closed, not JPY.

### C13 — missing Plan/Budget row currency defaults to JPY

- Classification: `MIGRATE_SOURCE_DATA_THEN_DELETE`
- Current owner: `source_currency_admission` policy `legacy_compatibility`; ordinary context proof path.
- Current callers: plan/budget projection, currency proof tests, ordinary context.
- Destination: `production_strict` companion-source admission only.
- Prerequisite: add explicit `currency=` to all supported Plan/Budget rows via audited migration.
- Delete: Phase 2, including `legacy_compatibility` and `empty_source_compatibility` proof bases.

### C14 — five-field Plan identity fallback

- Classification: `MIGRATE_SOURCE_DATA_THEN_DELETE`
- Current owners: `plan_rows.PlanId`, overlap helpers, completion evidence.
- Current behavior: absent or explicit-empty `plan_id=` becomes concatenated date/memo/from/to/amount identity; duplicate metadata follows first-token precedence.
- Destination: explicit durable `plan_id=` for every Plan row participating in completion, remaining-plan, trend reserve, overlap, or editor workflows.
- Prerequisite: audit Plan rows and matching Actual metadata; deterministic migration preview and stale-safe write.
- Delete: Phase 2. Missing/empty/duplicate plan identity becomes explicit validation state.

### C15 — YTD semantic role prefix fallback

- Classification: `MIGRATE_SOURCE_DATA_THEN_DELETE`
- Current owner: `ytd_summary.GetRole` maps familiar account prefixes when role metadata is empty.
- Destination: report classification uses explicit resolved role only.
- Prerequisite: account metadata audit and source migration for accounts used by YTD/report classification.
- Delete: YTD migration in Phase 4.

### C16 — missing `DEFAULT_CURRENCY` legacy report behavior

- Classification: `MIGRATE_SOURCE_DATA_THEN_DELETE`
- Current owner: Balances/report dispatch.
- Current behavior: fixtures/ledgers without the key retain an ordinary compatibility Balances body in full/cache; direct selected route fails without explicit currency.
- Destination: one required, supported `DEFAULT_CURRENCY` for normal report runs; explicit CLI selection can override it where supported.
- Prerequisite: config audit, public fixture migration, private config update under explicit direction.
- Delete: Phase 2 policy gate and Balances Phase 4 switch.

### C17 — repository/default config inheritance

- Classification: `KEEP_CANONICAL_DOMAIN_BEHAVIOR`
- Current owner: `config.LoadConfig` and `config/default_config.tsv`.
- Behavior to keep: named product defaults for genuinely optional policy/display settings.
- Constraint: required source/accounting coordinates such as `DEFAULT_CURRENCY`, source identity, and arithmetic domain must not be supplied by a compatibility default.
- Destination: explicit distinction between required ledger config and optional product defaults.
- Refine: Phase 0 strict-source decision; implementation in Phase 2.

### C18 — physical fallback transaction identity when `event-id` is absent

- Classification: `KEEP_CANONICAL_DOMAIN_BEHAVIOR`
- Current behavior: structural source position supplies a non-durable identity; durable metadata is used when present.
- Reason: event identity and accounting validity are distinct; current canonical cleanup deliberately removes reconstructible non-functional event IDs.
- Destination constraints:
  - preserve source provenance and transaction/posting identity within one admitted snapshot;
  - never use physical identity as a durable cross-source relationship;
  - require explicit IDs for relationships that need durability.
- Naming may change; this is not a report compatibility route.

### C19 — prefix-fallback counts in Household Metadata

- Classification: `KEEP_CANONICAL_DOMAIN_BEHAVIOR`
- Current behavior: counts familiar prefixes only to diagnose missing explicit roles; accounting consumers do not treat those counts as admitted classification.
- Destination: retain as an optional diagnostic query or replace with a more direct missing-role report.
- Constraint: no monetary report may infer role from this diagnostic.

### C20 — valid empty source behavior

- Classification: `KEEP_CANONICAL_DOMAIN_BEHAVIOR`
- Current behavior: declaration-only Actual and empty selected Plan/Budget can produce a valid empty admitted domain when evidence is otherwise complete.
- Destination: retain zero-row admitted facts with explicit domain/scale and no fabricated compatibility proof.

### C21 — supported historical Journal metadata semantics

- Classification: `KEEP_CANONICAL_DOMAIN_BEHAVIOR`
- Current behavior: plan IDs, allocation IDs, event IDs, receipt/tax/business metadata and other admitted relationships are preserved.
- Compatibility to delete: the profile name/branch `historical_external_plan` and its use as a weaker report transaction shape.
- Destination: one strict canonical metadata grammar with each retained key justified by current writer/consumer inventory.
- Progress: complete/single-domain admission now lives under `src/ledger`; production report/context/editor readers no longer invoke this profile. Offline editor maintenance commands that intentionally inspect old cleanup shape and focused characterization tests still use it.
- Delete profile mechanism: Phase 1; retain justified metadata semantics.

### C22 — offline legacy event-ID cleanup commands

- Classification: `KEEP_OFFLINE_MIGRATION_TOOL`
- Current owners: `src_edit/journal_cleanup_*`, identity inventory, canonical surface rewrite commands.
- Constraint: these commands must not be imported by production report/admission paths.
- Destination: move to an explicitly named migration/maintenance neighborhood if retained after cutover; use final strict parser/admission for before/after validation.

## C. API, wrapper, and test shelves

### C23 — `projection.bqn` delegate shelf

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current direct runtime importers: Context, Envelope, plan rows/overlap, Readiness, Journal projection/proof modules.
- Current delegates: Layer constants/names, day coordinate, arithmetic proof predicates, plus non-Actual projection vocabulary.
- Destination: callers import `layer`, `date/period`, proof, identity, and strict companion projection owners directly.
- Prerequisite: Phase 2/3 capability ownership.
- Delete: Phase 3; no projection forwarding module.

### C24 — Cube Layer compatibility exports

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current behavior: Cube re-exports Layer constants/names while `layer.bqn` is the semantic owner.
- Destination: direct Layer owner imports; Cube exports only Cube behavior.
- Delete: Phase 3 with all callers/checks.

### C25 — broad Context helper/wrapper export shelf

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current examples:
  - `BuildRowsForFileOptional`;
  - `BuildAuthorizedRowsFromSnapshot`;
  - `BuildAllRowsFromSnapshot`;
  - `BuildPeriodView`;
  - prepared test wrappers.
- Destination: strict source snapshot, companion admission, fact projection, and Period capabilities each expose one semantic API.
- Delete: Phases 2–3; old Context removed by Phase 7.

### C26 — `ForTest` aliases

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current owners: Context, Cycle Summary, Planned Payments, Daily Trend Plan, Outlook Remaining Plan, and selected prepared seams.
- Current pressure: roughly 60 references across production export records, checks, tests, and index evidence.
- Destination: tests call real canonical pure APIs. A function needed for direct semantic testing receives a truthful public capability name; otherwise test through the public owner.
- Delete: per module in Phases 1–4; zero at Phase 7.

### C27 — `_for_test` production modules

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current modules:
  - `journal_supported_single_currency_admission_for_test.bqn`;
  - `journal_multi_currency_container_admission_for_test.bqn`.
- Destination: production strict admission is directly testable with synthetic inputs and diagnostics.
- Delete: Phase 1 after unique proof cases migrate.

### C28 — broad/default/explicit report Build aliases

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current examples:
  - Outlook `Build`, `BuildAt`, `BuildFromPrepared` with `legacy_default`;
  - Daily Trend `Build`, `BuildAt`, `BuildFromPrepared`;
  - context-based and prepared variants throughout sections.
- Canonical behavior to keep: explicit section observation options and section-local time semantics.
- Destination: one semantic Build over narrow facts plus explicit options; one adapter in composition, not aliases in the section.
- Delete: each section in Phase 4.

### C29 — renderers that accept broad Context and perform Build/I/O

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current examples: Issues, Recent, Planned, Readiness human, JSON context entrypoints.
- Destination: Build returns Matrix/List/Card/custom result; all renderers accept only that result.
- Delete: each section in Phase 4.

### C30 — duplicated full/selected/JSON/compact composition

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current owners:
  - static descriptor list;
  - full-report builder list;
  - selected-section builder list;
  - JSON conditional dispatcher;
  - hand-written compact `summary.bqn` sequence.
- Destination: one static catalog plus one runtime route mapping; capability flags select human/compact/JSON.
- Delete: Phase 5.

### C31 — `src_next/main.bqn` diagnostic wrapper

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current caller: compatibility check and direct historical command users; `tools/report-next` already calls the named implementation.
- Destination: one plainly named inspection entrypoint under `src/cli` and one canonical tool name.
- Delete: Phase 7; no alias.

### C32 — historical report tool names

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current names:
  - `tools/report-next-summary` (compact production summary despite historical name);
  - `tools/report-next` (developer inspection).
- Current pressure: summary name appears across many checks/tools; inspection name appears across diagnostic checks/docs.
- Destination:
  - `tools/report` remains canonical human command;
  - `tools/report-summary` becomes canonical compact command;
  - a plainly named inspection command replaces `report-next`.
- Prerequisite: update `tools/query`, doctor, devtools, checks, docs, and Command Hub callers.
- Delete: Phase 5 introduces canonical names; old names physically removed in Phase 7.

### C33 — scripts that locate the repository by testing `src_next/report.bqn`

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current callers: multiple editor/check shell scripts.
- Destination: repository-root resolution by script location or stable project marker, independent of engine implementation path.
- Delete: Phase 5/7.

### C34 — old section compatibility fields and fallback labels

- Classification: `DELETE_RUNTIME_COMPATIBILITY`
- Current examples:
  - Snapshot `fallback/current-engine` source fields;
  - Cycle `no_base_compatibility` result;
  - Envelope compatibility test fields;
  - Outlook `legacy_default`, `last_journal` fallback, and compatibility next-obligation path.
- Destination: canonical Matrix/List/Card/custom result fields with explicit state/reason/provenance.
- Prerequisite: output contract inventory decides which user-visible meaning remains and which field disappears.
- Delete: owning section Phase 4 slice.

### C35 — JSON “null fallback” for unavailable/empty states

- Classification: `KEEP_CANONICAL_DOMAIN_BEHAVIOR`
- Current checks call this a fallback, but the underlying requirement is that unavailable and valid empty values serialize deterministically without fabricated numbers.
- Destination: availability/state masks map explicitly to JSON null/empty according to each schema.
- Constraint: keep semantics, remove compatibility naming and context-based renderer paths.

### C36 — read-only experiments with no production caller

- Classification: `ARCHIVE_ONLY`
- Current examples: `event_lens*`, `daily_capacity.bqn`, shadow-context rehearsals, isolated candidate views.
- Rule: a module moves to `src/` only if a destination report/query names it as a real capability. Otherwise remove code/tests/current-doc promises at cutover and rely on Git/archive history.
- Delete/review: Phase 3 capability inventory and Phase 7 final cleanup.

### C37 — old Go-editor byte compatibility comments/contracts

- Classification: `KEEP_CANONICAL_DOMAIN_BEHAVIOR`
- Current example: `src_edit/plan_list_cmd.bqn` documents byte/field compatibility with the retired Go editor.
- Behavior decision: current BQN editor output may remain a user contract, but the retired implementation is not its owner.
- Destination: rename documentation/tests around current BQN CLI behavior; do not keep an adapter to Go.
- Cleanup: editor migration/documentation slice before Phase 7.

## D. Strict-source decision table

Decision status: approved by moko after plain-language review. These are binding destination requirements, not compatibility options.

| coordinate | current behavior | destination decision | data prerequisite | deletion ID |
|---|---|---|---|---|
| report currency | selected route or ordinary implicit JPY | require supported `DEFAULT_CURRENCY`; explicit allowed override | config audit/migration | C16 |
| account currency | missing → JPY | require explicit supported `currency=` for arithmetic accounts | accounts audit/migration | C12 |
| Plan/Budget currency | missing → JPY under compatibility policy | require explicit supported `currency=` | Plan/Budget audit/migration | C13 |
| Plan relationship identity | absent/empty → five-field concatenation | require explicit durable `plan_id=` where relationship is used | Plan + Actual relation audit/migration | C14 |
| account semantic role | some reports infer familiar prefix | allow missing only as unclassified diagnostic; never infer money semantics | account role audit/migration | C15/C19 |
| Actual source path | direct path or silent `base/data` rewrite | one configured safe basename under one base | base-layout audit | C09 |
| Actual event identity | durable metadata or physical snapshot identity | retain optional physical identity; require durable ID only for durable relationships | none unless a relationship lacks ID | C18 |
| empty source | compatibility proof may fabricate JPY basis | valid empty only with explicit admitted domain/source policy | config/declaration evidence | C13/C20 |
| cycle observation | source-loading default and multiple adapters | explicit observation into one pure resolver; CLI supplies default clock once | none; contract parity | C08 |

## E. Deletion sequence

### Phase 1 — Actual facts

Close: C05, C06, C11, C21 profile branch, C27. Begin C09. Replace editor Actual readers with complete facts.

### Phase 2 — strict companion/config data

Close: C12, C13, C14, C16, companion parts of C10. Refine C17. Apply public/private data migrations under the roadmap safety rules.

### Phase 3 — accounting capabilities

Close: C08, C23, C24, C25. Move canonical behavior from C03 without its context wrapper. Review/archive C36.

### Phase 4 — section migration

Close per owner: C04, C07, C10 report-local reads, C15, C26, C28, C29, C34. Preserve C35 semantics in canonical result schemas.

### Phase 5 — composition and canonical tools

Close implementation duplication C30; introduce canonical names for C32; remove path-detection dependence C33; add cache stale-file deletion.

### Phase 7 — cutover/eradication

Close C01, C02, old path of C03, C31, aliases from C32, remaining C33/C36/C37 wording and tests. No deletion is deferred beyond this phase.

## F. Remaining Phase 0 work

This inventory closes the known compatibility classification pass, but Phase 0 is not complete until:

- every export has a repository-wide caller classification, not only compatibility candidates;
- human/compact/JSON/metadata/cache/CLI/diagnostic output contracts are recorded with byte-versus-semantic parity decisions;
- public fixtures and private sources have readonly audits for C09/C12/C13/C14/C15/C16;
- the approved strict-source decisions in section D are reflected in source migration checks;
- each approved source migration has a preview/backup/stale-safe implementation plan.

No `src/` code or Pivot API is authorized before those decisions.
