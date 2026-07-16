# Daily Trend Temporal Current Path

Status: current routing map
Owner: report
Canonical: no; the canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Exit: revise when the Daily Trend runtime meaning changes; detailed implemented decision records may move to archive without replacing this current path

This document is the short current entry point for Daily Trend temporal meaning.

It exists so maintainers and AI assistants do not need to reconstruct the current behavior from a chain of pre-runtime decision records.

## Current contract

Daily Trend currently uses these distinct meanings:

```text
S = source snapshot supplied to this run
D = rendered row coordinate
O_row = row observation rule, currently D
C = selected cycle boundary
L = local recorded-actual frontier context
K = historical knowledge boundary, unavailable / not claimed
```

The current product is **current-source coordinate replay**:

> Using the source snapshot supplied to this run, what does each cycle coordinate `D` look like under a row observation rule tied to `D`?

This is not historical knowledge replay. A past row may change when the current source snapshot changes.

## Current runtime shape

- Ordinary row membership comes from accepted actual projection coordinates restricted to `C`, sorted and deduplicated.
- When no accepted in-cycle actual coordinate exists, `cycle.start` is the explicit empty-state anchor.
- `L` remains record-frontier context and does not own ordinary row membership.
- Row-local future income uses `S + D + C` rather than one shared `L` cutoff.
- The ordinary reserve/fund/daily path is centered on `S + D + C + M`, where `M` is plan/journal identity state visible at `D`.
- Fixed-reserve money comes from admitted plan Posting IR joined to source identity by `source_row`; source evidence owns plan ID and D-local completion.
- Applicable rejected, duplicate, missing, or structurally unjoinable plan evidence fails the section closed with no numeric trend rows.
- `K` is not represented, so the report must not claim “what was known at D”.

## Header clock

The human Daily Trend header has a separate observation owner from the rows:

```text
report entry reads report_today once
  -> daily_trend.BuildAt(ctx, report_today)
  -> header days remaining uses report_today
```

This header observation does not replace row `O_row = D`, internal `L`, cycle selection, or reserve semantics.

`--outlook-as-of` remains Outlook-specific and does not control the Daily Trend header.

## Read order

1. `docs/TIME_AS_AXIS.md` for the canonical temporal principle.
2. This document for the current Daily Trend meaning.
3. `docs/DAILY_TREND_TEMPORAL_DEPENDENCY_MAP.md` when exact runtime dependencies are needed.
4. `docs/archive/completed-plans/DAILY_TREND_CURRENT_SOURCE_COORDINATE_REPLAY_DECISION.md` only when the historical product-selection rationale is needed.

The older unresolved temporal-semantics routing note is archived at:

- `docs/archive/completed-plans/DAILY_TREND_TEMPORAL_SEMANTICS.md`

Completed observation and knowledge-boundary decisions are archived at:

- `docs/archive/completed-plans/DAILY_TREND_OBSERVATION_CONSISTENCY_DECISION.md`
- `docs/archive/completed-plans/DAILY_TREND_KNOWLEDGE_BOUNDARY_DECISION.md`

Completed row-membership ownership is archived at:

- `docs/archive/completed-plans/DAILY_TREND_ROW_MEMBERSHIP_PRODUCER_DECISION.md`

Completed header decisions are archived at:

- `docs/archive/completed-plans/DAILY_TREND_HEADER_TIME_OWNER_DECISION.md`
- `docs/archive/completed-plans/DAILY_TREND_HEADER_CONCRETE_TIME_CARRIER_DECISION.md`

The explicit-empty-plan-identity product decision has completed its lifecycle and is archived at `docs/archive/completed-plans/DAILY_TREND_EXPLICIT_EMPTY_PLAN_IDENTITY_MEANING_DECISION.md`.

## Current code and evidence

- `src_next/daily_trend.bqn`
- `src_next/report.bqn`
- `src_next/daily_trend_plan.bqn`
- `tests/test_src_next_daily_trend_header_as_of_sensitivity.bqn`
- `tests/test_src_next_daily_trend_plan_numeric_owner.bqn`
- `checks/check-src-next-daily-trend-plan-numeric-owner.sh`
- `checks/check-json-clock-independence.sh`

## Non-goals

- no generic report-wide `--as-of` contract;
- no historical `K` or bitemporal source model;
- no claim that historical rows are immutable;
- no change to current report output or calculation;
- no automatic selection of another Daily Trend runtime slice.
