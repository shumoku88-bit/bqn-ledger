# Generic projection ownership inventory — 2026-07-24

Status: audit snapshot / completed docs-only inventory
Owner: architecture / projection / report
Canonical: no; current contracts remain `docs/CANONICAL_DAILY_CUBE.md`, `docs/TBDS_CONTRACT.md`, and the referenced runtime modules
Exit: retained as the A0 ownership snapshot; any extraction, test-only primitive, or runtime refactor requires a separately selected finite slice

## Finite question

> On current main, which modules own posting admission, Day / Account / Layer coordinates, exact accumulation, dense Cube materialization, validation, provenance, rejection evidence, TBDS period state, and downstream consumption?

This inventory does not assume that extraction is desirable. It records the current seams so a later slice can test that question without silently changing the Canonical Daily Cube or its consumers.

## Observation point

- Repository: `shumoku88-bit/bqn-ledger`
- Main SHA: `aa010ef9c7d1bdc3c871ef0f240c087164d97ddb`
- Date: 2026-07-24
- Production Actual source: configured native Journal
- Companion sources: `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, `issues.tsv`

No private ledger source, account, amount, transaction, backup, or production path was read for this inventory.

## Scope inspected

### Current contracts and routing

- `docs/CANONICAL_DAILY_CUBE.md`
- `docs/TBDS_CONTRACT.md`
- `docs/archive/active-plans/GENERIC_PROJECTION_AND_VALUATION_FOUNDATION_DESIGN_INTAKE-2026-07-24.md`
- `TODO.md`

### Posting and coordinate production

- `src_next/projection.bqn`
- `src_next/journal_posting_ir_stage2a.bqn`
- `src_next/context.bqn`
- `src_next/account_key.bqn`
- `src_next/cycle.bqn`

### Materialized views

- `src_next/cube.bqn`
- `src_next/tbds.bqn`

### Direct current consumers and entry surfaces

- `src_next/main.bqn`
- `src_next/summary.bqn`
- `src_next/daily_trend.bqn`
- `src_next/daily_flow.bqn`
- `src_next/readiness_check.bqn`
- `src_next/snapshot.bqn`
- `src_next/actual_snapshot.bqn`
- `src_next/envelope_computation.bqn`
- code-search results for current `ctx.cube`, `ctx.cube.cube`, `ctx.cube.valid_rows`, `ctx.tbds`, and `cube.Sum0` consumers

### Focused checks

- `tests/test_src_next_cube.bqn`
- current Cube and report checks routed by `tools/check.sh`

## Current pipeline

```text
configured native Journal
  -> journal profile Transaction IR
  -> journal_posting_ir_stage2a.BuildForSource

plan.tsv / budget_alloc.tsv
  -> context row evidence
  -> exact currency arithmetic authorization
  -> context projection-row builders

both routes
  -> merged checked Posting IR rows
  -> context.BuildPeriodView
       -> cube.Materialize
            selected-period dense Day × Account × Layer
            + valid/skipped evidence
            + compatibility totals and checks
       -> tbds.Build
            ledger-wide opening
            + selected-period movement
            + closing state
```

`context.BuildContext` is the production orchestration owner. `src_next/main.bqn` also calls `cube.Materialize` independently for its diagnostic sample-row surface; tests and probes call it directly as well.

## Ownership classes

| Class | Meaning in this inventory |
|---|---|
| source / semantic admission | Determines whether source facts may become checked Posting IR and what they mean. |
| axis-domain owner | Defines a coordinate domain or its finite size. |
| coordinate producer | Assigns a row to Day, AccountKey, or Layer coordinates. |
| measure owner | Defines the numeric value being accumulated. |
| view admission | Decides whether a checked row belongs in one selected materialized view. |
| accumulation | Combines equal or related coordinates using exact addition. |
| materialization | Chooses sparse or dense output shape. |
| evidence owner | Retains source identity, rejection, diagnostics, or contribution evidence. |
| compatibility output | Preserves a current result field or report/check surface that is not necessarily generic. |

## Current ownership matrix

| Concern | Current owner | Input | Output | Classification | Observation |
|---|---|---|---|---|---|
| Actual source parsing and transaction admission | Journal profile modules before Stage 2A | native Journal bytes | admitted Transaction IR or parser rejection | source / semantic admission | Cube never sees rejected parser input. |
| Actual Posting IR construction | `journal_posting_ir_stage2a.bqn` | admitted transactions, resolved accounts, cycle start, source file | checked posting rows or diagnostics | coordinate producer / evidence owner | Assigns account index, day index, layer index, side, delta, source and posting identity. |
| Plan and budget row evidence | `context.bqn` | supplied TSV snapshot | row evidence with parsed amount and currency provenance | source / semantic admission | Currency and amount evidence is resolved before rows enter the Cube. |
| Non-Actual arithmetic authorization | `context.bqn`, currency arithmetic modules, `projection.bqn` proof helpers | row evidence | one authorized arithmetic domain or diagnostics | source / semantic admission | This is not Cube admission and must stay fail-closed. |
| Non-Actual Posting IR construction | `context.BuildProjectionRowsForEvidence` | authorized row evidence, normalized coefficients, resolved accounts, cycle start | two ledger-like posting rows per admitted TSV row | coordinate producer / evidence owner | Produces the same current row shape as the Journal adapter. |
| Day domain | `cycle.bqn` | cycle declarations and observation date | `start`, `end_exclusive`, `day_count` | axis-domain owner | Cube receives `day_count`; it does not define the period. |
| Day coordinate | `projection.ResolveDayFromCycle`, called by posting-row builders | posting date and cycle start | signed `day_index` | coordinate producer | Negative and after-end coordinates remain evidence until view admission. |
| AccountKey domain | `account_key.Resolve` | `accounts.tsv` | ordered account keys, metadata, `count` | axis-domain owner | AccountKey is currently `(Account, Currency)`; no separate Currency axis. |
| Account coordinate | Journal adapter and context TSV builder | posting account and resolved account table | `account_key_index` | coordinate producer | Unknown accounts are rejected or represented with a sentinel before Cube indexing, depending on route and stage. |
| Layer semantic domain | `docs/CANONICAL_DAILY_CUBE.md` plus duplicated constants in `projection.bqn`, `cube.bqn`, and Journal adapter | source/layer declaration | four semantic layers | fixed Canonical contract | Semantic ownership is documented, but numeric constants are duplicated. |
| Layer coordinate | source mapping in `projection.bqn`; transaction layer in Journal adapter | source or transaction layer | `layer_index` and `layer_name` | coordinate producer | Current generic work must not reinterpret these meanings. |
| Measure | checked Posting IR builders | exact normalized source amount | signed exact `delta` | measure owner | Debit is positive and credit negative in the current row contract. |
| Source balancing check | `projection.BalanceBySourceOk` | posting rows | boolean source-group balance check | compatibility validation | Groups by `source_id`; separate from Cube conservation checks. |
| Selected-period row admission | `cube.PartitionRows` | checked posting rows, `day_count`, `ak_count` | valid rows, skipped rows, categorized reasons | view admission / evidence owner | Mixes semantic-error status and out-of-period exclusion in one partition, while preserving category differences. |
| Skipped classification | `cube.RowSkipCategory`, `RowSkipReason`, `BuildSkippedSummary` | one rejected-for-view row | category, reason, aggregate counts | Canonical diagnostics | Names are specific to Day / AccountKey / Layer and current status vocabulary. |
| Coordinate encoding | local `FlatIdx` inside `cube.Materialize` | valid row | flat integer index | generic-looking implementation inside Canonical owner | Formula is hard-coded for Day × Account × Layer. It is not exported. |
| Equal-coordinate accumulation | local cell loop inside `cube.Materialize` | flat indices and deltas | one exact value per dense cell | accumulation | No intermediate grouped sparse result exists. Every flat cell filters all valid rows. |
| Dense materialization | `cube.Materialize` | valid rows and three domain sizes | dense `day_count × ak_count × 4` array | Canonical materialization | Shape and axis order are public current behavior. |
| Layer totals | `cube.Materialize` | dense Cube and valid rows | dense-derived and row-derived layer totals | Canonical compatibility output | Actual and Plan equality are checked explicitly; all four layers are returned numerically. |
| Account totals | `cube.Materialize` | dense Cube and valid rows | actual / plan per-account totals | Canonical compatibility output | Several overlapping totals are returned for checks and early report consumers. |
| Expense totals | `cube.Materialize` | valid rows, kind, side, layer | actual and plan expense totals | report-like compatibility output | This is semantic report aggregation inside the Cube module, not generic dense materialization. |
| Cube validation | `cube.MakeValidationSummary` | row-derived totals and dense-derived totals | Actual, Plan, and per-account match booleans | Canonical validation | Field names and selected comparisons are layer-specific. |
| Minimal inspection rendering | `cube.Format*` functions | full Materialize result | diagnostic text | compatibility / presentation | Rendering is colocated with materialization but is not projection-kernel behavior. |
| TBDS row admission | local `LedgerValid` inside `tbds.Build` | ledger-wide posting rows and resolved domain | admitted ledger rows | TBDS-specific admission | Repeats status, AccountKey, and Layer checks rather than consuming `cube.valid_rows`. |
| TBDS period split | `tbds.Build` | valid ledger rows and absolute period bounds | before-period and in-period rows | TBDS-specific temporal semantics | Deliberately differs from Cube: pre-period rows become opening evidence instead of skipped accounting data. |
| TBDS accumulation | `OpeningByLayer`, `MovementByLayerSide`, `MovementByLayer` | rows, layer, side, account index | per-layer per-account vectors | accumulation / TBDS-specific | Repeats key filtering and exact summation patterns also present in Cube. |
| TBDS state rows | `tbds.Build` | opening and movement vectors plus account metadata | Period × Account × Layer rows with opening/movement/closing | TBDS materialization | Output is long rows, not a dense Day Cube. |
| Period-view orchestration | `context.BuildPeriodView` | ledger-wide rows, resolved account table, selected cycle | `{cube, tbds}` | orchestration | Calls both views from the same checked rows but does not provide a shared grouped-fact layer. |

## `projection.bqn` naming observation

`projection.bqn` is not currently a generic projection engine. Its present responsibilities include:

- the conceptual Posting IR row vocabulary;
- source-to-layer mapping for non-Actual sources;
- date and day-coordinate helpers;
- kind inference;
- Posting ID helpers for TSV-derived rows;
- arithmetic-currency proof authorization;
- source-group balance checking;
- diagnostic table formatting.

It explicitly does not materialize a Cube. The strongest reusable accumulation candidates currently live in `cube.bqn` and `tbds.bqn`, not in `projection.bqn`.

Renaming or moving existing responsibilities is not authorized by this observation.

## `cube.Materialize` current result contract

| Result field | Current role | Candidate classification | Current consumer pressure |
|---|---|---|---|
| `cube` | dense Day × Account × Layer values | Canonical Daily Cube | Direct numeric use by Daily Trend and Daily Flow. |
| `valid_rows` | rows admitted to selected Cube period | Canonical evidence surface | Used by Daily Trend, Daily Flow, envelope computations, household-policy diagnostics, and tests. |
| `skipped_rows` | status-invalid or coordinate-out-of-domain rows for this view | Canonical evidence surface | Used by readiness diagnostics and tests. |
| `valid_count`, `skipped_count` | partition counts | Canonical diagnostics | Used by readiness, snapshot, minimal summary, and golden checks. |
| `skipped_info`, `skipped_summary` | categorized view-rejection evidence | Canonical diagnostics | Used by readiness and compact output. |
| `layer_totals_vec` | dense-derived layer totals | Canonical numeric compatibility | Golden and unit checks. |
| `valid_layer_totals` | row-derived layer totals | Canonical validation input/output | Current Actual and Plan conservation checks. |
| `ak_totals` | dense-derived Actual account totals | Canonical numeric compatibility | Unit/golden validation. |
| `actual_account_totals`, `plan_account_totals` | row-derived account totals | Canonical/report compatibility | Existing checks and historical consumers. |
| `actual_expense_total`, `plan_expense_total` | row-semantic expense totals | report-like compatibility | Not required to define a generic dense array. |
| `valid_total_delta` | total admitted delta | generic-looking conservation datum | Current result compatibility; source balancing is also checked elsewhere. |
| `proj_ak_totals` | alias of Actual row-derived account totals | validation compatibility | Exists to compare with dense `ak_totals`. |
| `validation_summary` | selected layer/account equality checks | Canonical validation | Field vocabulary is Actual/Plan-specific. |

A production reconstruction cannot compare only the dense numeric payload. It must explicitly classify or preserve every field above.

## Consumer inventory

### Direct dense Cube numeric consumers

Current code search found two production section modules reading `ctx.cube.cube` directly:

1. `src_next/daily_trend.bqn`
   - extracts the Actual layer as a Day × Account matrix;
   - forms cumulative daily balances;
   - also reads `ctx.cube.valid_rows` for accepted Actual and Plan dates/evidence.
2. `src_next/daily_flow.bqn`
   - extracts the Actual layer by day and account;
   - builds daily income and expense breakdowns;
   - also reads `ctx.cube.valid_rows` for observed dates.

This is narrower than the total number of report sections.

### Cube evidence and diagnostic consumers

- `readiness_check.bqn` consumes skipped rows, skipped categories, and counts.
- `snapshot.bqn` consumes Cube counts and skipped-period summary, while its balances and cycle amounts come from TBDS.
- `envelope_computation.bqn` consumes `valid_rows` for selected Actual and Budget row aggregations.
- `summary.bqn` and `main.bqn` expose Cube inspection/validation text and pass valid rows to household-policy diagnostics.
- focused tests and probes consume the full current result contract.

Therefore `valid_rows` and skipped evidence are at least as important to compatibility as the dense array itself.

### TBDS consumers

Current `ctx.tbds` code search includes:

- `balances.bqn`;
- `cycle_summary.bqn`;
- `expense_breakdown.bqn`;
- `trial_balance.bqn`;
- `snapshot.bqn`;
- `summary.bqn`;
- selected envelope diagnostics.

`actual_snapshot.bqn` also builds a local TBDS for an explicit one-day observation window from checked Actual posting rows. Other report migrations use local TBDS period views while retaining posting-row evidence for rejection diagnostics.

This supports the observation that TBDS is already the dominant accounting-state view for balances and period state, while the dense Cube remains especially valuable for Day-axis replay and trend sections.

## Provenance and rejection findings

### Posting rows are the durable evidence surface

The merged checked posting rows retain, depending on source route:

- source file;
- source row or transaction ordinal;
- source event identity;
- transaction identity;
- posting identity;
- date;
- side;
- account coordinate;
- layer coordinate;
- exact delta;
- kind;
- status and message.

### Dense cells do not retain contributors

`cube.Materialize` returns the original admitted rows alongside the dense array, but an individual dense cell does not retain a list of contributing posting identities. Reconstructing cell provenance requires filtering or regrouping the retained rows by the same coordinates.

### TBDS rows also summarize away contributor identity

A TBDS row retains period, account, layer, account metadata, and opening/movement/closing values. It does not retain the posting IDs that produced each amount. Sections that require source-level rejection or completion evidence use `ctx.posting_rows` or local joins rather than treating TBDS as the evidence owner.

### Out-of-period is not semantic rejection

Cube admission classifies before-start and after-end rows as skipped for the selected dense period. TBDS deliberately uses before-start rows as opening-balance evidence. A generic admission module must not collapse these rows into the same meaning as invalid status, unknown account, or invalid layer.

## Duplication and coupling observations

### Exact accumulation is repeated

The following patterns are independently implemented:

- dense per-cell sums in `cube.Materialize`;
- per-layer totals in `cube.Materialize`;
- per-layer/per-account totals in `cube.Materialize`;
- per-layer/per-account opening totals in `tbds.Build`;
- per-layer/per-account/per-side movement totals in `tbds.bqn`;
- section-local exact group/filter/sum calculations over `valid_rows`.

This is evidence for testing one exact grouping primitive. It is not proof that all of these calculations should share one runtime API.

### `Sum0` is generic-looking but highly coupled

`cube.Sum0` is imported by TBDS and many report modules. Moving it merely to make file names look cleaner would create a broad seam unrelated to the first grouping proof. The first test-only primitive should not require relocating every existing `Sum0` call.

### Layer constants are duplicated

Layer indices and names appear in `projection.bqn`, `cube.bqn`, the Journal adapter, and some section-local literals. This is a real ownership duplication, but centralizing it is not required to characterize sparse grouping and would widen the first refactor.

### Cube admission and TBDS admission are related but not identical

Both check status, account-index bounds, and layer-index bounds. Cube additionally applies selected-period Day bounds and produces skipped diagnostics. TBDS uses absolute date boundaries to produce opening and movement. A single generic `admit` function would need explicit policy inputs and evidence outputs; a blind extraction would erase meaningful differences.

## Reuse classification

| Current behavior | Classification | Reason |
|---|---|---|
| exact empty-safe addition | generic-looking | Independent of axes and accounting meaning, but currently widely coupled through `cube.Sum0`. |
| group equal keys and sum exact values | strongest generic candidate | Repeated in Cube, TBDS, and sections; no current standalone owner. |
| encode coordinates into a dense flat index | generic-looking candidate | Arithmetic is generic, but current function is hard-coded and internal. |
| reshape flat values to Day × Account × Layer | Canonical-specific composition | Shape, order, and Layer count are current public contract. |
| status/day/account/layer partition | mixed / unclear | Contains both generic range checks and Canonical diagnostic semantics. |
| skipped category and message vocabulary | Canonical-specific | Names and precedence are current report/check contract. |
| Actual/Plan account and expense totals | Canonical/report-specific | Not necessary for a generic projection kernel. |
| Actual/Plan validation summary | Canonical-specific | Explicit layer semantics and compatibility fields. |
| TBDS opening/movement/closing | accounting-state-specific | Reusable accounting view, but not generic dense projection behavior. |
| source identity and posting evidence | Posting IR-specific | Must remain outside a numeric-only grouped result or be carried explicitly. |

## Main finding

The current system is not one monolithic Cube consumer graph.

```text
checked Posting IR
  -> dense Day Cube for daily coordinate replay
  -> TBDS for accounting period state
  -> direct row-evidence calculations for diagnostics and linkage-sensitive sections
```

The plausible reusable center is therefore smaller than a universal Cube:

```text
exact keys + exact values
  -> grouped sparse facts
  -> optional Canonical dense materialization
```

The inventory does not support starting with a generic admission framework or a large `CubeSpec` DSL. Current admission and evidence semantics are too different across source checking, selected-period Cube membership, and TBDS opening-state construction.

## Decision from A0

A0 is complete as an ownership inventory.

The evidence supports a bounded next experiment, not a production refactor:

1. test an I/O-free exact sparse grouping primitive over explicit keys and exact values;
2. preserve current `cube.Materialize`, TBDS, report, and source routes unchanged;
3. require duplicate-coordinate, empty-input, negative-value, and conservation evidence;
4. do not solve admission, provenance, dense shape, layer ownership, or currency in the same slice.

No module extraction is adopted by this inventory.

## Next finite candidates

### Candidate 1 — A1 exact sparse grouping characterization

Recommended next projection slice.

- test-only;
- public synthetic facts only;
- explicit keys and exact numeric values;
- empty input returns an empty grouped result;
- duplicate keys accumulate exactly;
- input total equals grouped total;
- no `cube.bqn` production integration;
- no movement of existing `Sum0` consumers.

### Candidate 2 — A3 Materialize result-contract classification

Docs-only alternative if further contract analysis is preferred before code evidence.

Classify every `Materialize` field as generic output, Canonical output, validation, evidence, presentation, or compatibility-only. This inventory provides the initial table but does not authorize removal or migration.

### Candidate 3 — B0 commodity and valuation ownership inventory

Independent docs-only track. It may proceed without projection extraction, but it must not reinterpret AccountKey currency separation as valuation support.

## Non-goals preserved

This inventory does not:

- modify `cube.bqn`, `tbds.bqn`, `projection.bqn`, or report code;
- add a universal Cube or projection DSL;
- add a Currency axis;
- add FX, valuation, price lookup, or mixed-currency totals;
- change `Day × Account × Layer`;
- change Posting IR fields or source admission;
- change skipped-row categories or diagnostics;
- change production source data;
- use private fixtures;
- select A1, A2, A3, A4, A5, B0, or any runtime work automatically.

## Verification basis

The inventory was checked against current-main source modules, current contracts, current direct-consumer code search, and the focused Cube unit test. It is a point-in-time ownership map, not a claim that all future consumers should share one abstraction.
