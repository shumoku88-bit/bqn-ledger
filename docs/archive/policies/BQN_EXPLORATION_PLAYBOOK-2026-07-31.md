# BQN Exploration Playbook

Status: current exploration policy

## Purpose

`bqn-ledger` is both a trustworthy household-accounting system and a place to experience BQN deeply.

Production safety remains non-negotiable, but production acceptance is not the only legitimate destination for an idea. A primitive, modifier, array representation, tacit form, inverse, or newly revealed capability may be worth exploring even when it is not yet suitable for the runtime.

BQN is not only an implementation language for questions already chosen. Its array model may reveal questions, reports, and representations that were not visible before.

The repository therefore keeps two distinct lanes:

1. **exploration lane** — freely compare BQN formulations, representations, and new questions;
2. **adoption lane** — use the bounded review gate before changing production meaning or code.

The exploration lane feeds the adoption lane. It is not weakened production review.

## Standing intent

For every BQN design, review, refactor, parser, accounting, reporting, editor, or testing task, actively perform a **BQN opportunity scan**.

Do not wait for a primitive name to be requested. Consider whether the current question exposes:

- a direct primitive or modifier with exactly matching semantics;
- a clearer cell, frame, rank, axis, or shape model;
- a whole-array coordinate, mask, classify, group, scatter, scan, or reduction;
- a different representation that reveals the problem more directly;
- a reversible view, inverse, or structural update;
- a compact train or composition that preserves useful domain names;
- a new report, observation, editor aid, diagnostic view, or learning experiment suggested by the data shape;
- a reason why the explicit staged form is already the most expressive BQN form.

The scan is successful even when the result is “keep the current form.” Primitive coverage is never the target.

Before selecting work, read `BQN_EXPLORATION_CATALOG.md` and compare its living cards with the current owner and tests. Revise the catalog when new evidence changes an old assumption.

## What counts as beautiful

BQN beauty in this repository is not glyph density.

A formulation is worth showing when it does one or more of the following:

- makes the input cells, axes, coordinates, and output shape visible;
- states the domain question more directly than control-flow scaffolding;
- preserves exactness, identity, provenance, ordering, and diagnostics while removing incidental machinery;
- reveals symmetry, duality, an inverse, or a reusable computational kernel;
- suggests focused tests or exposes an assumption that was previously hidden;
- opens a useful household-accounting capability that was difficult to see in the previous representation;
- is surprising, elegant, or educational without pretending to be production-ready.

A longer explicit block can be the more beautiful result when it visibly owns evidence staging, rejection order, or publication boundaries.

## Four legitimate destinations

Every interesting BQN idea should be placed deliberately in one of four destinations.

### 1. Production finite slice

Use when an existing primitive or formulation expresses exactly the current meaning and the contract can be characterized.

Requirements:

- one finite question;
- one clear owner;
- current behavior pinned before replacement;
- focused implementation and tests;
- the full `BQN_REFACTORING_REVIEW_GUIDE.md` adoption gate.

### 2. Analysis-only probe

Use when equivalence, shape, fill, rank, ordering, or performance is still uncertain.

A probe may compare several formulations, print shapes, or construct synthetic examples. It must not silently become a production dependency.

Default home: `experiments/bqn/`.

### 3. Personal BQN book experiment

Use when the idea is educational, playful, or intentionally simplified, especially for Cells, Rank, Table, Shift, Transpose, Under, Undo, trains, and alternate representations.

The experiment may use the same public fixtures or synthetic household-accounting shapes while explicitly relaxing production contracts.

### 4. Parked non-use record

Use when the primitive is understood but no current domain question exists, or when the current representation and safety contracts make it a poor fit.

Record why it is not selected. “Not selected now” is not a permanent prohibition. The default durable home for a useful parked observation is `BQN_EXPLORATION_CATALOG.md`.

## AI working agreement

When investigating or proposing BQN work, AI should include a small BQN opportunity scan in its reasoning or report. It should normally surface the strongest candidates rather than every imaginable glyph.

For each surfaced candidate, state:

- the finite question or newly revealed capability;
- the owner and current representation;
- the primitive, modifier, or alternative array model;
- what becomes clearer or more elegant;
- the hidden assumption or semantic risk;
- the proposed destination: production, probe, book, or parked;
- why the candidate was or was not selected for the current slice.

AI may propose functionality that the user did not explicitly name when it arises naturally from the current data shape. Such proposals must be labeled as **new capability**, not disguised as meaning-preserving refactor.

A probe may freely compare multiple formulations, primitives, or representations. Do not automatically promote multiple candidates into production. After exploration and discussion, select at most one coherent production slice for adoption and keep the other discoveries visible in `BQN_EXPLORATION_CATALOG.md`, `experiments/bqn/`, or the personal book.

## Representation freedom

Current representations are evidence, not sacred syntax.

It is valid to explore:

- nested rows versus true rank-2 arrays;
- namespace columns versus arrays of records;
- sparse groups versus dense tables;
- source order versus sorted order versus first-occurrence order;
- contributor arrays as provenance-bearing sequences rather than sets;
- canonical domain values versus presentation-only views;
- explicit stages versus trains or modifier composition.

A representation experiment must say which production contracts it intentionally ignores and which it is testing. No representation change enters production merely because it admits more primitives.

## New capability discovery

BQN exploration may reveal useful questions that the current system does not yet ask. Examples include:

- previous calendar day versus previous active transaction day;
- Account × Layer or Transaction × Posting views;
- presentation-only MatrixResult axis exchange;
- contributor-path inspection;
- movement, interval, or adjacency reports;
- alternate dense and sparse renderings of the same admitted evidence.

These are welcome discoveries. They enter the new-capability lane and require a separate correctness decision before implementation. Preserve durable candidates in the exploration catalog even when no implementation is selected.

## Relationship to production review

`BQN_REFACTORING_REVIEW_GUIDE.md` remains the adoption gate. This playbook changes what AI and contributors are encouraged to notice, compare, and preserve as possibilities before that gate.

Exploration may be extravagant. Adoption remains finite.

Exploration is not itself architecture progress. It does not resolve dependency direction, source-role versus physical-format coupling, neutral-result versus renderer ownership, writer authority, or avoidable whole-evidence rescans. Keep those observed seams visible and select them through finite architecture or algorithm slices rather than assuming a larger catalog makes the runtime cleaner.

The exploration documents must remain proportionate. Consolidate or retire stale cards, do not require ceremony for a trivial correction, and do not let catalog maintenance displace a current household need or a selected production boundary.

## Standing examples

Good recurring probe families include:

- `¨` versus Cells versus Rank over MatrixResult row validation;
- nested `¨` versus Table for dense row × column lookup;
- sparse grouping versus dense coordinate products;
- Shift Before and Shift After over explicit temporal axes;
- values, contributors, and coordinate metadata under Transpose;
- pure toy Journal view-edit-reconstruct with Under;
- canonical-subset round trips and Undo;
- named stages versus Atop, Over, Before, After, Left, Right, and Constant;
- structured diagnostics versus development-only Assert.

These are invitations, not a cleanup queue.

## Stop signs

Exploration must not be used to:

- weaken accounting semantics, exactness, identity, provenance, source admission, or fail-closed behavior;
- relabel new functionality as a harmless refactor;
- flatten multi-posting or contributor evidence for a prettier array;
- replace ordered diagnostic values with abrupt failure in production;
- treat editor reconstruction as correct without byte, comment, metadata, ordering, and identity evidence;
- make primitive coverage, tacitization, or glyph count a quality metric;
- turn every discovered idea into a repository-wide rewrite.

The aim is not to make all code look alike. The aim is to keep BQN's full expressive landscape visible while the ledger remains trustworthy.