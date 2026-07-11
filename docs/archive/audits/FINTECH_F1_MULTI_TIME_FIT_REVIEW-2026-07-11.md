# Fintech F1 Multi-time Transaction Semantics — Fit Review

Status: complete (evidence corrected)
Decision: adopt-later
Date: 2026-07-11
Reviewer: AI (pit)
Selection PR: #178

## 1. Scope

Read-only fit review of F1 against the current repository. This review distinguishes current runtime behavior, documented design intent, and optional future vocabulary. It changes no runtime, source TSV, schema, fixture, or check.

## 2. Current date semantics

The first journal date column is the current default Event/projection coordinate. Current accounting projections use it for Posting IR date/day resolution, Cube Day, TBDS period membership, and report period selection.

That sentence describes **current runtime usage**. The inspected current contracts do not require every journal date to have one unconditional human meaning such as “economic occurrence date.” A person chooses the date appropriate to the Event being recorded: the card-purchase Event and the later card-payment Event therefore have separate rows and dates.

`docs/TIME_AS_AXIS.md` distinguishes coordinate time from observation time and says that a view chooses its coordinate: Daily Exact uses the existing `date`, while a cashflow-due view can use `due_on`. This is the audit's summary of runtime evidence, not a quotation from that document:

- `src_next/projection.bqn` resolves the first-column date to Posting IR `day_index`.
- `src_next/cube.bqn` places Posting IR rows on its Day axis.
- `src_next/tbds.bqn` selects opening and movement rows using the first-column date and `[period_start, period_end_exclusive)`.
- report consumers use those projections or the plan date according to their own contract.

`as_of` is an observation boundary, not another posting coordinate. `occurred_on`, `booked_on`, `paid_on`, and `settled_on` remain illustrative future vocabulary; they are not adopted production row contracts.

## 3. Plan date, status, and matching

The first plan column is the planned Event's current date coordinate. `src_next/plan_evidence.bqn` derives completion by matching plan `plan_id` values against journal metadata; `src_next/plan_rows.bqn` derives row status/actual evidence; and `src_next/planned_payments.bqn` renders planned/paid views from that shared evidence and plan dates.

`src_edit/plan_finish_cmd.bqn` validates a user-supplied `actualDate`, emits it as the journal row's first column, and preserves `plan_id`. Thus a plan date and its actual journal date may differ without adding another date to either row.

## 4. `due_on` and account-metadata derivation

The repository contains a documented and fixture-backed **cashflow-due projection design**:

- `docs/CONVENTIONS.md` defines `due_day`, `due_month_offset`, and `payment_account` on a liability account and defines row-level `due_on` as an exception override.
- `docs/JOURNAL_META.md` marks `due_on` as an experimental exception override, normally derived from account metadata.
- `fixtures/multi-time-card/accounts.tsv` supplies `due_day=27`, `due_month_offset=1`, and `payment_account=assets:bank`.
- `fixtures/multi-time-card/journal.tsv` has one ordinary purchase and one `due_on=2026-03-05` override.
- `fixtures/multi-time-card/plan.tsv` is intentionally empty and states that the projection is derived from journal Events and account metadata.

However, the current tracked tree has **no executable derivation owner, report consumer, or check** for that design. Searches across `src_next`, `src_edit`, and `checks` find no `due_day`, `due_month_offset`, or `payment_account` consumer, and no source consumer of `due_on`. In particular, `src_next/planned_payments.bqn` consumes plan dates and `plan_id`-derived completion evidence; it does not consume `due_on`.

Historical docs name `engine/report_cashflow_due.bqn`, but that path is not present in the current tracked tree and is not current runtime evidence.

| Meaning | Source | Consumer | Accounting effect |
|---|---|---|---|
| journal date | first TSV column | `projection.bqn` → Posting IR/day resolution; `cube.bqn`; `tbds.bqn`; downstream reports | Current accounting coordinate |
| derived due date | liability account metadata: `due_day`, `due_month_offset`, `payment_account` | No executable current consumer; specified by `CONVENTIONS.md` and `fixtures/multi-time-card/README.md` for the experimental cashflow-due projection | Projection-only by design; no current calculation effect |
| `due_on` override | journal row metadata | No executable current consumer; fixture/design override for the same projection | Projection-only by design; no current calculation effect |

The fixture therefore proves the intended source and expected projection semantics, not current executable coverage.

## 5. Credit-card directions from the repository contract

`fixtures/multi-time-card/journal.tsv` is authoritative for this review. Under this repository's `from -> to` contract, `from` is credited and `to` is debited.

### Card usage

```text
2026-01-10  Book      liabilities:card -> expenses:book      800
2026-01-20  Computer  liabilities:card -> expenses:computer  1200
```

The expense (`to`) increases and the card liability (`from`) increases. The second row also carries the experimental due-date override.

### Card payment

```text
2026-02-28  Pay card  assets:bank -> liabilities:card  800
```

The bank asset (`from`) decreases and the card liability (`to`) decreases. Expense is not recorded again at settlement.

These are separate journal Events. The current default coordinate can place purchase accounting on purchase rows and bank/liability settlement on the later payment row without per-row `occurred_on` or `settled_on` metadata.

## 6. Revalidated consumer evidence

| Consumer | Current evidence | F1 implication |
|---|---|---|
| Posting IR / Cube | `projection.bqn` resolves first-column date to `day_index`; `cube.bqn` consumes it | Current accounting needs one default coordinate per Event |
| TBDS | `tbds.bqn` partitions postings by first-column date | No second row date is currently consumed |
| Cashflow-due projection | Contract and expected behavior exist in docs/fixture; executable owner/report/check is absent from the current tree | Already-designed multiple temporal meaning must be preserved, but is not a current runtime requirement |
| Planned payments | `planned_payments.bqn` consumes plan rows, plan dates, and shared completion evidence; not `due_on` | Do not cite it as the due-date consumer |
| Plan rows/status | `plan_evidence.bqn` and `plan_rows.bqn` use `plan_id` matches and plan dates | Plan-to-actual linkage does not require F1 metadata |
| Plan finish | `plan_finish_cmd.bqn` writes user-supplied actual date and preserves `plan_id` | Planned and actual dates can differ across rows |
| Event Lens | `event_lens.bqn` operates on existing projected rows; no F1 metadata consumer exists | Extensible read-only view, not present demand |
| Liability/card fixture | `journal.tsv` records liability→expense purchases and bank→liability payment; expected report artifacts are present | Evidence for separate-Event accounting direction |
| Fixture checks | No current check references `fixtures/multi-time-card` | Do not claim executable regression coverage |
| Reconciliation / tax / statement matching | No current consumer inspected | Plausible reopen triggers, not current evidence |

This review makes no blanket claim that every report section or editor flow proves F1 unnecessary. The narrower evidence above is sufficient for the decision.

## 7. Decision

**`adopt-later`**

Current accounting and liability settlement can be represented with separate journal Events and the current default date coordinate.

Additional per-row time metadata is not required by a current consumer, but may be reconsidered for reconciliation, tax export, or statement matching.

The account-metadata-plus-override cashflow-due design remains relevant: it gives one Event multiple projection meanings without changing Actual, Cube, or TBDS. Before promoting it to a current capability, the repository would need an executable owner and focused checks (or an explicit decision to retire the stale experimental fixture/design).

## 8. Reopen conditions

Reopen F1 when a concrete consumer requires a second coordinate on the same row, for example:

- reconciliation or statement matching cannot be correct from separate Events and existing identifiers;
- tax export requires a distinct row-level date;
- a cashflow-due implementation needs vocabulary beyond the existing account metadata plus `due_on` override;
- a demonstrated dataset produces incorrect accounting or matching under the current model.

Do not reopen merely because an external fintech model has booking/value/settlement dates.

## 9. Inspected paths

Docs:

- `docs/TIME_AS_AXIS.md`
- `docs/CONVENTIONS.md`
- `docs/JOURNAL_META.md`
- `docs/POSTING_IR_CONTRACT.md`
- `docs/TBDS_CONTRACT.md`
- `docs/CANONICAL_DAILY_CUBE.md`
- `docs/REPORT_CONTRACTS.md`
- `docs/FINTECH_ENGINEERING_REVIEW_BACKLOG.md`
- `docs/archive/completed-plans/EVENT_PROJECTION_PLAN.md`

Current source:

- `src_next/projection.bqn`
- `src_next/cube.bqn`
- `src_next/tbds.bqn`
- `src_next/planned_payments.bqn`
- `src_next/plan_evidence.bqn`
- `src_next/plan_rows.bqn`
- `src_next/event_lens.bqn`
- `src_edit/plan_finish_cmd.bqn`

Fixture and expected artifacts:

- `fixtures/multi-time-card/README.md`
- `fixtures/multi-time-card/accounts.tsv`
- `fixtures/multi-time-card/journal.tsv`
- `fixtures/multi-time-card/plan.tsv`
- `fixtures/multi-time-card/budget_alloc.tsv`
- `fixtures/multi-time-card/cycle.tsv`
- `fixtures/multi-time-card/expected/actual_comparison.tsv`
- `fixtures/multi-time-card/expected/cycle_summary.tsv`
- `fixtures/multi-time-card/expected/envelope_summary.tsv`
- `fixtures/multi-time-card/expected/liquid_assets_summary.tsv`
- `fixtures/multi-time-card/expected/plan_summary.tsv`
- `fixtures/multi-time-card/expected/report_numbers.tsv`
- `fixtures/multi-time-card/expected/report.txt`
- `fixtures/multi-time-card/expected/residual_summary.tsv`

Sandbox verification:

- `data/journal.tsv` — currently contains no card transaction

Searches included:

```bash
rg -n "due_on|due_day|due_month_offset|payment_account" \
  docs config src_next src_edit fixtures checks
rg -n "multi-time-card" checks tools tests src_next .github
```
