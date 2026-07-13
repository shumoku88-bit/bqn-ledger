# Travel Multi-Currency Settlement Design Intake — 2026-07-12

Status: parked intake
Owner: currency / travel settlement
Canonical: no
Current implementation authorization: none, except the separately selected I/O-free preview design slice below
Current selected consumer: `FRIEND_FOREIGN_LIABILITY_JPY_SETTLEMENT_PLAN-2026-07-13.md` is the canonical active plan for closing a confirmed FCY friend liability into an existing JPY friend liability. Follow that plan; this intake remains non-canonical for all other travel rails.
Reopen: only after the selected mixed-ledger daily-use path is stable enough to support another concrete travel consumer

## Purpose

Record the concrete lifestyle requirement and safety boundaries discussed on 2026-07-12 so later work does not collapse ordinary spending, asset exchange, card settlement, and JPY valuation into one ambiguous journal path.

This document is an intake, not an implementation plan. The current finite currency work remains M1 in:

- `CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md`
- `TODO.md`

## Concrete lifestyle requirement

The intended user may live outside Japan for roughly one or two months in a year.

During that period:

- the local currency may become the default input/report currency;
- JPY must remain available for Japanese subscriptions, bank withdrawals, rent, or other ongoing Japanese transactions;
- foreign cash may be acquired before departure and spent as a real foreign-currency asset;
- card purchases may be observed first in local currency and settled later in JPY;
- after returning to Japan, the trip may be reviewed or settled in JPY without rewriting the original foreign-currency facts.

Example:

```text
Japan
  exchange JPY for 200 USD at an airport
  declare/use assets:cash-USD

During travel
  spend USD cash from assets:cash-USD
  continue recording Japanese JPY payments
  record foreign card usage before the final JPY charge is known

After return
  record the actual JPY card settlements
  optionally close the trip with a JPY review/valuation
```

## 1. Currency configuration model

The intended shape separates engine knowledge, ledger-enabled currencies, and the current default.

### Engine currency catalog

Candidate repository-owned shape:

```tsv
code	minor_digits	symbol
JPY	0	¥
ILS	2	₪
USD	2	$
EUR	2	€
```

This catalog says what the engine understands. It must not select the user's current currency or perform valuation.

### Ledger-level currency declaration

Candidate `<LEDGER_DATA_DIR>/config.tsv` keys:

```tsv
DEFAULT_CURRENCY	JPY
ENABLED_CURRENCIES	JPY,ILS,USD
```

Exact names and semantic owner are not yet selected.

Required semantics:

```text
DEFAULT_CURRENCY
  = initial input selection
  = initial report selection
  = visible effective currency view

ENABLED_CURRENCIES
  = currencies available for explicit input/report selection

DEFAULT_CURRENCY ∈ ENABLED_CURRENCIES
```

Changing the default while abroad must not rewrite any existing account or transaction currency.

### Input and storage rule

```text
input may be convenient
source must be explicit
```

When the selected currency equals the default, the UI may avoid asking repeatedly. The editor must still write explicit `currency=...` metadata.

When another enabled currency is selected for one entry, only matching-currency From/To account candidates should be offered. The next entry may return to the configured default unless a later session-specific design says otherwise.

## 2. Ordinary journal rail

An ordinary journal row remains single-currency.

Example foreign cash spending:

```tsv
2026-09-02	Lunch	assets:cash-USD	expenses:food-USD	18.50	currency=USD	trip_id=usa-2026
```

Example Japanese spending during the same trip:

```tsv
2026-09-02	Japanese subscription	assets:bank	expenses:subscription	980	currency=JPY	trip_id=usa-2026
```

Rules:

- row currency must match From and To account currencies;
- no ordinary row may add or balance two currency domains;
- changing the ledger default does not change the meaning of an existing row;
- a foreign-currency expense is not converted to JPY inside the ordinary journal rail.

## 3. Cash exchange rail

Exchanging assets is not an expense merely because JPY leaves one account.

Example observation:

```text
31,500 JPY given
200.00 USD received
```

The two observed amounts are both primary facts. The effective rate can be derived:

```text
31,500 / 200 = 157.5 JPY per USD
```

But the rate alone must not replace the two observed amounts.

Safety boundary:

- do not disguise a two-currency exchange as a normal one-amount journal row;
- do not count the JPY exchanged for USD as travel spending;
- spending begins when the USD asset is later used for food, transport, and other expenses;
- exchange fees may eventually need a separate expense component rather than being silently absorbed.

Possible future owner:

```text
exchange event
  source account
  source amount + source currency
  target account
  target amount + target currency
  date / memo / exchange_id
```

Whether this becomes `exchange.tsv`, a typed event in a unified event log, or another checked source is intentionally undecided.

## 4. Card usage and settlement rail

A foreign card purchase and its later JPY charge are two stages of one economic event, not two independent expenses.

Example:

```text
usage observation
  card_txn_id = card-001
  original amount = 40.00 USD
  category = food
  state = pending

later settlement
  card_txn_id = card-001
  settled amount = 6,420 JPY
  state = settled
```

Required boundary:

```text
foreign original amount
  = local spending observation

JPY settled amount
  = Japanese funding/charge fact

both together
  = one linked purchase lifecycle
```

Reports must not add both as separate food expenses.

Possible views:

- local-currency travel view uses the original amount;
- JPY household funding view uses the settled amount;
- audit view shows both and their linkage;
- pending entries remain visibly unresolved until settlement evidence arrives.

Open design questions include card fees, partial settlement, refunds, reversals, and one statement line covering multiple usages. These are not authorized work.

## 5. Return-home JPY settlement and trip review

Original foreign-currency rows remain unchanged after return.

A later trip close may provide a JPY view using actual settlement evidence where available:

```text
cash spending
  use observed exchange acquisition / return amounts or another explicit policy

card spending
  use actual JPY card settlement amounts

remaining foreign cash
  retain as foreign asset or record a later reverse exchange
```

`trip_id` is a candidate grouping key, not yet a required source contract.

A future trip report may show:

```text
Original
  food       350.00 ILS
  transport  120.00 ILS

JPY settlement/review
  food       ¥15,050
  transport   ¥5,160
```

The JPY view must retain provenance. It must not silently overwrite original amounts or claim one universal market rate when actual cash and card settlement paths differ.

## 6. Four meanings that must not merge

```text
ordinary spending
  one currency, normal journal meaning

asset exchange
  two observed currency amounts, not itself an expense

card settlement
  later stage linked to an earlier purchase observation

valuation/report conversion
  derived view, not a rewrite of source facts
```

This separation is the central safety rule.

## 7. Sequencing boundary

Do not start travel settlement implementation from this intake.

Current sequence remains:

```text
M1
  selected-currency checked projection seam

M1.5 / M2 / M3 candidates
  explicit default and enabled currency declaration
  explicit source currency migration
  currency-aware editor
  selected-currency balances/reporting

later, after observation
  cash exchange event
  card usage/settlement lifecycle
  trip close and JPY review
```

The first travel implementation should be selected only from a concrete consumer and must remain one finite rail. Do not implement exchange, cards, trip reports, FX gains/losses, and valuation in one campaign.

## 8. Explicit non-goals for the current mixed-ledger plan

This intake does not alter the current non-goals of the active mixed-ledger M1 work:

- no FX arithmetic in M1;
- no conversion or valuation in M1;
- no two-currency Posting IR widening without a selected later design;
- no production source mutation;
- no card subsystem;
- no travel report;
- no automatic market-rate download;
- no exchange gain/loss accounting yet.

## 9. Restart checklist

When this topic is resumed, first confirm:

1. Is the selected-currency daily-use path implemented and observed?
2. Are `DEFAULT_CURRENCY` and enabled currencies explicit and distinct from source meaning?
3. Does the editor always save explicit currency metadata?
4. Which first concrete consumer is needed: cash exchange, card settlement, or trip review?
5. What is the smallest source contract that represents that consumer without double counting?
6. Which existing report must remain unchanged?
7. What fail-closed fixtures prove that meanings cannot cross rails?

Until those questions have evidence, keep this document parked.