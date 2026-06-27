# Axis Contract

Status: draft
Branch: `refactor/cycle-ledger-core`
Scope: BQN array axes for the cycle-ledger architecture

## 1. Purpose

This document defines the intended axes of the core BQN array model.

The goal is to make the shape of the program visible.

A BQN reader should be able to answer:

- what each axis means
- which axis is being reduced, sliced, scanned, or masked
- why records with different currencies are not accidentally mixed

## 2. First-phase core shape

The first-phase core shape is:

```text
Day × AccountKey × Layer
```

This is a refinement of the earlier shorthand:

```text
Day × Account × Layer
```

In this document, `AccountKey` means the accounting identity used by the cube.

`AccountKey` may represent a plain account in JPY-only data, or an `(Account, Currency)` pair when currency-separated balances are required.

## 3. Axis meanings

### Axis 0: Day

The `Day` axis represents the day index within the loaded date range or living cycle context.

Day-axis operations include:

- cycle slicing
- daily balances
- cumulative scans
- date-range comparisons

### Axis 1: AccountKey

The `AccountKey` axis represents the resolved account identity used for projection and balance calculation.

First-phase rule:

```text
AccountKey = (Account, Currency)
```

For JPY-only data, this may behave like a normal account axis.

For foreign-currency balances, separate currencies must remain separate account keys.

Examples:

```text
assets:bank / JPY
assets:bank / USD
assets:cash / JPY
assets:cash / EUR
```

These must not be collapsed into one numeric balance.

### Axis 2: Layer

The `Layer` axis represents the source or planning layer of a projected amount.

Initial layer order:

```text
0 actual
1 plan
2 budget
3 forecast
```

Layer meanings:

```text
actual    records from journal.tsv
plan      records from plan.tsv
budget    records from budget_alloc.tsv and budget-related projections
forecast  reserved, not required in first phase
```

Layer index values should be declared in one place.

Reports should not infer layer meaning from scattered numeric literals.

## 4. Currency separation policy

If original-currency balances become an active requirement, balances must be separated by currency.

The first implementation may represent this separation by treating `(Account, Currency)` pairs as distinct `AccountKey` values within the AccountKey axis.

A separate `Currency` axis remains a future option if currency-level reporting becomes a primary use case.

Current first-phase choice:

```text
use AccountKey = (Account, Currency)
do not add a separate Currency axis yet
```

This preserves the simpler first-phase cube shape while preventing meaningless currency mixing.

## 5. Future Currency axis option

A future version may introduce:

```text
Day × Account × Layer × Currency
```

This should happen only if the project actively needs currency-level reports such as:

- frequent slicing by currency
- currency-specific budgets
- currency-specific forecasts
- exchange-rate views
- foreign-currency balances as a first-class daily report surface

Until then, currency separation through `AccountKey` is sufficient.

## 6. AccountKey table

The loader or account resolver should be able to produce an inspectable AccountKey table.

Conceptual fields:

```text
account_key_index
account_name
currency
account_key
role
display_name
attributes
```

Example:

```text
0  assets:bank  JPY  assets:bank/JPY  asset  Bank JPY  ...
1  assets:bank  USD  assets:bank/USD  asset  Bank USD  ...
```

The exact TSV or BQN representation may differ, but the resolved account space should be inspectable.

## 7. Shape visibility

The core implementation should avoid hiding shape decisions.

Preferred code style:

- derive axis sizes from loaded data or one documented declaration
- name axis lengths clearly
- keep layer constants visible
- keep AccountKey resolution visible
- avoid scattered magic numbers such as unexplained `256`

## 8. Non-goals

The first axis contract does not require:

- a separate Currency axis
- exchange-rate conversion
- multi-currency net-worth reporting
- currency gains or losses
- full double-entry accounting

Those may be future work.
