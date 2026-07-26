# `projection.bqn` ownership audit — 2026-07-26

Status: completed docs-only audit
Owner: architecture / posting projection
Canonical: no; current runtime modules and current contracts remain authoritative
Exit: retain as the observation record for the selected cleanup sequence; revise only if the current module boundaries materially change

## Finite question

> On current main, what does `src_next/projection.bqn` actually own, which exports are production-critical, diagnostic-only, compatibility-only, duplicated, or apparently unused, and what is the smallest safe sequence for making the code more coherent without mechanically fragmenting it?

This audit does not modify runtime behavior and does not authorize a broad module split.

## Observation point

- Repository: `shumoku88-bit/bqn-ledger`
- Main SHA: `2e073ff0300ab8241ad32816400db7674837ac38`
- Date: 2026-07-26
- Production report entrypoint: `tools/report` → `src_next/report.bqn`
- Diagnostic prototype entrypoint: `src_next/main.bqn`
- Actual source: configured native Journal
- Non-Actual sources: `plan.tsv`, `budget_alloc.tsv`

No private ledger data, production paths, or private fixtures were read.

## Scope inspected

### Runtime

- `src_next/projection.bqn`
- `src_next/context.bqn`
- `src_next/selected_domain_context.bqn`
- `src_next/journal_posting_ir_stage2a.bqn`
- `src_next/date.bqn`
- `src_next/cycle.bqn`
- `src_next/main.bqn`
- current code-search results for every exported `projection.bqn` name

### Tests and contracts

- `tests/test_src_next_account_key.bqn`
- `tests/test_src_next_currency_domain_proof.bqn`
- `docs/POSTING_IR_CONTRACT.md`
- `docs/PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md`
- `docs/archive/audits/GENERIC_PROJECTION_OWNERSHIP_INVENTORY-2026-07-24.md`
- `docs/ARCHITECTURE.md`
- `docs/AI_CODEMAP.md`
- `TODO.md`

## Main finding

`projection.bqn` is not a generic projection engine and no longer has one coherent responsibility.

It is currently a shared vocabulary shelf containing seven different concern groups:

```text
Layer constants and source mapping
Posting row column vocabulary
Non-Actual TSV field / metadata / identity helpers
Date aliases and day-coordinate helpers
Arithmetic-currency proof authorization
Source-group balance validation
Diagnostic table rendering
```

Some of these meanings belong together. Others arrived during different historical phases and now make `projection.bqn` a dependency magnet.

The right cleanup is therefore not “split the file into seven files.” The right cleanup is to remove the clearest foreign responsibility first, then re-observe the remaining ownership pressure.

## Current responsibility inventory

### 1. Layer vocabulary and source mapping

Current exports:

- `layer_actual`
- `layer_plan`
- `layer_budget`
- `layer_forecast`
- `SourceLayer`
- `LayerName`

Observed use:

- the numeric layer constants are imported by several report modules and a focused test;
- `SourceLayer` is used by the non-Actual row builder in `context.bqn`;
- `LayerName` is used by `context.bqn` and a focused test;
- the Journal adapter independently owns its `actual / plan / budget / forecast` name table and derives `layer_index` from the transaction layer;
- the `SourceLayer` table includes `actual.journal`, but the current native Journal route does not call `SourceLayer` for Actual rows.

Classification:

- real shared semantic vocabulary;
- duplicated numeric/name ownership;
- not a presentation concern;
- not the first cleanup slice because centralizing Layer would touch multiple production consumers.

Observation:

A future dedicated Layer owner may be justified, but creating one before the easier foreign responsibilities are removed would widen the first refactor unnecessarily.

### 2. Posting row vocabulary

Current exports:

- `proj_cols`
- `InferKind`
- `FieldOrEmpty`
- `TxIdFromMeta`
- `PostingId`

Observed use:

- `proj_cols` is used only by the diagnostic `src_next/main.bqn` surface;
- `InferKind`, `FieldOrEmpty`, `TxIdFromMeta`, and `PostingId` are used by the non-Actual TSV projection path in `context.bqn`;
- `FieldOrEmpty` is also reused by several report-side source-row helpers;
- `PostingId` and `InferKind` are pinned by `test_src_next_account_key.bqn`;
- `InferKind` accepts `fromAcc` and `toAcc`, but current inference uses only `fromRole` and `toRole`;
- `kind` is transaction-level classification and must not be reused as posting-level account-role classification.

Classification:

- the row construction helpers are non-Actual adapter semantics rather than generic projection algebra;
- `proj_cols` is diagnostic presentation metadata;
- the current function names are still widely understood, so relocation should follow evidence rather than cosmetic renaming.

### 3. Scalar and metadata helpers

Current exports:

- `MetaValue`
- `IsDigits`
- `IsIntegerText`

Observed use:

- `MetaValue` is used internally by `TxIdFromMeta`; current repository code search found no external runtime caller of the exported name;
- `IsDigits` is used internally by `IsIntegerText`; other modules own their own digit logic;
- `IsIntegerText` is directly exercised by `test_src_next_account_key.bqn`, but current runtime amount admission uses `exact_decimal.bqn`, not this integer-only predicate.

Classification:

- compatibility and historical test surface;
- no evidence that these should be public projection vocabulary;
- removal requires a separate dead-export characterization because the repository is public and external imports cannot be observed by repository code search.

### 4. Date and day-coordinate helpers

Current exports:

- `IsValidDateText`
- `DaysFromEpoch`
- `ResolveDay`
- `ResolveDayFromCycle`

Observed use:

- `IsValidDateText` and `DaysFromEpoch` are direct aliases of `date.bqn` functions;
- many modules import `projection.bqn` to reach those date aliases;
- `cycle.bqn` already imports `date.bqn` directly but still calls `proj.IsValidDateText` and `proj.DaysFromEpoch`;
- `ResolveDayFromCycle` is a real posting-coordinate helper used by the Journal and non-Actual posting builders and several focused calculations;
- `ResolveDay` hardcodes `2026-01-01` and is labeled backward compatibility;
- current repository code search found no non-self caller of the exact hardcoded compatibility behavior.

Classification:

- `ResolveDayFromCycle` is a real coordinate producer;
- the date aliases are misplaced forwarding exports;
- `ResolveDay` is the clearest obsolete compatibility candidate, but should be removed only in a separate finite slice with exact code-search and test evidence.

### 5. Arithmetic-currency proof authorization

Current exports:

- `AuthorizeArithmeticCurrencyProof`
- `ArithmeticCurrencyAuthorizationMessage`
- `RequireArithmeticCurrencyProof`

Observed use:

- `context.BuildCheckedPostingProjectionFromPrepared` constructs the proof, calls the pure authorization predicate, and returns the structured diagnostic;
- focused currency tests call the predicate and message builder directly;
- current repository code search found no runtime or test caller of `RequireArithmeticCurrencyProof` outside its own definition;
- `RequireArithmeticCurrencyProof` prints and exits, while the current checked builder deliberately returns a data result and leaves terminal effects to outer compatibility wrappers;
- `PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md` still describes the runtime as not implemented and preserves `RequireArithmeticCurrencyProof` for possible direct callers, but current runtime and code-search evidence have moved beyond that observation point.

Classification:

- proof authorization belongs to checked projection admission, not row vocabulary;
- current evidence favors moving the pure predicate and message ownership toward `context.bqn` before creating another thin module;
- a dedicated proof module should be considered only if a second independent runtime consumer appears;
- contract synchronization is required before any move or deletion.

### 6. Source-group balance validation

Current exports:

- `BalanceBySourceOk`
- `FormatBalanceCheck`

Observed use:

- `BalanceBySourceOk` is called only by `FormatBalanceCheck`;
- `FormatBalanceCheck` is called only by `src_next/main.bqn`;
- production `tools/report` does not route through `src_next/main.bqn`;
- source and transaction balance admission already exists on the native Journal path before this diagnostic surface.

Classification:

- current implementation is diagnostic compatibility, not a production posting admission owner;
- it can move with the diagnostic presentation slice without changing the production report path.

### 7. Diagnostic table rendering

Current exports:

- `FormatProjTable`
- `FormatBalanceCheck`
- `proj_cols`

Observed use:

- all are consumed only by `src_next/main.bqn`;
- `src_next/main.bqn` still describes Phase 1 / Phase 2 prototype output;
- the production report entrypoint is `tools/report` → `src_next/report.bqn`;
- presentation is explicitly not a responsibility of the posting calculation core.

Classification:

- strongest foreign responsibility;
- smallest safe first extraction;
- moving these names local to `src_next/main.bqn`, or to one explicitly diagnostic module if locality becomes awkward, removes presentation and `Sum0` from `projection.bqn` without changing production row construction.

## Stale-document and naming observations

### Missing contract references

The header of `projection.bqn` refers to:

- `PROJECTION_CONTRACT.md`
- `AXIS_CONTRACT.md`

Neither file exists at the current repository location. The names remain only in runtime comments and historical archive documents.

Current contracts are instead represented by files such as:

- `docs/POSTING_IR_CONTRACT.md`
- `docs/CANONICAL_DAILY_CUBE.md`
- `docs/PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md`

The runtime header should be corrected during the first code slice rather than preserving a phantom map.

### Prototype language

`projection.bqn` still calls itself the “cycle-ledger prototype” skeleton, and `src_next/main.bqn` still presents Phase 1 / Phase 2 prototype language. The production system has moved beyond this stage. The diagnostic surface may remain useful, but its comments should state that it is a developer inspection entrypoint rather than the production report path.

### Contract implementation state

`PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md` has `Status: current contract` but still states “runtime not yet implemented.” Current `context.bqn` implements the selected pure checked-result boundary. This is a documentation synchronization defect, not a runtime defect.

## Dependency-shape finding

The file is a dependency magnet partly because several modules import it for one forwarded helper.

A representative example is `cycle.bqn`:

```text
imports date.bqn directly
imports projection.bqn
uses projection.DaysFromEpoch
uses projection.IsValidDateText
```

This makes a reader travel through `projection.bqn` to discover that `date.bqn` already owns the implementation.

The same pattern appears more broadly for date arithmetic. Direct owner imports would make the dependency graph more truthful, but replacing every alias in one PR would be broad and noisy. It should follow the smaller diagnostic extraction.

## Recommended cleanup sequence

### P1 — Extract diagnostic presentation from `projection.bqn`

Selected as the next finite code slice.

Move or localize:

- `proj_cols`
- `BalanceBySourceOk`
- `FormatBalanceCheck`
- `FormatProjTable`
- the local `Sum0` used only by the balance diagnostic

Preferred destination:

- local helpers in `src_next/main.bqn` while it remains the sole consumer.

Create a separate diagnostic module only if the resulting local section is demonstrably awkward or gains a second consumer.

Required evidence:

- `src_next/main.bqn` diagnostic output remains byte-equivalent on public fixtures;
- production `tools/report` and report checks remain unchanged;
- full `tools/check.sh`, Coverage, and CI pass;
- runtime comments point to current contracts and identify `src_next/main.bqn` as a diagnostic entrypoint.

Why first:

- removes a clear presentation responsibility;
- affects one non-production consumer;
- does not change Posting IR rows, currency proof, dates, Layer, Cube, TBDS, or reports;
- leaves a smaller module that can be reassessed before further extraction.

### P2 — Characterize and remove dead compatibility exports

Candidates:

- `ResolveDay`
- `RequireArithmeticCurrencyProof`
- exported `MetaValue`
- exported `IsDigits`
- exported `IsIntegerText`

Do not remove them merely because current code search finds no runtime caller. First record:

- repository caller evidence;
- focused test dependence;
- documentation promises;
- whether deprecation is preferable for clone users who may import modules directly.

### P3 — Restore direct date ownership

Replace forwarding use of:

- `projection.IsValidDateText`
- `projection.DaysFromEpoch`

with direct `date.bqn` ownership.

Start with modules already importing `date.bqn`, especially `cycle.bqn`, then proceed in small coherent groups. Keep `ResolveDayFromCycle` until a better coordinate owner is selected.

### P4 — Move arithmetic-proof authorization ownership

Current evidence favors:

```text
context proof construction
  -> context-local authorization predicate and message
  -> checked projection result
```

Do not create a new module solely to make `projection.bqn` shorter. A dedicated proof owner becomes justified only if another independent consumer needs the same proof contract.

Synchronize `PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md` in the same slice.

### P5 — Reassess Layer ownership

After the earlier removals, inventory:

- duplicated layer constants;
- source-to-layer mapping;
- Journal transaction layer mapping;
- report modules importing numeric layer constants.

A small `layer.bqn` may be justified because Layer is a real shared semantic axis. It should not be created before its complete consumer contract is known.

### P6 — Reassess the remaining non-Actual adapter helpers

If `projection.bqn` is then mostly:

- `FieldOrEmpty`
- `TxIdFromMeta`
- `PostingId`
- `InferKind`
- `SourceLayer`
- `LayerName`
- `ResolveDayFromCycle`

then its actual meaning is a non-Actual Posting IR adapter vocabulary, not a generic projection engine.

At that point choose among:

1. keep the smaller file and rename it only with a compatibility plan;
2. move the helpers into `context.bqn` if they have one owner;
3. extract a coherent `nonactual_posting_adapter.bqn` if the adapter boundary is independently useful.

No choice is selected by this audit.

## Things not recommended

This audit does not support:

- splitting every helper into a separate file;
- creating a generic utility module for unrelated short functions;
- renaming `projection.bqn` before reducing its responsibilities;
- centralizing all Layer constants in the same PR as presentation cleanup;
- moving proof authorization and date aliases together;
- replacing transaction-level `kind` with posting-level account classification;
- introducing a generic projection DSL;
- changing Posting IR shape;
- changing Cube, TBDS, report output, source formats, currency policy, or private data.

## Selected next finite slice

> P1: move the diagnostic projection table and source-balance display out of `projection.bqn`, preserve the developer inspection output exactly, correct stale runtime comments, and leave production calculation behavior unchanged.

The module should be reassessed after P1 before P2 is implemented. The purpose is not to maximize file count or minimize line count. The purpose is to make the code say where each meaning actually lives.

## Verification basis

This audit was checked against:

- current main source code;
- current production and diagnostic entrypoints;
- exact repository code-search results for exported names;
- focused tests that pin row, kind, date, identity, and proof behavior;
- current and historical ownership documents;
- current public contracts.

Repository code search cannot prove that no external clone imports a currently exported name. That limitation is why dead-export removal is separated from the presentation extraction.
