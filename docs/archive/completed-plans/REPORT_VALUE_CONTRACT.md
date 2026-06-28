# Report Value Contract

Status: draft
Branch: `refactor/cycle-ledger-core`
Scope: data shape returned by report sections before rendering

## 1. Purpose

This document defines the value shape that report sections should produce before text formatting, TSV export, HTML rendering, or notebook reading.

The goal is to keep computation separate from display.

A report section should first produce inspectable data.

Renderers may then display that data as CLI text, derived TSV, HTML, Pluto.jl notebook tables, or other reader surfaces.

## 2. SectionResult

Each report section should conceptually return a `SectionResult`.

Suggested shape:

```text
name
status
summary
table
messages
sources
meta
```

This is a conceptual contract, not necessarily a required BQN namespace layout.

## 3. Fields

### 3.1 `name`

Stable section identifier.

Examples:

```text
current_cycle_summary
remaining_until_next_income
food_daily_remaining
plan_vs_actual_difference
incomplete_planned_items
checks_warnings_unavailable
```

### 3.2 `status`

Section status.

Allowed initial values:

```text
ok
warning
unavailable
error
```

### 3.3 `summary`

Small human-scale summary value or summary table.

The summary should be useful for CLI display.

### 3.4 `table`

Structured tabular data for deeper reading or export.

The table should not depend on final display formatting.

### 3.5 `messages`

Human-readable notes, warnings, or error descriptions.

Messages should explain why a section is warning, unavailable, or error.

### 3.6 `sources`

Optional source references used to compute the section.

Conceptual examples:

```text
source files
source row ranges
cycle id
projection group
```

This helps debugging and AI-assisted maintenance.

### 3.7 `meta`

Optional machine-readable metadata.

Examples:

```text
currency policy applied
axis shape
layer indexes
report date
```

## 4. Rendering rule

Rendering should consume `SectionResult` values.

The renderer should not decide financial meaning.

Recommended flow:

```text
report state
  -> SectionResult values
  -> renderer
```

Renderers may include:

- minimum CLI text report
- derived TSV exports
- static HTML report
- Pluto.jl notebook reader

## 5. Derived TSV rule

Derived TSV files may be emitted from SectionResult tables or other documented report-state exports.

Derived TSV files are reader inputs, not canonical data.

A derived TSV should ideally include enough columns to preserve its meaning without relying on terminal formatting.

## 6. Multi-currency rule

If a section includes multiple currencies, it must not collapse them into one number unless a documented conversion rule exists.

First-phase behavior:

- JPY-only sections may summarize normally.
- currency-separated balances may display by AccountKey or by currency group.
- mixed-currency total sections should be `warning` or `unavailable` unless conversion is explicitly supported.

## 7. First sections

The first protected sections are:

```text
current_cycle_summary
remaining_until_next_income
food_daily_remaining
plan_vs_actual_difference
incomplete_planned_items
checks_warnings_unavailable
```

Each of these should eventually have a documented SectionResult shape.

## 8. Non-goals

This contract does not require:

- final CLI layout
- final HTML layout
- Pluto.jl notebook implementation
- all historical report sections
- full public schema freeze

It only defines the first layer of data returned by report sections.
