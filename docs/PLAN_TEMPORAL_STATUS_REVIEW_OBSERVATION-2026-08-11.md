# Plan Temporal Status review observation — 2026-08-11

## Baseline

Observed against `main` `e13db61c0b85a0209fc8a9959040ed6fd47739f8` after PR #630 closed the Plan Completion Join review and advanced the Phase 1 cursor to `src/accounting/plan_temporal_status.bqn`.

This document is observation-only. It does not change production BQN, tests, public output, temporal vocabulary, source authority, writer behavior, or the TODO cursor.

## Current owner boundary

`src/accounting/plan_temporal_status.bqn` is a small pure classifier:

```text
completed + Plan date + explicit as-of
→ future / due / overdue / completed
```

It imports only `src/ledger/date_ordinal.bqn`, reads no wall clock, performs no source I/O, chooses no cycle, renders no UI, and owns no envelope or completion matching policy.

The date relation is currently:

```text
Plan date < as-of  → overdue
Plan date = as-of  → due
Plan date > as-of  → future
completed          → completed
```

The scalar BQN expression is already compact. There is no evidence that Group, Rank, Cells, or Table would clarify this genuinely scalar relation.

## Current direct production consumer

Repository search finds one direct production import:

- `src_edit/plan_list_cmd.bqn`.

The focused test is `tests/test_accounting_plan_temporal_status.bqn`.

`plan_list_cmd.bqn` first separates:

```text
all Plans
→ open Plans
→ optional temporal filter
```

and calls:

```bqn
planStatus.Classify ⟨0,row.date,asOf⟩
```

only for open Plans. `--all` cannot be combined with temporal filtering. Therefore the current direct production consumer never exercises the `completed` branch.

The active unfinished-Plan export contract independently confirms this meaning: temporal filtering is an open-row operation; overdue is `date < as-of`, upcoming is due-or-future / `date >= as-of`, and closed rows have no selected temporal-filter meaning.

## Parallel temporal ownership in Planned Payments

`src/sections/planned_payments.bqn` does not import the temporal owner. It independently derives the same as-of-relative open status:

```text
Plan date < as-of  → overdue
Plan date = as-of  → due
Plan date > as-of  → future
```

This occurs after the Plan Completion Join has classified relationships and after only `open` Join rows are admitted into the section result.

The section also owns a different relation, `time_group`, against cycle boundaries:

```text
Plan date < cycle.start                 → overdue
cycle.start <= Plan date < cycle.end    → current_cycle
Plan date >= cycle.end                  → future_cycles
```

These two relations must not be conflated. Cycle grouping belongs to Planned Payments because it drives section membership, grouped totals, and presentation. Generic Plan-date versus explicit-as-of status is independently useful and currently duplicated.

## Historical ownership evidence

The independent projection was deliberate, not accidental.

The July design record `docs: define independent plan temporal status projection` explicitly moved temporal meaning out of a Planned Payments ViewModel and required explicit `as_of`, no wall clock, and reusable `future / due / overdue / completed` status.

The subsequent extraction commit `src_next: extract planned payment temporal status` removed Planned Payments' local `HumanStatusFor` and routed it through the shared Plan status classifier.

Later PR #575 redesigned Planned Payments into an **open-only unpaid Plan projection**. Completed Plans are now validated through the completion relation and then excluded from the section semantic result. During that redesign, the open `overdue / due / future` date relation was reintroduced locally while `time_group` was added for the new cycle-spanning report shape.

The current duplication is therefore best understood as an ownership drift caused by a legitimate product redesign, not as a reason to mechanically restore the old completed-row report model.

## Protected meaning

### KEEP explicit observation

The classifier must continue to receive `as_of` explicitly. It must not read today's date, infer a report-wide clock, or own observation defaulting policy.

### KEEP open temporal vocabulary

Current production behavior depends on:

```text
overdue
due
future
```

Plan List uses the relation for overdue/upcoming filtering. Planned Payments publishes the same row status vocabulary.

### KEEP strict date semantics outside incidental string ordering

Date relation should continue to use the strict Gregorian date coordinate owned by `date_ordinal.bqn`; do not replace it with ad-hoc lexicographic string comparison.

### KEEP Planned Payments cycle grouping section-local

`overdue / current_cycle / future_cycles` is a cycle-boundary classification with section-specific totals and presentation meaning. It is not the same relation as `overdue / due / future` against explicit as-of.

### KEEP completion ownership in Plan Completion Join

PRs #624–#630 established a durable Plan↔Actual completion relation with `open / completed / duplicate / ambiguous`, exact evidence, provenance, and fail-closed behavior.

Temporal status should not reacquire completion matching or become a second completion owner.

## Strong subtraction / ownership candidate

Current evidence supports one coherent end-state:

```text
open Plan date + explicit as-of
→ one shared temporal owner
→ overdue / due / future
```

That implies:

1. remove the `completed` input and `completed` branch from `plan_temporal_status.bqn`;
2. keep Plan List routed through this owner, now with only `planDate‿asOf`;
3. route Planned Payments' as-of-relative `status` through this owner instead of reimplementing the three-way date relation;
4. keep Planned Payments' `time_group`, cycle selection, observation admission, totals, and presentation where they are.

This is not a behavior feature. It is an ownership repair after the open-only redesign.

## Input coordinate observation

Planned Payments already has `planOrdinal` and `asOfOrdinal` because it needs cycle grouping and observation checks, while Plan List naturally holds date text.

Changing the shared owner to an ordinal-only API could avoid two conversions inside Planned Payments, but would push date-coordinate construction into Plan List and broaden the public surface during a review whose demonstrated problem is ownership duplication, not measured date-conversion cost.

Classification: **KEEP the current text-date input shape for the first ownership repair**. Reconsider an ordinal API only with broader `date_ordinal` / Facts evidence or measured need.

## Validation boundary

`date.Ordinal` assumes admitted strict Gregorian text. The current classifier does not duplicate date validation, and that separation is appropriate:

- Plan dates come from admitted/validated Plan sources;
- Plan List validates explicit `--as-of` before classification;
- Planned Payments validates explicit `as-of` before its semantic kernel.

Do not add duplicate validation to this pure classifier merely because it accepts text coordinates.

## Proposed qualification sequence

Before closing this review, a coherent implementation should prove all of the following together:

1. focused temporal-status tests characterize only open `overdue / due / future` boundaries;
2. `Classify` accepts `planDate‿asOf` and contains no completion responsibility;
3. Plan List preserves overdue/upcoming membership and argument behavior;
4. Planned Payments delegates row `status` to the shared owner;
5. Planned Payments retains its separate cycle `time_group` and all exact totals;
6. existing human / compact / JSON outputs and focused section laws remain unchanged;
7. full `tools/check.sh` and Coverage pass.

After that implementation is merged, reread both direct consumers and the owner on current `main` before advancing the review cursor.
