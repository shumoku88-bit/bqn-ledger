# Next session

Status: active plan / temporary repository pointer
Owner: report
Canonical: no; current plan: `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`
Exit: remove or replace after the next finite slice is jointly selected

The Actual Comparison numeric-owner runtime migration is complete. Completion
record:

- `docs/archive/completed-plans/ACTUAL_COMPARISON_NUMERIC_OWNER_RUNTIME_MIGRATION-2026-07-15.md`

Current runtime boundary:

```text
actual_comparison.BuildAt ⟨ctx, O⟩
```

`O` is explicit, owns `vm.as_of`, and hard-cuts current actual events. The
current window is `[cycle.start, min(O + 1 day, cycle.end_exclusive))`; the
baseline starts at the previous comparable income anchor and has the same
elapsed length. Human report and machine summary each capture today once at
their entry and pass it explicitly. No compatibility `Build`, section CLI
option, or report-wide `as_of` was added.

Amounts flow from the full checked ledger-wide Posting IR through local TBDS
half-open period views, then report-specific positive debit/credit measure
selection. Positive semantic sides are used only for period keys/counts, with
admitted source identity per lane/account. Anchor identity remains separate,
uses admitted journal/plan posting dates plus the narrow `cycle.tsv`
`income_account` evidence dependency, and is independent of amount sign; it
parses no amount. Applicable rejected actual evidence
is `error` with one diagnostic per source row and no numeric table. Missing
anchor/empty current window is `unavailable`. Vocabulary is
`ok / unavailable / error`; `insufficient_history` is removed.

The PR #261 normal/history fixtures remain unchanged evidence. The normal
fixture intentionally now returns `error` for explicit `O=2026-03-05`; new
clean-target and invalid-date fixtures cover `ok` and fail-closed behavior.
No private production data was accessed.

## Next selectable but unselected report slice

The next Report Projection Alignment candidate is an **Outlook /
`actual_snapshot` characterization foundation**. It should first characterize
current `O`, `L`, plan-anchor, and out-of-cycle behavior before any numeric
migration. No next slice is selected. Do not automatically implement Outlook,
`actual_snapshot`, a generic temporal kernel, report-wide `--as-of`, Projection
Workbench, Daily Trend, Envelopes, or another report lane.

## Daily Capacity completed baseline and parked candidates

The `POLICY_RISK_STYLE` meaning decision, Daily Capacity contract, 31-case
calculator characterization, production-available pure runtime seam,
evidence-adapter ownership audit, and test-only assembler characterization are
complete.

The pure boundary remains:

```text
src_next/daily_capacity.bqn
  BuildDailyCapacityFromEvidence
    ⟨observation, horizon, arithmetic_domain, asset_scope, obligation_scope⟩
      -> contract-shaped result
```

It retains `ok`, `deficit`, `unavailable`, and `error`. No adapter or consumer
imports it, and current Outlook behavior remains unchanged. The test-only
assembler joins explicit in-memory facts and decisions by stable identity and
returns empty input under `error > unavailable > resolved`; it remains
unconnected.

The three independent unselected choices remain:

1. promote the characterized pure assembler seam;
2. select Candidate B for O-bounded account-balance facts; or
3. select Candidate C for pool/reservation facts.

Do not promote the assembler, begin Candidate B/C, add config or metadata, wire
Outlook/report output, or migrate compatibility behavior automatically.
