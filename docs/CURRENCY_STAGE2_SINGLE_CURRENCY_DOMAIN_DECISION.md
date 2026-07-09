# Currency Stage 2 Single-Currency Domain Decision

Status: current contract / docs-only decision record
Owner: config
Canonical: yes
Decision date: 2026-07-09
Depends on: `docs/CURRENCY_AWARENESS_CAMPAIGN_MAP.md`, `docs/CURRENT_CURRENCY_ASSUMPTION_MAP.md`, `docs/CURRENCY_STAGE1_AMOUNT_SEMANTICS_DECISION.md`, `docs/POSTING_IR_CONTRACT.md`, `docs/CURRENCY_STAGE2_BUILDPERIODVIEW_DOWNSTREAM_BOUNDARY_DECISION.md`
Exit: supersede when a later current currency contract replaces the single-currency domain proof, carrier, enforcement-gate semantics, and downstream trusted-precondition boundary

This PR selects the Stage 2 domain-proof architecture only. Current runtime remains unchanged.

## 1. Question

Where and how is one arithmetic currency domain proven, carried, and enforced before projection and aggregation create or consume naked Posting IR deltas?

This is a product / architecture semantics decision. It does not implement currency support, row currency parsing, FX, conversion, currency axes, or runtime enforcement.

## 2. Selected architecture

Selected Stage 2 chain:

```text
source currency resolution
  -> prove exactly one arithmetic currency domain
  -> carry proven domain in run context
  -> enforce proof before naked Posting IR delta creation
  -> downstream cube / TBDS / reports consume posting rows under the trusted post-gate caller contract
```

The candidate locations are not interchangeable alternatives. They have distinct responsibilities:

```text
source compatibility resolution
  = proof input / evidence

run context
  = resolved runtime carrier

projection boundary
  = enforcement gate

ledger config
  = may later constrain or declare expected policy,
    but is not sufficient proof by itself
```

Preserve:

```text
proof source != runtime carrier
runtime carrier != enforcement gate
declared policy != proven arithmetic compatibility
```

## 3. Arithmetic currency domain meaning

Selected meaning:

```text
arithmetic currency domain
=
one resolved monetary currency identity
within which naked deltas are authorized to be added
for the current run/domain
```

Examples:

```text
proven domain = JPY
  -> JPY-domain naked delta arithmetic may proceed

proven domain = ILS
  -> ILS-domain naked delta arithmetic may proceed

resolved currencies = JPY + ILS
  -> not a single-currency domain
  -> naked delta arithmetic not authorized

unresolved / unknown explicit currency
  -> fail closed
```

The domain is a condition for arithmetic authorization. It is not a conversion target.

Preserve:

```text
arithmetic domain currency
!= source row currency identity
!= account currency
!= display currency
!= reporting currency
!= base currency
!= valuation currency
```

Also preserve:

```text
currency label != arithmetic addability
naked delta != universally addable monetary value
```

## 4. Proof source

Selected proof input:

```text
single-currency proof input
=
resolved source-row currency identities
under the Stage 1 compatibility semantics
```

Stage 1 meanings used as inputs:

```text
missing source currency
  -> legacy compatibility JPY resolution

known explicit currency
  -> explicit source currency identity

unknown explicit currency
  -> invalid / fail closed
```

Conceptual proof rule:

```text
resolved source currencies contain exactly one distinct known currency
  -> single-currency proof succeeds

resolved source currencies contain more than one known currency
  -> mixed domain
  -> proof fails

any explicit unknown currency
  -> proof fails closed
```

Current runtime fact: the runtime does not yet implement explicit row currency metadata. This decision defines the proof model only.

## 5. Missing / explicit / unknown resolution

Selected resolution meanings:

```text
missing source currency
  -> compatibility JPY resolution
  -> not explicit JPY evidence

explicit known currency
  -> explicit source currency identity

explicit unknown currency
  -> invalid / fail closed
```

This preserves Stage 1:

```text
missing currency != explicit JPY
missing currency != unknown explicit currency
```

The proof source is resolved source-row currency identity, not account denomination, display formatting, or a declared base/reporting currency.

## 6. Empty-source compatibility case

Selected current compatibility behavior:

```text
no monetary source rows
  -> legacy compatibility JPY arithmetic domain
     for current existing operation
```

This is a compatibility resolution. It is not observed row evidence.

Preserve:

```text
empty source set
!= explicit JPY evidence
```

The purpose is to avoid making an empty current ledger unusable while preserving the distinction between compatibility fallback and explicit identity.

## 7. Run context carrier

Selected runtime-carrier role:

```text
resolved run context
=
runtime carrier of the proven arithmetic currency domain
```

Conceptual shape:

```text
ctx.arithmetic_currency_domain = JPY
```

or:

```text
ctx.arithmetic_currency_domain = ILS
```

The exact runtime field name is not implemented in this PR. The context carrier must represent a proof result, not an independent guess.

Preserve:

```text
run context carries domain
!= run context invents domain
run context carrier != proof source
```

Do not simply hardcode:

```text
ctx.currency = JPY
```

and call that proof.

## 8. Projection enforcement gate

Selected enforcement gate:

```text
single-currency proof must succeed
before projection creates naked Posting IR delta rows
```

Current projection conceptually performs:

```text
one source amount
  -> debit +amount
  -> credit -amount
```

The Stage 2 contract must not allow:

```text
create naked deltas first
then attach a currency-domain label afterward
```

Selected ordering:

```text
resolve source currency evidence
  -> prove one domain
  -> carry proof into run context / projection invocation
  -> only then authorize naked delta construction
```

Preserve:

```text
projection gate != semantic owner
post-hoc label != pre-arithmetic proof
```

Current runtime fact: this gate is not implemented in this PR.

## 9. Account currency non-authority

Stage 1 remains preserved:

```text
account currency != source amount authority
```

Stage 2 additionally selects:

```text
account currency != arithmetic domain proof
```

Examples such as:

```text
assets:bank/JPY
assets:usd_cash/USD
```

must not automatically establish:

```text
domain = JPY
```

or:

```text
domain = USD
```

and must not authorize mixed arithmetic.

Account denomination metadata may later participate in compatibility validation, but it is not the Stage 2 proof owner. This decision does not redesign AccountKey and does not change current AccountKey runtime behavior.

## 10. Ledger config role

Ledger config is not selected as sufficient proof by itself.

Selected rule:

```text
ledger config may later:
- declare expected domain
- constrain allowed domain
- provide explicit policy input

but:

declared currency
!= proven compatibility of admitted source rows
```

For example, a future declaration conceptually saying:

```text
expected arithmetic domain = JPY
```

must not make an explicit ILS source row safe to add as JPY.

This decision does not introduce `BASE_CURRENCY`. This Stage 2 domain is not a reporting, valuation, or conversion base currency. No exact config key is selected here.

## 11. Downstream aggregation rule

Selected downstream rule:

```text
cube / TBDS / ViewModels / reports
do not independently infer arithmetic currency domain
```

They consume posting rows under the trusted post-gate caller contract selected in `docs/CURRENCY_STAGE2_BUILDPERIODVIEW_DOWNSTREAM_BOUNDARY_DECISION.md`.

The executable Stage 2 claim is scoped to the normal checked path:

```text
normal checked BuildContext path
-> proof resolution
-> projection-owned authorization
-> authorized posting rows
-> BuildPeriodView
```

This does not claim that arbitrary direct invocation of exported `BuildPeriodView` is mechanically proof-gated.

Preserve:

```text
downstream aggregation
!= currency inference
trusted precondition
!= mechanically enforced boundary
```

Current runtime fact: `BuildPeriodView` itself remains a proof-free downstream consumer; the projection boundary is the arithmetic authorization gate before naked delta construction.

## 12. Failure states

Selected classification:

| State | Stage 2 classification |
|---|---|
| exactly one resolved currency | proven single-currency domain |
| more than one resolved currency | mixed domain / fail closed for naked-delta arithmetic |
| unknown explicit currency | invalid / fail closed |
| unresolved proof state | fail closed |
| no monetary rows | legacy compatibility JPY domain for current existing operation; not explicit JPY evidence |

No FX behavior is defined. Mixed domains are not converted.

## 13. Current runtime vs selected future contract

Current runtime fact:

```text
BuildContext
  -> resolve accounts
  -> BuildAllRows
  -> projection.MakeRow
  -> naked deltas
  -> BuildPeriodView
  -> cube / TBDS
```

Observed current ordering:

1. `BuildContext` reads `cycle.tsv` and `accounts.tsv`.
2. `account_key.Resolve` resolves accounts and AccountKey strings, including current account-level currency defaulting.
3. `BuildAllRows` reads `journal.tsv`, optional `plan.tsv`, and optional `budget_alloc.tsv`.
4. `BuildRowsForFile*` calls `projection.MakeRow` for each admitted source row.
5. `projection.MakeRow` parses the naked source `amount` integer and creates debit / credit posting rows with signed naked `delta`.
6. `BuildPeriodView` passes rows to cube materialization and TBDS construction.

Selected Stage 2 semantic contract: a future implementation cannot establish the single-currency proof only after `BuildAllRows`, because `BuildAllRows` already enters the posting-row construction path that creates naked deltas.

Future implementation consequence: the proof must be available before the posting-row construction path is authorized to create naked deltas. This may require a pre-`BuildAllRows` resolution/proof step and an explicit context/projection invocation carrier, but this PR does not modify `src_next/context.bqn` or `src_next/projection.bqn`.

Still-unresolved later question: the exact runtime field name, function shape, and minimal compatibility implementation plan remain separate decisions.

## 14. Consequences for next implementation slice

Smallest justified next finite slice:

```text
Currency Awareness Stage 2 minimal domain-proof implementation plan
```

Next finite question:

```text
What is the smallest runtime slice that resolves the current JPY compatibility domain before BuildAllRows / projection, carries the proof in context, and fails closed without introducing per-row multi-currency support?
```

That next slice should plan, but not automatically implement:

- how to resolve the current compatibility domain before naked delta construction;
- how to carry the proven domain in context without inventing it there;
- where projection receives proof authorization;
- how unresolved or incompatible proof states fail closed;
- how `journal.tsv`, `plan.tsv`, and `budget_alloc.tsv` evidence are covered together.

## 15. Non-goals

This decision does not implement or authorize:

- runtime BQN changes;
- shell behavior changes;
- tests, checks, or fixture changes;
- source TSV changes;
- real source TSV edits;
- sample source TSV edits;
- `currency=` runtime parsing;
- decimal parser;
- rounding or scale validation;
- Posting IR runtime shape changes;
- BuildContext runtime shape changes;
- projection argument changes;
- cube / TBDS / ViewModel / JSON changes;
- editor changes;
- metadata schema changes;
- AccountKey runtime behavior changes;
- `BASE_CURRENCY`;
- `base_amount`;
- FX;
- automatic conversion;
- currency axis;
- per-row mixed-currency support.

## 16. Exit / supersession conditions

This decision remains current until superseded by a later current currency contract that explicitly covers:

- proof input and compatibility resolution;
- runtime carrier shape;
- projection enforcement gate;
- failure states;
- empty-source compatibility behavior;
- account-currency non-authority;
- ledger config policy role;
- downstream aggregation responsibility;
- whether naked Posting IR deltas remain valid or are replaced by a richer value shape.

Any superseding decision must preserve or explicitly replace these guards:

```text
source row currency != arithmetic domain currency
account currency != arithmetic domain proof
account currency != source amount authority
declared policy != proven compatibility
run context carrier != proof source
projection gate != semantic owner
post-hoc label != pre-arithmetic proof
arithmetic domain currency != reporting/base currency
currency label != arithmetic addability
naked delta != universally addable monetary value
```
