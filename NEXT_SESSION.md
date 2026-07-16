# Next session

Status: active plan / temporary repository pointer
Owner: report
Canonical: no; current plan: `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`
Exit: remove or replace after the next finite slice is jointly selected

Outlook Report Projection Alignment Slices A and B are complete.

Current records:

- `docs/archive/completed-plans/OUTLOOK_ACTUAL_SNAPSHOT_CHARACTERIZATION-2026-07-16.md`
- `docs/archive/completed-plans/OUTLOOK_ACTUAL_SNAPSHOT_NUMERIC_OWNER_COMPATIBILITY_DECISION-2026-07-16.md`
- `docs/archive/completed-plans/OUTLOOK_ACTUAL_SNAPSHOT_NUMERIC_OWNER_RUNTIME_MIGRATION-2026-07-16.md`
- `docs/archive/completed-plans/OUTLOOK_REMAINING_PLAN_NUMERIC_OWNER_RUNTIME_MIGRATION-2026-07-16.md`
- `fixtures/outlook-remaining-plan-numeric-owner-target/`
- `tests/test_src_next_outlook_remaining_plan_numeric_owner.bqn`
- `checks/check-src-next-outlook-remaining-plan.sh`

## Completed Outlook boundary

`actual_snapshot.BuildAt ⟨ctx,O⟩` derives ledger-cumulative inclusive-O balances from checked actual Posting IR through a local `[O,O+1)` TBDS closing view.

`outlook_remaining_plan.BuildAt ⟨ctx,O⟩` derives current remaining-plan money from admitted plan Posting IR joined to source identity, completion, and anchor evidence.

The remaining horizon is:

```text
O <= plan date < C.end_exclusive
```

Completed plans do not contribute.

Anchor policy is asymmetric:

- valid anchored outflows remain reserved when the anchor is unmet;
- valid anchored inflows count only after an admitted actual matching income event at or before O within C;
- unknown, non-income, duplicate, or empty anchor metadata is `error`.

Applicable actual or plan evidence failure propagates through Outlook. Monetary fields become `unavailable`, source-row diagnostics remain visible, and normal daily-allowance numbers are not rendered.

The two differently bounded latest-date helpers remain compatibility surfaces and were not renamed. Cycle-end next-obligation rendering remains a separate source-evidence compatibility surface.

## Next selectable but unselected report slice

The next Report Projection Alignment candidate is **Daily Trend plan monetary ownership**.

Before implementation, characterize the current `D`-local row-observation behavior and decide the exact checked-Posting-IR join needed to preserve source identity and historical coordinate semantics.

Do not infer:

- a report-wide observation clock;
- generic temporal kernel work;
- Outlook helper renaming;
- Daily Capacity wiring;
- Cube shape changes;
- source/config/metadata migration;
- editor changes;
- automatic advice or writes.

## Daily Capacity remains parked

The pure `src_next/daily_capacity.bqn` seam remains unconnected. Its assembler promotion, Candidate B O-bounded balance facts, and Candidate C pool/reservation facts remain independent unselected choices and are not implied by completed Outlook work.
