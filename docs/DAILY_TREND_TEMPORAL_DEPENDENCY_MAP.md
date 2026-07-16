# Daily Trend Temporal Dependency Map

Status: current implementation companion
Owner: report
Canonical: no; canonical temporal policy remains `docs/TIME_AS_AXIS.md`
Current route: `docs/DAILY_TREND_TEMPORAL_CURRENT.md`
Exit: revise only when Daily Trend runtime dependencies materially change

## Purpose

This document is the compact current dependency map for `src_next/daily_trend.bqn` after PRs #101, #105, #110, and #120.

It records what the current runtime depends on. It is not a new implementation plan and does not authorize another temporal slice.

The former detailed 700-plus-line revision history is preserved at:

- `docs/archive/completed-plans/DAILY_TREND_TEMPORAL_DEPENDENCY_MAP_DETAILED_HISTORY.md`

## Current model

```text
S = source snapshot supplied to this run
D = rendered row coordinate
P = predecessor rendered row coordinate
O_row = row observation rule, currently D
O_header = report observation carried to the human header
C = selected cycle boundary
L = local recorded-actual frontier context
R = rendered row coordinate set
M = plan/journal identity state visible at D
K = historical knowledge boundary, unavailable / not claimed
```

The selected product is current-source coordinate replay:

```text
O_row = D
K is unavailable
S is current source state, not historical knowledge replay
```

A past row may therefore change when the supplied source snapshot changes. The report must not describe such a row as “what was known at D”.

## Current ownership

### Row membership

```text
R = accepted actual projection coordinates restricted to C
    -> sorted
    -> deduplicated
```

When no accepted in-cycle actual coordinate exists, `cycle.start` is the explicit empty-state anchor.

`L` is frontier context. It does not own ordinary row membership and cannot reintroduce a coordinate rejected by the accepted actual projection.

### Row-local calculations

| Term | Current dependency | Meaning |
|---|---|---|
| row coordinates | `R_actual + A_empty + C` | accepted in-cycle actual coordinates, or `cycle.start` when empty |
| `liquid` | `S + D + C` | cumulative actual state at row coordinate |
| cumulative savings | `S + D + C` | savings accounts from the same cumulative row |
| planned future income | `S + D + C` | plan dates `> D` and `< C.end_exclusive` |
| ordinary reserve | `S + D + C + M` | admitted plan Posting IR money joined by `source_row`; row-local plan/journal completion identity evidence |
| ordinary fund | `S + D + C + M` | `liquid + planned_future_income - reserve` |
| `days_left` | `D + C` | `C.end_exclusive - D` |
| ordinary daily amount | `S + D + C + M` | ordinary fund divided by remaining days |
| day actual terms | `S + D + C` | actual values at row coordinate |
| `delta` | `S + D + P + C + R + M` | current row daily minus predecessor row daily |
| VM `as_of` | `L` | local record-frontier context only |
| human header days remaining | `O_header + C` | explicit report observation carried by `report_today` |

### Header clock

PR #120 separated the human header observation from internal frontier context:

```text
report_today
  -> daily_trend.BuildAt(ctx, report_today)
  -> vm.header_O
  -> header days remaining
```

`O_header` does not replace `O_row = D`, `L`, cycle selection, or reserve semantics.

`--outlook-as-of` remains Outlook-specific.

### Preserved edge branch

The code still contains an empty-identity reserve branch whose explicit-empty syntax path was closed by PR #110.

Do not generalize that branch to ordinary 5-field reserve behavior. Other reachability is not claimed by this map.

## Current conclusions

- The former ordinary-row mixture of coordinate-local values with one shared `L` future-income cutoff has been removed.
- Backdated changes in source snapshot `S` may still change a past coordinate row.
- `L` remains finite and named: VM frontier context and the preserved edge branch.
- Ordinary reserve remains identity-sensitive through `M`, while its numeric owner is admitted plan Posting IR.
- Applicable rejected or ambiguous plan evidence fails the section closed instead of becoming zero.
- Delta remains second-order because it depends on predecessor selection and row set `R`.
- Historical knowledge boundary `K` is not implemented.

## Current evidence

- `src_next/daily_trend.bqn`
- `src_next/report.bqn`
- `src_next/daily_trend_plan.bqn`
- `tests/test_src_next_daily_trend_header_as_of_sensitivity.bqn`
- `tests/test_src_next_daily_trend_plan_numeric_owner.bqn`
- `fixtures/daily-trend-plan-numeric-owner-target/`
- `checks/check-src-next-daily-trend-plan-numeric-owner.sh`

## Archived rationale

Read these only for historical investigation:

- `docs/archive/completed-plans/DAILY_TREND_CURRENT_SOURCE_COORDINATE_REPLAY_DECISION.md`
- `docs/archive/completed-plans/DAILY_TREND_OBSERVATION_CONSISTENCY_DECISION.md`
- `docs/archive/completed-plans/DAILY_TREND_KNOWLEDGE_BOUNDARY_DECISION.md`
- `docs/archive/completed-plans/DAILY_TREND_ROW_MEMBERSHIP_PRODUCER_DECISION.md`
- `docs/archive/completed-plans/DAILY_TREND_HEADER_TIME_OWNER_DECISION.md`
- `docs/archive/completed-plans/DAILY_TREND_HEADER_CONCRETE_TIME_CARRIER_DECISION.md`
- `docs/archive/completed-plans/DAILY_TREND_EXPLICIT_EMPTY_PLAN_IDENTITY_MEANING_DECISION.md`
- `docs/archive/completed-plans/DAILY_TREND_TEMPORAL_DEPENDENCY_MAP_DETAILED_HISTORY.md`

## Non-goals

This map does not select or authorize:

- historical immutability;
- a stored knowledge boundary `K`;
- a generic Daily Trend `BuildAt(ctx, O)` API;
- a broad `L -> D`, `L -> O`, or `L -> K` rewrite;
- reserve redesign;
- a shared temporal kernel;
- another runtime slice without a separately justified user need.
