# Destination Planned Payments section

Status: Phase 3I destination section proof (updated: unpaid Plan projection)

Owner: `src/sections/planned_payments.bqn`

Generic open Plan as-of status owner: `src/accounting/plan_temporal_status.bqn`

## Composition

The section receives only:

```text
Plan Facts
Actual Facts
successful resolved cycle
explicit as-of
```

It composes:

```text
all-Plan date-ordered selection & all-Actual completion selection
  → durable Plan completion Join
  → exclude completed Plans from section semantic result
  → shared open Plan as-of status (overdue / due / future)
  → section-local cycle grouping (overdue / current_cycle / future_cycles)
  → exact totals (current_cycle_total, due_through_cycle_total, overdue_total, future_cycles_total)
  → open-only List result
  → human / compact / JSON renderers
```

There is no source path, I/O, clock, report context, Cube/TBDS, raw TSV row, or the retired report runtime import.

## Selection and observation

Plan Transactions across all periods are selected and sorted by date before the Join. Actual Transactions across all admitted Actual evidence are selected for completion matching to prevent false-positive open status for previously or future paid Plans. Equal-date source order remains deterministic.

The explicit section observation must equal:

- the latest selected Actual Transaction date in the current cycle; or
- cycle start when selected Actual in current cycle is empty.

A caller cannot substitute hidden today or a report-wide fallback date. Invalid/mismatched observation fails closed with no rows or total.

## Relationship policy

Only Join rows in `open` state are included in the section result. Completed Plans are verified for currency and direction agreement, then excluded from the open Planned Payments projection.

- `duplicate` completion evidence is rejected as `completion_duplicate`;
- conflicting evidence is rejected as `completion_ambiguous`;
- completed currency mismatch is rejected;
- completed Account-direction mismatch is rejected;
- multiple selected open Plan currency domains are rejected before computing exact totals.

The section never sums multiple Actual completion transactions. It preserves source-qualified Plan Transaction references and Posting contributors in the result.

## Temporal status and cycle grouping

Open Plan rows are classified into three time groups relative to the current cycle boundaries. This relation is section-local because it drives grouped totals and presentation:

```text
plan date < cycle.start                 → overdue (期限超過の未払い)
cycle.start <= plan date < cycle.end    → current_cycle (今サイクルの未払い)
plan date >= cycle.end                  → future_cycles (サイクル外の予定)
```

Each open row also carries a generic as-of-relative status from `src/accounting/plan_temporal_status.bqn`:

```text
plan date < as-of  → overdue
plan date = as-of  → due
plan date > as-of  → future
```

Completion is not a temporal-status responsibility here. Completion state comes from the Plan Completion Join; completed Plans are validated and excluded before the shared open temporal classifier is used.

## Exact amounts and totals

Every open row retains its own admitted coefficient and scale. Open Plan amounts normalize to the highest selected open scale and use checked exact summation. Different currency domains are never normalized or added together.

Explicit totals are provided for:
- `current_cycle_total` (unpaid total for the current cycle)
- `due_through_cycle_total` (overdue past + current cycle unpaid)
- `overdue_total` (overdue past unpaid)
- `future_cycles_total` (future cycles unpaid)

Human/compact/JSON rendering occurs from the same section result. JSON numbers are emitted from exact decimal text, not binary-float conversion.

## Category label

Account role determines which Plan direction supplies the category:

- income-source Plan uses the `from` Account;
- other Plans use the `to` Account.

Existing `income:`, `expenses:`, and `liabilities:` prefixes are shortened only after explicit role selection. Prefixes do not infer accounting role.

## Output contracts

Human, compact, and JSON express the same open-only projection. Human displays grouped subsections (`── 期限超過の未払い ──`, `── 今サイクルの未払い ──`, `── サイクル外の予定 ──`) and removes the completed section and status legend entry. Compact emits open planned payments with `ledger_planned_payment:` prefix:

```text
--- Ledger Planned Payments ---
ledger_planned_payment: ... planned ...
```

No `retired_planned_payment` alias or completed (`paid`) rows are emitted by the destination renderer.

Goldens:

- `fixtures/ledger-facts-phase1-proof/planned_payments.destination.human.txt`
- `fixtures/ledger-facts-phase1-proof/planned_payments.destination.compact.txt`
- `fixtures/ledger-facts-phase1-proof/planned_payments.destination.json`

## Proof

`tests/test_section_planned_payments.bqn` proves:

- exclusion of completed current-cycle and past-cycle Plans from Planned Payments;
- multi-timegroup classification (overdue, current_cycle, future_cycles);
- exact source-qualified Transaction and Posting provenance;
- deterministic human/compact/JSON output;
- empty Plan output;
- overdue/due/future as-of status and exact group totals;
- observation mismatch fail-closed;
- duplicate completion refusal with no partial rows.

`checks/check-ledger-facts-phase1-proof-fixture.sh` compares destination human and JSON bytes/schema with current production output for the same public evidence. No private household data is used.
