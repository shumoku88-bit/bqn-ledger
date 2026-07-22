# Next session

Status: selected finite characterization plan
Owner: journal source migration
Canonical: no; canonical routing remains `TODO.md`
Exit: focused public-synthetic implementation, review, completion record, and return to no selected finite Journal slice
Date: 2026-07-22

## Current state

Selected finite plan:

`docs/JOURNAL_BUDGET_COMPANION_PROJECTION_CHARACTERIZATION_PLAN.md`

## Selected path

```text
persisted Journal events
  -> Stage 1 Transaction IR
  -> Stage 2A checked Posting IR (via journal_read_only_source_carrier)
  -> BuildPeriodView (src_next/context.bqn)
  -> TBDS layer-filtered views (src_next/tbds.bqn)
  -> separately observable actual and budget layers
```

## Objective

Characterize that persisted balanced budget companion events can be projected through standard Stage 1 IR, Stage 2A Posting IR, and `BuildPeriodView` into TBDS layer-filtered views, observing actual-layer and budget-layer account movements separately without changing actual-layer amounts or mutating production routing.

## Production boundary

Production Journal routing, writer/editor work, envelope/report runtime migration, private data, source conversion, shadow read, cutover, reverse synchronization, per-posting layers, correction-event policy, and Cube/TBDS shape changes remain unselected.
