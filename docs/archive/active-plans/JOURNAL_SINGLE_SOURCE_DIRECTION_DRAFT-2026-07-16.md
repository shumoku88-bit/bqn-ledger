# Household journal direction draft

Status: parked design exploration / docs-only / no runtime authorization
Date: 2026-07-17
Owner: architecture discussion
Exit: revise, reject, or later promote one finite characterization slice through `TODO.md`

## Purpose

Explore a future durable household source written in a human-readable hledger-compatible journal form.

The journal-format direction is now the stable design preference under discussion. The implementation language, parser, writer, runtime owner, migration path, and production source-of-truth transition remain deliberately unselected.

This document is background design evidence only. It does not authorize implementation.

## Decisions reached so far

1. Prefer journal-form durable records over the current horizontal TSV row form.
2. Do not equate one conceptual journal with one physical file.
3. Keep transaction postings as the authoritative accounting skeleton.
4. Enrich transactions with optional household-event coordinates inspired by the 6D idea.
5. Do not use a pure six-column 6D event row as the sole accounting source.
6. Initially model four journal families:
   - declarations
   - actual transactions
   - concrete planned transactions
   - budget allocation transactions
7. Keep cycle view configuration, report configuration, issue tracking, and development decisions outside the initial household journal.
8. Keep implementation-language choice outside this draft.
9. Select no next finite program slice yet.

## Current baseline

Current `main` intentionally uses separate TSV sources:

- `accounts.tsv`
- `journal.tsv`
- `plan.tsv`
- `budget_alloc.tsv`
- `cycle.tsv`
- `issues.tsv`

The current transaction-like TSV contract is a two-account row:

```text
date | memo | from | to | amount | metadata...
```

That form is compact and machine-friendly, but it compresses one household event into a long horizontal record and makes multi-posting transactions awkward.

This draft explores a different source shape. It does not modify the current contract.

## Core idea: one event block, two readings

A household journal transaction has two related parts:

```text
upper part: what happened in household life
lower part: how value moved between accounts
```

Example:

```journal
2026-07-17 * スーパー | 食材と日用品
    ; action: buy
    ; destination: 自宅
    ; receipt: receipt-2026-07-17-001
    expenses:食費          8000 JPY
    expenses:日用品        4000 JPY
    assets:ゆうちょ      -12000 JPY
```

The header and tags preserve household meaning. The postings preserve accounting meaning.

The same source block can therefore answer both:

```text
生活として: スーパーで食材と日用品を買い、自宅へ持ち帰った
会計として: 食費 8,000円、日用品 4,000円、ゆうちょ -12,000円
```

## Relationship to the 6D event idea

The original 6D idea was:

```text
when
where / with whom
what
where to
how much
what happened
```

A pure 6D row is attractive as a life record:

```text
2026-07-17 | スーパー | 食材 | 自宅 | 3820 JPY | 買った
```

However, it does not by itself identify:

- the payment account
- split expense categories
- liability creation or repayment
- principal versus interest
- transfers
- multiple commodities
- balanced multi-posting structure

Adding all of those fields turns the six-column form into an increasingly large custom event language.

The current draft therefore maps the 6D idea into a journal transaction rather than replacing postings with it.

### Candidate coordinate mapping

| 6D coordinate | Journal representation |
|---|---|
| when | transaction date |
| where / with whom | payee or first description segment |
| what | note or second description segment |
| where to | optional `destination:` tag |
| how much | authoritative posting amounts, not a duplicate metadata scalar |
| what happened | optional controlled `action:` tag |

Candidate description convention:

```text
payee | what
```

Example:

```journal
2026-07-17 * スーパー | 食材と日用品
```

The coordinates are not all mandatory. A normal transaction should contain only the metadata that adds durable meaning.

## One conceptual journal, several physical files

The preferred direction is multiple journal files assembled through small root journals.

Candidate layout:

```text
journal/
├── current.journal
├── outlook.journal
├── declarations.journal
├── actual/
│   └── 2026.journal
├── plans.journal
└── budget/
    └── 2026.journal
```

### Current-world entry point

```journal
include declarations.journal
include actual/2026.journal
include budget/2026.journal
```

`current.journal` represents completed household and budget events.

### Outlook entry point

```journal
include current.journal
include plans.journal
```

`outlook.journal` overlays concrete future plans on the current world.

This gives two deliberate readings:

```text
current.journal = completed actual and budget history
outlook.journal = current world plus concrete plans
```

The exact filenames and include topology remain candidates, not contracts.

## Initial journal families

### 1. Declarations

Current account and commodity declarations may become journal directives.

```journal
commodity JPY

account assets:ゆうちょ
    ; role: asset
    ; type: liquid

account expenses:食費
    ; role: expense
    ; budget: daily

account budget:unassigned
    ; role: budget
    ; kind: unassigned

account budget:daily
    ; role: budget
    ; kind: envelope
```

Declarations are the cast list, not chronological household history, so they should live separately from daily transactions.

### 2. Actual transactions

Actual transactions record completed household events.

```journal
2026-07-17 * スーパー | 食材
    ; action: buy
    ; txn-id: txn-2026-07-17-001
    expenses:食費          3820 JPY
    assets:ゆうちょ       -3820 JPY
```

Candidate rules:

- actual records use ordinary balanced transactions
- future-dated actuals remain invalid or fail-visible
- `txn-id` is optional unless a durable cross-reference requires it
- all posting amounts are explicit in the initial profile
- JPY remains integer-valued in household use

The status marker `*` retains its hledger meaning. It must not be treated as the sole representation of household `actual` semantics without an explicit design decision.

### 3. Concrete planned transactions

Plans use the same transaction and posting grammar as actuals.

```journal
2026-08-15 ! 大家 | 8月分家賃
    ; action: planned-payment
    ; layer: plan
    ; plan-id: plan-2026-08-15-rent
    ; series: rent
    ; recur: cycle
    expenses:家賃         64000 JPY
    assets:ゆうちょ      -64000 JPY
```

A completed plan is not deleted. Matching actual evidence carries the same `plan-id`.

```journal
2026-08-14 * 大家 | 8月分家賃
    ; action: paid
    ; layer: actual
    ; plan-id: plan-2026-08-15-rent
    expenses:家賃         64000 JPY
    assets:ゆうちょ      -64000 JPY
```

This preserves:

- early completion
- late completion
- planned versus actual amount differences
- non-destructive plan history
- exact plan-to-actual linkage

The first household journal profile should prefer concrete dated plans over periodic-transaction expansion. Recurrence metadata may describe or help generate the next concrete plan, but generated plan identity and completion must remain inspectable.

### 4. Budget allocation transactions

Budget allocation is represented as balanced movement within the budget namespace.

```journal
2026-08-15 自分 | 生活費をdailyへ配賦
    ; action: allocate
    ; layer: budget
    ; allocation-id: alloc-2026-08-daily
    budget:daily            50000 JPY
    budget:unassigned      -50000 JPY
```

This records a real household decision without pretending that bank assets moved.

Budget allocation history belongs in the journal direction. The mechanism for recording budget consumption remains open.

## Major open budget decision

There are two candidate ways to represent envelope consumption.

### A. Explicit budget postings in the actual transaction

```journal
2026-07-17 * スーパー | 食材
    ; action: buy
    expenses:食費           3820 JPY
    assets:ゆうちょ        -3820 JPY
    budget:spent             3820 JPY
    budget:daily            -3820 JPY
```

Advantages:

- the source block visibly contains the complete accounting and envelope effect
- no hidden category-to-envelope derivation is needed
- exceptional envelope choice can be represented transaction by transaction

Costs:

- ordinary purchases become heavier
- actual-money and budget-layer postings coexist in one transaction
- standard accounting views require clear namespace or layer filtering

### B. Derive budget consumption from account metadata

```journal
account expenses:食費
    ; budget: daily
```

The purchase remains a small two- or three-posting actual transaction. The budget effect is derived from the expense-account declaration.

Advantages:

- daily source entry stays compact
- repeated envelope metadata is not copied into each transaction
- this resembles the current account-to-budget mapping

Costs:

- the complete budget effect is not visible in the transaction block
- changing account metadata may alter interpretation of old history unless metadata is temporal or snapshotted
- exceptional routing needs another mechanism
- the current Envelope characterization found that implicit ownership and missing linkage can create divergent projections

No choice is made in this draft.

## Multi-posting examples

### Split receipt

```journal
2026-07-17 * スーパー | 食材と日用品
    ; action: buy
    ; receipt: receipt-2026-07-17-001
    expenses:食費          8000 JPY
    expenses:日用品        4000 JPY
    assets:ゆうちょ      -12000 JPY
```

One event remains one transaction even when several categories are involved.

### Loan repayment with principal and interest

```journal
2026-07-20 * 友人 | 借金返済
    ; action: repay
    ; agreement-id: loan-friend-001
    liabilities:友人      9000 JPY
    expenses:利息         1000 JPY
    assets:ゆうちょ     -10000 JPY
```

The journal block preserves both the life event and the accounting split. A pure scalar 6D amount cannot represent this distinction without an added substructure.

## Candidate minimal writing rules

These are design candidates, not selected source contracts.

1. One household event is normally one transaction block.
2. Postings are the authoritative representation of monetary movement.
3. Every posting amount is explicit in the initial profile.
4. Household JPY amounts remain integer-valued.
5. Actual and plan records use the same transaction grammar.
6. Concrete plans carry durable `plan-id` values.
7. Actual completion evidence copies the matching `plan-id`.
8. Completed plans are not deleted or rewritten into actuals.
9. Split receipts and compound payments use multiple postings rather than duplicate event rows.
10. Account metadata lives in account declarations.
11. Description may use `payee | what` as a readable convention.
12. `action`, `destination`, `receipt`, `agreement-id`, and similar coordinates are optional and added only when they preserve useful meaning.
13. Metadata keys use stable lower-case names.
14. Recurrence rules do not replace concrete dated plan evidence.
15. Unsupported or ambiguous records must fail visibly rather than being silently reinterpreted.

## Initially outside the household journal

### Cycle configuration

The current cycle model is primarily a view over time coordinates, such as an income-anchored or fixed half-open interval. It is not necessarily a durable property of each household event.

Initial direction:

- keep cycle-view configuration outside the journal
- derive income-anchor boundaries from actual and planned journal transactions where useful
- do not create synthetic `cycle-start` events merely to force view configuration into the journal

### Report and UI configuration

Report defaults, output selection, terminal preferences, and editor behavior are configuration, not household history.

### Issues and development decisions

Issue open/close records and architecture decisions should not enter the initial accounting journal merely because a zero-posting transaction could encode them.

These domains may be reconsidered later, but journal unification is not valuable when it erases useful boundaries.

## Safety principles

- actual-only views must not accidentally include plans
- plans must remain queryable without entering actual balances
- budget postings must not be mistaken for real asset movement
- account metadata must not silently rewrite historical meaning
- source tags needed for household semantics must remain inspectable
- invalid dates, amounts, accounts, or links must fail visibly
- plan completion must have one shared definition across all projections
- a root journal must assemble sources without duplicating one event in several physical files

## What remains deliberately unselected

- exact physical file layout
- exact root-journal names
- required versus optional 6D coordinates
- final controlled vocabulary for `action`
- whether ordinary actuals require `layer: actual`
- whether status markers participate in household layer semantics
- explicit versus derived budget consumption
- parser implementation
- writer or editor implementation
- runtime/report owner
- implementation language
- hledger library or command integration
- conversion of current fixtures or production data
- source-of-truth migration
- archival and rollback policy

## Questions for the next design discussion

1. Does the proposed transaction block remain pleasant to read after dozens of ordinary daily purchases?
2. Which 6D coordinates are genuinely durable, and which are decorative duplication?
3. Should `payee | what` be a convention or only a visual habit?
4. Is `action` useful enough to standardize, or can postings and description usually express it?
5. Should actual and budget postings coexist in one transaction?
6. If budget consumption is derived, how is historical account-to-envelope meaning frozen?
7. Should `plans.journal` retain completed plans indefinitely, or move them through time-based archival without deleting evidence?
8. Which four or five real household examples are sufficient to judge readability before any parser work?

## Non-goals of this draft

- implementing a parser
- selecting an implementation language
- rewriting reports
- changing editor behavior
- changing current TSV source truth
- converting production household data
- selecting a migration stage
- selecting a next finite program slice
- implementing all of hledger
- forcing every household or project event into one journal

## Possible evidence-only follow-up, still unselected

A later finite slice could create one public synthetic paper fixture containing only:

- declarations
- one split receipt
- one planned payment and early completion
- one budget allocation
- one loan repayment with principal and interest

That slice would judge human readability and semantic sufficiency only. It would select no parser, writer, runtime, language, or migration work.

Until such a slice is explicitly selected through `TODO.md`, this document remains parked background design evidence.