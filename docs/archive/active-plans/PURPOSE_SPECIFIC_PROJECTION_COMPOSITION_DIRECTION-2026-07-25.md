# Purpose-Specific Projection Composition Direction

Status: architectural reference / evidence updated
Owner: architecture / projection
Canonical: no; complements `docs/CANONICAL_DAILY_CUBE.md` and `GENERIC_PROJECTION_AND_VALUATION_FOUNDATION_DESIGN_INTAKE-2026-07-24.md`
Exit: revise, replace, move to completed history, or delete when experiments provide better evidence

Created: 2026-07-25
Updated: 2026-07-26

> This document records one promising architectural direction and the evidence obtained so far. It may guide, inspire, or be contradicted by reversible experiments. It does not grant or withhold permission for current work.

## 1. Decision

The long-term direction is not one universal cube containing every possible dimension.

The intended architecture is:

> preserve checked accounting facts and reusable projection materials, then compose multiple purpose-specific sparse projections or dense cubes from those materials.

The current Canonical Daily Cube remains a valid and important product contract, but it is treated as one standard composition rather than the unique final form of accounting data.

```text
human-readable source evidence
  -> checked posting facts
  -> reusable projection materials
  -> purpose-specific projection specification
  -> sparse grouped result
  -> optional dense materialization
  -> consumer-specific validation and presentation
```

This direction is evidence to explore rather than a permission boundary. Small experiments may test, refine, combine, or reject it.

## 2. Source truth, facts, and views

The intended separation is:

### Source evidence

Human-readable Journal and companion/configuration TSV remain source truth.

### Checked accounting facts

A shared fact relation preserves at least the meanings required by each admitted posting, including identity, time, account coordinate, layer, exact amount evidence, arithmetic domain, and provenance.

A fact relation is not itself a report and is not required to be dense.

### Purpose-specific views

A cube, matrix, balance view, movement view, settlement view, travel view, or ranking is a projection from checked facts for a concrete consumer.

The same source evidence may therefore support multiple views without making any one view the new source truth.

## 3. Projection materials

The reusable materials should be characterized as semantic modules rather than one module per tiny operation.

### 3.1 Admission and evidence retention

Owns which checked facts may enter a projection and preserves the difference between:

- admitted evidence;
- outside-selected-domain evidence;
- skipped evidence;
- rejected evidence;
- warning and unavailable states.

### 3.2 Coordinate extraction

Candidate coordinate meanings include:

- Day or another explicit time coordinate;
- Account;
- Layer;
- Lifecycle;
- Party or obligation party;
- Project or trip;
- other coordinates justified by a concrete consumer.

Coordinate modules extract meaning from facts. They do not automatically add themselves to every dense cube.

### 3.3 Measures

A projection must state what enters each cell or group, for example:

- signed exact movement;
- debit or credit movement;
- posting count;
- quantity;
- budget allocation;
- opening, movement, or closing evidence where the current TBDS contract permits it.

A measure owns its arithmetic requirements. An amount measure must not silently discard the domain required to add it safely.

### 3.4 Partition and filter

Some meanings should normally constrain or partition a projection before grouping rather than become dense axes automatically.

Important candidates include:

- arithmetic domain or commodity;
- economic entity or ownership boundary;
- ledger or book boundary where distinct from entity;
- explicit selected lifecycle policy;
- account-role or account-namespace partitions required by one concrete consumer.

Filters may include project, trip, party, location, source, layer, side, period, or other evidence needed by a concrete view.

A critical distinction obtained from the first real consumer is:

- transaction-level `kind` answers what kind of transaction this is;
- posting-level AccountKey partition answers which account coordinate this posting belongs to.

A multi-posting expense transaction can contain a non-expense debit coordinate such as a prepaid asset. Transaction kind therefore cannot classify every posting account.

### 3.5 Exact grouping

A reusable grouping boundary may accept explicit coordinate keys and exact values, then return deterministic sparse groups with exact accumulated values.

It must define empty input, duplicate coordinates, additive identity, rejected evidence, and provenance behavior explicitly.

`src_next/queries/exact_sparse_grouping.bqn` now provides the characterized minimal boundary:

```text
explicit keys + already-admitted exact values
  -> first-occurrence deterministic groups
  -> exact accumulated values
  -> conservation evidence
  -> optional contributor-index sidecar
```

The kernel deliberately does not own accounting axes, account roles, arithmetic-domain selection, valuation, source I/O, or posting identity.

### 3.6 Materialization

Dense materialization is optional and justified only when:

- axis domains are explicit and finite;
- a real consumer benefits from indexed dense shape;
- the shape and memory cost are understood;
- sparse facts and diagnostic evidence remain reachable.

The dense array is an output choice, not the universal stored representation.

### 3.7 Ordering and visible-result policy

Ordering belongs to the concrete consumer, not the grouping kernel.

The first ranking consumer established these useful distinctions:

- grouped order may preserve first occurrence;
- visible rows may exclude zero-net groups;
- ranking may use amount descending with semantic AccountKey ascending for ties;
- `ranking_order` must remain valid coordinates into the original grouped relation;
- hidden visible rows do not erase conservation or contributor evidence.

## 4. Axis, partition, filter, and metadata are different roles

A field is not an axis merely because it exists.

### Axis

Used repeatedly as a coordinate for grouping or indexed materialization in a specific projection.

Examples may include Day, Account, Layer, Party, or Lifecycle.

### Partition

Separates facts that must not be combined under the selected measure.

Arithmetic domain and economic entity are leading candidates. Currency may therefore remain an outer selected partition for many projections rather than becoming a new axis of the Canonical Daily Cube.

The expense AccountKey set used by one expense consumer is a semantic partition for that query. Its existence does not require adding `expense` as a global axis or copying account roles into every checked posting fact.

### Filter

Selects a contextual subset for one purpose-specific view, such as a trip, project, party, layer, side, or selected period.

A filter may later become an axis only after multiple concrete consumers justify the promotion.

### Metadata and provenance

Receipt references, memo, source file, source row, import identity, and similar evidence remain reachable without automatically becoming grouping axes.

## 5. Standard compositions

### 5.1 Canonical Daily Cube

The current standard composition remains:

```text
selected admissible fact partition
  + Day coordinate
  + Account coordinate
  + Layer coordinate
  + signed exact movement measure
  + exact grouped sum
  + dense Day × Account × Layer materialization
  + canonical validation
```

The current consumer-visible contract remains unchanged until an equivalence and migration sequence demonstrates a coherent replacement.

### 5.2 Selected-domain balances

A selected-domain balance view is another purpose-specific composition. It should not be treated as an exception bolted onto a JPY-centered core.

### 5.3 Actual expense ranking

The first real direct sparse consumer is:

```text
checked selected-domain posting facts
  + selected-period bounds
  + Actual layer filter
  + debit-side filter
  + explicit expense AccountKey partition
  + exact delta measure
  -> exact sparse groups by AccountKey
  -> hide zero-net groups from visible ranking
  -> amount descending, AccountKey ascending ties
  -> contributor posting IDs
```

Its current API accepts the posting rows, expense AccountKeys, period day count, selected currency, and calculation scale explicitly.

The focused evidence includes:

- duplicate expense postings;
- non-expense debit exclusion inside a transaction whose `kind` is `expense`;
- status/layer/period/side exclusions;
- deterministic tie order;
- contributor posting IDs;
- ranking coordinates into the original grouped relation;
- TBDS `ActualExpenseBreakdown` relation parity;
- `selected_domain_context` producer integration over a public synthetic fixture;
- JPY scale 0 and ILS scale 2 success;
- domain and scale mismatch fail-closed behavior.

This consumer is not yet a public report section and does not replace Cube or TBDS production accumulation.

### 5.4 Possible future views

Examples include:

```text
Month × Account × Layer movement
Party × Lifecycle × Account settlement
Project × Month expense movement
Trip-filtered Day × Account movement
Event × Account sparse matrix
Commodity-separated account balance view
```

Each view should state its partition, axes, measure, aggregation, validation, materialization, ordering, and provenance policy.

## 6. Safety and semantic invariants

Experiments in this area should preserve these invariants or explain clearly why an alternative is better:

- rejected facts never enter ordinary numeric output;
- exact amount evidence remains exact;
- values are accumulated only within an arithmetic domain authorized by the measure;
- different commodities are never directly added;
- different economic entities are never silently merged;
- duplicate coordinates combine deterministically;
- sparse grouped totals agree with admitted totals;
- dense output agrees with sparse output when dense materialization is used;
- source transaction and posting evidence remain reachable;
- unavailable, zero, skipped, warning, and error remain distinct;
- consumer-specific validation does not become a second contradictory source of accounting truth;
- transaction semantics and posting-coordinate classification are not silently collapsed;
- visible-result ordering remains traceable to the grouped relation it reorders.

## 7. Relationship to multiple books

A book need not be a separate copy of source data.

A future multi-book design may treat a book as a named projection policy over shared evidence, for example by selecting an economic entity, ownership boundary, arithmetic domain, time policy, and consumer-specific coordinates.

This direction should not assume in advance that every book can share all facts or that all ownership semantics are already represented. Economic entity and ownership need observation before implementation.

## 8. Ideas not implied by this direction

Purpose-specific projection composition does not require:

- one giant universal cube;
- automatic addition of every field as a dimension;
- a Currency axis in the Canonical Daily Cube;
- a universal CubeSpec DSL;
- SQL-like arbitrary querying;
- dynamic code generation;
- indiscriminate module fragmentation;
- source Journal replacement;
- implicit FX or valuation;
- mixed-domain totals;
- automatic book creation;
- automatic account creation;
- broad report rewrites;
- private production-data experiments;
- copying resolved account roles into checked facts before a real consumer requires that ownership change.

These remain separate questions rather than forbidden ideas.

## 9. Evidence obtained

The initial evidence-first sequence has now reached these points:

1. ownership across checked facts, coordinates, accumulation, Cube, TBDS, diagnostics, provenance, and consumers was inventoried;
2. `exact_sparse_grouping.bqn` characterized the minimal exact sparse grouping primitive with public synthetic facts;
3. the primitive reconstructed Canonical Cube numeric payload and supported TBDS-like grouping in parallel tests;
4. `actual_expense_ranking.bqn` proved one real direct consumer over checked posting facts;
5. review of that consumer exposed and corrected the transaction-kind versus posting-account-partition boundary;
6. complete visible relation parity with TBDS expense meaning was tested without importing Cube/TBDS into the production consumer;
7. selected-domain JPY/ILS producer integration and fail-closed arithmetic boundaries were demonstrated.

What has **not** been demonstrated:

- a second independent real consumer;
- a stable shared vocabulary broad enough to justify a generic projection DSL;
- complete Cube or TBDS result-contract replacement;
- production report wiring for the expense ranking;
- performance or memory evidence for broad replacement;
- ownership semantics for economic entities or multiple books.

## 10. Current next evidence

The next useful evidence is **a second independent real query over checked posting facts**.

It should be chosen because the query is useful, not because it resembles the first ranking. The purpose is to discover whether any filter/key/order vocabulary is genuinely shared, or whether the current exact grouping kernel is the appropriate stopping point.

A second consumer should state explicitly:

- the concrete question;
- input producer;
- arithmetic-domain partition;
- semantic account or entity partition;
- period/layer/side filters;
- exact measure;
- grouping keys;
- visible-result and ordering policy;
- provenance requirements;
- comparator or parity evidence;
- failure contract.

Only after the second independent consumer and complete result-contract evidence should the project choose among:

1. keep only the exact grouping kernel;
2. extract a small shared projection vocabulary;
3. adopt a larger projection kernel;
4. reject the abstraction and keep purpose-specific consumers independent.

The purpose is not maximum abstraction. The purpose is the smallest reusable projection algebra that can reproduce current views and support genuinely different questions without erasing accounting meaning.
