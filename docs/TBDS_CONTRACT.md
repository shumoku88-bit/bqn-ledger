# TBDS Contract

Status: **active contract draft / next ledger engine candidate**
Date: 2026-06-25

TBDS means **Trial Balance Dataset**.

TBDS is the accounting-state boundary between the normalized posting/cube layer and report-specific views.

```text
Posting IR
  -> validated ledger-wide posting set
  -> TBDS(period, as_of)
  -> accounting reports
  -> household views
  -> formatters
```

Important: TBDS is period-aware, but the ledger is not period-bounded. A period/cycle is a report query boundary, not a source loading boundary.

## 1. Purpose

TBDS prevents every report view from directly slicing the cube in its own way.

Instead of each report re-implementing period/account/layer logic, TBDS provides a small, structured account-state dataset for a selected period or as-of date.

## 2. Scope

TBDS contains accounting state, not UI layout and not household advice.

Allowed concepts:

- ledger-wide validated postings as input
- period start / end
- as-of date
- account key / account role / metadata needed for grouping
- layer
- opening balance before the period
- period movement inside `[period_start, period_end_exclusive)`
- closing balance (`opening + movement`)
- validation status
- provenance references

Out of scope:

- report section text formatting
- ASCII art
- advice text
- `food` / `daily` / `safe` as hard-coded engine concepts
- source TSV parsing
- editor behavior

## 3. Minimal row shape

A TBDS row is one account/layer state for one period.

Required fields:

| field | type | meaning |
|---|---|---|
| `period_id` | string | Stable period label, e.g. `cycle:2026-06-15..2026-06-22` |
| `period_start` | string | Inclusive start date |
| `period_end_exclusive` | string | Exclusive end boundary |
| `as_of` | string | Date used for as-of calculations |
| `account_key` | string | Canonical account key |
| `account_key_index` | number | Index into AccountKey table |
| `account_name` | string | Human account name |
| `currency` | string | Currency code if available |
| `role` | string | Account role metadata, e.g. asset/liability/income/expense |
| `layer` | string | actual/plan/budget/forecast |
| `layer_index` | number | Layer index |
| `opening` | number | Balance immediately before `period_start`, computed from valid postings dated `< period_start` |
| `debit_movement` | number | Sum of debit-side deltas within `[period_start, period_end_exclusive)` |
| `credit_movement` | number | Sum of credit-side deltas within `[period_start, period_end_exclusive)` |
| `movement` | number | Net movement: `debit_movement + credit_movement` |
| `closing` | number | `opening + movement` |
| `status` | string | ok/warn/error/unavailable |
| `message` | string | diagnostic text |

Optional fields may include policy metadata such as `budget`, `budget_group`, or `spend_class`, but report views must treat those as policy metadata, not core accounting axes.

## 4. Amount, value, and Measure axis

Amount itself is not a TBDS axis.

Amount is the numeric value stored at a coordinate. In array terms, the core daily cube is best understood as:

```text
Day × AccountKey × Layer -> Amount
```

TBDS adds period/accounting-state meaning on top of that. It may be viewed as:

```text
Period × AccountKey × Layer × Measure -> Amount
```

Where `Measure` is the accounting-state meaning of the numeric amount:

- `opening`
- `debit_movement`
- `credit_movement`
- `movement`
- `closing`

This distinction is important:

- Do not model raw yen values as an axis.
- Do not create one coordinate per possible amount.
- Do model the meaning of the amount as `Measure`.
- Do keep the amount as the scalar value at the selected coordinate.

For example:

```text
cycle:2026-06-15..2026-08-15 × assets:bank × actual × opening  = 100000
cycle:2026-06-15..2026-08-15 × assets:bank × actual × movement = -1000
cycle:2026-06-15..2026-08-15 × assets:bank × actual × closing  = 99000
```

Amount buckets may be introduced later for analytical reports, such as spending distribution or anomaly detection, but that would be a separate report lens, not the accounting-state TBDS core.

## 5. Invariants

For every TBDS row:

```text
opening  = sum(delta where date < period_start)
movement = debit_movement + credit_movement
closing  = opening + movement
```

`opening = 0` is valid only when the actual computed opening balance is zero. It must not be used as a placeholder for unimplemented history handling.

For balanced layers derived from Posting IR:

```text
sum(movement by layer over all accounts) = 0
```

For a selected account group, report views may sum TBDS rows, but they must not mutate TBDS values.

## 6. Relationship to Cube

The cube remains the dense materialized form:

```text
Day × AccountKey × Layer
```

TBDS is a period/account summary derived from validated ledger-wide Posting IR or from a cube that preserves enough pre-period history to compute opening balances.

A cycle-bounded cube that drops pre-period postings is not sufficient to build TBDS for balances, because it cannot compute `opening`.

TBDS does not replace the cube immediately. The migration order is:

1. Validate Posting IR across the ledger-wide source history.
2. Build cube / posting indexes equivalently to the current path without losing pre-period actual postings.
3. Derive TBDS for a selected period from the validated ledger-wide input.
4. Move report views one by one from direct cube slicing to TBDS queries.

## 7. Query style for report views

Views should use TBDS through simple filters and sums:

```text
filter period
filter role/account group
filter layer
select measure: opening / movement / closing according to report kind
sum selected measure values
```

Report usage rule:

| Report kind | TBDS field / Measure |
|---|---|
| Trial Balance | opening, debit_movement, credit_movement, movement, closing |
| Balance Sheet / Snapshot / Balances | closing |
| Income Statement / Cycle Summary | movement |

Views should not recompute day indexes, account indexes, or layer indexes unless explicitly documented.

## 8. First adoption target

The first TBDS adoption should be a small accounting report surface where expected values are already covered:

- Trial Balance opening / movement / closing
- Cycle Summary actual income / expense / net from movement
- Balances nonzero actual account totals from closing
- YTD actual income / expense / net from movement over the YTD period

Cycle Summary uses TBDS as follows:

- income = negated `credit_movement` of income accounts in actual layer
- expense = `debit_movement` of expense accounts in actual layer
- net = income - expense

This preserves current report semantics for gross expense debit flow while keeping net account movement available.

The first gate is value parity, not display parity.

## 9. Failure behavior

If Posting IR validation fails, TBDS must not produce polished successful values from invalid input.

Allowed statuses:

- `ok`: value is available and validated
- `warn`: value is available with non-blocking diagnostic
- `error`: value must not be used as a successful report value
- `unavailable`: required input is missing or not implemented

`0` must only mean numeric zero, not missing or invalid.
