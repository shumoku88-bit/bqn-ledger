# Data Contract

Status: draft
Branch: `refactor/cycle-ledger-core`
Scope: canonical TSV data rules for the cycle-ledger refactor

## 1. Purpose

This document defines what the canonical data files mean before the refactor changes implementation code.

The goal is to keep the source data human-readable, stable, and safe to maintain while leaving room for future extensions such as currency-separated balances.

This document is a contract for loaders, projections, reports, checks, and AI-assisted edits.

## 2. Core rule

Canonical data lives in TSV files under `data/`.

BQN reads canonical data and produces derived views and reports.

BQN must not rewrite canonical TSV files in the core report path.

Derived files, caches, exports, generated reports, and helper outputs are not canonical unless another document explicitly says so.

## 3. Canonical files

The expected canonical files are:

```text
data/journal.tsv        actual records
data/plan.tsv           planned records
data/budget_alloc.tsv   budget or envelope allocation records
data/accounts.tsv       account names, display names, roles, and attributes
data/cycle.tsv          living-cycle boundaries
data/config.tsv         minimal settings, if needed
```

The first phase should not add more canonical files unless the need is clear.

## 4. File meanings

### 4.1 `journal.tsv`

`journal.tsv` records actual events that already happened.

It feeds the `actual` layer.

Examples of actual records:

- spending
- income received
- transfers already made
- adjustments already accepted as factual

### 4.2 `plan.tsv`

`plan.tsv` records expected or scheduled future items.

It feeds the `plan` layer.

A planned item is not an actual event until represented in `journal.tsv` or otherwise explicitly marked by a future projection rule.

### 4.3 `budget_alloc.tsv`

`budget_alloc.tsv` records budget or envelope allocation.

It feeds the `budget` layer.

Budget data is not the same thing as actual money movement unless a specific projection rule says so.

### 4.4 `accounts.tsv`

`accounts.tsv` defines the account space used by projections and reports.

It should include account names, display names, roles, and attributes needed for report grouping.

The implementation must derive account-space size from resolved account keys rather than relying on unexplained numeric literals.

If a fixed account slot count is retained for architectural reasons, it must be declared in one place and documented as a deliberate limit.

### 4.5 `cycle.tsv`

`cycle.tsv` defines living-cycle boundaries.

The first report engine is cycle-oriented, so cycle boundaries are part of the canonical data contract.

Cycle ranges should be treated as half-open intervals unless another contract explicitly says otherwise.

### 4.6 `config.tsv`

`config.tsv` is optional in the first phase.

It may hold minimal settings, but it should not become a hidden second source of truth.

## 5. Amount, currency, and AccountKey

The first phase should keep the core report path simple while still allowing currency-separated balances when they become necessary.

The preferred amount-bearing record shape is:

```text
amount      integer minor-unit amount
currency    ISO-like currency code such as JPY, USD, EUR
```

Current records may effectively be JPY-only.

Rules for the first phase:

- `amount` is an integer.
- The default currency is `JPY` when the existing file format has no currency field.
- Currency conversion is out of scope.
- Exchange-rate gain/loss reporting is out of scope.
- Amounts in different currencies must not be silently added together.
- Currency-separated balances may be represented by resolving `(Account, Currency)` pairs into distinct `AccountKey` values.

First-phase internal identity:

```text
AccountKey = (Account, Currency)
```

Examples:

```text
assets:bank / JPY -> assets:bank/JPY
assets:bank / USD -> assets:bank/USD
assets:cash / EUR -> assets:cash/EUR
```

This means that a USD balance can remain a USD balance without requiring a separate Currency axis in the first implementation.

A future version may introduce a separate Currency axis only if currency-level reporting becomes a primary use case.

Open questions:

- Should a `currency` column be added soon to all canonical amount-bearing TSV files, even if every row is currently `JPY`?
- Should `accounts.tsv` explicitly declare allowed currencies per account, or should AccountKeys be derived from actual records first?

## 6. Layers

The initial layer mapping is:

```text
actual    from journal.tsv
plan      from plan.tsv
budget    from budget_alloc.tsv and budget-related projections
forecast  reserved, not required in first phase
```

Layer meanings should stay stable.

A record should not change layers accidentally because a report needs a convenient shortcut.

## 7. Projections

A projection is a derived representation of canonical records into the internal array model.

The implementation may produce projection rows such as:

```text
day_index
account_key_index
layer_index
delta
kind
source
```

This is not a required storage format, but it is a useful mental model.

Projection functions should make these operations explicit:

```text
source record
  -> account resolution
  -> currency resolution
  -> AccountKey resolution
  -> day/cycle resolution
  -> layer assignment
  -> delta output
```

The main branch hardening notes identify repeated projection patterns in the current engine. This refactor should treat that as a design smell to clarify, not merely as code duplication to mechanically compress.

See also:

```text
docs/AXIS_CONTRACT.md
docs/PROJECTION_CONTRACT.md
```

## 8. Account-space size

The internal array model needs a stable AccountKey axis.

However, hardcoded unexplained values such as `256` should not be scattered through projection and materialization code.

Preferred rule:

```text
account_key_count = derived from resolved AccountKey table
```

Allowed fallback:

```text
account_key_slot_count = declared once, documented, and checked against resolved AccountKey table
```

The key requirement is that shape decisions must be visible.

A BQN reader should be able to see why the array has its shape.

## 9. Missing, invalid, or unsupported data

The report engine should distinguish:

```text
warning      data exists but may indicate a problem
unavailable  section cannot be computed safely
error        contract violation or impossible state
```

Examples:

- Missing optional future data may be `unavailable`.
- Unknown account names may be `error`.
- Unsupported currency may be `warning` or `unavailable`.
- Mixed-currency totals without conversion support may be `warning` or `unavailable`.
- Empty optional sections should not be confused with failed parsing.

## 10. AI edit boundaries

AI agents may help edit documents, helper code, or experimental branch code.

Canonical TSV files are high-risk and should not be edited by AI unless the user explicitly asks for it and the change is narrow.

Recommended labels for future documentation:

```text
canonical     source of truth; edit carefully
derived       generated or reproducible
helper        optional tooling
experimental  safe workbench area
```

## 11. Dependency boundary

The minimum core target is:

```text
BQN + canonical TSV files -> minimum report
```

Shell, Go, gum, fzf, and other tools may exist as optional helpers.

They should not be required for the smallest report path unless the project deliberately chooses that dependency and documents why.

External process calls should be visible at module boundaries.

## 12. Future journal source sets / year split

The current first-phase canonical file list uses a single physical file:

```text
data/journal.tsv
```

This is the current simple form, not a permanent requirement that all actual records must live in one physical TSV forever.

A future version may split actual records across multiple physical journal files, for example:

```text
data/journal-2026.tsv
data/journal-2027.tsv
data/journal-2028.tsv
```

or:

```text
data/journals/2026.tsv
data/journals/2027.tsv
data/journals/2028.tsv
```

If this happens, the BQN core should treat them as one logical actual-record stream:

```text
logical source: journal
physical files: one or more journal TSV files
layer: actual
```

The projection contract should preserve physical provenance for inspection and debugging:

```text
source_file
source_row
source_id
```

This means year-split journal files can still feed the same `actual` layer without losing the ability to trace a projected amount back to its original file and row.

### 12.1 Date-range and cycle-range loading

The loader should eventually be able to choose the needed physical journal files from a requested report range.

Examples:

- A report for only 2027 may read `journal-2027.tsv`.
- A cycle crossing New Year may read both `journal-2026.tsv` and `journal-2027.tsv`.
- A multi-year comparison may read all relevant journal files.

The internal `Day` axis should be based on the loaded date range or cycle context, not on the physical file boundary.

### 12.2 Balance continuity across files

Splitting journal files creates a balance-continuity question.

Allowed strategies, from simplest to more advanced:

1. Read all historical journal files needed to reconstruct the requested balances.
2. Add explicit opening-balance records at a documented boundary.
3. Use a derived closing snapshot cache, while keeping it non-canonical unless another contract explicitly promotes it.

The preferred first strategy is to keep full-history loading possible and introduce opening balances or snapshots only when the need is clear.

If opening balances are introduced, the contract must prevent double-counting with earlier journal files.

If snapshots are introduced, they must not silently replace canonical journal records in the minimum core path.

### 12.3 Current implementation status

This is a design allowance, not an implemented feature.

The current prototype may still read `journal.tsv` directly.

Future work should avoid scattering the physical filename `journal.tsv` through projection code. Instead, introduce a small source resolver that maps logical source names to physical TSV files.

Suggested future resolver shape:

```text
ResolveSourceSet(base, logical_source, date_range)
  -> list of physical TSV files
```

For the current simple case, the resolver may return:

```text
logical_source = journal
files = data/journal.tsv
```

For a future year-split case, it may return:

```text
logical_source = journal
files = data/journal-2026.tsv data/journal-2027.tsv
```

The important rule is that physical file partitioning should not change the meaning of the projected records.

## 13. First-phase non-goals

This section records what the first phase (current prototype under `src_next/`)
does **not** require. These items are not bugs — they are deliberately deferred.

The first phase does not require the following:

- currency conversion
- exchange-rate gain/loss reporting
- separate Currency axis
- event-first canonical storage
- tax export
- full double-entry export
- automatic rewriting of canonical TSV files
- `budget_alloc.tsv` projection in `src_next` Phase 7
- report sections in `src_next` Phase 7 (the prototype prints cube sanity, not reports)
- year-split journal source resolver implementation (design allowed, not implemented)
- derived snapshot cache
- `incomeAnchor` cycle resolution
- `calendarMonth` cycle resolution

Future journal source sets (Section 12) are allowed by design but not implemented
in the current prototype. The current simple path reads `journal.tsv` directly.
The first phase should not accidentally require year-split journal support.
