# Daily Trend Temporal Semantics

Status: current design note / unresolved semantic contract
Owner: report
Canonical: no; canonical temporal principle: `docs/TIME_AS_AXIS.md`; current runtime behavior remains `src_next/daily_trend.bqn` plus characterization tests
Knowledge-boundary correction: `docs/DAILY_TREND_KNOWLEDGE_BOUNDARY_DECISION.md`
Exit: replace or archive after a later explicit Daily Trend temporal contract chooses and documents a semantic model

## Purpose

This note records an unresolved temporal meaning in Daily Trend historical rows.

It does not choose a final model, and it does not authorize runtime changes. Its purpose is to keep the ambiguity visible before any fix, refactor, or semantic selection.

The baseline principle is still `docs/TIME_AS_AXIS.md`: coordinate time, observation `as_of`, `system_today`, `last_recorded_on`, `data_cutoff`, `horizon_end`, and period/cycle boundaries are distinct meanings. They must not be collapsed into one global date.

The first protected property for subsequent Daily Trend temporal work is now selected as **observation consistency**. See `docs/DAILY_TREND_OBSERVATION_CONSISTENCY_DECISION.md`. That decision does not choose Candidate A or Candidate B.

## Knowledge-boundary revision

The original A/B candidate pair was one-dimensional:

```text
fixed historical observation
vs
present-knowledge retrospective projection
```

External temporal-model comparison exposed a missing distinction:

```text
O = observation / replay frame
K = knowledge or source-admission boundary
```

These are not equivalent.

Current source TSV does not generally preserve a canonical historical transaction / recorded-time axis. Therefore this note must not imply that an observation cutoff alone can reconstruct:

```text
what the user knew at that historical date
```

The stronger correction is recorded in:

```text
docs/DAILY_TREND_KNOWLEDGE_BOUNDARY_DECISION.md
```

Candidate A and Candidate B remain useful historical shorthand, but neither is complete without stating the source knowledge frame.

## Current unresolved question

For a Daily Trend row with coordinate date `D`, what does the row mean?

Two candidate directions remain plausible:

1. **Candidate A: fixed historical observation direction**
2. **Candidate B: retrospective projection direction**

The current implementation behavior does not, by itself, prove that either candidate is the intended semantic contract.

The candidate direction must additionally state whether it uses:

```text
current source snapshot S_now
```

or:

```text
historical knowledge boundary K
```

when such a K is actually available.

## Characterized behavior that motivates this note

`tests/test_src_next_daily_trend_historical_stability.bqn` characterizes that an old Daily Trend row can change after an unrelated later journal Event is added.

For the same coordinate row `2026-01-02`, the characterized values are:

```text
liquid:    100 -> 100
days_left:   9 -> 9
fund:     1000 -> 100
daily:     111 -> 11
```

The observed trigger is:

```text
an unrelated later journal Event
  -> advances a local latest-journal clock
  -> the local clock moves past a future-income plan date
  -> planned_future_income changes
  -> the old Daily Trend row is recomputed differently
```

This is a characterization of current runtime behavior, not a semantic decision.

`tests/test_src_next_daily_trend_row_frame_mixing.bqn` further characterizes that one historical row can keep coordinate-local `days_left` while a shared future-income contribution changes with the report-local clock. This is the direct evidence used by the observation-consistency decision.

## Candidate A: fixed historical observation direction

Under this direction, a row for coordinate date `D` represents a calculation observed at `D`, or at an explicitly defined observation cutoff associated with `D`.

Possible implications:

- Historical stability may be protected relative to a fixed source snapshot and explicit temporal inputs.
- The observation cutoff must be explicit. It might be `D`, end-of-day `D`, a cycle-local cutoff, or another named boundary, but it cannot be an implicit local clock with unclear meaning.
- Newer source rows may be useful for other views, but they do not automatically revise an old Daily Trend observation unless the contract says so.

Critical limitation:

```text
O = D
```

does not by itself mean:

```text
knowledge as it existed at D
```

A current-source calculation can contain a backdated Event that was entered after `D`.

Therefore Candidate A splits conceptually into at least:

```text
A1 current-source coordinate / observation replay

A2 historical-knowledge replay using explicit K
```

A2 is the stronger audit product and is not generally supported by current source data alone.

Under A1, the characterized `fund` / `daily` change for `2026-01-02` may still be evidence of a property violation if the selected contract says later source changes must not revise the row.

Under A2, the question additionally requires a preserved historical knowledge state.

## Candidate B: retrospective projection direction

Under this direction, a row for coordinate date `D` represents a projection over past coordinate `D` using a later or current source knowledge state.

Possible implications:

- Historical rows may legitimately change when the selected source state changes.
- A regenerated report can answer “what does the old coordinate look like from this source state?” rather than “what was known then?”
- The observation frame still needs an explicit contract.
- Allowing retrospective replay does not automatically justify dependence on any available local clock.

Critical clarification:

```text
present knowledge
```

must not be treated as a magic preserved timeline.

With current architecture, the feasible narrow meaning is usually:

```text
the current source snapshot supplied to this run
```

A stronger bounded-knowledge retrospective query requires explicit `K` or an external historical source snapshot.

Therefore Candidate B splits conceptually into at least:

```text
B1 current-source retrospective projection

B2 bounded-knowledge retrospective projection using K
```

Under B1, the characterized `fund` / `daily` change for `2026-01-02` might be acceptable, but only if Daily Trend explicitly defines the source and observation frames that cause the change.

## Intentional retrospective replay vs implicit local clock dependence

The important distinction remains:

```text
intentional retrospective replay
  != accidental dependence on an implicit local latest-journal clock
```

A retrospective contract can be valid, but it should name its frame.

Possible meanings include:

```text
O = observation / replay frame
K = knowledge / source-admission boundary, if available
S = explicit source snapshot identity
L = last recorded coordinate frontier
```

These are not substitutes for one another.

The current characterized behavior is more specific: an unrelated later journal Event advances a local latest-journal clock, and that clock changes whether a future-income plan row is counted for all trend rows. That coupling is not automatically justified merely because retrospective replay is a possible semantic model.

Also, do not assume:

```text
shared helper shape == shared semantic contract
```

Daily Trend and another section may both use similarly shaped local date helpers while answering different temporal questions.

## Critical non-equivalences

```text
L != O
L != K
O != K
historical coordinate != historical knowledge state
```

Current local `L` is a journal-coordinate frontier. It does not preserve when facts entered the source or when corrections were learned.

An explicit `O` can cut coordinate visibility. It cannot recreate source facts that existed only in a historical source state unless that state is preserved separately.

## Protected properties

These properties are related but not equivalent:

- **Historical stability**: a previously rendered row for coordinate `D` remains stable under a stated source and temporal contract.
- **Observation consistency**: every time-sensitive term has an explainable dependency on a named temporal frame, and combinations of distinct frames are intentional rather than accidental consequences of an implicit local clock.
- **Cross-domain independence**: unrelated journal Events should not affect old Daily Trend rows through a hidden coupling unless the semantic contract explicitly permits that dependency.
- **Auditability**: a user can tell whether a row is current-source replay, historical-source replay, or retrospective reinterpretation.
- **Reproducibility**: given the same source snapshot, config, code, and explicit temporal frame, the row can be regenerated with the same values.

The first selected property remains **observation consistency**. This selection is recorded in `docs/DAILY_TREND_OBSERVATION_CONSISTENCY_DECISION.md`.

This does not mean all values must use one date. Coordinate `D`, observation/replay frame `O`, cycle/period boundary `C`, local frontier `L`, and knowledge/source frame `K` or `S` remain distinct.

## Current decision

No final Daily Trend temporal semantic model is selected here.

Candidate A and Candidate B remain open directions, but the previous one-dimensional wording is corrected:

```text
observation frame
and
knowledge/source frame
```

must be stated separately.

Current runtime behavior remains unchanged.

The next finite slice should characterize source-knowledge drift independently from local max-coordinate `L`, as specified in `docs/DAILY_TREND_KNOWLEDGE_BOUNDARY_DECISION.md`.
