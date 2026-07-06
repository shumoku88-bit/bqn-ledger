# Daily Trend Temporal Dependency Map

Status: current observation / pre-runtime dependency map
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Exit: revise or archive after an explicit Daily Trend temporal contract and runtime slice consume this map

## Purpose

This docs-only map follows `docs/DAILY_TREND_OBSERVATION_CONSISTENCY_DECISION.md`.

It classifies current `src_next/daily_trend.bqn` terms by the temporal frames and matching state they actually consume before any runtime change.

This map does not choose between:

1. fixed historical observation,
2. present-knowledge retrospective projection.

It also does not authorize a runtime fix.

## Revision note

The first version of this map broadly classified reserve as:

```text
reserve = f(D, L, C)
```

That was too broad.

A follow-up characterization attempt expected an ordinary 5-field fixed plan reserve to change from `300` to `0` when an unrelated later journal Event advanced local `L`. The first dedicated run instead reported:

```text
Assertion failed: expected 0 but got 300
```

Inspection of `src_next/plan_journal_overlap.bqn` explains why.

`PlanId` does not return an empty identity merely because a plan lacks `plan_id=` metadata. For ordinary 5-field rows it falls back to the first five TSV fields.

Therefore ordinary 5-field plans follow the non-empty identity branch in current Daily Trend reserve logic.

This revision separates:

```text
ordinary fallback-identity reserve path
```

from:

```text
empty-identity edge path
```

and removes the unsupported claim that normal reserve behavior is simply `f(D, L, C)`.

## Symbols

```text
D = current trend-row coordinate date
P = predecessor trend-row coordinate used by delta
O = explicit observation or replay frame
C = cycle / period boundary
L = current report-local latest-journal clock from LatestActualDateInCycle
R = current trend-row coordinate set / ordering
M = plan/journal identity matching state visible at row D
E = empty-identity edge path
```

Important:

```text
O is not currently supplied as an explicit Daily Trend observation/replay frame.
```

The current variable named `as_of` is derived locally from `LatestActualDateInCycle`; this map therefore classifies it as `L`, not as proof of canonical observation time `O`.

## High-level result

Current Daily Trend is not one temporal frame.

At least these structures are present:

```text
D
C
L
R
M
```

and `delta` additionally depends on predecessor row `P`.

The strongest currently characterized row-frame mixing remains:

```text
coordinate-local actual state
  +
report-local planned-future-income cutoff
  +
cycle boundary
```

inside one historical row.

The reserve path is more conditional than the first map claimed and must be split by identity semantics.

## Dependency table

| Term | Current dependency | Current mechanism | Observation |
|---|---|---|---|
| `trend row coordinate set` | `R + L + C` | actual posting dates plus local `as_of`, then sort/deduplicate and cycle filter | local clock can add a coordinate row |
| `date_str` | `D + R` | row `dn` resolved through `trend_dns` / `trend_dates` | presentation coordinate follows row set |
| `liquid` | `D + C` | cumulative actual cube slice at day offset from cycle start | coordinate-local cumulative actual state |
| cumulative `sav` | `D + C` | same cumulative actual cube mechanism | coordinate-local cumulative actual state |
| `planned_future_income` | `L + C` | plan date `> as_of_dn` and `< cycle_end_exclusive` | shared report-local scalar reused across rows |
| ordinary 5-field `reserve` | `D + C + M` | plan window uses `D`; journal identities visible through `D`; ordinary rows receive non-empty fallback identity | no direct `L` dependence established for this path |
| empty-identity reserve edge | `D + L + C + E` | empty identity branch compares plan date with `last_act_dn`, whose current expression includes local `as_of_dn` | edge path exists statically; ordinary 5-field reachability is not implied |
| ordinary-path `fund` | `D + L + C + M` | `liquid + planned_future_income - reserve` | still mixes row-local state with shared `L` cutoff through future income |
| `days_left` | `D + C` | `cycle_end_exclusive - D` | coordinate-local denominator term |
| ordinary-path `daily` | `D + L + C + M` | `fund / days_left` | inherits mixed fund plus coordinate denominator |
| `day_var` | `D + C` | actual slice for row day | coordinate-local day actual |
| `day_sav` | `D + C` | actual slice for row day | coordinate-local day actual |
| `day_fixed` | `D + C` | actual slice for row day | coordinate-local day actual |
| `delta` | `D + P + L + C + R + M` | current `daily` minus previous rendered row `daily` | also depends on predecessor and row ordering |
| VM `as_of` | `L` | `LatestActualDateInCycle(base, cy)` | local clock, not explicit `O` |
| human header `days_left` | `L + C` | `cycle_end_exclusive - vm.as_of` | header clock differs from historical row `D` |

## Evidence by term

### 1. Trend coordinate set: `R + L + C`

Current row coordinates are built from valid actual posting dates and local `as_of`:

```text
trend_dates_all = j_dates + <as_of>
```

They are then sorted, deduplicated, and filtered to the selected cycle.

Therefore local `L` can participate in row-coordinate membership itself.

### 2. `liquid`: `D + C`

The actual cube is cumulatively summed and indexed by row day offset:

```text
d = D - C.start
cum = cumulative_actual[d]
liquid = sum liquid accounts from cum
```

Once row `D` exists, the local liquid formula does not directly consume `L`.

### 3. cumulative `sav`: `D + C`

Cumulative saving is read from the same cumulative actual row as liquid, over savings accounts.

### 4. `planned_future_income`: `L + C`

Current plan rows are admitted when:

```text
plan.date > L
plan.date < C.end_exclusive
```

The result is computed once outside the per-row loop:

```text
planned_future_income = f(L, C)
```

Existing characterization shows the visible effect when `L` advances past a future-income plan date:

```text
future contribution: 900 -> 0
```

while the same historical row coordinate remains present.

### 5. ordinary 5-field `reserve`: `D + C + M`

Current reserve logic first filters journal identity evidence through row `D`:

```text
journal.date <= D
```

Candidate plans are row-local and period-bound:

```text
plan.date >= D
plan.date < C.end_exclusive
```

The critical correction is identity extraction.

For an ordinary 5-field plan without `plan_id=` metadata, current `PlanId` falls back to the first five fields rather than returning empty identity.

Therefore the ordinary path reaches the non-empty identity branch:

```text
plan remains open when its fallback identity is not present
among journal identities visible at D
```

A later unrelated Event can advance `L` without matching that plan identity.

The first dedicated reserve run observed exactly the contradiction to the earlier hypothesis:

```text
expected after reserve: 0
observed after reserve: 300
```

So normal 5-field reserve must not be documented as direct `L` dependence on current evidence.

### 6. empty-identity reserve edge: `D + L + C + E`

The code still contains an empty-identity branch.

That branch compares plan date with `last_act_dn`, whose current expression appends local `as_of_dn`:

```text
last_act_dn = last((journal dates <= D) + <as_of_dn>)
```

Under the current expression shape, the appended local value is the final element, so the branch can consume `L`.

But this is an edge-path statement.

It does not imply ordinary 5-field plans use that path.

Reachability and intended semantics of explicit empty identity should be characterized separately before any broader conclusion.

### 7. ordinary-path `fund`: `D + L + C + M`

Current formula:

```text
fund = liquid + planned_future_income - reserve
```

For the ordinary identity path:

```text
liquid                = f(D, C)
planned_future_income = f(L, C)
reserve               = f(D, C, M)
```

Therefore:

```text
fund = f(D, L, C, M)
```

The mixed `L` path remains through `planned_future_income` even after correcting reserve semantics.

### 8. `days_left`: `D + C`

Current formula:

```text
days_left = max(0, C.end_exclusive - D)
```

Existing characterization shows historical `days_left` remains tied to row `D` when local `L` advances.

### 9. ordinary-path `daily`: `D + L + C + M`

Current formula:

```text
daily = floor(fund / max(1, days_left))
```

Because ordinary-path `fund` contains the shared `planned_future_income(L, C)` term while `days_left` is coordinate-local, current `daily` still mixes row and report-local frames.

### 10. day actual terms: `D + C`

The following index the actual slice for row day:

```text
day_var
day_sav
day_fixed
```

No direct `L` cutoff is consumed in their current local formulas.

### 11. `delta`: `D + P + L + C + R + M`

`delta` is computed after trend rows exist:

```text
current daily - previous rendered row daily
```

It inherits the temporal and matching dependencies of `daily`, and predecessor selection depends on sorted/deduplicated row set `R`.

A local clock shift can affect delta through at least:

1. mixed daily values,
2. row-set membership and predecessor relation.

### 12. human header: `L + C`

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

This may be intentional presentation, but the distinction should remain explicit.

## Current absence of explicit `O`

No term in this map is classified as consuming an explicit Daily Trend observation/replay frame `O`.

That does not mean the report has no observation-like behavior.

It means Daily Trend derives local `L` and names the VM field `as_of`, but current implementation does not receive an explicit observation/replay frame whose semantic contract is established for Daily Trend.

Therefore:

```text
current local L
  != automatically explicit O
```

## Findings

### Finding A: planned future income remains the characterized cross-frame path

The strongest directly characterized row-frame mixing remains:

```text
historical D
+
shared planned_future_income(L, C)
+
days_left(D, C)
```

This is sufficient to keep the observation-consistency question open.

### Finding B: the first reserve map overgeneralized an edge branch

The earlier map treated the empty-identity branch as representative of ordinary plan rows.

That was incorrect because ordinary 5-field rows receive fallback identity.

### Finding C: identity semantics are part of reserve dependency

Reserve is not only a date-cutoff problem.

For ordinary rows it also depends on which plan identity is considered matched by journal identities visible at row `D`.

This is captured as `M`.

### Finding D: row membership itself consumes `L`

Because local `as_of` is appended before row sort/deduplication, `L` can influence which trend rows exist.

### Finding E: `delta` is a second-order consumer

Delta compares adjacent rendered rows and therefore depends on predecessor selection and row ordering in addition to each row's own value dependencies.

### Finding F: no explicit `O` path is present

Candidate A/B remains unresolved.

## What this map does not decide

This map does not decide:

- that historical rows must be stable,
- that retrospective replay is intended,
- that `D` must equal `O`,
- that local `L` must be replaced by `ctx.as_of`,
- that ordinary reserve is wrong,
- that the empty-identity edge path is reachable in normal data,
- that `planned_future_income` is wrong,
- that row coordinates should exclude local `L`,
- that all sections should share one date helper.

## Recommended next finite slices

### Immediate verification

Rerun the corrected dedicated reserve test after changing its expectation from the disproved `300 -> 0` hypothesis to the observed ordinary-path stability:

```text
reserve: 300 -> 300
```

Do not merge that characterization until the corrected test actually passes.

### After that

Choose one finite question, not a bundled redesign:

1. characterize explicit empty `plan_id=` reachability and behavior, or
2. return to the already characterized `planned_future_income(L, C)` path and decide what explicit observation/replay contract it should obey.

The second path is more directly connected to current observed historical-row instability.

Keep either slice separate from:

- broad runtime repair,
- global `as_of`,
- `TemporalFrame`,
- helper deduplication,
- source TSV changes.

## Current conclusion

The corrected approximate shape is:

```text
row coordinates             = f(R, L, C)
liquid                       = f(D, C)
ordinary reserve             = f(D, C, M)
empty-identity reserve edge  = f(D, L, C, E)
planned_future_income        = f(L, C)
ordinary-path fund           = f(D, L, C, M)
days_left                    = f(D, C)
ordinary-path daily          = f(D, L, C, M)
day actual terms             = f(D, C)
delta                        = f(D, P, L, C, R, M)
header days_left             = f(L, C)
```

This correction preserves the broader observation-consistency problem while removing an unsupported claim about ordinary reserve behavior.

The next question should still be answered by one narrow characterization at a time, not by a bundled temporal redesign.
