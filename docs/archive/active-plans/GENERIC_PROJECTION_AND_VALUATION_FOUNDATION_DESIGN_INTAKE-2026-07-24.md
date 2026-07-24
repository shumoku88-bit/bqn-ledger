# Generic Projection and Valuation Foundation Design Intake

Status: active backlog / docs-only design intake
Owner: architecture / projection / currency
Canonical: no; current contracts: `docs/ARCHITECTURE.md`, `docs/CANONICAL_DAILY_CUBE.md`, and current currency contracts
Exit: replace with separately selected finite plans, or archive as rejected research if the proposed boundaries do not survive characterization

Date: 2026-07-24
Base main at intake: `2240aacc8b305ff96a20b66ac7f2f32f6e7e054c`

## 1. Purpose

This intake records a possible direction for making the current accounting kernel more reusable without turning it into one universal accounting application.

The direction has two related but independently gated parts:

1. build purpose-specific projections from a small set of reusable array modules;
2. separate original commodity quantity from explicit, evidenced valuation.

The existing Canonical Daily Cube should remain a stable current product contract. The intended architectural experiment is stronger than adding a second generic cube: the current cube itself should eventually be reproducible as one standard composition of smaller projection modules, if characterization proves that this can be done without changing any consumer-visible result.

This document authorizes no runtime implementation. `TODO.md` remains the selection gate for each finite slice.

## 2. Current truths to preserve

### 2.1 Source and evidence boundary

Human-readable Journal and source TSV remain source truth. Checked Posting IR remains the natural candidate for shared projection input. Projection work must not rewrite source meaning or erase transaction, posting, rejection, or provenance evidence.

### 2.2 Canonical Daily Cube contract

The current canonical shape remains:

```text
Day × Account × Layer
```

The cube is a materialized view, not source truth and not the only possible view of time or accounting facts.

The following do not become additional axes of the Canonical Daily Cube:

- party
- shop
- memo
- project
- tax metadata
- arbitrary categories
- commodity or currency merely because the field exists

Such dimensions may be used by separate sparse projections when a concrete consumer justifies them.

### 2.3 TBDS boundary

TBDS continues to own accounting period state expressed through opening, movement, and closing. A generic projection primitive must not silently duplicate or replace TBDS semantics.

### 2.4 Currency production boundary

Current production Actual arithmetic behavior remains unchanged. This intake does not authorize FX, valuation, mixed-currency aggregation, a currency axis, automatic rate retrieval, or a production Journal schema migration.

## 3. Central decisions proposed for characterization

### 3.1 Do not build one universal cube

The desired abstraction is a projection mechanism that can generate multiple purpose-specific views.

```text
checked facts
  -> admission
  -> coordinate extraction
  -> exact grouped accumulation
  -> sparse result
  -> optional dense materialization
```

A dense cube is an output choice, not the mandatory representation of every projection.

### 3.2 The Canonical Daily Cube should be a standard composition

The target concept is:

```text
Canonical Daily Cube
=
Day/Account/Layer axis specification
+ canonical admission policy
+ coordinate extraction
+ exact grouped sum
+ dense materialization
+ canonical validation
```

The current cube remains canonical for current reports. The composition idea is accepted only if it reproduces the current output and diagnostics exactly enough for all existing consumers and checks.

### 3.3 Sparse first

Generic projections begin as sparse grouped facts. Dense materialization is considered only when:

- the axis domains are explicit and finite;
- a real consumer benefits from dense indexing;
- memory and shape costs are understood;
- provenance and rejection behavior remain visible.

### 3.4 Generic means generative

The generic part is the ability to compose a view, not a data structure containing every possible dimension.

Examples of possible future projections, none selected here:

```text
Day × Account × Layer
Month × Account × Layer
Party × Expense Account
Commodity × Account
Project × Month
```

## 4. Current `cube.bqn` responsibility inventory hypothesis

Current `cube.bqn` appears to combine several meanings that should be characterized separately before any extraction:

1. layer constants and names;
2. row admission and coordinate range checks;
3. skipped-row category and reason construction;
4. sparse coordinate encoding into flat indices;
5. dense cube materialization;
6. layer and account reductions;
7. canonical numeric validation;
8. minimal inspection formatting.

This is not a claim that the file is too large. It is an ownership hypothesis. Extraction is justified only where a meaning has an independent contract or second consumer.

## 5. Candidate small module boundaries

Names are provisional. Characterization may merge, rename, or reject them.

### 5.1 `projection_admission.bqn`

Candidate responsibility:

```text
facts + axis-domain policy
  -> admitted facts
  -> skipped or rejected evidence
```

It should avoid knowing the semantic names Day, Account, and Layer when a more general range or predicate contract is sufficient.

It must preserve:

- original fact identity;
- admission state;
- skip category and diagnosable reason;
- distinction between rejected evidence and out-of-selected-domain evidence.

### 5.2 `projection_group.bqn`

Candidate responsibility:

```text
keys + exact values
  -> unique keys + exact summed values
```

This is the central sparse accumulation primitive. It should know nothing about accounting layers, reports, currencies, or dense shapes.

It must define empty input and additive identity explicitly.

### 5.3 `projection_dense.bqn`

Candidate responsibility:

```text
shape + coordinates or flat indices + values
  -> dense array
```

Possible internal concerns:

- multidimensional coordinate encoding;
- shape validation;
- scatter or grouped placement;
- explicit additive identity.

It must not own accounting semantics.

### 5.4 `projection_validation.bqn`

Candidate generic checks:

- admitted total equals grouped sparse total;
- grouped sparse total equals dense total when dense materialization is used;
- all encoded coordinates belong to the declared shape;
- duplicate coordinates are combined exactly;
- empty input produces a valid identity result;
- rejected facts never enter ordinary numeric output.

This module should not know that layer 0 is Actual or layer 1 is Plan.

### 5.5 `canonical_daily_cube.bqn`

Candidate responsibility:

- own the `Day × Account × Layer` specification;
- own layer names and fixed layer count;
- extract canonical coordinates and delta from admitted Posting IR facts;
- compose generic admission, grouping, and dense materialization;
- expose the current cube result contract.

This should become a thin semantic assembly module, not a new global hub.

### 5.6 `canonical_daily_cube_checks.bqn`

Candidate canonical checks:

- Actual and Plan totals agree with admitted facts;
- per-account Actual totals agree;
- household-specific layer invariants remain checked where they currently belong;
- current validation vocabulary and evidence remain stable.

Generic conservation checks and canonical accounting checks should not become a second source of truth for one another.

## 6. Avoid over-fragmentation

The goal is not one function per file.

Do not create a debris field such as:

```text
sum.bqn
zero.bqn
index.bqn
shape.bqn
filter.bqn
```

A module boundary is justified by semantic ownership, a stable contract, independent testing value, or a second consumer.

The provisional six-module picture is an upper-bound sketch, not a required file count. Characterization may conclude that fewer modules are clearer.

## 7. Proposed composition path

Conceptually, a future canonical build might look like:

```text
rows
  -> canonical admission policy
  -> admitted rows + skipped evidence
  -> canonical coordinate extraction
  -> sparse exact grouping
  -> dense Day × Account × Layer materialization
  -> generic conservation checks
  -> canonical daily cube checks
  -> current result namespace
```

The first proof target is not replacement. It is parallel equivalence:

```text
current Materialize result
=
small-module composition result
```

Equivalence must cover more than numeric cube cells. It must account for the current result fields, diagnostics, skipped evidence, totals, and downstream consumer expectations.

## 8. Generic projection workstream

### A0. Ownership inventory

Type: docs-only characterization.

Inventory at least:

- `src_next/projection.bqn`
- `src_next/cube.bqn`
- `src_next/tbds.bqn`
- `src_next/context.bqn`
- checked Posting IR builders and carriers
- section-local numeric aggregations that may be independent consumers

For each relevant function or result field, record:

- input shape;
- output shape;
- semantic owner;
- axis owner;
- measure owner;
- admission and rejection owner;
- provenance retention;
- current consumers;
- whether it is canonical-cube-specific, TBDS-specific, generic-looking, or unclear.

This inventory must not conclude in advance that extraction is desirable.

### A1. Exact sparse grouping characterization

Type: test-only, separately selected.

Using public synthetic facts only, prove a pure grouping primitive with explicit empty behavior and duplicate-coordinate accumulation.

No production integration, CubeSpec DSL, config file, report change, or currency axis.

### A2. Canonical parallel reconstruction proof

Type: test-only, separately selected.

Build the current Day/Account/Layer numeric payload from the small primitives and compare it with current `cube.Materialize` on public fixtures.

At this stage the existing production path remains unchanged.

### A3. Full result-contract compatibility decision

Inventory every current `Materialize` output field and decide whether it belongs to:

- generic projection output;
- Canonical Daily Cube output;
- canonical validation;
- report or inspection formatting;
- historical compatibility only.

Only after this decision may a production refactor be proposed.

### A4. One independent second consumer

Select at most one second consumer to test whether the abstraction is genuinely reusable.

Initial candidate:

```text
Month × Account × Layer movement
```

The candidate must be compared with existing TBDS or period aggregation semantics. If it merely duplicates TBDS without benefit, stop rather than broadening the abstraction.

### A5. Production adoption decision

Choose one outcome:

1. close as research-only evidence;
2. adopt only a shared sparse grouping primitive;
3. adopt small projection modules while preserving the canonical wrapper;
4. reject the abstraction because evidence or maintenance cost is worse than the current implementation.

## 9. Commodity and valuation boundary

Projection modularity does not by itself solve multiple currencies.

The intended conceptual split is:

```text
original commodity quantity
  != reporting value
```

### 9.1 Commodity

A unit kind such as JPY, USD, ILS, a point unit, or a future security identifier.

The first practical scope may remain currency-only, but an internal contract should not confuse currency display metadata with arithmetic value.

### 9.2 Quantity

Candidate minimal shape:

```text
commodity_code
integer_coefficient
scale
```

Different commodities are not directly additive.

### 9.3 Valuation fact

Candidate evidence shape:

```text
source commodity
source quantity
target commodity
target value
valuation date
valuation kind
valuation source
source transaction identity
source posting identity
```

A rate may be derived from directly observed source quantity and target value. The design must not require a floating-point rate when exact values are available.

### 9.4 Required distinctions

Do not conflate:

- original quantity;
- historical transaction value;
- current market value;
- reporting currency selection;
- formatting symbol;
- unavailable valuation.

## 10. Commodity and valuation workstream

### B0. Current ownership inventory

Type: docs-only characterization.

Inventory:

- `config/currencies.tsv`
- `src_next/currency_registry.bqn`
- `src_next/currency_setup.bqn`
- currency arithmetic and proof modules
- Posting IR currency fields and amount scale
- editor admission and formatting
- JPY-only production guards
- USD and ILS public fixtures
- travel-specific currency paths
- report-level currency selection

Record owners for code, scale, source currency, arithmetic domain, formatting, mixed-currency rejection, and production guards.

### B1. Quantity contract

Type: docs-only decision, separately selected.

Required invariants:

- exact integer coefficient;
- explicit scale;
- explicit supported commodity;
- no default-currency repair of missing source evidence;
- no direct addition across commodity codes.

### B2. Valuation fact contract

Type: docs-only decision, separately selected.

Define evidence and provenance before selecting any source representation.

### B3. Exact valuation primitive

Type: test-only, separately selected.

Use public synthetic evidence only. No external rate API and no production source changes.

### B4. Commodity-separated balance view

Type: test-only, separately selected.

Show balances grouped by commodity without producing a cross-currency total.

### B5. Historical transaction valuation view

Type: test-only, separately selected.

Project only postings with explicit historical valuation evidence into a reporting commodity. Missing valuation remains unavailable, not zero and not silently converted.

### B6. Source representation decision

Choose separately among Journal posting metadata, transaction metadata, a dedicated valuation source, travel-specific source evidence, or no production representation yet.

## 11. Workstream interaction

Projection and valuation remain independently testable.

```text
checked Posting IR
  -> generic projection modules

commodity quantity + valuation evidence
  -> valuation modules

valued facts
  -> optional purpose-specific projection
```

The generic projection modules should not require valuation. The valuation modules should not require a particular dense cube.

Suggested evidence order, not automatic authorization:

```text
A0 projection ownership inventory
B0 currency ownership inventory
A1 sparse grouping characterization
B1 quantity contract
B2 valuation contract
A2 canonical reconstruction proof
B3 exact valuation primitive
A3/A4 compatibility and second-consumer decisions
B4/B5 test-only views
```

## 12. Global invariants

### Projection

- rejected Posting IR does not enter ordinary numeric output;
- exact deltas remain exact;
- duplicate coordinates combine deterministically;
- input admitted totals equal sparse grouped totals;
- dense totals equal sparse totals when dense materialization is selected;
- source and posting evidence remain reachable;
- zero, unavailable, skipped, warning, and error remain distinct;
- current Canonical Daily Cube consumers remain unchanged until a separate migration is approved.

### Commodity

- quantities with different commodity codes are not directly added;
- missing commodity evidence is not filled from `DEFAULT_CURRENCY`;
- unsupported commodities fail visibly;
- symbols and display precision do not own arithmetic meaning.

### Valuation

- no implicit conversion;
- original quantity is never discarded;
- target value retains valuation date, kind, and source;
- historical and current valuation are separate concepts;
- no production adoption before rounding and precision ownership are explicit.

## 13. Global non-goals

This intake does not authorize:

- a universal giant cube;
- axes added to the Canonical Daily Cube;
- arbitrary metadata dimensions in dense arrays;
- a projection DSL or SQL-like query language;
- dynamic code generation;
- broad module decomposition based on file size;
- a database;
- an external FX service;
- automatic rate download;
- market valuation;
- unrealized gain or loss accounting;
- automatic cross-currency totals;
- source Journal migration;
- production report multi-currency conversion;
- private production-data experiments;
- changes to current JPY production behavior;
- a broad ERP or tax-accounting expansion.

## 14. First eligible finite slice

The smallest next eligible slice is:

> Generic projection ownership inventory.

It should produce one docs-only inventory and no runtime change.

Acceptance criteria:

- record the inspected main SHA;
- enumerate current projection, cube, TBDS, context, and Posting IR ownership;
- classify every current `cube.Materialize` responsibility;
- inventory the complete returned namespace and current consumers;
- distinguish generic-looking mechanics from canonical accounting meaning;
- record provenance and rejection paths;
- identify TBDS overlap risks;
- offer at most three next finite candidates;
- do not select implementation automatically.

The currency ownership inventory is a separate later slice. The two inventories may inform one another, but they should not be combined into one broad audit unless concrete evidence requires it.

## 15. Exit outcomes

This intake succeeds if it produces explicit decisions, even if no generic kernel is adopted.

Possible closures:

- small modules reproduce the Canonical Daily Cube and one independent consumer, enabling a separately planned refactor;
- only an exact sparse grouping primitive is worth sharing;
- TBDS and current Cube boundaries already cover the useful consumers;
- provenance or complexity costs make generic composition undesirable;
- commodity and valuation remain research-only because no concrete consumer justifies production representation.

The desired design is not maximum abstraction. It is the smallest set of reusable meanings that lets the current cube remain understandable while permitting genuinely different projections later.
