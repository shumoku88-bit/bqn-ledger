# Behavior Drift Report Decisions

Archive status: **historical decisions digest**
Archived on: 2026-06-22
Source document: `docs/BEHAVIOR_DRIFT_REPORT_PLAN.md`
Current status note: `docs/BEHAVIOR_DRIFT_REPORT_PLAN.status.md`
Current report direction:

```text
docs/ACTUAL_COMPARISON_REPORT_PLAN.md
docs/REPORT_DESIGN.md
```

This file preserves the useful decisions from the behavior-drift / residual discussion without treating the old roadmap as the current report direction.

Do not use this file as the current TODO list.

## Reading rule

Use this file to understand historical decisions about Plan / Actual / Residual, Envelope boundaries, Scenario placement, and behavior-drift observation.

Use these files for current report work:

```text
docs/ACTUAL_COMPARISON_REPORT_PLAN.md
docs/REPORT_DESIGN.md
docs/BEHAVIOR_DRIFT_REPORT_PLAN.status.md
```

## Current report direction

- The old Plan / Actual / Residual main section was deleted.
- Actual period comparison was introduced as `actual-comparison`.
- `residual` should not become a scoring, guilt, or budget-failure report.
- Plan fulfillment confirmation mostly belongs to the `planned` section.
- Everyday money management remains centered on Envelope.

## Preserved decisions

### Envelope and Plan answer different questions

```text
Envelope = available money / remaining allowance
Plan     = concrete, consciously intended event
Residual = auxiliary observation of intention vs actual
```

Envelope remains the primary everyday view for questions like:

- how much is left for food / daily spending,
- which envelope is being consumed,
- whether the current pace can survive the cycle.

Plan remains for concrete events with date / content / amount awareness.

Do not force repetitive food, tobacco, daily items, or uncertain small purchases into `plan.tsv` only to make residual tables look complete.

### Residual is observation, not judgment

- `actual_only` is not waste.
- `plan_only` is not failure.
- A positive residual is not a moral warning.
- Residual should keep `plan_amount`, `actual_amount`, and `residual_amount` together, not only the difference.
- If residual returns in the future, its language must stay observational.

### Actual comparison replaced the main residual direction

The current comparison direction is Actual-vs-Actual over comparable time windows, especially:

```text
current_cycle_elapsed
vs
previous_cycle_same_elapsed
```

When the baseline is unavailable, do not invent data. Show unavailable.

### Scenario stays outside Canonical Daily Cube

Do not add Scenario as a Canonical Daily Cube axis without a separate architecture decision.

Preferred historical direction:

```text
Canonical Daily Cube
  actual / plan / budget / forecast
            |
            +-- Scenario Projection as separate derived long view
```

Scenario / behavior class work should remain optional, derived, and outside canonical balances until its meaning is stable.

## Not current work

- Do not revive the deleted residual main section from the old plan.
- Do not add Behavior Class as a required source TSV field.
- Do not add Scenario as a Cube axis.
- Do not make `plan_id` mandatory for ordinary spending.
- Do not require all repetitive spending to be prewritten in `plan.tsv`.
- Do not make R or Racket/Scheme a source-data update path.

## Non-goals

- Do not edit source TSV data.
- Do not change `BuildCube` meaning.
- Do not change Canonical Daily Cube shape or Layer meaning.
- Do not turn residual into a success / failure report.
- Do not let observation reports update actual money.

## Future cleanup

A later docs hygiene pass may either:

1. move the full original document to archive if a safe full-file move is practical, or
2. replace `docs/BEHAVIOR_DRIFT_REPORT_PLAN.md` with a short historical stub.

Until then, keep the original document as long historical reasoning and use this digest for the current reading path.
