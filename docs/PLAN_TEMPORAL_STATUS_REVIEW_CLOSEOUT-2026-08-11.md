# Plan Temporal Status review closeout — 2026-08-11

## Baseline

Final reread is against merged `main` `05edf2aecdd2d5d467a66fce0b00f17c87ec8e54` after PR #632.

The review sequence was:

- PR #631: recorded current reachability, historical ownership, the Planned Payments duplication, and the distinction between generic as-of status and section-local cycle grouping;
- PR #632: narrowed the temporal classifier to open Plans, removed stale completion responsibility, and routed both Plan List and Planned Payments through the same generic as-of relation.

## Final owner

`src/accounting/plan_temporal_status.bqn` now owns exactly:

```text
open Plan date + explicit as-of
→ overdue / due / future
```

The implementation remains a small scalar date-coordinate relation:

```text
Plan date < as-of  → overdue
Plan date = as-of  → due
Plan date > as-of  → future
```

It reads no wall clock, chooses no observation default, performs no source I/O, matches no completion evidence, chooses no cycle, and renders no UI.

## KEEP

- explicit `as-of` as an input coordinate;
- strict Gregorian date meaning through `src/ledger/date_ordinal.bqn` rather than string-order inference;
- the stable `overdue / due / future` vocabulary;
- Plan List overdue/upcoming filtering as an open-Plan consumer;
- Planned Payments as an open-only projection after Plan Completion Join verification;
- Planned Payments `time_group` (`overdue / current_cycle / future_cycles`) as a separate cycle-boundary relation owned by the section;
- Planned Payments cycle selection, observation admission, exact grouped totals, provenance, and presentation;
- completion state and completion evidence in `src/accounting/plan_completion_join.bqn`;
- the text-date API because it is natural for Plan List and no measured need justifies an ordinal-only public surface.

## SUBTRACTED

- the `completed` input from `plan_temporal_status.Classify`;
- the `completed` output branch from the temporal owner;
- Plan List's constant `0` completion argument;
- Planned Payments' local mutable three-way `overdue / due / future` derivation;
- the implication in the active Planned Payments contract that the section independently owns generic as-of status.

## Ownership after the review

The relevant semantic path is now:

```text
Plan + Actual evidence
→ Plan Completion Join
→ open Plan relation
→ Plan Temporal Status
→ consumer-specific use
```

Plan List consumes the generic status only to decide overdue versus upcoming membership.

Planned Payments consumes the same generic status for each open result row, while separately classifying that row against cycle boundaries for `time_group` and grouped totals.

No consumer needs temporal status to classify completion. That responsibility is no longer duplicated.

## Array-language decision

The classifier is genuinely scalar. Forcing Group, Rank, Cells, Table, or another array combinator into this owner would add shape that the domain relation does not contain.

The existing boolean-derived status coordinate is compact, direct BQN and preserves the three-way relation visibly. Consumers apply it over their own row collections at the appropriate boundary.

## Validation and coordinate decision

`date.Ordinal` remains a coordinate conversion over already admitted strict Gregorian text. Validation stays with the source/request owners:

- admitted Plan dates are already valid;
- Plan List validates explicit `--as-of` before temporal filtering;
- Planned Payments validates explicit observation before using the classifier.

The section already owns ordinal values for cycle grouping, so calling the text-date classifier repeats a small conversion there. No performance evidence justifies widening the shared API to ordinals or moving coordinate ownership into Plan List during this review.

## Qualification

PR #632 preserved the existing focused and integration laws:

- `tests/test_accounting_plan_temporal_status.bqn` fixes the open `overdue / due / future` boundary;
- `checks/check-edit-bqn-plan-list.sh` protects open-only overdue/upcoming membership and CLI failure behavior;
- `tests/test_section_planned_payments.bqn` protects as-of status, independent cycle `time_group`, completion exclusion, exact totals, provenance, and output goldens;
- full `tools/check.sh` and Coverage passed on the PR head.

The owner and both production consumers were reread after merge on `main` `05edf2aecdd2d5d467a66fce0b00f17c87ec8e54`.

## Final classification

The Plan Temporal Status review is complete.

No further Plan Temporal Status-specific subtraction is currently justified. The next normal Phase 1 cursor is:

`src/accounting/profit_and_loss.bqn`
