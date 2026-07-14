# Daily Trend Observation Consistency Decision

Status: current decision / pre-runtime temporal property
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Exit: revise or archive after an explicit Daily Trend temporal contract and runtime slice consume this decision

## Decision

The first protected temporal property for the next Daily Trend runtime work is:

```text
observation consistency
```

This decision does not choose between:

1. fixed historical observation,
2. present-knowledge retrospective projection.

Those candidate meanings remain unresolved in `docs/DAILY_TREND_TEMPORAL_SEMANTICS.md`.

This decision also does not authorize a runtime change by itself.

## Why this property comes first

Current characterization shows more than historical instability.

A Daily Trend row can combine:

```text
D = row coordinate date
L = report-local latest-journal date
C = cycle boundary
```

in one rendered row.

PR #78 characterizes that coordinate-local terms stay tied to `D` while a shared future-income contribution changes when report-local `L` advances:

```text
as_of:
  2026-01-03 -> 2026-01-06

2026-01-02 days_left:
  9 -> 9

2026-01-03 days_left:
  8 -> 8

future_contribution for both historical rows:
  900 -> 0
```

The current implementation therefore needs a property that can judge temporal frame composition before deciding whether historical rows should be fixed or intentionally replayed.

## Protected property

For Daily Trend, observation consistency means:

> Every time-sensitive term must have an explainable dependency on a named temporal frame, and combinations of distinct frames must be intentional rather than accidental consequences of an implicit local clock.

This does **not** mean all values must use one global date.

`docs/TIME_AS_AXIS.md` remains authoritative that coordinate time, observation time, period boundaries, system time, data cutoffs, and other temporal meanings are distinct.

The property is satisfied only when the dependency can be stated explicitly, for example:

```text
coordinate-relative term -> D
observation-relative term -> O
period-bound term         -> C
```

where:

```text
D = row coordinate
O = named observation or replay frame
C = cycle / period boundary
```

A term may depend on more than one frame when the contract requires it, but that composition must be explicit.

## What this decision rejects

This decision rejects the following as a sufficient temporal contract:

```text
use whichever latest journal date is locally available
```

An implicit local latest-journal date is not automatically equivalent to:

- row coordinate `D`,
- canonical observation `as_of`,
- `last_recorded_on`,
- `data_cutoff`,
- cycle end,
- replay cutoff.

The same helper shape or the same variable name also does not prove shared semantic meaning across report sections.

## Current Daily Trend evidence

Current `src_next/daily_trend.bqn` computes a report-local `as_of` from `LatestActualDateInCycle`.

It then computes `planned_future_income` once outside the per-row loop using that report-local `as_of` cutoff.

Inside the per-row loop, coordinate-local values use row date `dn`, including:

```text
days_left = cycle_end_exclusive - dn
```

while:

```text
fund = liquid + planned_future_income - reserve
```

receives the shared report-local future-income scalar.

PR #78 characterizes the observable consequence without changing runtime behavior.

This evidence is sufficient to choose observation consistency as the first property, but not sufficient to choose Candidate A or Candidate B.

## Relationship to other candidate properties

### Historical stability

Not selected first.

Protecting historical stability now would bias the unresolved semantic choice toward fixed historical observation.

Historical stability remains a candidate property after the observation/replay frame is explicit.

### Cross-domain independence

Not selected first.

Unrelated journal Events can currently move local clocks and affect other report meanings. That coupling matters, but removing one coupling does not by itself define the temporal frame of a row.

Cross-domain independence remains a candidate property after frame dependencies are mapped.

### Period containment

Not selected first.

Period leaks are already separately characterized, including Outlook behavior. They should remain finite independent slices rather than being bundled into Daily Trend frame work.

### Auditability and reproducibility

Not selected first.

Both are expected to improve when the temporal frame is explicit, but neither alone decides whether the intended frame is historical observation or retrospective replay.

## Immediate consequence for the next finite slice

Before a runtime fix, map Daily Trend terms to their current temporal dependencies.

At minimum inspect:

```text
liquid
reserve
planned_future_income
fund
days_left
daily
day_var
day_sav
day_fixed
delta
```

Classify each dependency using named symbols such as:

```text
D = row coordinate
O = explicit observation / replay frame, if present
C = cycle / period boundary
L = current implicit local latest-journal clock
```

The next slice should remain finite and should not introduce:

- a global `as_of`,
- a `TemporalFrame` object,
- helper deduplication,
- source TSV changes,
- a bundled runtime fix.

## Runtime gate

A later runtime slice may proceed only after it can state:

1. which Daily Trend terms are coordinate-relative,
2. which are observation/replay-relative,
3. which are period-bound,
4. whether any current `L` dependency is intentional,
5. whether the runtime change preserves Candidate A/B neutrality or explicitly chooses one candidate.

Until then, current behavior remains characterized rather than corrected.
