# Daily Trend Temporal Semantics

Status: superseded
Owner: report
Canonical: no; current temporal principle: `docs/TIME_AS_AXIS.md`; current Daily Trend route below
Exit: keep as a short routing stub while older references may still point here

## Purpose

This file used to hold the unresolved pre-selection Daily Trend temporal question.

It is **not** the current semantic contract and must not be used to infer that Candidate A / Candidate B are still open product choices.

The old note was written before the selected current-source coordinate replay model and before the runtime slices that followed it.

## Current selected model

Current Daily Trend product meaning is A1-like current-source coordinate replay:

```text
S = source snapshot supplied to this run
D = Daily Trend row coordinate
O_row = D
C = cycle / period boundary
L = record-frontier context
K = unavailable / not claimed
```

Preserve:

```text
L != O_row
L != K
O_row != K
historical coordinate != historical knowledge state
```

The selected model does **not** claim historical-knowledge replay.

## Current reading path

For new Daily Trend temporal work, read in this order:

1. `docs/TIME_AS_AXIS.md`
   - canonical temporal vocabulary and non-equivalences
2. `docs/DAILY_TREND_CURRENT_SOURCE_COORDINATE_REPLAY_DECISION.md`
   - selected Daily Trend product model
3. `docs/DAILY_TREND_TEMPORAL_DEPENDENCY_MAP.md`
   - current post-runtime dependency map
4. `src_next/daily_trend.bqn`
   - current runtime truth
5. characterization / contract tests for the specific consumer being changed

Use supporting decisions only when relevant:

- `docs/DAILY_TREND_OBSERVATION_CONSISTENCY_DECISION.md`
- `docs/DAILY_TREND_KNOWLEDGE_BOUNDARY_DECISION.md`
- `docs/DAILY_TREND_ROW_MEMBERSHIP_PRODUCER_DECISION.md`
- `docs/DAILY_TREND_EXPLICIT_EMPTY_PLAN_IDENTITY_MEANING_DECISION.md`

## Implemented milestones

The current route must be read with these runtime changes in mind:

- PR #101: planned future income cutoff ownership moved from report-local `L` to row `D`
- PR #105: ordinary row membership moved to accepted in-cycle actual coordinates plus explicit empty-state anchoring; `L` no longer owns ordinary row membership
- PR #110: explicit empty `plan_id=` falls back to the existing five-field compatibility identity while first matching token precedence is preserved
- PR #111: explicit-empty identity docs synchronized and that narrow campaign closed

The historical PR #107 reserve result `300 -> 0` remains valid as pre-#110 characterization evidence only. Under the post-#110 runtime, the same fixture pair keeps reserve `300 -> 300` while VM `as_of` still moves.

## Current unresolved surface

Do not infer that all temporal work is complete.

Current named `L` responsibilities still include:

```text
VM as_of
human header days_left
```

The empty-id reserve branch code also remains present, but the explicit-empty syntax reachability path characterized by PR #107 was closed by PR #110. Other reachability is not claimed here.

`K` remains unavailable / not claimed.

## Continuation rule

Do not restart from the old A/B candidate discussion.

For the next slice:

```text
current runtime + current dependency map
  -> choose one concrete inconsistency or unclear owner
  -> characterize reachability / sensitivity when needed
  -> state the protected property
  -> make one small runtime or docs change
  -> synchronize current routing before continuing
```

Do not perform a global:

```text
L -> D
L -> O
L -> K
```

rewrite.

Do not bundle VM `as_of`, header, reserve, Outlook, K, or shared temporal-kernel work.

## Historical note

The previous contents of this file discussed unresolved Candidate A / Candidate B directions and source-knowledge drift before the current product selection.

That material is historical background, not current authorization. Use repository history and the archived temporal audits when the pre-selection reasoning is specifically needed.
