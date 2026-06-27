# as_of section audit

> **Note (2026-06-26):** 旧エンジン (, , ) は削除されました。この文書内の旧エンジンへの参照は履歴として残ります。現行エンジンは  です。
Status: current-behavior inventory  
Date: 2026-06-18

This document records how the human report sections currently apply `as_of`.
It is an inventory, not a behavior change proposal.

Related:

- `docs/TIME_AS_AXIS.md`
- `docs/MAIN_SECTIONS.md`
- `src/reports/report_engine.bqn`
- `src/reports/report_sections.bqn`

## Shared entry behavior

- `src/reports/main_impl.bqn` accepts `--as-of YYYY-MM-DD`.
- Without `--as-of`, `report_engine.Build` reads `dt.Today` once and passes it into `BuildAt`.
- `BuildAt` materializes the full Daily Cube from source TSVs, then slices `cube_balances` at `as_of` for the shared snapshot `bal_final`.
- Section renderers do not call `dt.Today` directly; they render fields from the `report_engine` record.
- Some calculations use `as_of`, while others use all loaded rows or cycle windows that are resolved independently of `as_of`.

## Shared computed values

| value / module | `as_of` behavior | notes |
|---|---|---|
| `bal_final` in `report_engine.BuildAt` | Snapshot at latest cube day `<= as_of`; before first cube day returns zero matrix. | Future-dated journal rows after `as_of` do not affect this snapshot. |
| `ytd_view.Build` | Receives `as_of` and filters to `as_of` year, `year-01-01 <= journal date <= as_of`. | Updated after this audit to match the YTD label. |
| `cycle_view.Build` | Current-cycle call receives `as_of` and sums journal rows in the resolved cycle with `date <= as_of`. | Past-cycle compatibility fields are still computed without `as_of`, but the public past-cycle section is disabled. |
| `balance_view.Build` | Uses snapshot fields plus `as_of <= plan date < cycle_end` for future planned liquid reserve. | Same-day plans are included in reserve. |
| `plan_view.Build` | Uses `as_of` for daily amount ranges, journal lag, no-`plan_id` open filtering, and plan lifecycle status (`overdue_open` / `due_open` / `future_open`). `plan_id` matches in journal produce `completed`. | `last_journal_date` is the max journal coordinate when journal rows exist, with `as_of` only as empty-journal fallback. |
| `liquid_view.Build` | Trend dates are journal dates in current cycle up to `as_of`, plus `as_of`. Future plan income uses `as_of < plan date < cycle_end`. | Trend is sparse journal-date based, not every calendar day. |
| `envelope_view.Build` | Envelope history/current balances are clipped to cube days `<= as_of`. Future planned envelope spend uses `as_of < plan date < cycle_end`. | Same-day plans are excluded from envelope future spending. |
| `residual_view.Build` | Receives `as_of` and `plan_status_table`. Actual rows are limited to current cycle dates `<= as_of`; plan rows use lifecycle status and exclude `future_open`. | Compares due/open overdue/completed plan rows and observed actuals only. |
| `hygiene_view.Build` | Receives `as_of` and warns about `journal.tsv` rows after `as_of`. | Some warnings inherit `as_of`-sliced envelope values, while duplicate/stale checks use raw rows and cycle start. |

## Human report sections

| section | key | `as_of` application | Future-dated `journal.tsv` behavior |
|---|---|---|---|
| 1 | `snapshot` | Uses `liq_total`, `sav_total`, `inv_total`, `assets_total`, `liabilities_total` from `bal_final` snapshot at `as_of`. | Rows after `as_of` are not included in snapshot balances. |
| 2 | `ytd` | Uses `as_of` cutoff and only journal rows in the observation year. | Rows after `as_of` are excluded. |
| 3 | `balances` | Uses account balances from `bal_final` snapshot at `as_of`. | Rows after `as_of` are not included in displayed balances. |
| 4 | `cycle` | Uses resolved cycle window and journal rows inside it up to `as_of`. | Rows after `as_of` are excluded. |
| 5 | `envelopes` | Current envelope balances, cycle allocation/spent, avg spend, and health are computed from budget cube state up to `as_of`; days-left uses `as_of -> cycle_end`. | Budget consumption from future journal rows after `as_of` is not included in current envelope balance/spent. |
| 6 | `planned` | Displays open future payments with `plan.date >= as_of`, plus a Plan Status table for all plan rows. Completed status is derived by matching `plan_id` in journal. No-`plan_id` rows are open by date relative to `as_of`. | Overdue open rows are shown in Plan Status, not in the future payments list. Future journal rows after `as_of` are warned elsewhere; a matching future journal `plan_id` would still mark a plan completed because journal rows are source data. |
| 7 | `recent` | No `as_of` cutoff. Shows last 10 journal rows by file order. | Future rows are shown if they are among the last rows. |
| 8 | `check` | Metadata readiness has no `as_of`. Hygiene warnings partly inherit cycle/envelope state; duplicate/stale plan checks use raw rows. | Future rows can affect duplicate-plan checks and cycle-derived warnings. |
| 9 | `outlook` | Prints `as_of`, snapshot assets, `last_journal_date`, days left, and daily amounts based on plans in `as_of <= date < cycle_end`. | Snapshot excludes future actual rows, but `last_journal_date` / lag may be affected by future rows in file order. |
| 10 | `daily-trend` | Trend dates are current-cycle journal dates `<= as_of`, plus `as_of`; balances are sampled at each trend date. | Journal rows after `as_of` are not trend points and do not affect balances at trend dates before them. |
| 11 | `cycle-consult` | Explicitly uses `as_of`: recorded actuals are `cycle_start <= journal date <= as_of`; remaining plans are `as_of <= plan date < cycle_end`. | Future actual rows after `as_of` are excluded from the recorded-actual subtotal. |
| 12 | `cashflow` | Composite view over outlook, envelope, and daily-trend fields. | Inherits mixed behavior from those fields. |
| 13 | `residual` | Uses current-cycle expense rows observed through `as_of`; plan rows are included only when lifecycle status is `completed`, `due_open`, or `overdue_open`. | Future actual rows after `as_of` are excluded; `future_open` plans are excluded until due/overdue/completed. |
| 14 | `debug` | Displays `as_of` and checks invariants against `bal_final` snapshot. | Invariant checks use snapshot balances, so future rows after `as_of` do not affect them. Source row counts still include all rows. |

## Current suspicious points / follow-up candidates

These are not changed by this audit, but should be considered before tightening `as_of` contracts or building Go input workflows.

1. **YTD was corrected after this audit.**
   - `ytd_view.Build` now uses `year-01-01 <= journal date <= as_of`.
   - Future journal coordinates after `as_of` are excluded from the YTD section.

2. **Cycle summary and residual were corrected after this audit.**
   - `cycle_view.Build` now receives `as_of` for the current cycle and excludes later journal rows.
   - `residual_view.Build` now receives `as_of` and excludes future actual rows plus `future_open` plan rows.
   - `cycle-consult` continues to have its own explicit `as_of`-bounded recorded subtotal.

3. **Cycle boundary resolution is based on journal/plan data, not `as_of`.**
   - `cycle.bqn` uses the maximum journal date for `last_dn` and `calendarMonth` base.
   - A future-dated journal row can change the resolved current cycle even when reporting with an earlier `--as-of`.

4. **`last_journal_date` was corrected after this audit.**
   - It now reports the max journal coordinate when journal rows exist, with `as_of` only as empty-journal fallback.
   - Plan-open behavior was kept separate and still uses `as_of` for no-`plan_id` rows.
   - A later rename to `last_recorded_on` may still be clearer, but the displayed lag now reflects journal recency.

5. **Planned payments use `as_of` for no-`plan_id` openness.**
   - This preserves the former effective behavior while allowing `last_journal_date` to mean last recorded journal coordinate.
   - Rows with `plan_id` are excluded when matching journal `plan_id` exists.

6. **Plan filtering is not uniform across views.**
   - `planned` applies open/completed filtering.
   - `cycle-consult` uses raw `plan_rows` by date range.
   - Plan-layer based calculations use the cube’s plan updates, so they may include rows that `future_payments` hides.

7. **Envelope average elapsed days was corrected after this audit.**
   - `envelope_view.bqn` now uses ordinal day difference for inclusive elapsed days.
   - `fixtures/envelope-month-boundary` fixes the month-boundary regression case (`2026-01-31` to `2026-02-02`).

8. **Same-day plan inclusion differs by view.**
   - Outlook / balance reserve uses `as_of <= plan date < cycle_end`.
   - Envelope future spend and liquid trend future income use `as_of < plan date < cycle_end`.
   - The distinction may be intentional, but it should be documented as a contract if kept.

## Suggested next checks

- Added `fixtures/future-journal-as-of` with `--as-of 2026-01-03` to freeze current behavior for snapshot, YTD, cycle, residual, recent, and trend. Residual is now `as_of`-bounded while recent remains file-order based.
- Journal rows after `as_of` remain a historical-observation warning in Sec8. Journal rows after `system_today` are input errors and fail lint/strict check because future declarations belong in `plan.tsv`.
- Decide whether cycle resolution should use observation time (`as_of`) or data state (`last recorded anchor`) for each cycle mode.
- Decide whether plan-derived calculations should all share `plan_open` semantics, or whether raw plan-layer calculations intentionally differ.
