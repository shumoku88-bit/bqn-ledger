# Outlook / Actual Snapshot Characterization

Status: completed
Owner: report
Canonical: no; current paths: `src_next/outlook.bqn`, `src_next/actual_snapshot.bqn`, `docs/OUTLOOK_TEMPORAL_CURRENT.md`, and `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`
Exit: retain as pre-migration evidence; any numeric-owner or anchor compatibility decision must cite this fixture and its current values

## Scope

This slice characterizes the current Outlook / `actual_snapshot` source-parser path before any numeric-owner migration. It changes no BQN runtime, report output, source schema, config, metadata, editor behavior, currency policy, Daily Capacity behavior, or private production data.

Public synthetic evidence:

- `fixtures/outlook-actual-snapshot-characterization/`
- `tests/test_src_next_outlook_actual_snapshot_characterization.bqn`
- existing empty-frontier and explicit-observation evidence in `tests/test_src_next_outlook_explicit_observation_path.bqn`

## Time roles

The fixture fixes:

```text
C = [2026-02-01, 2026-02-11)
O = 2026-02-05
L = 2026-02-12
```

`O`, `L`, and `C` remain distinct.

## Actual snapshot behavior

`actual_snapshot.BuildAt ⟨ctx,O⟩` rereads `journal.tsv`, validates date and integer amount text locally, resolves both account names against `ctx.resolved`, and accumulates every accepted source row with `date <= O`.

The current view is ledger-cumulative to `O`, not cycle movement:

- the pre-cycle `2026-01-31` row is included;
- the `2026-02-05` row is included because the cutoff is inclusive;
- the in-cycle `2026-02-06` row is excluded at `O=2026-02-05`;
- the `2026-02-11` end-exclusive row and `2026-02-12` out-of-cycle row are excluded at that O;
- moving O to `2026-02-12` admits both the end-exclusive and later out-of-cycle rows because `BuildAt` has no cycle cutoff.

At `O=2026-02-05`, the characterized entries are:

```text
assets:cash/JPY    250
income:base/JPY   -300
expenses:misc/JPY   50
```

The liquid/assets/net-worth values are all `250`.

At `O=2026-02-12`, the characterized entries are:

```text
assets:cash/JPY      260
income:base/JPY     -300
income:after_o/JPY   -30
income:outside/JPY   -20
expenses:misc/JPY     90
```

The liquid/assets/net-worth values are all `260`.

## Two differently bounded latest-date helpers

The fixture makes the current helper distinction explicit:

- `actual_snapshot.LatestActualDateInCycle` applies `[C.start,C.end_exclusive)` and returns `2026-02-06`;
- Outlook's exported compatibility `LatestActualDateInCycle` delegates to a frontier scan with `date >= C.start` and no upper cycle bound, returning `2026-02-12`.

The second helper name therefore does not imply an upper cycle bound. This is compatibility evidence, not a rename or runtime change.

## Explicit Outlook observation and frontier

For `outlook.BuildAt ⟨ctx,2026-02-05⟩`:

- `vm.as_of = 2026-02-05`;
- actual balances use the explicit O cutoff and remain `liq_total=250`;
- `last_recorded_on = 2026-02-12`;
- `record_frontier_relation = after_observation`;
- `record_frontier_distance_days = 7`;
- `journal_lag = 0`;
- `days_left = 6` through `C.end_exclusive`.

This confirms that a source coordinate after O and after cycle end may move L without entering the O-bounded actual balance.

## Current remaining-plan anchor behavior

The fixture contains three otherwise comparable remaining expense rows:

1. `60` with an anchor matching the in-cycle `2026-02-06` income;
2. `70` with a nonexistent anchor;
3. `80` with no anchor metadata.

The current source-parser path includes all three rows. The characterized values are:

```text
planned_future_income = 0
fixed_reserve = 210
liq_daily = floor((250 - 210) / 6) = 6
```

Therefore, for this valid source shape, anchor presence or membership does not exclude a remaining-plan row from the Outlook monetary aggregate. This record does not endorse that behavior as target policy. A later compatibility decision must explicitly preserve, correct, or replace it instead of silently claiming parity.

## Existing boundary evidence retained

The existing explicit-observation test continues to fix:

- moving O while holding L fixed;
- moving L while holding O fixed;
- empty frontier as explicit `unavailable` on `BuildAt`;
- legacy `Build` cycle-start fallback behavior.

This slice supplements those tests with cumulative actual boundaries, cycle-end/out-of-cycle evidence, and plan-anchor monetary behavior.

## Verification

GitHub Actions workflow `check`, run 938, completed successfully on the characterized implementation head:

- all BQN unit tests, including `test_src_next_outlook_actual_snapshot_characterization.bqn`;
- all existing src_next fixture and section checks;
- existing Outlook explicit-observation and empty-frontier evidence;
- editor and engine-independent checks;
- MCP lint/tests;
- coverage.

The first focused expectation pass was intentionally allowed to fail and was used as characterization evidence. It exposed `fixed_reserve=130` rather than the assumed `60`. A second discriminating fixture added a nonexistent anchor and an unanchored row, exposing the final current value `fixed_reserve=210`. The final expectations were then verified by the focused test and the full repository suite. Runtime code was not changed to make the fixture pass.

## Next selectable but unselected slice

The next finite Report Projection Alignment candidate is a compatibility decision for Outlook / `actual_snapshot` numeric ownership. It should decide separately:

1. how an O-bounded checked Posting IR or TBDS balance view treats rejected, invalid-date, invalid-amount, unsupported-currency, and unknown-account rows;
2. whether the actual-balance migration can proceed before plan monetary aggregates;
3. whether the two latest-date helper contracts and names remain compatibility surfaces;
4. whether the characterized all-included anchor behavior is preserved, corrected, or replaced when plan amounts move to checked ownership.

No runtime migration, shared temporal kernel, report-wide `--as-of`, Daily Capacity connection, config change, source migration, or automatic write is selected by this record.
