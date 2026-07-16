# Next session

Status: active plan / temporary repository pointer
Owner: report
Canonical: no; current plan: `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`
Exit: remove or replace after the next finite slice is jointly selected

The Outlook / `actual_snapshot` characterization foundation is complete.
Evidence record:

- `docs/archive/completed-plans/OUTLOOK_ACTUAL_SNAPSHOT_CHARACTERIZATION-2026-07-16.md`
- `fixtures/outlook-actual-snapshot-characterization/`
- `tests/test_src_next_outlook_actual_snapshot_characterization.bqn`

No BQN runtime, report output, source schema, config, metadata, editor behavior,
Daily Capacity behavior, or private production data changed.

## Characterized current boundaries

```text
C = [2026-02-01, 2026-02-11)
O = 2026-02-05
L = 2026-02-12
```

`actual_snapshot.BuildAt ⟨ctx,O⟩` is ledger-cumulative through inclusive O. It
includes pre-cycle history, excludes rows after O, and has no cycle cutoff when O
moves past cycle end. The fixture fixes `liq_total=250` at O and `liq_total=260`
at `O=2026-02-12` after admitting the end-exclusive and later out-of-cycle rows.

The two exported latest-date helpers retain different bounds:

- `actual_snapshot.LatestActualDateInCycle` applies `[C.start,C.end_exclusive)`
  and returns `2026-02-06`;
- Outlook's compatibility helper scans `date >= C.start` without an upper cycle
  bound and returns `2026-02-12`.

For explicit Outlook O, the later L changes frontier evidence but not the
O-bounded actual balance:

```text
vm.as_of = 2026-02-05
last_recorded_on = 2026-02-12
record_frontier_relation = after_observation
record_frontier_distance_days = 7
liq_total = 250
```

The fixture also fixes current remaining-plan anchor behavior. A matched anchor,
a nonexistent anchor, and a row with no anchor are all included in the monetary
aggregate:

```text
fixed_reserve = 210
liq_daily = 6
```

This is compatibility evidence, not target policy.

## Next selectable but unselected report slice

The next Report Projection Alignment candidate is a docs-only compatibility
decision for Outlook / `actual_snapshot` numeric ownership. It should decide:

1. rejected/invalid/unsupported source behavior for an O-bounded checked Posting
   IR or TBDS actual-balance view;
2. whether actual-balance migration proceeds before plan monetary migration;
3. whether the two latest-date helper contracts/names remain compatibility
   surfaces;
4. whether the characterized all-included anchor behavior is preserved,
   corrected, or replaced.

No runtime migration is selected. Do not automatically implement a checked
snapshot adapter, plan-side migration, generic temporal kernel, report-wide
`--as-of`, Daily Capacity connection, Daily Trend, Envelopes, source migration,
or automatic write.

## Daily Capacity completed baseline and parked candidates

The pure seam remains:

```text
src_next/daily_capacity.bqn
  BuildDailyCapacityFromEvidence
    ⟨observation, horizon, arithmetic_domain, asset_scope, obligation_scope⟩
      -> contract-shaped result
```

It remains unconnected. Promotion, Candidate B O-bounded balance facts, and
Candidate C pool/reservation facts remain three independent unselected choices.
Do not infer policy, add config/metadata, or wire Outlook automatically.
