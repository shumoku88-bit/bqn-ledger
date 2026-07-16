# Journal single-source direction draft

Status: parked design exploration / docs-only / no runtime authorization
Date: 2026-07-16
Owner: architecture discussion
Exit: revise, reject, or promote one finite characterization slice through `TODO.md`

## Purpose

Explore whether BQN Ledger should move from several TSV source files to one human-readable hledger-compatible journal as the durable source of truth, while preserving BQN as the accounting and household-report engine.

This document does not select implementation, migration, parser work, report rewrites, editor changes, or production-data conversion.

## Current baseline

Current `main` intentionally uses TSV source files and a two-account row contract:

- `accounts.tsv`
- `journal.tsv`
- `plan.tsv`
- `budget_alloc.tsv`
- `cycle.tsv`
- `issues.tsv`

The current architecture also explicitly says not to replace the TSV row form with ledger-style multi-posting blocks. Therefore this proposal is an architectural alternative, not an inferred continuation of current work.

The following current assets may remain reusable if the source format changes:

- validated Posting IR
- ledger-wide accounting checks
- Canonical Daily Cube
- TBDS period projections
- report-local `Build -> ViewModel -> Format` boundaries
- BQN ownership of meaning and calculation
- shell/gum/fzf ownership of terminal interaction
- preview, stale-check, backup, and post-check safety patterns

## Working hypothesis

Use one journal file as the normal durable source:

```text
ledger.journal
```

Do not split durable source by semantic role into `actual.journal`, `plan.journal`, `budget.journal`, `cycle.journal`, and `issues.journal`.

If physical splitting becomes necessary later, prefer time-based archival, such as yearly files included by one root journal, rather than semantic fragmentation.

```text
ledger.journal
archive/2026.journal
archive/2027.journal
```

The root journal remains the one configured entry point.

## One journal, several event meanings

The journal may contain:

- account declarations
- commodity declarations
- ordinary actual transactions
- planned transactions
- budget declarations or events
- cycle-boundary events
- issue and decision events

Meaning is distinguished by standard journal fields where possible and tags where BQN-specific semantics are required.

### Actual transaction

```journal
2026-07-16 * スーパー | 食材
    ; txn-id: txn-2026-07-16-001
    ; layer: actual
    expenses:food       4200 JPY
    assets:bank        -4200 JPY
```

### Planned transaction

```journal
2026-08-15 家賃
    ; plan-id: plan-2026-08-15-rent
    ; layer: plan
    ; recur: cycle
    expenses:rent      64000 JPY
    assets:bank       -64000 JPY
```

### Plan completion by appended actual evidence

```journal
2026-08-16 * 家賃
    ; txn-id: txn-2026-08-16-rent
    ; layer: actual
    ; plan-id: plan-2026-08-15-rent
    expenses:rent      64000 JPY
    assets:bank       -64000 JPY
```

The plan is not deleted. BQN resolves completion from matching actual evidence, preserving the current non-destructive plan lifecycle.

### Non-posting dated event

hledger journal transactions may contain no postings, so dated BQN-specific events can remain in the same chronological source without changing account balances.

```journal
2026-08-15 年金サイクル開始
    ; event: cycle-start
    ; cycle-id: cycle-2026-08-15
```

Possible event classes include:

- `cycle-start`
- `budget-declare`
- `issue-open`
- `issue-close`
- `decision`

Whether all of these belong in the accounting journal remains an open design question. The proposal only establishes that a single source is technically possible.

## BQN Journal Profile

Do not aim for full Ledger or hledger language compatibility.

Define a small supported profile that hledger can also read.

### Candidate initial syntax

Transactions:

- `YYYY-MM-DD` date
- optional status
- description, including optional `payee | note`
- transaction comments and tags
- zero or more postings

Postings:

- account
- explicit signed amount and commodity
- at most one omitted amount per balanced transaction
- posting comments and tags

Directives:

- `account`
- `commodity`
- comments
- possibly a constrained `include`

### Initially excluded

- automated postings
- full periodic transaction compatibility
- virtual postings
- complex aliases
- lot and investment syntax
- complete cost and valuation semantics
- all Ledger/hledger parser edge cases
- all non-journal input formats

Unsupported syntax must fail clearly with source location evidence. It must not be silently reinterpreted.

## Internal projection

Parse the journal into separate transaction and posting structures.

### Transaction IR candidate

```text
transaction_id
date
status
code
description
payee
note
tags
source_file
source_line
```

### Posting IR candidate

```text
transaction_id
posting_index
account
amount
commodity
tags
source_file
source_line
```

The source-facing parser and transaction balancing layer should feed the existing ledger-wide Posting IR boundary where compatible.

```text
ledger.journal
  -> journal parser
  -> transaction validation and amount completion
  -> Posting IR
  -> Cube / TBDS / report projections
```

The journal parser must not push source-language details into every report.

## hledger-like standard reports

BQN Ledger should be able to produce the standard reports needed for daily comparison and validation.

### First report family

- `print`
- `register`
- account-centred register similar to `aregister`
- `balance`
- monthly, quarterly, and yearly balance columns
- historical closing balances
- income statement
- balance sheet
- cash flow
- account, commodity, payee, description, and tag listings
- basic journal statistics

### Shared report engine hypothesis

Avoid one independent calculator per command. Express reports as projections over validated postings.

```text
filter
row axis
column axis
period partition
measure
accumulation mode
account depth
sort
layout
```

Examples:

```text
balance --monthly
  rows: account
  columns: month
  measure: movement
```

```text
balance --monthly --historical
  rows: account
  columns: month
  measure: closing balance
```

```text
register assets:bank
  filter: matching postings
  rows: postings
  accumulation: historical running balance
```

Initial compatibility target is semantic equivalence, not byte-for-byte formatting equivalence:

- same accepted journal subset
- same selected postings
- same period boundaries
- same movement and balance totals
- explicit documented differences

hledger should be usable as a reference implementation and comparison oracle for fixtures.

## BQN-specific reports

Preserve the reports that motivated BQN Ledger:

- snapshot
- cycle summary
- plan status
- actual comparison
- outlook
- daily trend
- envelope views when enabled
- owner-specific future views

The accounting core must remain independent from household policy. Cycle, pension cadence, envelope choice, and planning policy belong above validated accounting projections.

## Journal entry assistance

Rebuild the daily entry path around multi-posting transactions rather than two-account TSV rows.

### Candidate workflow

1. choose or enter date
2. choose or enter payee/description
3. offer a similar recent transaction as a template
4. edit, add, or remove postings
5. complete accounts, commodities, and tags
6. preview the complete journal block
7. run parser and accounting checks
8. append atomically
9. run post-check

### Candidate suggestions

- recent similar descriptions
- recent transactions for the same payee
- frequently used accounts
- previous posting structure for that payee
- previous commodity
- known account, commodity, payee, and tag names
- unfinished plans as transaction templates
- relative date words at the UI boundary

### Responsibility boundary

- BQN owns candidate derivation, meaning, and validation
- gum/fzf owns search, selection, and terminal presentation
- shell owns interaction flow and safe-write orchestration
- shell must not infer accounting meaning independently

This preserves the current `BQN = meaning`, `UI = interaction` boundary.

## Single-source safety rules

A single journal containing actual and plan records needs strong default views.

Candidate rules:

- normal accounting reports default to actual transactions only
- plan and forecast reports opt into planned transactions explicitly
- `--layer all` is always explicit
- hledger comparison commands use a documented tag query profile
- plan records must never enter actual balances accidentally
- source tags must remain queryable and round-trippable through BQN views

The exact hledger query profile is an open characterization task and should be verified against fixtures before adoption.

## Migration outline

### Stage 0: docs and fixture only

- define the BQN Journal Profile
- create a small synthetic journal fixture
- verify that hledger reads it
- specify expected Transaction IR and Posting IR
- specify actual/plan selection semantics
- change no current runtime path

### Stage 1: read-only parser experiment

- parse the synthetic fixture
- report source-located errors
- balance multi-posting transactions
- compare normalized postings with hledger output

### Stage 2: read-only standard reports

- `print`
- `balance`
- `register`
- monthly movement and historical closing balances

### Stage 3: entry prototype

- multi-posting preview
- recent-transaction suggestion
- account and commodity completion
- append only to a disposable fixture

### Stage 4: compatibility observation

- convert synthetic and public fixture TSV data
- compare old BQN reports, new BQN reports, and hledger reports
- document semantic losses and gains

### Stage 5: production migration decision

Only after explicit evidence:

- decide whether journal becomes source truth
- decide whether all source classes belong in one file
- define backup and rollback
- define archival policy
- retire TSV writers only through a separate selected migration plan

## Success criteria

- one configured root journal is sufficient for normal use
- hledger and BQN both read the supported transaction subset
- multi-posting transactions balance correctly
- standard report totals agree for characterized fixtures
- monthly movement and historical balances are available
- account-centred transaction reports are available
- entry suggestions reduce repeated typing without hidden writes
- plans remain non-destructive and linkable to actual evidence
- BQN-specific household reports remain possible
- the implementation remains substantially smaller and more understandable than full hledger compatibility

## Non-goals

- implementing all of hledger
- replacing hledger as a general-purpose project
- byte-for-byte report compatibility
- supporting every Ledger dialect
- adding a web UI
- bank synchronisation
- automatic financial advice
- automatic production migration
- changing current source truth in this PR

## Open decisions

1. Should budget, cycle, and issue events live in the same journal or remain external configuration/event data?
2. Should `layer: actual` be written explicitly, or should ordinary transactions default to actual?
3. Which tags are durable source contracts rather than temporary migration aids?
4. Is one constrained `include` required from the beginning, or should the first profile accept one physical file only?
5. How should BQN and hledger select actual-only data identically?
6. Which hledger report commands define the first semantic-equivalence test matrix?
7. How much amount inference should the BQN profile permit?
8. Which current Cube/TBDS boundaries can be reused unchanged?
9. Should the first experiment live inside this repository or in a separate branch/repository?

## Smallest selectable follow-up

If this direction remains interesting, the smallest finite follow-up is a docs-and-fixture characterization only:

- define the minimal BQN Journal Profile
- add one synthetic single-journal fixture
- write expected normalized postings
- document the exact hledger commands used for comparison
- select no production parser, writer, or migration work
