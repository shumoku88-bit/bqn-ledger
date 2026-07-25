# Purpose-Specific Projection Composition Direction

Status: accepted architectural direction / docs-only / no runtime authorization
Owner: architecture / projection
Canonical: no; complements `docs/CANONICAL_DAILY_CUBE.md` and `GENERIC_PROJECTION_AND_VALUATION_FOUNDATION_DESIGN_INTAKE-2026-07-24.md`
Exit: replace with separately selected finite characterization and implementation plans, or archive if evidence rejects the direction

Date: 2026-07-25

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

No runtime refactor is authorized by this document. `TODO.md` remains the gate for every finite slice.

## 2. Source truth, facts, and views

The intended separation is:

### Source evidence

Human-readable Journal and companion/configuration TSV remain source truth.

### Checked accounting facts

A shared fact relation preserves at least the meanings required by each admitted posting, including identity, time, account coordinate, layer, exact amount evidence, arithmetic domain, and provenance.

A fact relation is not itself a report and is not required to be dense.

### Purpose-specific views

A cube, matrix, balance view, movement view, settlement view, or travel view is a projection from checked facts for a concrete consumer.

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
- explicit selected lifecycle policy.

Filters may include project, trip, party, location, source, or other evidence needed by a concrete view.

### 3.5 Exact grouping

A reusable grouping boundary may accept explicit coordinate keys and exact values, then return deterministic sparse groups with exact accumulated values.

It must define empty input, duplicate coordinates, additive identity, rejected evidence, and provenance behavior explicitly.

### 3.6 Materialization

Dense materialization is optional and justified only when:

- axis domains are explicit and finite;
- a real consumer benefits from indexed dense shape;
- the shape and memory cost are understood;
- sparse facts and diagnostic evidence remain reachable.

The dense array is an output choice, not the universal stored representation.

## 4. Axis, partition, filter, and metadata are different roles

A field is not an axis merely because it exists.

### Axis

Used repeatedly as a coordinate for grouping or indexed materialization in a specific projection.

Examples may include Day, Account, Layer, Party, or Lifecycle.

### Partition

Separates facts that must not be combined under the selected measure.

Arithmetic domain and economic entity are leading candidates. Currency may therefore remain an outer selected partition for many projections rather than becoming a new axis of the Canonical Daily Cube.

### Filter

Selects a contextual subset for one purpose-specific view, such as a trip, project, or party.

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

The current consumer-visible contract remains unchanged until a separately approved equivalence and migration sequence proves otherwise.

### 5.2 Selected-domain balances

A selected-domain balance view is another purpose-specific composition. It should not be treated as an exception bolted onto a JPY-centered core.

### 5.3 Possible future views

None are selected automatically, but examples include:

```text
Month × Account × Layer movement
Party × Lifecycle × Account settlement
Project × Month expense movement
Trip-filtered Day × Account movement
Event × Account sparse matrix
Commodity-separated account balance view
```

Each view must state its partition, axes, measure, aggregation, validation, and materialization policy.

## 6. Safety and semantic invariants

Any future projection composition must preserve these invariants:

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
- consumer-specific validation does not become a second contradictory source of accounting truth.

## 7. Relationship to multiple books

A book need not be a separate copy of source data.

A future multi-book design may treat a book as a named projection policy over shared evidence, for example by selecting an economic entity, ownership boundary, arithmetic domain, time policy, and consumer-specific coordinates.

This direction must not assume in advance that every book can share all facts or that all ownership semantics are already represented. Economic entity and ownership require separate characterization before implementation.

## 8. Non-goals

This direction does not authorize:

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
- private production-data experiments.

## 9. Migration posture

The existing Canonical Daily Cube and current reports remain operational.

The safe migration sequence is evidence-first:

1. inventory current owners of facts, axes, measures, grouping, dense materialization, validation, diagnostics, provenance, TBDS overlap, and consumers;
2. characterize one exact sparse grouping primitive with public synthetic facts;
3. reconstruct the Canonical Daily Cube in parallel and compare its complete result contract;
4. prove one genuinely independent second consumer;
5. choose whether to adopt only the primitive, adopt a small projection kernel, or reject the abstraction.

The purpose is not maximum abstraction. The purpose is the smallest reusable projection algebra that can reproduce the current cube and support genuinely different views without erasing accounting meaning.

## 10. Immediate routing consequence

This document records architectural intent only.

The first eligible finite slice remains a docs-only ownership inventory. It should inspect the current implementation without assuming that extraction is already justified and without changing `cube.bqn`, TBDS, reports, source formats, or runtime routing.
