# Projection Contract

Status: draft
Branch: `refactor/cycle-ledger-core`
Scope: rules for projecting canonical TSV records into the BQN array model

## 1. Purpose

This document defines how canonical records become array updates.

The projection path is the bridge between human-readable TSV records and the BQN core shape.

The goal is to make projection behavior inspectable, reusable, and safe.

## 2. Core flow

Every projection should follow this conceptual flow:

```text
source record
  -> account resolution
  -> currency resolution
  -> AccountKey resolution
  -> day/cycle resolution
  -> layer assignment
  -> delta output
```

This flow should be recognizable in the implementation even if the exact BQN representation differs.

## 3. Projection row mental model

A projection may be represented conceptually as:

```text
source_file
source_row
source_id
day_index
account_key_index
layer_index
delta
kind
status
message
```

This is not necessarily a stored TSV format.

It is a mental model for the derived updates that feed the cube.

## 4. Account and currency resolution

Projection must resolve canonical account names into `AccountKey` values.

First-phase policy:

```text
AccountKey = (Account, Currency)
```

Rules:

- JPY-only records resolve to JPY account keys.
- Foreign-currency balances resolve to foreign-currency account keys.
- Different currencies must not be projected into the same numeric balance.
- Unknown account names are contract errors.
- Unknown or unsupported currencies should produce structured checks before report values are computed.

## 5. Amount rules

The projected `delta` is numeric only within a single resolved AccountKey.

The engine must not silently add:

```text
1000 JPY + 10 USD
```

If a record cannot be safely projected because its currency semantics are unsupported, it should produce a warning, unavailable status, or error according to the surrounding contract.

## 6. Layer assignment

Projection must assign each record to a layer explicitly.

Initial layer mapping:

```text
journal.tsv      -> actual
plan.tsv         -> plan
budget_alloc.tsv -> budget
forecast         -> reserved
```

Layer numeric indexes should be declared in one place.

Projection functions should not contain scattered layer magic numbers.

## 7. Repeated projection patterns

The current engine hardening notes identify repeated patterns in projection functions such as actual, budget consumption, budget allocation, and plan projection.

This refactor should treat those repetitions as a design signal.

Preferred structure:

```text
resolve account/currency/day/layer
  -> emit projection delta
```

Differences between source types should be explicit parameters or clearly separated small functions.

The goal is not to make the code artificially clever.

The goal is to make the common projection shape visible.

## 8. Projection checks

Projection should be able to emit or collect checks such as:

- unknown account
- unsupported currency
- missing required field
- malformed amount
- impossible date
- missing cycle for date
- unsupported source kind

These checks should be available to the report layer.

## 9. Projection sanity check

Before implementing a full report, the new path should support a minimal sanity check:

```text
canonical TSV
  -> projection rows
  -> cube shape
  -> simple sums by Day / AccountKey / Layer
```

This is a better first BQN validation target than a polished text report.

If the projection path is wrong, all reports built on top of it are decorative fog.

## 10. Output stability

Behavior-preserving refactors should not change projected meaning.

If a projection rule changes, document:

- source file affected
- old behavior
- new behavior
- reason for the change
- expected report impact

## 11. Non-goals

The first projection contract does not require:

- exchange-rate conversion
- separate Currency axis
- tax export projection
- double-entry export projection
- event-first canonical storage

Those may be future contracts.
