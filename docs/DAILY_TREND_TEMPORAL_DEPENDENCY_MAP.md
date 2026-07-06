# Daily Trend Temporal Dependency Map

Status: current observation / pre-runtime dependency map
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Exit: revise or archive after an explicit Daily Trend temporal contract and runtime slice consume this map

## Purpose

This docs-only map follows the protected-property decision in `docs/DAILY_TREND_OBSERVATION_CONSISTENCY_DECISION.md`.

It classifies current `src_next/daily_trend.bqn` terms by the temporal frames they actually consume before any runtime change.

This map does not choose between:

1. fixed historical observation,
2. present-knowledge retrospective projection.

It also does not authorize a runtime fix.

## Symbols

```text
D = current trend-row coordinate date
P = predecessor trend-row coordinate used by delta
O = explicit observation or replay frame
C = cycle / period boundary
L = current report-local latest-journal clock from LatestActualDateInCycle
R = current trend-row coordinate set / ordering
```

Important:

```text
O is not currently supplied as an explicit Daily Trend observation/replay frame.
```

The current variable named `as_of` is derived locally from `LatestActualDateInCycle`; this map therefore classifies it as `L`, not as proof of canonical observation time `O`.

## High-level result

Current Daily Trend is not one temporal frame.

Its row values currently combine at least:

```text
D
C
L
R
```

and `delta` additionally depends on the predecessor row `P`.

The strongest result is:

```text
coordinate-local actual terms
  +
row-local reserve logic
  +
report-local future-income cutoff
  +
cycle boundary
```

are composed inside one row.

This confirms why observation consistency was selected before historical stability or a runtime fix.

## Dependency table

| Term | Current dependency | Current mechanism | Observation |
|---|---|---|---|
| `trend row coordinate set` | `R + L + C` | actual posting dates plus local `as_of`, then sort/deduplicate and cycle filter | the report-local clock can add a coordinate row |
| `date_str` | `D + R` | row `dn` is resolved back through `trend_dns` / `trend_dates` | presentation coordinate follows current row set |
| `liquid` | `D + C` | cumulative actual cube slice at day offset from cycle start | coordinate-local cumulative actual state |
| `saving cumulative` (`sav`) | `D + C` | same cumulative actual cube mechanism | coordinate-local cumulative actual state |
| `planned_future_income` | `L + C` | plan date `> as_of_dn` and `< cycle_end_exclusive` | one shared report-local scalar reused across rows |
| `reserve` | `D + L + C` | plan date window uses `D`; completed PID evidence is filtered through `D`; no-PID branch compares plan date with local `as_of_dn` | mixed row-local and report-local frame |
| `fund` | `D + L + C` | `liquid + planned_future_income - reserve` | explicit composition of coordinate-local and report-local terms |
| `days_left` | `D + C` | `cycle_end_exclusive - D` | coordinate-local denominator term |
| `daily` | `D + L + C` | `fund / days_left` | inherits mixed `fund` plus coordinate denominator |
| `day_var` | `D + C` | actual slice for row day | coordinate-local day actual |
| `day_sav` | `D + C` | actual slice for row day | coordinate-local day actual |
| `day_fixed` | `D + C` | actual slice for row day | coordinate-local day actual |
| `delta` | `D + P + L + C + R` | current `daily` minus previous rendered row `daily` | depends on row ordering and both rows' mixed daily values |
| VM `as_of` | `L` | `LatestActualDateInCycle(base, cy)` | local clock, not explicit `O` |
| human header `days_left` | `L + C` | `cycle_end_exclusive - vm.as_of` | header clock differs from each historical row's `D` |

## Evidence by term

### 1. Trend coordinate set: `R + L + C`

Current row coordinates are built from valid actual posting dates and the local `as_of` value:

```text
trend_dates_all = j_dates + <as_of>
```

They are then sorted, deduplicated, and filtered to the selected cycle.

Therefore `L` does not only affect row values. It can participate in row-coordinate membership itself.

This is a separate dependency from the already characterized shared future-income scalar.

### 2. `liquid`: `D + C`

The actual cube is materialized as a day-by-account slice, cumulatively summed, and indexed by the row day offset:

```text
d = D - C.start
cum = cumulative_actual[d]
liquid = sum liquid accounts from cum
```

Within the current implementation, once row `D` exists, `liquid` does not directly consume local `L`.

### 3. Cumulative saving: `D + C`

`sav` is computed from the same cumulative actual row as `liquid`, over savings accounts.

It therefore has the same direct temporal shape:

```text
D + C
```

### 4. `planned_future_income`: `L + C`

Current plan rows are admitted when:

```text
plan.date > L
plan.date < C.end_exclusive
```

The resulting amount is computed once outside the per-row loop.

Therefore it is a shared report-local scalar:

```text
planned_future_income = f(L, C)
```

PR #78 characterizes the visible consequence:

```text
L advances
  -> future contribution changes 900 -> 0
  -> same shared change appears in multiple historical rows
```

### 5. `reserve`: `D + L + C`

Current reserve logic contains several temporal relations.

First, journal completion evidence is filtered through row coordinate `D`:

```text
journal.date <= D
```

Second, candidate plans are row-local and period-bound:

```text
plan.date >= D
plan.date < C.end_exclusive
```

Third, the no-PID branch compares plan date with `last_act_dn`, whose current expression appends `as_of_dn` and selects the final element:

```text
last_act_dn = last((journal dates <= D) + <as_of_dn>)
```

Under the current expression shape, the appended local `as_of_dn` is the final element. The no-PID comparison therefore consumes `L`:

```text
plan.date >= L
```

The result is not a simple row-coordinate reserve:

```text
reserve = f(D, L, C)
```

This is a static dependency observation. It is not yet a semantic judgment about whether the composition is intended.

### 6. `fund`: `D + L + C`

Current formula:

```text
fund = liquid + planned_future_income - reserve
```

Substituting direct dependencies:

```text
liquid                = f(D, C)
planned_future_income = f(L, C)
reserve               = f(D, L, C)
```

gives:

```text
fund = f(D, L, C)
```

This is the clearest current row-frame composition point.

### 7. `days_left`: `D + C`

Current formula:

```text
days_left = max(0, C.end_exclusive - D)
```

PR #78 characterizes that historical `days_left` remains tied to row `D` when local `L` advances.

### 8. `daily`: `D + L + C`

Current formula:

```text
daily = floor(fund / max(1, days_left))
```

Because:

```text
fund      = f(D, L, C)
days_left = f(D, C)
```

current `daily` inherits:

```text
D + L + C
```

This explains how a historical row can preserve `days_left` while its `daily` changes later.

### 9. Day actual terms: `D + C`

The following terms index the actual slice for the row day:

```text
day_var
day_sav
day_fixed
```

They are direct row-coordinate terms:

```text
D + C
```

No direct `L` cutoff is consumed in their current local formulas.

### 10. `delta`: `D + P + L + C + R`

`delta` is computed after all trend rows exist:

```text
current daily - previous rendered row daily
```

Each `daily` already depends on:

```text
D + L + C
```

The predecessor is determined by the sorted/deduplicated row set `R`.

Therefore `delta` has an additional structural dependency:

```text
D + P + L + C + R
```

A local clock shift can affect `delta` through at least two paths:

1. changing mixed `daily` values,
2. participating in current row-set membership.

This map does not yet characterize those two paths separately.

### 11. Human header: `L + C`

`FormatHuman` computes header days remaining from:

```text
C.end_exclusive - vm.as_of
```

where VM `as_of` is current local `L`.

The section can therefore display:

```text
historical row days_left = f(D, C)
header current days_left = f(L, C)
```

This difference may be intentional presentation, but its frame should remain explicit.

## Current absence of explicit `O`

No term in this map is classified as consuming explicit Daily Trend observation/replay frame `O`.

That does not mean the report has no observation-like behavior.

It means current Daily Trend derives a local clock `L` and names the VM field `as_of`, but the current implementation does not receive an explicit observation/replay frame whose semantic contract is established for Daily Trend.

Therefore this map preserves the distinction:

```text
current local L
  != automatically explicit O
```

## Findings

### Finding A: PR #78 frame mixing is broader than one scalar

PR #78 directly characterizes `planned_future_income` contribution mixing, but static dependency tracing shows that `reserve` also combines row-local and report-local temporal relations.

This does not prove both are bugs.

It proves the next runtime decision should not treat `planned_future_income` as the only temporal dependency without reviewing reserve semantics.

### Finding B: row membership itself consumes `L`

Because local `as_of` is appended to actual posting dates before row sorting and deduplication, `L` can influence which trend coordinate rows exist.

A runtime change to `L` can therefore affect both:

```text
row values
row set / predecessor relation
```

### Finding C: `delta` is a second-order temporal consumer

`delta` does not merely inherit one row's frame.

It compares adjacent rendered rows, so it also depends on row ordering and predecessor selection.

### Finding D: no explicit `O` path is present

Current Daily Trend uses a local value named `as_of`, but this map finds no explicit Daily Trend observation/replay frame input.

The Candidate A/B question therefore remains unresolved.

## What this map does not decide

This map does not decide:

- that historical rows must be stable,
- that retrospective replay is intended,
- that `D` must equal `O`,
- that local `L` must be replaced by `ctx.as_of`,
- that `reserve` is wrong,
- that `planned_future_income` is wrong,
- that the row set should exclude local `L`,
- that all sections should share one date helper.

## Recommended next finite slice

Do not implement a broad runtime fix yet.

The strongest next slice is one focused characterization around the newly exposed `reserve` dependency:

```text
same historical row D
same relevant fixed plan
advance unrelated later journal date L
observe whether reserve changes through the no-PID branch
```

Why this one first:

1. PR #78 already characterizes shared future-income contribution.
2. This map statically exposes a second `D + L + C` path in `reserve`.
3. A narrow fixture can determine whether that path is observable before choosing Candidate A or B.

Keep that slice separate from:

- runtime repair,
- explicit `O` plumbing,
- `TemporalFrame`,
- helper deduplication,
- source TSV changes.

## Current conclusion

The current Daily Trend dependency shape is approximately:

```text
row coordinates       = f(R, L, C)
liquid                 = f(D, C)
reserve                = f(D, L, C)
planned_future_income  = f(L, C)
fund                   = f(D, L, C)
days_left              = f(D, C)
daily                  = f(D, L, C)
day actual terms       = f(D, C)
delta                  = f(D, P, L, C, R)
header days_left       = f(L, C)
```

This map satisfies the immediate pre-runtime gate from the observation-consistency decision at the level of current static dependencies.

The next question should be answered by one narrow characterization, not by a bundled runtime redesign.
