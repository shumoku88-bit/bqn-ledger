# Plan Temporal Status Projection Plan - 2026-07-05

Status: Planning-stage plan / docs-only / no runtime implementation in this PR

Selected from:

- `TODO.md` remaining candidate: execution-envelope `DUE` / `LATE` / `MISSING` relationship with `plan.tsv`
- `docs/ENVELOPE_EXECUTION_AND_PLAN_POLICY.md`

## Decision

Do not make temporal plan status a property of execution envelopes.

Instead, define an independent readonly projection:

```text
plan row
  + completion evidence
  + explicit as_of
  -> temporal status row
```

The projection must not require:

```text
budget_alloc.tsv
envelope remaining
envelope_role
budget_pool
EXECUTION_PLANNED_PAYMENTS_ENVELOPE
```

Envelope coverage may later consume or join the projection, but envelope state is not the owner of `due`, `overdue`, or `completed` meaning.

## Why this direction

`plan.tsv` answers:

```text
what is expected
when it is expected
whether matching actual evidence has completed it
```

Execution envelopes answer a different question:

```text
how much budget-layer funding has been reserved for execution
```

The adopted envelope policy already separates these meanings:

```text
plan.tsv
  payment schedule, deadline, completion state

execution envelope
  funding reserved for execution
```

It also already requires that due/done meaning and envelope remaining not be confused.

Therefore temporal status belongs to the plan projection layer first.

## Current implementation evidence

This plan does not assume the feature is absent.

Current `src_next/planned_payments.bqn` already contains partial temporal behavior:

1. Current-cycle plan rows are selected.
2. Current-cycle journal rows are selected.
3. `StatusFor` derives a matching state from completion evidence.
4. `BuildViewModel` derives human statuses:

```text
future
due
overdue
completed
```

5. Human and JSON renderers consume those statuses.

Current date relation:

```text
plan date <  as_of -> overdue
plan date == as_of -> due
plan date >  as_of -> future
matching completion evidence -> completed
```

Current `as_of` is derived internally as the latest actual journal date in the cycle, falling back to cycle start.

Current completion matching uses `plan_id` as primary identity with the existing five-field fallback in `planned_payments.bqn`.

Current editor behavior also matters:

- `src_edit/plan_finish_cmd.bqn` refuses to finish a plan without `plan_id`.
- successful plan finish appends an actual journal row carrying the plan identity.

The design problem is therefore not "add due/overdue from zero".

The design problem is:

```text
existing temporal meaning
  currently embedded in report ViewModel construction
  -> make ownership explicit and reusable
```

## Projection contract

### Inputs

Conceptually:

```text
PlanTemporalStatus(plan_row, completion_evidence, as_of)
```

The core temporal classifier must receive `as_of` explicitly.

It must not read wall-clock time by itself.
It must not infer `as_of` from envelope state.
It must not silently read another report section.

### Output vocabulary

Preserve the current externally visible vocabulary for the first slice:

```text
future
due
overdue
completed
```

Do not rename these to `UPCOMING`, `DUE`, `LATE`, or other new terms in the first extraction slice.

Reason:

- human report already uses current values
- structured JSON already exposes current values
- status renaming is a separate contract change

### Precedence

Completion evidence wins over date relation.

```text
if completed:
  completed
else if plan_date < as_of:
  overdue
else if plan_date == as_of:
  due
else:
  future
```

This precedence must be testable without rendering human text.

### `MISSING` decision

Do not add `missing` as a temporal row status in the first design.

`missing` is ambiguous. It could mean:

```text
missing plan_id
missing expected recurrence
missing actual payment
missing envelope funding
missing plan row
```

Those are different diagnostics.

Therefore:

```text
future / due / overdue / completed
  -> temporal status vocabulary

missing ...
  -> future diagnostic vocabulary only after the missing object is defined
```

This avoids using one word to hide several unrelated failures.

## `as_of` ownership decision

The projection core requires explicit `as_of`.

The caller owns the defaulting policy.

For the first execution slice, preserve current report behavior:

```text
planned_payments caller
  computes current compatibility as_of
  using existing LatestActualDateInCycle behavior
  then passes that value explicitly to the projection
```

Do not silently switch the production report to today's wall-clock date in the extraction PR.

A later independent decision may consider:

```text
--as-of YYYY-MM-DD
wall-clock today
data-through date
latest actual date
cycle-relative report date
```

That decision must not be smuggled into a refactor.

## Completion evidence boundary

The first execution slice must preserve current matching behavior unless a separate characterization proves a safe change.

Current compatibility includes:

```text
plan_id primary identity
five-field fallback for rows without explicit plan_id
```

Do not tighten or remove fallback behavior during extraction.

Longer term, explicit `plan_id` remains the preferred identity because the BQN editor `plan finish` path already requires it.

## Cycle boundary

Current `planned_payments.bqn` scopes plan rows and completion evidence to the current cycle before status derivation.

The first extraction slice should preserve that observable behavior.

The temporal classifier itself should not need to know what an envelope is.

Whether cycle selection remains in `planned_payments.bqn` or later becomes a separate plan-selection projection is outside the first slice.

## Proposed ownership

### New narrow projection owner

Candidate:

```text
src_next/plan_status.bqn
```

Responsibility:

- classify one open plan date against explicit `as_of`
- apply completion precedence
- expose small reusable BQN functions
- contain no formatting
- contain no envelope logic

Exact function names are deferred to Execution.

### Existing report owner

```text
src_next/planned_payments.bqn
```

Responsibility after first extraction:

- load/select current rows
- preserve current matching compatibility
- choose compatibility `as_of`
- call the temporal projection
- build report-specific grouping and amounts
- render human and JSON output

### Envelope owner

```text
src_next/envelope_computation.bqn
```

First-slice decision:

```text
unchanged
```

No envelope code should be modified merely to extract temporal status meaning.

## Recommended first Execution slice

Potential changed files:

```text
src_next/plan_status.bqn
src_next/planned_payments.bqn
tests/test_src_next_plan_status.bqn
```

Optional check wiring only if required by current test conventions:

```text
tools/check.sh
```

Preferred implementation shape:

```text
1. Add pure status classification with explicit as_of.
2. Add boundary tests for before / equal / after dates.
3. Add completion-precedence test.
4. Make planned_payments.BuildViewModel call the projection.
5. Preserve current human and JSON status values.
6. Preserve current open/completed grouping and totals.
```

## Acceptance criteria

A future implementation is acceptable only if all of the following hold.

### A. Envelope independence

The status projection imports no envelope module and reads no envelope config.

### B. Explicit time input

Core classification receives `as_of` explicitly.

### C. Boundary correctness

Tests prove:

```text
plan_date <  as_of -> overdue
plan_date == as_of -> due
plan_date >  as_of -> future
```

### D. Completion precedence

Matching completion evidence yields:

```text
completed
```

regardless of whether the plan date would otherwise be future, due, or overdue.

### E. No report drift in first slice

Existing human and JSON status vocabulary remains:

```text
future
due
overdue
completed
```

### F. No grouping drift

Existing open/completed grouping and `open_total` meaning remain unchanged.

### G. No matching migration hidden inside extraction

Current `plan_id` primary behavior and legacy five-field fallback are preserved unless separately characterized and approved.

### H. No source mutation

Do not modify source TSV data.

### I. Existing checks remain green

Recommended verification:

```text
bqn tests/test_src_next_plan_status.bqn
rtk bash ./tools/check.sh
```

## Non-goals

Do not bundle:

- envelope auto-consumption
- explicit plan-to-envelope link metadata
- `budget_pool=main` implementation
- recurrence engine
- expected-series missing detection
- source TSV schema changes
- `plan finish` redesign
- wall-clock `today` migration
- cycle model redesign
- status vocabulary rename
- broad report rewrite

## Future joins after projection is stable

Only after the independent projection exists should later design consider joins such as:

```text
plan temporal status
  x execution envelope coverage
  -> due item with enough reserved funding?
```

or:

```text
overdue plan
  x actual evidence
  x issue log
  -> unresolved payment exception view
```

These are derived views.
They must not move temporal ownership back into the envelope layer.

## PR boundary for this Planning stage

This PR is docs-only.

It does not authorize runtime implementation by itself.

Do not modify in this PR:

```text
src_next/planned_payments.bqn
src_next/envelope_computation.bqn
src_edit/plan_finish_cmd.bqn
source TSV
live config
```

## Recommended next step

```text
review this plan
  -> if approved
create one small Execution PR
  -> extract current temporal meaning
  -> preserve current report behavior
  -> review whether the independent projection creates useful new joins
```
