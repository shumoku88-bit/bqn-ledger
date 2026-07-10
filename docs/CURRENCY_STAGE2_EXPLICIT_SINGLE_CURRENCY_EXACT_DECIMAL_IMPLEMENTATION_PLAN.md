# Currency Stage 2 Explicit Single-Currency Exact-Decimal Implementation Plan

Status: active implementation plan / docs-only
Owner: config
Canonical: yes
Decision date: 2026-07-10
Depends on: `docs/CURRENCY_STAGE1_AMOUNT_SEMANTICS_DECISION.md`, `docs/CURRENCY_STAGE2_SINGLE_CURRENCY_DOMAIN_DECISION.md`, `docs/CURRENCY_STAGE2_MINIMAL_DOMAIN_PROOF_IMPLEMENTATION_PLAN.md`, `docs/CURRENCY_STAGE2_BUILDPERIODVIEW_DOWNSTREAM_BOUNDARY_DECISION.md`, `docs/CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_ADMISSION_DECISION.md`, `docs/POSTING_IR_CONTRACT.md`
Exit: archive or supersede after the selected staged runtime path either reaches honest all-ILS exact-decimal operation or a later current contract replaces its exact-decimal carrier, normalization scale, proof shape, or output-readiness boundary

This document plans the smallest staged runtime path from the current JPY-only integer projection implementation to an honest all-ILS single-currency domain that can preserve an exact source amount such as:

```text
42.50 currency=ILS
```

This PR is docs-only. It does not implement runtime, tests, checks, fixtures, source TSV, metadata schema, editor, report, JSON, Posting IR, cube, or TBDS changes.

## 1. Current implementation evidence

The current runtime is narrower than the selected Stage 1 and explicit-admission semantics.

### 1.1 Amount path

Current `src_next/context.bqn`:

```text
amountText
  -> projection.IsIntegerText
  -> •BQN amountText
  -> scalar Number amount
  -> debit delta = amount
  -> credit delta = -amount
```

Therefore:

```text
42.50
  -> invalid_amount
```

The current source-to-projection path is integer-only.

### 1.2 Currency proof path

Current `ResolveArithmeticCurrencyProof`:

```text
any explicit currency= token
  -> unsupported
```

Current projection authorization:

```text
proof.state = proven
proof.domain = JPY
proof.basis in {
  legacy_compatibility,
  empty_source_compatibility
}
```

Only then is projection authorized.

### 1.3 Aggregation path

Current cube and TBDS consumers assume each posting row carries one addable scalar `delta` and use ordinary numeric reduction:

```text
+´ deltas
```

and related array sums.

This scalar shape is valuable. Replacing every cube / TBDS cell with a decimal namespace pair in the first non-JPY slice would broaden the change surface substantially.

## 2. Selected exact-decimal representation

This plan selects a two-boundary representation:

```text
source parse boundary
  -> canonical exact-decimal pair

arithmetic boundary for one proven snapshot
  -> snapshot-scale normalized integer coefficient
```

### 2.1 Parsed exact-decimal pair

Selected conceptual parse result:

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
exact monetary quantity
  = coefficient × 10^(-scale)
```

Examples after canonicalization:

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

Trailing fractional zeros are removed for arithmetic canonicalization because Stage 1 selects an exact decimal monetary quantity, not lexical display precision.

Preserve:

```text
source amount quantity != source text spelling
source amount quantity != display precision
```

The original source text remains available for diagnostics where needed.

### 2.2 Selected source grammar

The first exact-decimal parser accepts only:

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

The first parser rejects:

```text
+42.50
-42.50
.50
42.
1e3
1E3
1,200
42 50
empty
```

Rationale:

- current journal direction is expressed by `from` / `to`, not by a signed amount field;
- exponent and locale syntax are not needed for the concrete ILS consumer;
- a deliberately small grammar reduces ambiguous parsing and silent normalization.

No automatic rounding is selected.

### 2.3 Do not parse a decimal literal through the current generic numeric path

The first implementation must not treat this as sufficient:

```text
•BQN "42.50"
```

The parser must separate decimal text into digit-only coefficient information and scale before arithmetic admission.

This plan does not claim any host/runtime decimal literal representation is exact.

## 3. Selected arithmetic carrier

After all admitted posting-source rows in one shared snapshot have valid exact-decimal parse results, select one snapshot-wide arithmetic scale:

```text
amount_scale
  = maximum canonical row scale
    across all admitted monetary source rows
```

Empty source:

```text
amount_scale = 0
```

For each parsed amount:

```text
normalized_coefficient
  = coefficient × 10^(amount_scale - row.scale)
```

Examples:

```text
source rows:
  42.50 -> canonical 425 × 10^-1
  0.05  -> canonical   5 × 10^-2
  18    -> canonical  18 × 10^0

snapshot amount_scale = 2

normalized coefficients:
  4250
     5
  1800
```

Selected Posting IR direction:

```text
delta
  = signed normalized integer coefficient
    inside one proven arithmetic currency domain
    at one carried amount_scale
```

Therefore current scalar aggregation shape can remain structurally usable:

```text
cube / TBDS
  -> continue summing scalar integer coefficients
```

while monetary meaning is carried by the proven run context:

```text
currency domain + amount_scale
```

## 4. Why snapshot-wide scale is selected

This plan does not select:

```text
A. decimal pair namespace in every cube cell
B. implicit binary floating-point amount
C. per-currency hardcoded minor-unit scale as source truth
D. automatic rounding to a fixed scale
```

Selected reason for snapshot-wide scale:

- preserves exact finite-decimal quantities by power-of-ten normalization;
- keeps one addable scalar delta shape for array aggregation;
- preserves current JPY integer fixtures as `amount_scale = 0`;
- does not make display precision the authority for source amount meaning;
- does not require FX or mixed-currency partitions;
- avoids introducing a broad currency registry merely to prove the first ILS path.

Important consequence:

```text
amount_scale
  != currency identity
  != display precision
  != exchange rate
  != valuation policy
```

It is an arithmetic-unit carrier for one loaded posting-source snapshot.

## 5. Exactness and representable-range boundary

The implementation must fail closed if either:

```text
parsed coefficient
```

or:

```text
normalized coefficient
```

cannot be represented exactly by the selected runtime integer path.

Selected diagnostic class:

```text
amount_out_of_exact_range
```

or a repository-native equivalent with the same meaning.

The implementation must not silently continue after numeric rounding or overflow.

This plan does not hardcode an unverified numeric limit. The first runtime implementation must add executable boundary evidence for its exact-integer conversion and normalization path.

Preserve:

```text
syntactically valid decimal
  != exactly representable normalized runtime coefficient
```

## 6. Selected row currency resolver

For every admitted monetary source row from:

```text
journal.tsv
plan.tsv
budget_alloc.tsv
```

inspect only metadata tokens after the protected first five fields.

Selected resolver:

```text
no currency= token
  -> row currency identity = JPY
  -> evidence kind = legacy_compatibility

exactly one currency=JPY
  -> row currency identity = JPY
  -> evidence kind = explicit

exactly one currency=ILS
  -> row currency identity = ILS
  -> evidence kind = explicit

exactly one other currency=<value>
  -> invalid / unsupported explicit currency
  -> fail closed

more than one currency= token
  -> invalid duplicate currency metadata
  -> fail closed
```

Duplicate tokens fail closed even when values are identical.

Do not use first-wins or last-wins behavior.

## 7. Selected snapshot proof algorithm

Proof input remains the exact same in-memory snapshot later used for amount normalization and posting-row construction.

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
  -> select snapshot amount_scale
  -> exact-normalize every row coefficient
  -> build proof
  -> projection-owned authorization
  -> build posting rows from the same snapshot-derived row evidence
```

Do not re-read source TSV between proof and projection.

Preserve:

```text
proof input snapshot
  = amount normalization input snapshot
  = projection input snapshot
```

## 8. Selected proof shape extension

Current carrier:

```text
ctx.arithmetic_currency_proof = {
  state,
  domain,
  basis,
  message
}
```

Selected extension:

```text
ctx.arithmetic_currency_proof = {
  state,
  domain,
  basis,
  amount_scale,
  message
}
```

Do not add a second independent truth such as:

```text
ctx.amount_scale
```

unless a concrete consumer later requires a separately owned carrier.

The proof carrier remains the single current arithmetic-domain context.

### 8.1 Selected proof basis vocabulary

Retain:

```text
empty_source_compatibility
legacy_compatibility
```

Add one narrow basis:

```text
resolved_single_currency
```

Selected meaning:

```text
empty_source_compatibility
  -> no admitted monetary rows
  -> domain = JPY
  -> amount_scale = 0

legacy_compatibility
  -> all admitted rows lack explicit currency metadata
  -> all resolve through compatibility JPY

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

The basis records proof evidence meaning. It does not duplicate the domain.

## 9. Selected projection authorization rule

Future authorization after the staged implementation reaches ILS admission:

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

Projection must not normalize amounts independently from proof resolution.

Preferred evidence shape:

```text
ResolvePostingArithmeticEvidence snapshot
  -> {
       proof,
       admitted_rows_with_parsed_amounts,
       normalized_coefficients
     }
```

or an equivalent focused shape that makes it impossible for proof, scale selection, and projection to use different row snapshots.

Exact function names remain implementation details.

## 10. JPY compatibility boundary

Existing JPY source data must remain behaviorally compatible.

For current data shaped as:

```text
all rows missing currency=
all amounts integer text
```

expected:

```text
proof.domain = JPY
proof.basis = legacy_compatibility
proof.amount_scale = 0
normalized coefficient = existing integer amount
posting delta = existing delta
cube / TBDS numeric values unchanged
```

This is the strongest compatibility requirement of the plan.

The first ILS work must not require rewriting historical JPY rows with explicit `currency=JPY`.

## 11. ILS target boundary

The first honest non-JPY target is:

```text
all admitted monetary source rows resolve to ILS
```

Example:

```text
42.50 currency=ILS
18     currency=ILS
0.05   currency=ILS
```

Expected arithmetic evidence:

```text
proof.state = proven
proof.domain = ILS
proof.basis = resolved_single_currency
proof.amount_scale = 2
```

Expected normalized amounts:

```text
42.50 -> 4250
18    -> 1800
0.05  -> 5
```

Expected exact sum meaning:

```text
4250 + 1800 + 5
  = 6055 at scale 2
  = 60.55 ILS
```

No FX conversion is involved.

## 12. Mixed and invalid boundaries

Selected fail-closed cases:

```text
missing + explicit ILS
  -> resolved JPY + ILS
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
  -> unsupported explicit currency in first admitted set
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

```text
valid decimal text whose normalized coefficient is not exactly representable
  -> amount_out_of_exact_range
  -> fail closed
```

No failing state becomes zero.

## 13. Account currency boundary

Account-level currency remains separate:

```text
account currency
  != source amount currency authority
  != arithmetic domain proof
```

Do not infer the ILS proof from account metadata or AccountKey suffixes.

However, an end-to-end ILS fixture should use explicitly ILS-denominated fixture accounts for the accounts it exercises, so TBDS/account labels do not misleadingly describe an ILS arithmetic fixture as JPY.

This is fixture coherence, not proof ownership.

Cross-currency account settlement remains out of scope.

## 14. Cube and TBDS consequence

This plan does not select a new cube axis or TBDS currency partition.

Selected arithmetic consequence:

```text
within one proven domain and one amount_scale
  -> normalized scalar deltas remain addable
  -> cube / TBDS reductions may remain structurally numeric
```

But preserve:

```text
raw normalized coefficient
  != human monetary amount text
```

Therefore current raw `•Fmt` amount rendering is not automatically ILS-ready.

## 15. Human and machine output readiness boundary

The runtime must not claim complete daily-use ILS support merely because BuildContext can aggregate normalized coefficients.

Before a user-facing report surface claims ILS monetary amounts, it must either:

```text
format normalized coefficient using proof.amount_scale and proof.domain
```

or explicitly remain unsupported for ILS.

Selected shared conceptual formatter:

```text
FormatExactAmount ⟨coefficient, scale⟩
  -> canonical exact decimal text
```

Examples:

```text
⟨4250, 2⟩ -> 42.50 or a separately selected presentation form
⟨5, 2⟩    -> 0.05
```

Presentation trailing-zero policy remains separate from arithmetic canonicalization.

### 15.1 Machine output

Do not silently emit a normalized coefficient as though it were the original monetary amount.

For JSON or other structured consumers, a later surface decision must choose one explicit shape, for example:

```text
amount_text
currency
```

or:

```text
coefficient
scale
currency
```

This plan does not select a repository-wide JSON migration.

Until a concrete structured consumer is updated, ILS support claims must remain scoped to the checked engine surface actually carrying scale.

## 16. Metadata schema and editor ordering

Current `config/meta_schema.tsv` does not operationally register source-row `currency=`.

Selected ordering:

```text
1. exact-decimal kernel
2. fixture-only row currency resolver / proof evidence
3. normalized posting-row path with focused ILS fixture evidence
4. only then metadata-schema admission for JPY|ILS
5. editor input support only after the parser and schema contract exist
6. real source TSV remains human-controlled and is not migrated automatically
```

Do not add `currency=` to schema first and thereby create an appearance of runtime support.

Do not loosen amount validation in the editor before the exact parser contract exists.

## 17. Planned staged runtime slices

The path is deliberately staged. Completion of one slice does not automatically authorize the next unless TODO routing is updated.

### Slice A: exact-decimal kernel

Scope:

```text
pure BQN exact-decimal text parser
canonical coefficient + scale result
exactness/range failure boundary
unit tests
```

No source-row `currency=` admission.

No projection authorization change.

No fixture source change required beyond test-local parser cases.

### Slice B: row currency resolution + snapshot arithmetic evidence

Scope:

```text
resolve missing / JPY / ILS / unknown / duplicate
parse admitted row amounts
prove exactly one resolved domain
select amount_scale
normalize coefficients
carry proof amount_scale
focused fixture/test evidence
```

Projection ILS authorization may remain closed until Slice C if needed to prevent partial downstream support.

### Slice C: checked ILS posting path

Scope:

```text
projection authorizes proven ILS domain
posting rows use normalized signed integer coefficients
same-snapshot invariant preserved
all-ILS exact-decimal fixture reaches BuildContext / cube / TBDS arithmetic evidence
legacy JPY scale-0 behavior remains unchanged
```

This slice must not claim all report / JSON surfaces are ILS-ready.

### Slice D: daily-use admission boundary

Only after concrete consumer review:

```text
metadata schema admission
editor input path
required human formatting
required structured output contract
```

This is the earliest point at which broad daily-use ILS support may be claimed.

Do not auto-start Stage 3 mixed-currency work.

## 18. Planned executable evidence matrix

### 18.1 Parser valid cases

```text
1200
42.50
0.05
00042.50
0.000
```

Assert exact canonical coefficient and scale.

### 18.2 Parser invalid cases

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

Assert visible failure, not zero.

### 18.3 Exact-range failure

Use an implementation-owned boundary case that proves a syntactically valid decimal is rejected if coefficient conversion or scale normalization cannot remain exact.

Do not rely only on happy-path monetary sizes.

### 18.4 Legacy JPY compatibility

Existing fixture with integer amounts and no explicit currency:

```text
domain = JPY
basis = legacy_compatibility
amount_scale = 0
existing deltas unchanged
existing golden output unchanged
```

### 18.5 Empty source

```text
domain = JPY
basis = empty_source_compatibility
amount_scale = 0
```

### 18.6 Explicit JPY single domain

All rows resolve to JPY, with at least one explicit `currency=JPY`:

```text
domain = JPY
basis = resolved_single_currency
```

First implementation may retain integer-only JPY admission if needed for compatibility containment; any such narrower boundary must be explicit and tested.

### 18.7 All-ILS exact decimal

Fixture-local source rows:

```text
42.50 currency=ILS
18     currency=ILS
0.05   currency=ILS
```

Assert:

```text
domain = ILS
basis = resolved_single_currency
amount_scale = 2
normalized coefficients = 4250, 1800, 5
exact aggregate meaning = 60.55 ILS
```

### 18.8 Missing + ILS

Assert mixed-domain fail closed before posting-row construction.

### 18.9 JPY + ILS

Assert mixed-domain fail closed before posting-row construction.

### 18.10 Unknown explicit currency

Assert fail closed.

### 18.11 Duplicate currency metadata

Cover both:

```text
currency=ILS currency=ILS
currency=JPY currency=ILS
```

Assert fail closed.

### 18.12 Same-snapshot property

Preserve existing Stage 2 property:

```text
load snapshot
mutate backing temporary fixture
resolve / normalize / project loaded snapshot
```

Assert no re-read changes proof, amount scale, or projected coefficients.

### 18.13 Cube / TBDS scaled-integer arithmetic

For one all-ILS fixture, assert exact normalized totals through:

```text
posting rows
cube
TBDS
```

and interpret totals only with the carried amount scale.

## 19. Likely runtime owners

Preferred ownership:

```text
src_next/exact_decimal.bqn
  -> exact decimal grammar
  -> canonical coefficient + scale
  -> normalization helper
  -> exactness/range diagnostics
```

or an equivalently focused module.

```text
src_next/context.bqn
  -> one posting-source snapshot
  -> row currency resolution orchestration
  -> snapshot arithmetic evidence
  -> proof carrier construction
```

```text
src_next/projection.bqn
  -> proof authorization
  -> normalized signed delta admission
```

```text
src_next/cube.bqn / src_next/tbds.bqn
  -> no new currency ownership
  -> continue arithmetic only on already authorized normalized scalars
```

Do not make cube or TBDS infer currency or scale.

## 20. Explicit non-goals

This plan does not authorize in this PR:

- runtime BQN changes;
- tests or checks;
- fixtures;
- source TSV changes;
- real data changes;
- sample data changes;
- metadata schema changes;
- editor changes;
- report formatting changes;
- JSON schema changes;
- Posting IR field additions;
- cube axis changes;
- TBDS axis changes;
- per-row mixed-currency operation;
- currency partitions;
- `BASE_CURRENCY`;
- `base_amount=`;
- FX rates;
- conversion;
- valuation semantics;
- live APIs;
- broad ISO currency registry;
- automatic source migration;
- account-currency-derived proof.

## 21. Exact next authorized runtime slice

After this plan is merged, the next finite runtime slice is only:

```text
Currency Stage 2 Slice A: exact-decimal kernel
```

Implement a pure BQN exact-decimal helper that:

1. accepts only the selected unsigned finite-decimal grammar;
2. returns canonical coefficient + scale without parsing the decimal text as a generic decimal Number;
3. canonicalizes leading zeros and trailing fractional zeros without changing quantity;
4. rejects invalid syntax visibly;
5. fails closed when the selected integer conversion / normalization path cannot remain exact;
6. includes focused unit tests for valid, invalid, canonicalization, and exact-range cases;
7. does not yet admit `currency=ILS` into projection;
8. does not change source TSV, metadata schema, editor, cube, TBDS, report, or JSON behavior.

This slice is intentionally smaller than full ILS admission.

It creates the exact amount kernel required before explicit ILS proof can safely reach arithmetic.

## 22. Closure of this planning slice

```text
source exact decimal parse representation
  -> selected: coefficient + scale

single-domain arithmetic carrier
  -> selected: snapshot-wide amount_scale + normalized integer coefficients

proof carrier
  -> selected: extend arithmetic_currency_proof with amount_scale

explicit domains
  -> selected first admitted set: JPY / ILS

mixed JPY + ILS
  -> fail closed

missing + ILS
  -> fail closed as mixed

unknown / duplicate currency metadata
  -> fail closed

legacy JPY integers
  -> scale 0 compatibility requirement

cube / TBDS
  -> keep scalar aggregation shape; do not infer currency/scale

full ILS daily-use claim
  -> not yet authorized

next runtime slice
  -> pure exact-decimal kernel only
```
