# Report Contracts

Status: current index / boundary note
Owner: report
Canonical: yes
Exit: keep current while `src_next` report contracts route through this index
Date: 2026-07-16

This file exists so current safety and report-policy docs have a live landing page.

It is **not** a revival of the archived old-engine report contract. The historical contract remains at:

- `docs/archive/completed-plans/REPORT_CONTRACTS.md`

## Current sources of truth

For current `src_next` behavior, use these in order:

1. `tools/report --list-sections` — canonical list of currently runnable human report sections.
2. `src_next/report_sections.bqn` — static section key, canonical order, and metadata descriptor fields.
3. `src_next/report.bqn` — section builder mapping, dispatcher, and human report rendering entrypoint.
4. `tools/report-section-metadata` — structured section metadata export for UI tools (TSV default / JSON), without reading source TSV.
5. `src_next/summary.bqn` — current machine-readable compact summary fields.
6. `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md` — checklist for section identity, data ownership, empty-state/status behavior, labels, machine output, and fixture coverage.
7. `docs/archive/active-plans/REPORT_SECTION_STATUS_POLICY.md` — `OK / WARN / ERROR / SKIPPED / UNAVAILABLE` status vocabulary and partial implementation policy.
8. `docs/TIME_AS_AXIS.md` — canonical temporal vocabulary and non-equivalences.
9. `docs/DAILY_TREND_TEMPORAL_CURRENT.md` — compact current Daily Trend temporal contract.
10. `docs/OUTLOOK_TEMPORAL_CURRENT.md` — compact current Outlook temporal and checked-money contract.
11. Fixture checks under `checks/check-src-next-*.sh` and BQN unit tests under `tests/test_src_next_*.bqn` — executable contracts.

## Current section list

Daily Trend currently uses current-source coordinate replay with row observation `O_row = D`; it does not claim historical knowledge replay. Outlook has a separate explicit observation contract. Use the two compact current routes above instead of reconstructing current behavior from archived implementation decisions.

As of this note, `tools/report --list-sections` reports these section keys:

```text
snapshot
issues
ytd
balances
cycle
trial-balance
envelopes
planned
recent
check
outlook
daily-trend
daily-flow
actual-comparison
debug
```

Do not edit this list by hand as a contract change. If section behavior changes, update the implementation/checks first, then refresh this note if it is useful.

## Actual Comparison boundary

`actual-comparison` receives an explicit observation through `actual_comparison.BuildAt ⟨ctx,O⟩`. Its current window is `[cycle.start, min(O + 1 day, cycle.end_exclusive))`; `O` is a hard cutoff and owns `vm.as_of`. Amounts come from actual-layer local TBDS period views over checked ledger-wide Posting IR. Counts use admitted posting source identity per lane/account; rejected-row diagnostics deduplicate separately per source row.

Status vocabulary is `ok / unavailable / error`. A missing previous anchor or empty current window is `unavailable`; invalid observation/cycle or applicable rejected actual evidence is `error`. Both states have an empty numeric table, but machine reason and human wording distinguish them. Observable invalid-date journal evidence fails closed; a valid-date rejected journal row fails only when it falls in the current or baseline window. Snapshot-wide amount/currency authorization still precedes section construction.

Production human and machine entries capture today once through `src_next/date.bqn` and pass it explicitly. There is no Actual Comparison CLI override or report-wide `as_of` contract.

Executable coverage: `tests/test_src_next_actual_comparison.bqn` and `checks/check-src-next-actual-comparison.sh`.

## Outlook checked actual snapshot boundary

`outlook.BuildAt ⟨ctx,O⟩` receives actual balances from `actual_snapshot.BuildAt ⟨ctx,O⟩`. The snapshot is ledger-cumulative through inclusive O and derives numeric balances from checked ledger-wide Posting IR through a local `[O,O+1)` actual-layer TBDS closing view, not an independent `journal.tsv` amount parser.

Rows before O form TBDS opening, rows on O form movement, and closing is the cumulative balance through O. Pre-cycle history therefore remains part of the balance, and `cycle.end_exclusive` does not cap the snapshot when O is later.

Snapshot and Outlook status vocabulary for this boundary is `ok / error`.

- invalid observation -> `error / invalid_observation`;
- invalid-date actual evidence -> applicability-unknown and `error`;
- valid-coordinate rejected actual with `D <= O` -> `error / rejected_actual_evidence`;
- valid-coordinate rejected actual with `D > O` -> outside that O snapshot;
- valid empty journal -> `ok` with real zero balances.

Diagnostics deduplicate checked debit/credit posting pairs by source row. On snapshot error, Outlook does not combine plan values with invalid actual balances and does not render normal daily-allowance numbers.

Executable coverage: `tests/test_src_next_actual_snapshot_numeric_owner.bqn` and `checks/check-src-next-actual-snapshot.sh`.

## Outlook checked remaining-plan boundary

`outlook_remaining_plan.BuildAt ⟨ctx,O⟩` owns current remaining-plan monetary aggregation.

The checked owner split is:

| Meaning | Owner |
|---|---|
| amount and liquid delta | admitted `plan.tsv` Posting IR |
| source identity and metadata | source evidence joined by `source_row` |
| completed / unfinished | existing `plan_rows.PlanId` evidence |
| observation and horizon | explicit O and selected C |
| anchor activation | admitted actual income-credit evidence through O |

The remaining horizon is `O <= D < C.end_exclusive`. Completed plan rows are excluded.

Anchor policy is asymmetric for household safety:

- unanchored outflows are reserved;
- valid anchored outflows are reserved even when their anchor is unmet;
- unanchored inflows are included;
- valid anchored inflows are included only after an actual matching income event is admitted at or before O within C;
- an anchor event after O does not activate the inflow at O.

`anchor=` must appear at most once, be nonempty, resolve exactly, and identify an account with `role=income`. Applicable unknown-account, invalid-date, invalid-anchor, or structural join evidence returns `error / rejected_plan_evidence`. Outlook then exposes source-row diagnostics and suppresses all monetary output.

Cycle-end next-obligation rendering remains a separate compatibility surface and may still read source plan rows. Slice B migrates the current remaining aggregate, not every plan consumer.

Machine output includes `src_next_outlook_status`, `src_next_outlook_reason`, and `src_next_outlook_diagnostic` for both actual and plan failures.

Executable coverage: `tests/test_src_next_outlook_remaining_plan_numeric_owner.bqn` and `checks/check-src-next-outlook-remaining-plan.sh`.

## Outlook envelope presentation boundary

Human Outlook uses the existing household group settings without changing its overall liquid arithmetic. Envelopes whose `group` is in `HOUSEHOLD_GROUP_LIFE` appear in the daily-use table with `remaining` and `/day`. Envelopes whose `group` is in `HOUSEHOLD_GROUP_RESERVE` appear separately under `まとめ支出の確保` with `remaining` only. Empty groups omit their respective table. Unknown groups remain outside both Outlook tables.

This is a human presentation split only. It does not change `liq_total`, planned income/expense, `liq_basis`, `liq_daily`, budget allocation, envelope backing, execution-plan linkage, or machine Outlook output.

Executable coverage: `tests/test_src_next_outlook.bqn` and `fixtures/outlook-envelope-purpose-split/`.

## Daily Trend checked plan-money boundary

Daily Trend remains current-source coordinate replay with `O_row = D`. Ordinary row membership, header observation, cycle boundaries, and the lack of historical knowledge boundary K are unchanged.

The monetary/evidence split is:

| Meaning | Owner |
|---|---|
| future planned-income delta | admitted plan Posting IR already present in the cycle projection |
| fixed reserve amount | admitted `plan.tsv` debit Posting IR |
| stable source correspondence | `source_file=plan.tsv` plus `source_row` |
| plan ID and completion identity | source evidence using the existing `plan_rows` / overlap fallback contract |
| reserve observation | each rendered row coordinate D |

For every applicable source plan row, `src_next/daily_trend_plan.bqn` requires exactly one admitted debit/credit pair with matching date and plan layer. Fixed classification comes from the admitted debit account. Source amount text is never parsed by the helper.

At D, a fixed plan contributes when `D <= plan date < C.end_exclusive` and no matching completion row exists at or before D. This preserves same-day completion exclusion, completion-before-due exclusion, multiple-day behavior, and end-exclusive cycle semantics. The separate future-income rule remains strict `plan date > D`.

Invalid plan dates have unknown applicability and fail closed. Applicable unknown accounts, malformed required evidence, or structural join failure returns `error / rejected_plan_evidence`. Daily Trend then exposes diagnostics and no numeric trend rows; these states are not converted to zero.

Identity policy is unchanged. Metadata absence and explicit empty `plan_id=` use the five-field fallback identity; duplicate metadata preserves existing first matching token precedence; duplicate plan identities and duplicate completion rows preserve exact-any-match completion behavior. Posting IR does not reject those identity shapes, so this helper does not promote overlap ambiguity diagnostics into a new runtime error.

Executable coverage: `tests/test_src_next_daily_trend_plan_numeric_owner.bqn`, `fixtures/daily-trend-plan-numeric-owner-target/`, and `checks/check-src-next-daily-trend-plan-numeric-owner.sh`.

## Envelope safety note

The `envelopes` section must not show only per-envelope balances while hiding an over-allocated budget pool. Current `src_next/envelope_computation.bqn` derives the unassigned pool from `accounts.tsv` entries with `role=budget kind=unassigned` and exposes these compact summary keys.

Important: this is **ledger unassigned**, not cash-backed surplus. It is the unallocated amount inside the Budget layer / `budget_alloc.tsv` movements. It must not be presented as "safe to spend" until a Budget Backing invariant defines 可用資金 (`type=liquid`) and cash backing for envelope balances.

- `src_next_envelope_unassigned_remaining`
- `src_next_envelope_unassigned_status`
- `src_next_envelope_unassigned_account_count`

If the unassigned pool is negative, status is `OVER_ALLOCATED` and the human report shows a visible warning.

The human section groups envelopes into Dynamic / Execution / Unassigned / Backing diagnostic blocks. `envelope_role=dynamic|execution` is used when present; missing `kind=envelope` falls back to dynamic for compatibility. Unknown roles are displayed separately and excluded from active envelope totals. Existing envelope machine-readable keys are preserved. `readiness` exposes unknown/inconsistent `envelope_role` counts so metadata drift is visible.

The section also exposes a readonly backing diagnostic. This is intentionally not a write-path or allocation rule yet: `src_next_envelope_funding_base` is currently a provisional `type=liquid` actual closing balance, while `src_next_envelope_allocated_total` is the sum of active envelope remaining balances. `src_next_envelope_cash_backed_unassigned` and `src_next_envelope_backing_status` show whether the envelope balances are cash-backed under that provisional base.

Backing status vocabulary:

- `OK`: 現金裏付け未割当 (cash-backed unassigned) equals ledger unassigned.
- `MISMATCH`: 現金裏付け未割当 differs from ledger unassigned; readonly diagnostic only, no automatic correction. This is not a hard warning by itself.
- `OVER_ALLOCATED`: active envelope remaining total exceeds the provisional funding base. This is the strong warning state.
- `unavailable...` / `error...`: backing diagnostic cannot be trusted because the unassigned budget account is missing, ambiguous, or otherwise unavailable.

- `src_next_envelope_funding_base`
- `src_next_envelope_allocated_total`
- `src_next_envelope_cash_backed_unassigned`
- `src_next_envelope_ledger_cash_delta`
- `src_next_envelope_backing_status`

The section also exposes a readonly execution-vs-plan coverage diagnostic when `EXECUTION_PLANNED_PAYMENTS_ENVELOPE` is set in config. It compares the named execution envelope remaining balance with unfinished in-cycle planned payments. This is diagnostic only and never writes adjustment rows.

- `src_next_envelope_execution_planned_envelope`
- `src_next_envelope_execution_planned_remaining`
- `src_next_envelope_execution_planned_open_total`
- `src_next_envelope_execution_planned_delta`
- `src_next_envelope_execution_planned_status`
- `src_next_envelope_execution_planned_row` (repeated: `date<TAB>category<TAB>memo<TAB>amount<TAB>plan_id`)

- `src_next_envelope_funding_base_source` (repeated when funding source accounts exist)
- `src_next_envelope_active_remaining_source` (repeated)
- `src_next_envelope_ledger_unassigned_source` (repeated when unassigned account exists)
- `src_next_envelope_active_movement` (repeated budget-layer movement provenance)
- `src_next_envelope_ledger_unassigned_movement` (repeated budget-layer movement provenance)

Movement provenance values are TSV-like payloads: `date<TAB>source_row<TAB>account<TAB>side<TAB>delta<TAB>source_id`.

## What belongs here later

Only add stable contracts here when they are true for the current `src_next` engine and have a check/fixture or clear implementation reference.

Good candidates:

- per-section checklist applications after they have matching checks;
- section-level status contract once the output is uniform enough to document;
- machine-readable summary key groups that are intentionally stable;
- fail-closed behavior for known invalid input classes.

Do not put old-engine guarantees here unless they have been revalidated against current `src_next`.
