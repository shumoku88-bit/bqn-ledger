# Next session

Status: active plan / temporary repository pointer
Owner: report
Canonical: no; current plan: `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`
Exit: remove or replace after the next finite slice is jointly selected

Outlook / `actual_snapshot` Slice A is complete.

Current records:

- `docs/archive/completed-plans/OUTLOOK_ACTUAL_SNAPSHOT_CHARACTERIZATION-2026-07-16.md`
- `docs/archive/completed-plans/OUTLOOK_ACTUAL_SNAPSHOT_NUMERIC_OWNER_COMPATIBILITY_DECISION-2026-07-16.md`
- `docs/archive/completed-plans/OUTLOOK_ACTUAL_SNAPSHOT_NUMERIC_OWNER_RUNTIME_MIGRATION-2026-07-16.md`
- `fixtures/actual-snapshot-numeric-owner-target/`
- `tests/test_src_next_actual_snapshot_numeric_owner.bqn`
- `checks/check-src-next-actual-snapshot.sh`

## Completed Slice A boundary

`actual_snapshot.BuildAt ⟨ctx,O⟩` now derives its ledger-cumulative inclusive-O balances from checked ledger-wide Posting IR through a local `[O,O+1)` actual-layer TBDS closing view.

```text
rows before O -> opening
rows on O     -> movement
closing       -> cumulative balance through O
```

This preserves pre-cycle history and does not apply `C.end_exclusive` as an actual-balance cutoff when O lies later.

The runtime now exposes `state / reason / diagnostics`:

- invalid O -> `error / invalid_observation`;
- rejected actual with valid `D <= O` -> `error / rejected_actual_evidence`;
- rejected actual with valid `D > O` -> outside this snapshot;
- invalid-date actual -> applicability-unknown and `error`;
- valid empty journal -> `ok` with real zero balances;
- source diagnostics deduplicate the debit/credit pair per source row.

Outlook propagates snapshot failure. It does not combine plan values with an invalid actual balance or print normal daily-allowance numbers. Machine output now includes Outlook status/reason/diagnostics, while normal plan and anchor behavior remains unchanged when the snapshot is valid.

The two differently bounded latest-date helpers remain compatibility surfaces and were not renamed.

## Next selectable but unselected slice

The next Report Projection Alignment candidate is **Slice B: Outlook remaining-plan monetary ownership and anchor policy**.

The approved target contract is:

- admitted `plan.tsv` Posting IR owns amounts and liquid delta;
- existing plan-ID evidence owns completed/unfinished identity;
- horizon remains `O <= plan date < C.end_exclusive`;
- unanchored rows remain eligible;
- valid anchored outflows remain reserved even when their anchor is unmet;
- valid anchored inflows require an admitted actual matching income event at or before O within C;
- unknown, non-income, duplicate, or empty anchor metadata is `error`;
- completed plans do not contribute.

Slice B remains unselected. Do not infer helper renaming, Daily Capacity wiring, a generic temporal kernel, report-wide `--as-of`, Cube shape change, source migration, editor changes, automatic advice, or writes.

## Daily Capacity remains parked

The pure `src_next/daily_capacity.bqn` seam remains unconnected. Its assembler promotion, Candidate B O-bounded balance facts, and Candidate C pool/reservation facts remain independent unselected choices and are not implied by Slice A.
