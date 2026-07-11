# Currency Stage 2 B2 Arithmetic Ownership Recheck

Status: completed
Owner: currency/docs
Canonical: no; current B2 semantics and routing: `docs/CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md`
Exit: retired after Outcome B selected one runtime owner and routing returned to B2 implementation

Date: 2026-07-11

## Purpose

Perform one finite ownership recheck before implementing Currency Stage 2 Slice B2.

This review exists because the current split decision assigns B2 arithmetic aggregation to `src_next/context.bqn`, while current-main observation shows growing orchestration pressure in `context.bqn` and suggests that snapshot arithmetic may deserve a dedicated pure owner.

The review must decide ownership only. It must not redesign B2 semantics and must not implement B2 arithmetic.

## Preserved B2 semantics

The following meaning is fixed for this review:

- aggregate the pre-built B1 row evidence;
- require exactly one resolved currency domain;
- select snapshot-wide `amount_scale`;
- normalize coefficients exactly;
- fail closed on normalized coefficient overflow;
- return internal arithmetic evidence.

The following exclusions remain fixed:

- no proof carrier extension;
- no projection row `delta` change;
- no ILS projection admission;
- full projection admission for scale > 0 rows remains closed.

This review must not reopen those decisions.

## Selected outcome: B — dedicated pure arithmetic owner

The later B2 runtime slice will introduce exactly one dedicated owner:

```text
src_next/currency_arithmetic.bqn
```

Its exact input is only the pre-built B1 row evidence produced from the shared in-memory posting snapshot. It must not read source files, reload a snapshot, split TSV rows, resolve metadata, parse source amounts, or rebuild row evidence.

Its output is internal snapshot arithmetic evidence containing:

- exactly one resolved currency domain, or fail-closed domain error evidence;
- snapshot-wide `amount_scale`, selected as the maximum canonical row scale;
- exact normalized coefficients;
- normalized coefficient overflow/error evidence.

`src_next/context.bqn` remains the orchestration owner. It loads one shared snapshot, builds B1 row evidence, passes that evidence to `currency_arithmetic.bqn`, and consumes the returned arithmetic evidence. This preserves the same-snapshot invariant without giving the arithmetic module any loading or projection responsibility.

Focused B2 unit tests will import `src_next/currency_arithmetic.bqn` directly. They will prove mixed-domain failure, amount-scale selection, exact normalization, and normalized overflow without requiring full context construction.

This is a real semantic seam reduction rather than a decorative wrapper: exactly-one-domain aggregation and snapshot-wide coefficient normalization form an independently meaningful pure boundary, separate from context loading, cycle resolution, account resolution, projection authorization, cube, and TBDS.

The dedicated module is not a generic arithmetic framework, FX owner, display precision owner, valuation owner, or mixed-currency engine.

## Candidate ownership models

### A. Keep B2 arithmetic in `src_next/context.bqn`

Shape:

```text
exact_decimal.bqn
  scalar exact-decimal parsing

context.bqn
  row evidence orchestration
  snapshot arithmetic aggregation
  amount_scale selection
  normalization
  overflow evidence
  downstream orchestration
```

Adopt only if the arithmetic helper can remain pure, narrow, independently testable, and does not materially worsen context ownership pressure.

### B. Introduce one dedicated pure snapshot arithmetic module

Candidate shape:

```text
exact_decimal.bqn
  scalar exact-decimal parsing

<dedicated arithmetic module>
  aggregate pre-built row evidence
  exactly-one-domain check
  amount_scale selection
  exact coefficient normalization
  normalized overflow evidence

context.bqn
  orchestration only
  passes pre-built B1 row evidence into the arithmetic owner
  consumes returned internal evidence
```

Possible names are examples only, not preselected API decisions:

- `src_next/currency_arithmetic.bqn`
- `src_next/snapshot_amount_arithmetic.bqn`

Do not create both. Do not choose a name before ownership is decided.

## Review questions

Answer using current-main evidence:

1. Does B2 arithmetic have a coherent pure input/output boundary independent of context loading and projection authorization?
2. Would keeping B2 in `context.bqn` add materially different ownership to an already central orchestration module?
3. Can a dedicated module consume only pre-built B1 row evidence with no source re-read and preserve the same-snapshot invariant?
4. Can focused unit tests prove mixed-domain failure, amount-scale selection, exact normalization, and normalized overflow without constructing full context?
5. Would extraction create a real seam reduction, or only move a few lines into a decorative wrapper?
6. Which owner makes B3 integration clearer without pre-implementing B3?

## Required evidence

Before selecting ownership, inspect at minimum:

- `src_next/context.bqn`
- `src_next/exact_decimal.bqn`
- `docs/CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md`
- `docs/archive/audits/CURRENCY_STAGE2_SLICE_B1_POST_IMPLEMENTATION_VERIFICATION-2026-07-10.md`
- B1 focused tests/checks that prove pre-built evidence and same-snapshot ownership

Use current `main`, not the pre-audit ZIP state.

## Decision outcomes

Select exactly one:

### Outcome A: keep current owner

Record why `context.bqn` remains the better owner and why a new module would be decorative or premature.

### Outcome B: dedicated pure arithmetic owner

Record:

- selected module responsibility;
- exact input boundary from pre-built B1 row evidence;
- exact output/internal evidence boundary;
- why this reduces semantic ownership pressure rather than merely moving code;
- narrow test owner;
- confirmation that context remains orchestration owner.

### Outcome C: insufficient evidence

Do not implement B2. Record what concrete current-main evidence is missing and the smallest way to obtain it.

## Non-goals

Do not:

- implement B2 arithmetic;
- change B2 semantics;
- change B1 row evidence shape unless a separate decision is first required;
- extend the proof carrier;
- change projection `delta`;
- admit ILS;
- admit scale > 0 full projection;
- split `context.bqn` broadly;
- refactor `exact_decimal.bqn` broadly;
- create a generic arithmetic framework;
- create multiple new modules;
- add telemetry, lint, registry, CI gates, or a compatibility layer.

## Acceptance criteria

- one ownership outcome is selected explicitly;
- B2 semantics and exclusions are restated unchanged;
- current-main evidence supports the decision;
- no runtime/test/fixture/source/workflow change occurs in the ownership-decision slice;
- the selected next runtime route is explicit;
- any dedicated module decision names one owner only and preserves the same-snapshot invariant.

## Decision closure and next routing

Outcome B is the only selected outcome. Current-main B1 evidence establishes a coherent pre-built row-evidence input, while `context.bqn` already owns loading, row-evidence construction, proof gating, projection coordination, cycle/account resolution, cube, and TBDS orchestration. The dedicated pure owner therefore removes independently testable arithmetic meaning from that central orchestrator without changing the B1 evidence shape.

The exact next authorized runtime slice is:

```text
Currency Stage 2 Slice B2: Snapshot Arithmetic Evidence
owner: src_next/currency_arithmetic.bqn
orchestrator: src_next/context.bqn
```

B2 semantics remain unchanged: aggregate pre-built B1 row evidence, require exactly one resolved domain, select maximum canonical row scale as `amount_scale`, exact-normalize coefficients, fail closed on normalized coefficient overflow, and return internal arithmetic evidence.

Exclusions also remain unchanged: no proof carrier extension, projection row `delta` change, ILS projection admission, full projection admission for scale > 0 rows, B1 row-evidence shape change, broad `context.bqn` decomposition, or broad `exact_decimal.bqn` refactor. This completed decision contains no runtime implementation.
