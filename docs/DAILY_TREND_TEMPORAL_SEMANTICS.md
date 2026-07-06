# Daily Trend Temporal Semantics

Status: current design note / unresolved semantic contract
Owner: report
Canonical: no; canonical temporal principle: `docs/TIME_AS_AXIS.md`; current runtime behavior remains `src_next/daily_trend.bqn` plus characterization tests
Exit: replace or archive after a later explicit Daily Trend temporal contract chooses and documents a semantic model

## Purpose

This note records an unresolved temporal meaning in Daily Trend historical rows.

It does not choose a final model, and it does not authorize runtime changes. Its purpose is to keep the ambiguity visible before any fix, refactor, or semantic selection.

The baseline principle is still `docs/TIME_AS_AXIS.md`: coordinate time, observation `as_of`, `system_today`, `last_recorded_on`, `data_cutoff`, `horizon_end`, and period/cycle boundaries are distinct meanings. They must not be collapsed into one global date.

The first protected property for subsequent Daily Trend temporal work is now selected as **observation consistency**. See `docs/DAILY_TREND_OBSERVATION_CONSISTENCY_DECISION.md`. That decision does not choose Candidate A or Candidate B.

## Current unresolved question

For a Daily Trend row with coordinate date `D`, what does the row mean?

Two candidate meanings are plausible and remain open:

1. **Candidate A: fixed historical observation**
2. **Candidate B: present-knowledge retrospective projection**

The current implementation behavior does not, by itself, prove that either candidate is the intended semantic contract.

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

## Candidate A: fixed historical observation

Under this candidate, a row for coordinate date `D` represents the world observable at `D`, or at an explicitly defined observation cutoff associated with `D`.

Possible implications:

- Historical stability is protected: later unrelated Events should not silently rewrite old rows.
- A past row can be used to audit what the user could have known or acted on at that time.
- The observation cutoff must be explicit. It might be `D`, end-of-day `D`, a cycle-local cutoff, or another named boundary, but it cannot be an implicit local clock with unclear meaning.
- Newer source rows may be useful for other views, but they do not automatically revise an old Daily Trend observation unless the contract says so.

Under Candidate A, the characterized `fund` / `daily` change for `2026-01-02` would be evidence of a property violation, unless the later Event is within the explicitly defined observation cutoff for that row.

## Candidate B: present-knowledge retrospective projection

Under this candidate, a row for coordinate date `D` represents a projection over past coordinate `D` using a later or current knowledge state.

Possible implications:

- Historical rows may legitimately change when newer knowledge appears.
- A regenerated report can answer “what does the old coordinate look like from the current knowledge frame?” rather than “what was known then?”
- The observation frame still needs an explicit contract. A retrospective view must say what knowledge state, input boundary, or replay cutoff it uses.
- Allowing retrospective replay does not automatically justify dependence on any available local clock.

Under Candidate B, the characterized `fund` / `daily` change for `2026-01-02` might be acceptable, but only if Daily Trend explicitly defines the later knowledge frame that caused the change.

## Intentional retrospective replay vs implicit local clock dependence

The important distinction is:

```text
intentional retrospective replay
  != accidental dependence on an implicit local latest-journal clock
```

A retrospective contract can be valid, but it should name its frame. Examples of possible named boundaries include `as_of`, `data_cutoff`, `last_recorded_on`, or an explicitly section-local replay cutoff.

The current characterized behavior is more specific: an unrelated later journal Event advances a local latest-journal clock, and that clock changes whether a future-income plan row is counted for all trend rows. That coupling is not automatically justified merely because retrospective replay is a possible semantic model.

Also, do not assume:

```text
shared helper shape == shared semantic contract
```

Daily Trend and another section may both use similarly shaped local date helpers while answering different temporal questions.

## Protected properties

These properties are related but not equivalent:

- **Historical stability**: a previously rendered row for coordinate `D` remains stable under later unrelated Events, unless the chosen contract intentionally replays it.
- **Observation consistency**: every time-sensitive term has an explainable dependency on a named temporal frame, and combinations of distinct frames are intentional rather than accidental consequences of an implicit local clock.
- **Cross-domain independence**: unrelated journal Events should not affect old Daily Trend rows through a hidden coupling unless the semantic contract explicitly permits that dependency.
- **Auditability**: a user can tell whether a row records past decision state or a present-knowledge reinterpretation.
- **Reproducibility**: given the same source TSV, config, code, and explicit temporal frame, the row can be regenerated with the same values.

The first selected property is **observation consistency**. This selection is recorded in `docs/DAILY_TREND_OBSERVATION_CONSISTENCY_DECISION.md`.

This does not mean all values must use one date. Coordinate `D`, observation/replay frame `O`, and cycle/period boundary `C` remain distinct. The selected property requires their dependencies and compositions to be explainable.

Choosing Candidate A would emphasize historical stability and past decision audit. Choosing Candidate B would emphasize retrospective reinterpretation. Either choice still needs an explicit temporal frame.

## Current decision

No final Daily Trend temporal semantic model is selected here.

The first protected property is observation consistency. Candidate A and Candidate B remain open, runtime behavior remains unchanged, and the next finite slice should map current Daily Trend term dependencies before any runtime fix.
