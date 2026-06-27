# Cycle Ledger Design Decisions

Status: draft
Branch: `refactor/cycle-ledger-core`
Scope: compact decision log for the current design direction

## 1. Core direction

The project remains centered on:

```text
canonical TSV + BQN array engine + small report surface
```

The first-phase goal is not to build a general accounting application.

The goal is to build a cycle-oriented household-accounting report engine.

## 2. Required core path

The minimum core path should remain:

```text
BQN + canonical TSV files -> minimum report
```

Shell, Go, gum, fzf, Pluto.jl, HTML, and other tools may exist, but they are optional helpers or reader layers unless explicitly promoted later.

## 3. First-phase array shape

The first-phase BQN core shape is:

```text
Day × AccountKey × Layer
```

This replaces the earlier shorthand:

```text
Day × Account × Layer
```

`AccountKey` is the resolved account identity used by the cube.

## 4. Currency decision

Currency-separated balances are allowed without adding a separate Currency axis in the first phase.

First-phase policy:

```text
AccountKey = (Account, Currency)
```

Examples:

```text
assets:bank/JPY
assets:bank/USD
assets:cash/EUR
```

Different currencies must not be silently mixed into one numeric balance.

Currency conversion, exchange-rate gain/loss reporting, and a separate Currency axis are out of scope for the first phase.

A future version may introduce:

```text
Day × Account × Layer × Currency
```

only if currency-level reporting becomes a primary requirement.

## 5. Projection decision

Projection should be treated as a first-class design object.

Conceptual flow:

```text
source record
  -> account resolution
  -> currency resolution
  -> AccountKey resolution
  -> day/cycle resolution
  -> layer assignment
  -> delta output
```

The first implementation should validate projection sanity before building polished reports.

## 6. Report value decision

Report sections should produce data before formatting.

Conceptual section result:

```text
name
status
summary
table
messages
sources
meta
```

Renderers may consume these values for CLI text, TSV export, HTML, Pluto.jl, or other reader layers.

## 7. Reader layer decision

BQN core should produce trustworthy report data.

Reader layers may read derived TSV files or documented report-state exports.

Reader layers must not become canonical data.

Reader layers must not be required for the minimum report path.

## 8. Current design documents

The current design set is:

```text
docs/ARCHITECTURE_NEXT.md
docs/DATA_CONTRACT.md
docs/AXIS_CONTRACT.md
docs/PROJECTION_CONTRACT.md
docs/REPORT_CONTRACT.md
docs/REPORT_VALUE_CONTRACT.md
docs/MIGRATION_PLAN.md
docs/CYCLE_LEDGER_DECISIONS.md
```

## 9. Implementation posture

Implementation should not begin with a full report rewrite.

Recommended first implementation candidate:

```text
read canonical TSV
resolve AccountKey table
produce projection rows
materialize a tiny cube
print projection sanity checks
```

Only after the array is standing should the project add user-facing report sections.
