# Next session

Status: active plan / temporary repository pointer
Owner: report
Canonical: no; current plan: `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`
Exit: remove or replace after the next finite slice is jointly selected

Actual Comparison, Outlook Slices A/B, and Daily Trend plan monetary ownership are complete.

Latest record and executable evidence:

- `docs/archive/completed-plans/DAILY_TREND_PLAN_NUMERIC_OWNER_RUNTIME_MIGRATION-2026-07-16.md`
- `src_next/daily_trend_plan.bqn`
- `fixtures/daily-trend-plan-numeric-owner-target/`
- `tests/test_src_next_daily_trend_plan_numeric_owner.bqn`
- `checks/check-src-next-daily-trend-plan-numeric-owner.sh`

## Completed Daily Trend boundary

Daily Trend keeps current-source coordinate replay:

```text
S = current source snapshot
D = rendered row coordinate
O_row = D
C = selected cycle
K = unavailable / not claimed
```

Fixed-reserve money now comes from admitted `plan.tsv` Posting IR joined to source evidence by stable `source_row`. Source evidence continues to own plan ID and completion identity at each D. The existing future-income path already uses admitted plan projection rows.

Applicable invalid dates, unknown accounts, missing required evidence, or a join other than one debit/credit Posting IR pair returns `error / rejected_plan_evidence`. Numeric trend rows are then absent; rejected inputs are not converted to zero. Metadata absence and explicit empty `plan_id=` keep the five-field fallback; duplicate metadata keeps first-match precedence, and duplicate plan/completion identities keep prior exact-any-match behavior.

The migration does not change row membership, header observation, cycle policy, completion policy, current-source replay, or the absence of historical knowledge boundary K.

## Next selectable but unselected report slice

The next Report Projection Alignment candidate is **Envelopes / Cycle remaining-plan monetary ownership**.

Before implementation, characterize allocation compatibility and cycle remaining-plan paths independently. Do not infer:

- automatic selection or implementation;
- envelope backing or cycle policy changes;
- a report-wide observation clock or generic temporal kernel;
- Cube shape, source/config/metadata, or editor changes;
- Daily Capacity wiring, automatic advice, or writes.

## Daily Capacity remains parked

The pure `src_next/daily_capacity.bqn` seam remains unconnected. Its assembler promotion, Candidate B O-bounded balance facts, and Candidate C pool/reservation facts remain independent unselected choices.
