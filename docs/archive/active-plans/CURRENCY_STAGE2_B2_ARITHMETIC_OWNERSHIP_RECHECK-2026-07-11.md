# Currency Stage 2 B2 Arithmetic Ownership Recheck

Status: active plan
Owner: currency/docs
Canonical: no; B2 semantics remain owned by `docs/CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md`
Exit: retire after one docs-only ownership decision records the selected runtime owner and routing returns to B2 implementation

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

## Current selected owner

Current split decision:

```text
src_next/context.bqn
  arithmetic aggregation helper
```

This remains the selected owner unless the finite review explicitly changes it.

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

## Routing after decision

After this ownership recheck closes:

```text
Currency Stage 2 Slice B2: Snapshot Arithmetic Evidence
```

remains the next runtime slice.

The ownership decision changes only where B2 arithmetic lives, not what B2 means.
