# Currency Stage 2 Explicit Single-Currency Admission Decision

Status: current contract / docs-only decision record
Owner: config
Canonical: yes
Decision date: 2026-07-10
Depends on: `docs/CURRENCY_AWARENESS_CAMPAIGN_MAP.md`, `docs/CURRENCY_STAGE1_AMOUNT_SEMANTICS_DECISION.md`, `docs/CURRENCY_STAGE2_SINGLE_CURRENCY_DOMAIN_DECISION.md`, `docs/CURRENCY_STAGE2_MINIMAL_DOMAIN_PROOF_IMPLEMENTATION_PLAN.md`, `docs/CURRENCY_STAGE2_BUILDPERIODVIEW_DOWNSTREAM_BOUNDARY_DECISION.md`, `docs/POSTING_IR_CONTRACT.md`
Exit: supersede when a later current contract replaces explicit source-currency admission, single-domain proof resolution, or the exact-decimal readiness boundary for non-JPY operation

This document selects the next narrow Stage 2 meaning after a concrete consumer requirement emerged: support real single-currency ILS recording without jumping to mixed-currency arithmetic or FX.

This slice is docs-only. It does not authorize runtime, test, fixture, source TSV, metadata schema, editor, or report changes.

## 1. Question

How may explicit source-row currency identity such as:

```text
currency=ILS
```

be admitted as proof evidence for one non-JPY single-currency arithmetic domain without authorizing:

- mixed JPY + ILS arithmetic;
- per-row multi-currency reporting;
- FX conversion;
- valuation semantics;
- a false claim that current integer-only runtime already supports ordinary ILS amounts such as `42.50`?

## 2. Selected meaning

Selected Stage 2 extension:

```text
explicit source-row currency identity
may become single-domain proof evidence
only after every admitted posting-source row in one shared snapshot resolves to exactly one arithmetic currency identity
```

The intended checked path remains:

```text
one posting-source snapshot
  -> resolve row currency identities
  -> prove exactly one arithmetic currency domain
  -> projection-owned authorization
  -> construct naked Posting IR deltas
  -> trusted downstream BuildPeriodView path
```

This is still Stage 2 single-currency operation.

It is not Stage 3 mixed per-row original-currency operation.

## 3. Initial admitted explicit currency set

The first implementation plan may target only:

```text
JPY
ILS
```

Reason:

- JPY is the existing compatibility domain;
- ILS is the concrete non-JPY consumer requirement;
- adding a broad ISO-code registry is not required to prove the first non-JPY single-domain path.

This decision does not claim that JPY and ILS are the permanent full currency set.

Adding USD, EUR, or other codes later requires an explicit extension of the admitted known-currency policy or a separately owned registry decision.

## 4. Row currency resolution

For each admitted monetary source row from:

```text
journal.tsv
plan.tsv
budget_alloc.tsv
```

inspect metadata tokens only after the protected first five fields.

Selected resolution:

```text
no currency= token
  -> legacy compatibility JPY identity

exactly one currency=JPY token
  -> explicit JPY identity

exactly one currency=ILS token
  -> explicit ILS identity

exactly one other currency=<value> token
  -> unknown / unsupported explicit currency
  -> invalid / fail closed

more than one currency= token
  -> duplicate currency metadata
  -> invalid / fail closed
```

Duplicate `currency=` tokens fail closed even if their values are identical.

Examples:

```text
currency=ILS currency=ILS
  -> invalid duplicate metadata

currency=JPY currency=ILS
  -> invalid duplicate metadata
```

Do not silently use first-wins or last-wins behavior.

Preserve:

```text
missing currency != explicit JPY
explicit row identity != arithmetic domain proof by itself
```

## 5. Snapshot-level domain proof

Proof input must remain the exact same in-memory posting-source snapshot later used for projection.

After resolving every admitted monetary source row, collect distinct resolved currency identities.

Selected proof rule:

```text
exactly one distinct resolved currency identity
  -> single-currency proof succeeds
  -> proof.domain = that identity

more than one distinct resolved currency identity
  -> mixed domain
  -> fail closed before naked delta construction

any invalid / unknown / duplicate row currency state
  -> fail closed before naked delta construction
```

Selected examples:

```text
all rows missing currency
  -> all resolve through compatibility JPY
  -> domain = JPY
```

```text
missing currency rows + explicit currency=JPY rows
  -> all resolve to JPY identity
  -> domain = JPY
```

```text
all rows explicit currency=ILS
  -> domain = ILS
```

```text
missing currency row + explicit currency=ILS row
  -> resolved identities = JPY + ILS
  -> mixed domain
  -> fail closed
```

```text
explicit currency=JPY + explicit currency=ILS
  -> mixed domain
  -> fail closed
```

```text
no monetary source rows
  -> preserve current empty-source compatibility
  -> domain = JPY
  -> basis = empty_source_compatibility
```

The empty-source case does not infer ILS.

## 6. Proof basis consequence

The current Stage 2 runtime authorizes only JPY proofs with:

```text
legacy_compatibility
empty_source_compatibility
```

A later implementation plan must revise proof-basis semantics deliberately rather than merely changing:

```text
domain = JPY
```

to:

```text
domain in {JPY, ILS}
```

The proof must retain enough evidence meaning to distinguish at least:

```text
legacy compatibility resolution
empty-source compatibility resolution
explicit single-currency resolution
```

Exact runtime field names and basis strings remain implementation-plan decisions.

Do not create a second independent domain truth beside the proof carrier without a concrete consumer requirement.

## 7. Exact-decimal readiness boundary

Stage 1 already selects:

```text
source amount = exact decimal monetary quantity
```

and gives the intended ILS example:

```text
42.50 currency=ILS
```

Current runtime remains integer-only.

Therefore selected product truth:

```text
explicit ILS proof support alone
!= operational ILS recording support complete
```

A later implementation must not claim ordinary ILS recording is complete while the source / projection amount path still rejects exact decimal quantities such as `42.50`.

The next implementation plan must explicitly decide an exact-decimal runtime representation and arithmetic path that:

- does not use implicit binary floating-point semantics;
- does not silently round;
- preserves the Stage 1 source amount meaning;
- authorizes arithmetic only inside the proven single-currency domain;
- remains compatible with existing integer JPY rows.

This decision does not yet select:

- integer minor-unit normalization;
- coefficient + scale representation;
- rational representation;
- another exact-decimal carrier.

Choosing that runtime representation is part of the next finite planning slice.

## 8. Posting IR boundary

Preserve the Stage 1 transitional rule:

```text
naked Posting IR delta
is valid only inside a proven single-currency arithmetic domain
```

For future ILS support:

```text
proven domain = ILS
  -> ILS-domain arithmetic may proceed only after the exact-decimal runtime path is explicitly selected and implemented
```

This document does not add currency fields to Posting IR and does not authorize a mixed-currency Posting IR shape.

## 9. Downstream boundary

The current `BuildPeriodView` decision remains unchanged:

```text
BuildPeriodView
= trusted post-gate downstream consumer
```

The normal checked claim remains scoped to:

```text
BuildContext
  -> proof resolution
  -> projection-owned authorization
  -> authorized posting rows
  -> BuildPeriodView
```

This decision does not add a proof argument to `BuildPeriodView`, narrow its export, or make it a second authorization owner.

## 10. Stage distinction

Selected classification:

```text
all admitted rows resolve to JPY
  -> Stage 2 single-currency JPY domain

all admitted rows resolve to ILS
  -> Stage 2 single-currency ILS domain

admitted rows resolve to JPY + ILS
  -> mixed domain
  -> fail closed
  -> not supported by this Stage 2 slice
```

Stage 3 remains the later problem of preserving mixed per-row original currency safely.

Do not smuggle Stage 3 in through a permissive `currency=` parser.

## 11. Non-goals

This decision does not authorize:

- runtime BQN changes;
- tests or checks;
- fixtures;
- source TSV changes;
- real data changes;
- sample data changes;
- `config/meta_schema.tsv` changes;
- `docs/JOURNAL_META.md` operational support claims;
- editor changes;
- decimal parser implementation;
- Posting IR shape changes;
- cube / TBDS axis changes;
- currency-partitioned reports;
- per-row mixed-currency operation;
- `base_amount=`;
- `BASE_CURRENCY`;
- FX rates;
- conversion;
- valuation semantics;
- live APIs.

## 12. Next finite slice

Selected next finite slice:

```text
Currency Stage 2 explicit single-currency + exact-decimal minimal implementation plan
```

That plan must decide, before runtime work:

1. exact-decimal source parser and exact internal carrier;
2. row currency resolver behavior for missing / JPY / ILS / unknown / duplicate states;
3. snapshot-level distinct-domain proof algorithm;
4. proof basis and projection authorization changes;
5. compatibility behavior for existing integer JPY rows;
6. fixture and executable evidence matrix;
7. editor / metadata-schema work ordering without changing real source TSV first;
8. the smallest runtime slice that can honestly demonstrate `42.50 currency=ILS` inside an all-ILS single domain.

No runtime implementation is authorized by this decision itself.

## 13. Closure of this decision slice

```text
explicit JPY / ILS row identity semantics -> selected
single-snapshot exact-one-domain proof rule -> selected
missing + ILS -> mixed / fail closed
JPY + ILS -> mixed / fail closed
duplicate currency metadata -> fail closed
empty source -> existing JPY compatibility preserved
operational ILS support without exact decimals -> explicitly not claimed
Stage 3 mixed-currency operation -> not authorized
FX / valuation -> not authorized
next step -> docs-only minimal implementation plan
```
