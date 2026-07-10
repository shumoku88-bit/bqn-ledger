# Currency Stage 2 Explicit Single-Currency Exact-Decimal Implementation Plan

Status: active implementation plan / docs-only
Owner: config
Canonical: yes
Decision date: 2026-07-10
Depends on: `docs/CURRENCY_STAGE1_AMOUNT_SEMANTICS_DECISION.md`, `docs/CURRENCY_STAGE2_SINGLE_CURRENCY_DOMAIN_DECISION.md`, `docs/CURRENCY_STAGE2_MINIMAL_DOMAIN_PROOF_IMPLEMENTATION_PLAN.md`, `docs/CURRENCY_STAGE2_BUILDPERIODVIEW_DOWNSTREAM_BOUNDARY_DECISION.md`, `docs/CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_ADMISSION_DECISION.md`, `docs/POSTING_IR_CONTRACT.md`
Exit: archive or supersede after the selected staged runtime path reaches honest all-ILS exact-decimal operation or a later current contract replaces its exact-decimal carrier, normalization scale, or proof shape

This document plans the smallest staged runtime path from the current integer-only JPY compatibility implementation toward an all-ILS single-currency domain that can preserve an exact source amount such as:

```text
42.50 currency=ILS
```

This PR is docs-only. It does not implement runtime, tests, checks, fixtures, source TSV, metadata schema, editor, report, JSON, Posting IR, cube, or TBDS changes.

## 1. Current runtime facts

Current `src_next/context.bqn` amount flow is:

```text
amountText
  -> projection.IsIntegerText
  -> •BQN amountText
  -> scalar Number amount
  -> debit / credit delta
```

Therefore:

```text
42.50
  -> invalid_amount
```

Current currency proof behavior is also narrower than the selected decision:

```text
any explicit currency= token
  -> unsupported
```

Current projection authorization requires:

```text
proof.state = proven
proof.domain = JPY
proof.basis in {
  legacy_compatibility,
  empty_source_compatibility
}
```

Current cube and TBDS consumers sum scalar `delta` values with ordinary numeric reductions.

Consequence:

```text
admit currency=ILS only
  != honest ILS support
```

The amount path and arithmetic carrier must be made exact first.

## 2. Selected exact-decimal parse carrier

At the source parse boundary, represent one exact finite decimal as:

```text
{
  coefficient,
  scale,
  source_text,
  state,
  message
}
```

Meaning:

```text
quantity = coefficient × 10^(-scale)
```

Examples after arithmetic canonicalization:

```text
1200
  -> coefficient = 1200
  -> scale = 0

42.50
  -> coefficient = 425
  -> scale = 1

0.05
  -> coefficient = 5
  -> scale = 2

0.000
  -> coefficient = 0
  -> scale = 0
```

Trailing fractional zeros are removed for arithmetic canonicalization.

Preserve:

```text
exact quantity != source text spelling
exact quantity != display precision
```

The original source text remains available for diagnostics.

## 3. Selected parser grammar

Accept only:

```text
digits+
```

or:

```text
digits+ "." digits+
```

Examples:

```text
1200      valid
42.50     valid
0.05      valid
00042.50  valid, canonicalized
```

Reject:

```text
empty
+42.50
-42.50
.50
42.
1e3
1E3
1,200
42 50
1.2.3
```

Rationale:

- current transaction direction is expressed by `from` / `to`;
- exponent and locale syntax are not required by the concrete ILS consumer;
- no automatic rounding policy is selected.

The implementation must not treat this as sufficient:

```text
•BQN "42.50"
```

Decimal text must be split into digit-only coefficient information and scale before arithmetic admission.

## 4. Selected arithmetic carrier

After all admitted posting-source rows in one shared snapshot have valid exact-decimal parse results, select one snapshot-wide arithmetic scale:

```text
amount_scale
  = maximum canonical row scale
```

Empty source:

```text
amount_scale = 0
```

Normalize each parsed amount exactly:

```text
normalized_coefficient
  = coefficient × 10^(amount_scale - row.scale)
```

Example:

```text
42.50 -> canonical 425 × 10^-1
0.05  -> canonical   5 × 10^-2
18    -> canonical  18 × 10^0

amount_scale = 2

normalized coefficients:
4250
5
1800
```

Selected Posting IR direction:

```text
delta
  = signed normalized integer coefficient
    inside one proven currency domain
    at one carried amount_scale
```

This preserves the useful scalar aggregation shape of cube and TBDS.

Preserve:

```text
amount_scale
  != currency identity
  != display precision
  != exchange rate
  != valuation policy
```

It is an arithmetic-unit carrier for one loaded posting-source snapshot.

## 5. Exactness / range boundary

The implementation must fail closed if either:

```text
parsed coefficient
```

or:

```text
normalized coefficient
```

cannot be represented exactly by the selected runtime integer path.

Selected diagnostic meaning:

```text
amount_out_of_exact_range
```

or a repository-native equivalent.

Do not silently continue after numeric rounding or overflow.

This plan does not hardcode an unverified numeric limit. Slice A must include executable boundary evidence for its exact integer conversion path.

Preserve:

```text
syntactically valid decimal
  != exactly representable runtime coefficient
```

## 6. Selected row currency resolution

For every admitted monetary source row from:

```text
journal.tsv
plan.tsv
budget_alloc.tsv
```

inspect only metadata tokens after the protected first five fields.

Selected resolution:

```text
no currency= token
  -> JPY identity
  -> evidence = legacy_compatibility

exactly one currency=JPY
  -> JPY identity
  -> evidence = explicit

exactly one currency=ILS
  -> ILS identity
  -> evidence = explicit

exactly one other currency=<value>
  -> invalid / unsupported
  -> fail closed

more than one currency= token
  -> invalid duplicate metadata
  -> fail closed
```

Duplicate tokens fail closed even when values are identical.

## 7. Selected snapshot arithmetic-proof flow

Proof input, amount normalization input, and projection input must remain one shared in-memory snapshot.

Selected order:

```text
LoadPostingSourceSnapshot once
  -> split admitted rows
  -> resolve row currency identity
  -> parse exact decimal amount
  -> reject unknown / duplicate currency states
  -> reject invalid decimal states
  -> reject non-exact coefficient range states
  -> collect distinct resolved currency identities
  -> require exactly one currency domain
  -> select amount_scale
  -> exact-normalize row coefficients
  -> build proof
  -> projection-owned authorization
  -> build posting rows from the same snapshot evidence
```

Preserve:

```text
proof input snapshot
  = amount normalization input snapshot
  = projection input snapshot
```

Do not re-read source TSV between these stages.

## 8. Selected proof carrier extension

Current carrier:

```text
ctx.arithmetic_currency_proof = {
  state,
  domain,
  basis,
  message
}
```

Selected future carrier:

```text
ctx.arithmetic_currency_proof = {
  state,
  domain,
  basis,
  amount_scale,
  message
}
```

Do not add a second independent domain or scale truth unless a concrete consumer later requires it.

### 8.1 Proof basis vocabulary

Retain:

```text
empty_source_compatibility
legacy_compatibility
```

Add:

```text
resolved_single_currency
```

Selected meanings:

```text
empty_source_compatibility
  -> no admitted monetary rows
  -> domain = JPY
  -> amount_scale = 0
```

```text
legacy_compatibility
  -> all admitted rows lack explicit currency metadata
  -> all resolve to JPY
```

```text
resolved_single_currency
  -> at least one explicit JPY or ILS identity participates
  -> every admitted row resolves to exactly one domain
```

Examples:

```text
missing + explicit JPY
  -> domain = JPY
  -> basis = resolved_single_currency
```

```text
all explicit ILS
  -> domain = ILS
  -> basis = resolved_single_currency
```

## 9. Future projection authorization rule

After the staged implementation reaches ILS admission:

```text
proof.state = proven
proof.domain in {JPY, ILS}
proof.basis in {
  empty_source_compatibility,
  legacy_compatibility,
  resolved_single_currency
}
proof.amount_scale is a valid non-negative integer scale
```

Additional invariant:

```text
empty_source_compatibility
  -> domain = JPY
  -> amount_scale = 0
```

Projection must not choose or change amount scale independently from proof resolution.

## 10. Compatibility and fail-closed matrix

### Existing JPY compatibility

For current rows shaped as:

```text
missing currency=
integer amount text
```

require:

```text
domain = JPY
basis = legacy_compatibility
amount_scale = 0
normalized coefficient = existing integer amount
posting delta unchanged
existing golden behavior unchanged
```

Historical JPY rows are not rewritten.

### All-ILS target

Example:

```text
42.50 currency=ILS
18     currency=ILS
0.05   currency=ILS
```

Expected:

```text
domain = ILS
basis = resolved_single_currency
amount_scale = 2
normalized coefficients = 4250, 1800, 5
```

Exact aggregate meaning:

```text
4250 + 1800 + 5
  = 6055 at scale 2
  = 60.55 ILS
```

### Mixed / invalid states

```text
missing + explicit ILS
  -> JPY + ILS
  -> mixed
  -> fail closed
```

```text
explicit JPY + explicit ILS
  -> mixed
  -> fail closed
```

```text
currency=USD
  -> unsupported in first admitted set
  -> fail closed
```

```text
currency=ILS currency=ILS
  -> duplicate metadata
  -> fail closed
```

```text
42.5.0 currency=ILS
  -> invalid decimal
  -> fail closed
```

No failing state becomes zero.

## 11. Cube / TBDS and output boundary

This plan does not add a cube currency axis or TBDS currency partition.

Selected arithmetic consequence:

```text
one proven domain + one amount_scale
  -> normalized scalar deltas remain addable
  -> cube / TBDS may keep numeric reduction shape
```

But:

```text
raw normalized coefficient
  != human monetary amount text
```

Therefore current raw `•Fmt` rendering is not automatically ILS-ready.

Before a user-facing surface claims ILS monetary amounts, it must either:

```text
format coefficient using amount_scale and domain
```

or explicitly remain unsupported for ILS.

Machine output must not silently emit a normalized coefficient as though it were the original amount.

This plan does not select a repository-wide JSON migration.

## 12. Account currency boundary

Preserve:

```text
account currency
  != source amount currency authority
  != arithmetic domain proof
```

Do not infer the ILS proof from account metadata or AccountKey suffixes.

A later all-ILS fixture should nevertheless use coherent ILS-denominated fixture accounts for the accounts it exercises, so TBDS/account labels do not misleadingly describe the fixture as JPY.

Cross-currency account settlement remains out of scope.

## 13. Staged runtime path

Completion of one slice does not automatically authorize the next.

### Slice A: exact-decimal kernel

```text
pure BQN parser
canonical coefficient + scale
exactness/range failure boundary
focused unit tests
```

No `currency=ILS` projection admission.

### Slice B: snapshot arithmetic evidence

```text
row currency resolver
exact decimal row parse
exactly-one-domain proof
amount_scale selection
normalized coefficients
proof carrier extension
focused fixture evidence
```

ILS projection authorization may remain closed until the next slice.

### Slice C: checked ILS posting path

```text
projection authorizes proven ILS
normalized signed integer deltas
same-snapshot invariant
all-ILS fixture through BuildContext / cube / TBDS evidence
legacy JPY scale-0 regression
```

This still does not imply every report or JSON surface is ILS-ready.

Daily-use schema/editor/output admission remains a later consumer-driven slice.

## 14. Planned executable evidence

### Slice A parser cases

Valid:

```text
1200
42.50
0.05
00042.50
0.000
```

Invalid:

```text
empty
+1
-1
.5
5.
1e3
1,000
1.2.3
```

Assert canonical coefficient + scale or visible failure.

Also include an implementation-owned exact-range boundary case.

### Later domain cases

```text
legacy integer JPY
empty source
explicit JPY single domain
all-ILS exact decimal
missing + ILS mixed
JPY + ILS mixed
unknown explicit currency
duplicate currency metadata
same-snapshot mutation property
cube / TBDS normalized exact total
```

These later cases are planned, not authorized by Slice A.

## 15. Preferred ownership

```text
src_next/exact_decimal.bqn
  -> exact decimal grammar
  -> canonical coefficient + scale
  -> exactness/range diagnostic
```

```text
src_next/context.bqn
  -> one posting-source snapshot
  -> row currency resolution orchestration
  -> snapshot arithmetic evidence
  -> proof carrier
```

```text
src_next/projection.bqn
  -> proof authorization
  -> normalized signed delta admission
```

```text
src_next/cube.bqn / src_next/tbds.bqn
  -> no new currency or scale ownership
```

Do not make cube or TBDS infer currency or scale.

## 16. Explicit non-goals

This planning PR does not authorize:

- runtime BQN changes;
- tests or checks;
- fixtures;
- source TSV changes;
- real or sample data changes;
- metadata schema changes;
- editor changes;
- report formatting changes;
- JSON schema changes;
- Posting IR field additions;
- cube or TBDS axis changes;
- per-row mixed-currency operation;
- currency partitions;
- `BASE_CURRENCY`;
- `base_amount=`;
- FX rates;
- conversion;
- valuation;
- live APIs;
- broad ISO currency registry;
- automatic source migration;
- account-currency-derived proof.

## 17. Exact next authorized runtime slice

After this plan is merged, the next finite runtime slice is only:

```text
Currency Stage 2 Slice A: exact-decimal kernel
```

Implement a pure BQN helper that:

1. accepts only the selected unsigned finite-decimal grammar;
2. returns canonical coefficient + scale without parsing decimal source text as a generic decimal Number;
3. canonicalizes leading zeros and trailing fractional zeros without changing quantity;
4. rejects invalid syntax visibly;
5. fails closed when coefficient conversion cannot remain exact;
6. includes focused tests for valid, invalid, canonicalization, and exact-range cases;
7. does not yet admit `currency=ILS` into projection;
8. does not change source TSV, metadata schema, editor, cube, TBDS, report, or JSON behavior.

This creates the exact amount kernel required before explicit ILS proof can safely reach arithmetic.

## 18. Closure of this planning slice

```text
source parse carrier
  -> coefficient + scale

single-domain arithmetic carrier
  -> snapshot-wide amount_scale + normalized integer coefficients

proof carrier
  -> arithmetic_currency_proof gains amount_scale in later slice

first explicit domains
  -> JPY / ILS

mixed JPY + ILS
  -> fail closed

missing + ILS
  -> fail closed as mixed

unknown / duplicate currency metadata
  -> fail closed

legacy integer JPY
  -> scale-0 compatibility requirement

cube / TBDS
  -> keep scalar aggregation shape; no currency/scale ownership

broad daily-use ILS claim
  -> not yet authorized

next runtime slice
  -> pure exact-decimal kernel only
```
