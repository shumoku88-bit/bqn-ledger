# Current Balance Sheet and Profit and Loss reports

Status: retained Actual-only household statements with explicit unresolved decisions

## Questions

`balance-sheet` answers:

> At one explicit observation, what are the admitted asset, liability, and stated-equity balances, and what unclosed accumulated result is required for the accounting equation?

`profit-and-loss` answers:

> In one explicit half-open period, what Actual income and expense movement occurred by Account, and what net income results?

They are separate retained reports because position at an instant and performance over a period are different accounting questions.

## Inputs and ownership

Both reports consume strict canonical Actual Transaction/Posting Facts for one currency domain. They do not read Plan, Entitlement, Envelope policy/history, Issues, Daily Target policy, a clock, or inferred Account-name prefixes.

Account classification comes only from admitted Account `role` metadata:

```text
Balance Sheet      asset | liability | equity
Profit and Loss    income | expense
```

Canonical Account admission permits only Asset, Liability, Equity, Income, and Expense roles. A synthetic/noncanonical Fact with a nonzero unsupported role makes Balance Sheet unavailable rather than silently disappearing from the equation.

All arithmetic uses exact coefficient/scale operations. Account rows and derived totals retain source-qualified Posting contributors.

## Profit and Loss contract

Coordinates are strict `[start,end_exclusive)` dates. The report includes every admitted income and expense Account in source order, including exact zero movement.

Canonical Posting signs remain debit-positive and credit-negative. Statement measures normalize presentation meaning as:

```text
income amount  = - signed income movement
expense amount =   signed expense movement
net income     = total income - total expenses
```

A debit to an income Account or credit to an expense Account therefore remains visible as a negative amount rather than being reclassified by Account name or counterpart inference.

The current report is human-only. It has no Envelope/Actual comparison, monthly columns, ratios, tax adjustment, or retained-earnings transfer.

## Balance Sheet contract

The coordinate is one strict `as_of` date and includes Actual Postings through that date.

Statement signs normalize normal balances as:

```text
asset balance     =   signed Account closing
liability balance = - signed Account closing
equity balance    = - signed Account closing
```

Abnormal balances remain negative after this normalization.

Current journals do not require periodic closing entries from Income and Expense into Equity. Balance Sheet therefore publishes the derived line:

```text
unclosed accumulated result = -(sum income and expense closing balances through as_of)
```

This is not labeled retained earnings and does not invent a fiscal closing. It is the accumulated unclosed result required to show the current equation:

```text
total assets = total liabilities + stated equity + unclosed accumulated result
```

The report fails closed if the canonical Account total is not zero, an unsupported Account role has a nonzero Actual balance, an exact sum fails, or the displayed equation does not reconcile.

## What is deliberately not decided yet

The current reports are useful household accounting statements, not a claim of statutory, tax, GAAP, or IFRS compliance. A future change must select its question before deciding any of the following:

1. **Closing policy** — whether and when Income/Expense balances are transferred to a durable Equity/retained-earnings Account.
2. **Reporting year** — calendar year, another fiscal year, cycle periods, or no formal year-end.
3. **Opening and migration meaning** — whether `equity:opening-balances` represents net opening equity, a migration clearing balance, deficits, or another explicitly documented source event.
4. **Classification depth** — current/noncurrent assets and liabilities, operating/nonoperating income and expense, cost categories, contra Accounts, and statement ordering metadata.
5. **Comparatives** — prior observation, prior period, monthly columns, and aligned-period policy.
6. **Household transfers and owner flows** — whether particular Equity movements require a distinct household classification.
7. **Formal adjustments** — accruals, depreciation, inventory, tax, valuation, FX, and consolidation.
8. **Structured surfaces** — the neutral JSON/API schema needed by a conversational or HTML presenter.

Do not infer these from Account names. Add metadata or a new narrow capability only after a concrete consumer chooses the semantics.

## BQN shape

The current finite data flow is:

```text
canonical Actual Facts
  -> explicit date/domain selection
  -> Account role mask
  -> exact Account movement or closing
  -> sign-normalized statement rows
  -> exact totals and reconciliation
  -> bounded semantic section result
  -> human renderer
```

A future classify-once grouping experiment may improve larger-data scaling, but it must preserve exact diagnostics, Account order, zero rows, contributor identity, and report bytes unless a separately reviewed contract changes them.
