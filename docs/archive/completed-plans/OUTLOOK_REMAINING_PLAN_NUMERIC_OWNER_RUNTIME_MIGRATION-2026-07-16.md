# Outlook Remaining-Plan Numeric-Owner Runtime Migration

Status: completed runtime slice
Owner: report
Canonical: no; current contracts are `docs/OUTLOOK_TEMPORAL_CURRENT.md`, `docs/REPORT_CONTRACTS.md`, runtime modules, and executable checks
Exit: retain as completed Slice B evidence; do not infer Daily Capacity or later report slices
Decision: `OUTLOOK_ACTUAL_SNAPSHOT_NUMERIC_OWNER_COMPATIBILITY_DECISION-2026-07-16.md`
Slice A: `OUTLOOK_ACTUAL_SNAPSHOT_NUMERIC_OWNER_RUNTIME_MIGRATION-2026-07-16.md`

## Completed boundary

Slice B moves Outlook's current remaining-plan monetary aggregate away from its independent raw `plan.tsv` amount parser.

The runtime path is now:

```text
checked ledger-wide Posting IR
  -> admitted plan.tsv posting pair joined by source_row
  -> liquid-account delta

plan/journal source evidence
  -> plan metadata
  -> existing plan_id completion identity
  -> anchor validation and activation

joined checked result
  -> future liquid net
  -> planned future income
  -> fixed reserve
  -> Outlook daily amounts
```

`src_next/outlook_remaining_plan.bqn` is the narrow checked owner. `src_next/outlook.bqn` consumes its result only after the checked actual snapshot succeeds.

## Preserved temporal contract

The remaining horizon remains:

```text
O <= plan date < C.end_exclusive
```

- O is inclusive;
- `C.end_exclusive` is excluded from current remaining money;
- a valid row later than the horizon does not fail the current aggregate merely because its posting evidence is rejected;
- an invalid-date plan row has unknown applicability and fails closed;
- cycle-end next-obligation rendering remains a separate compatibility surface and was not migrated by this slice.

## Completion ownership

Existing `plan_rows.PlanId` evidence owns completed/unfinished identity.

- unfinished in-horizon plans are eligible;
- completed plans do not contribute to remaining income, reserve, net, or daily amounts;
- source text may retain identity and metadata, but it does not own the amount.

## Anchor policy

`anchor=<account>` must resolve to exactly one account with `role=income`.

Anchor activation requires an admitted actual journal credit posting for that income account in:

```text
C.start <= D <= O
D < C.end_exclusive
```

The safety policy is asymmetric:

- unanchored outflows are reserved;
- valid anchored outflows are reserved even when the anchor is unmet;
- unanchored inflows are included;
- valid anchored inflows are included only when the anchor is active through O;
- a matching actual event after O does not activate the inflow at O.

This prevents a conditionally expected inflow from increasing spendable capacity early while retaining known obligations.

## Fail-closed behavior

Applicable unfinished plan evidence fails Outlook closed when it has:

- unknown account posting evidence;
- structural source/Posting-IR join failure;
- duplicate anchor metadata;
- empty anchor metadata;
- unknown anchor account;
- anchor account without `role=income`;
- invalid date with unknown applicability.

Outlook returns:

```text
state = error
reason = rejected_plan_evidence
monetary fields = unavailable
```

Diagnostics are emitted once per source row rather than once per debit/credit posting.

## Intentional compatibility change

The former characterization fixture admitted a nonexistent anchor and produced `fixed_reserve=210`. That result remains historical evidence only.

Under the approved target contract, the same applicable nonexistent anchor is invalid evidence. Outlook now returns `error / rejected_plan_evidence` instead of a normal-looking amount.

## Evidence

- target fixture: `fixtures/outlook-remaining-plan-numeric-owner-target/`;
- focused test: `tests/test_src_next_outlook_remaining_plan_numeric_owner.bqn`;
- updated characterization: `tests/test_src_next_outlook_actual_snapshot_characterization.bqn`;
- compatibility test: `tests/test_src_next_outlook.bqn`;
- integration guard: `checks/check-src-next-outlook-remaining-plan.sh`;
- suite routing: `tools/check.sh`.

The numeric-owner test deliberately gives source evidence amount `999` while the checked Posting IR for the same source row carries `10`; the result remains `10`.

## Next selectable report slice

The next Report Projection Alignment candidate is `daily-trend` plan monetary ownership.

It remains unselected. Completion of Outlook Slice B does not authorize:

- Daily Capacity wiring;
- a generic temporal kernel;
- a report-wide observation clock;
- latest-date helper renaming;
- Cube shape change;
- source/config/metadata migration;
- editor changes;
- automatic advice or writes;
- private production-data access.
