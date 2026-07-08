# Currency Awareness Campaign Map

Status: active plan
Owner: config
Canonical: no; canonical path: `docs/ENGINEERING_ROADMAP.md`
Exit: archive when the currency-awareness campaign closes or when a current currency contract replaces this plan
Date: 2026-07-08

## Purpose

This document stages the path from the current JPY-only assumptions toward a currency-aware ledger without jumping directly into exchange-rate valuation.

The selected order is:

```text
current assumptions
  -> amount / currency semantics
  -> single-currency awareness
  -> per-row original currency
  -> currency-partitioned reports
  -> Japan + Israel travel proof
  -> FX valuation only if needed
  -> closure review
```

The immediate reason is concrete rather than speculative: daily use may soon include travel in Israel, so JPY-only assumptions now have a plausible real-life pressure point. This does not authorize broad multi-currency implementation by itself.

## Current repository evidence

The current source and engine boundaries already expose the important constraints:

- `journal.tsv` / `plan.tsv` keep five required columns: date, memo, from, to, amount.
- Sixth and later columns can carry `key=value` metadata.
- Current accounting calculations primarily consume the first five columns.
- Current Posting IR uses a signed integer `delta`.
- `docs/ENGINEERING_ROADMAP.md` already contains a broader multi-currency proposal with `currency`, `base_amount`, `BASE_CURRENCY`, and TBDS changes.

That older roadmap is retained. This plan inserts earlier stages before it, because `currency` awareness and FX valuation are different problems.

## Core semantic separations

The campaign must preserve these non-equivalences:

```text
amount != currency
original_amount != reporting_value
currency != exchange_rate
transaction_date != rate_observation_date
rate_observation_date != valuation_date
valuation_date != report_coordinate
```

Do not silently collapse one into another.

## Scope boundary

This campaign may eventually cover:

- explicit currency meaning;
- JPY compatibility;
- non-JPY single-currency operation;
- per-row original currency;
- currency-safe aggregation;
- currency-partitioned reporting;
- travel fixtures;
- FX valuation only after a concrete need is demonstrated.

The first slice is docs-only.

## Non-goals for the first stages

Do not start by:

- adding live exchange-rate APIs;
- introducing automatic FX conversion;
- adding `base_amount` everywhere;
- changing TBDS axes immediately;
- rewriting real source TSV data;
- changing all reports in one PR;
- treating `currency=ILS` as proof that mixed-currency arithmetic is safe;
- inventing historical valuation semantics without evidence.

## Stage 0: current assumption map

### Question

Where does the current repository assume JPY or otherwise assume that one numeric amount axis is sufficient?

### Observe at least

```text
source TSV
metadata schema
loader
projection
Posting IR
cube
TBDS
ViewModel
FormatHuman
structured JSON
editor
lint / strict checks
fixtures
golden outputs
docs
```

### Classify each finding

```text
A. source meaning
B. parsing
C. arithmetic
D. aggregation
E. display
F. validation
G. documentation only
```

### Deliverable

A docs-only current-state map. No runtime change.

### Exit gate

Stage 0 closes only when the repository-wide assumption surface is explicit enough to choose the smallest Stage 1 decision slice.

## Stage 1: amount and currency semantics

### Main question

What does the source `amount` field mean once non-JPY currency exists?

### Required decisions

Decide explicitly:

- source amount semantics;
- internal amount semantics;
- missing currency semantics;
- unknown currency semantics;
- precision semantics;
- fallback compatibility for existing JPY data;
- whether currency is ledger-level, row-level, or both;
- whether display precision is part of currency metadata.

### Important design branch

The following options are not yet decided.

#### Option A: source stores integer minor units

```text
JPY 1200 yen -> 1200
ILS 42.50    -> 4250
USD 12.34    -> 1234
```

Strength: integer arithmetic remains simple.

Risk: direct TSV readability is weaker because `4250` no longer visibly means `42.50 ILS`.

#### Option B: source stores human-readable decimal amount, internal projection normalizes to integer minor units

```text
source:
42.50  currency=ILS

internal:
4250 minor units
currency=ILS
```

Strength: source remains human-readable while the internal arithmetic boundary can stay integer-based.

Risk: current integer-only amount validation and Posting IR contracts must change explicitly.

This is a preliminary candidate, not a selected decision.

#### Option C: source integer meaning changes by currency

```text
JPY 1200 -> 1200 yen
ILS 4250 -> 42.50 ILS
```

Risk: the naked fifth column becomes context-dependent and harder for humans to read safely.

This option should not be selected without strong evidence.

### Exit gate

No implementation until one source/internal amount contract is selected and compatibility behavior is documented.

## Stage 2: single-currency awareness

### Goal

Generalize the current JPY-only ledger into an explicitly single-currency ledger before allowing mixed currencies.

Examples:

```text
ledger currency = JPY
```

or:

```text
ledger currency = ILS
```

### Candidate initial set

```text
JPY
ILS
USD
EUR
```

This set is provisional until Stage 1 decides the metadata and amount contract.

### Required gates

- existing JPY fixture behavior remains compatible;
- missing currency fallback is explicit;
- unknown currency fails visibly;
- formatting does not leak into accounting arithmetic;
- machine output and human output do not silently diverge in meaning.

## Stage 3: per-row original currency

### Goal

Allow rows to preserve the currency in which the real-world event occurred.

Example shape:

```text
2026-07-28  Tokyo     ...  1200   currency=JPY
2026-07-30  Tel Aviv  ...  42.50  currency=ILS
```

The exact amount representation remains governed by Stage 1.

### Critical invariant

```text
1000 JPY + 50 ILS != 1050
```

Mixed currencies must not enter one undifferentiated arithmetic total.

### Required gate

The projection / Posting IR boundary must preserve enough currency identity to prevent cross-currency addition.

## Stage 4: currency-partitioned reports

### Goal

Support mixed original currency without FX conversion.

Example:

```text
JPY balance:  53,200 JPY
ILS spending:    418.50 ILS
```

### Report classification

Classify each report or section as:

```text
safe as-is
currency-partitionable
requires one currency
requires FX valuation
```

At minimum review:

- Snapshot;
- Balances;
- Daily Trend;
- Envelopes;
- Outlook;
- Planned.

Do not update every report in one slice.

## Stage 5: Japan + Israel travel proof

### Goal

Use fixtures before real source data to test plausible travel events.

Fixture scenarios should include:

```text
Japan
  JPY actual
  JPY plan

Israel
  ILS cafe
  ILS transport
  ILS grocery

mixed period
  JPY + ILS
```

Potential later scenarios may include:

```text
ILS cash
ILS debit payment
Japanese card purchase denominated in ILS
later JPY card settlement
```

Do not assume that purchase and settlement are one event.

```text
purchase event != settlement event
```

Only promote this distinction into a contract after evidence shows it is needed.

## Stage 6: FX valuation, only if needed

### Goal

Introduce reporting-currency valuation only after original-currency handling is stable and a concrete consumer requires conversion.

Only here reconsider:

```text
base_currency
exchange_rate
rate_source
rate_observation_date
valuation_date
base_amount
```

This is where the broader `docs/ENGINEERING_ROADMAP.md` proposal becomes directly relevant.

### Temporal boundary

Preserve:

```text
transaction_date
  != rate_observation_date
  != valuation_date
  != report_coordinate
```

No automatic historical FX semantics should be invented.

## Stage 7: closure review

The campaign may close when current evidence supports a stable boundary such as:

```text
JPY-only compatibility
single-currency non-JPY operation
mixed original currency preservation
currency-safe aggregation
explicit unsupported-FX boundary or explicit FX contract
```

Closure must record residual independent candidates rather than leaving the campaign permanently open.

## Compatibility invariants across the campaign

Unless a later explicit decision says otherwise:

- existing JPY source data remains valid;
- real `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, and `accounts.tsv` are not rewritten automatically;
- first five journal-like TSV columns remain protected until a specific contract change is selected;
- optional metadata does not become accounting truth merely because it parses;
- unknown or incompatible currency states fail visibly rather than becoming zero;
- human formatting does not define machine arithmetic;
- current report semantics are not silently broadened from one currency to many.

## Relation to existing roadmap

`docs/ENGINEERING_ROADMAP.md` remains the broad engineering roadmap and is not deleted or rewritten by this map.

Its current multi-currency steps involving:

```text
currency
base_amount
BASE_CURRENCY
TBDS base_amount axis
```

are treated here as later design material, especially for Stage 6. They are not automatic authority to skip Stages 0-5.

## Work authorization boundary

This document authorizes planning structure only.

The next finite slice after accepting this map should be:

```text
Stage 0: docs-only current JPY / single-amount assumption map
```

Do not begin runtime, test, fixture, source TSV, Posting IR, TBDS, or FX changes merely because this campaign map exists.
