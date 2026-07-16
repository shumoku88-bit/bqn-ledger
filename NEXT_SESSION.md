# Next session

Status: active plan / temporary repository pointer
Owner: report
Canonical: no; current plan: `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`
Exit: remove or replace after the next finite slice is jointly selected

The Outlook / `actual_snapshot` characterization and numeric-owner compatibility decision are complete.

Current records:

- `docs/archive/completed-plans/OUTLOOK_ACTUAL_SNAPSHOT_CHARACTERIZATION-2026-07-16.md`
- `docs/archive/completed-plans/OUTLOOK_ACTUAL_SNAPSHOT_NUMERIC_OWNER_COMPATIBILITY_DECISION-2026-07-16.md`
- `fixtures/outlook-actual-snapshot-characterization/`
- `tests/test_src_next_outlook_actual_snapshot_characterization.bqn`

No BQN runtime, report output, source schema, config, metadata, editor behavior, Daily Capacity behavior, or private production data changed in the decision slice.

## Approved migration order

```text
Slice A: actual_snapshot actual-balance numeric owner
Slice B: Outlook remaining-plan monetary owner and anchor policy
```

The slices are independent. Slice A must not absorb plan aggregation or anchor-policy runtime changes.

## Slice A approved contract

`actual_snapshot.BuildAt ⟨ctx,O⟩` remains ledger-cumulative through inclusive O:

```text
journal actual posting
status = ok
D <= O
```

It includes pre-cycle opening history and has no cycle-end cutoff when O lies after C. Amounts must come from checked ledger-wide Posting IR / a local O-bounded TBDS-family view, not a second `journal.tsv` parser.

Applicable rejected actual evidence fails closed:

- valid rejected row with `D <= O` -> `error`;
- valid rejected row with `D > O` -> outside this snapshot;
- invalid-date actual row -> `error` because applicability is unknown;
- invalid amount/currency may continue to stop at upstream context authorization;
- invalid O -> `error`, not a valid-looking zero snapshot;
- empty valid journal -> `ok` with real zero balances.

Outlook must propagate snapshot error and must not combine plan values with an invalid actual balance to produce daily allowance numbers.

## Temporal and helper boundaries retained

```text
O = explicit actual cutoff
L = recorded-actual frontier evidence
C = selected cycle
```

The two latest-date helpers remain separate compatibility surfaces. Slice A does not rename or merge them.

## Later Slice B anchor policy

The later plan migration will use admitted plan Posting IR for amounts and existing plan-ID completion evidence for unfinished identity.

- remaining horizon: `O <= plan date < C.end_exclusive`;
- unanchored rows are admitted normally;
- valid anchored outflows remain reserved even when the anchor is unmet;
- valid anchored inflows count only after an admitted actual matching income event in `[C.start,min(O+1,C.end_exclusive))`;
- missing/unknown/non-income/duplicate/empty anchor metadata is `error`;
- completed plans do not contribute;
- the characterized all-included `fixed_reserve=210` is compatibility evidence, not target policy.

## Next selectable but unselected slice

The next Report Projection Alignment candidate is **Slice A: `actual_snapshot` checked numeric-owner runtime migration**.

It may implement only:

- cumulative inclusive-O actual balances from checked Posting IR / TBDS-family ownership;
- snapshot `ok / error` evidence;
- rejected-actual applicability and source-row diagnostics;
- narrow Outlook propagation of snapshot failure;
- focused fixtures/checks and stable report-contract updates needed for the visible status change.

Do not automatically implement plan monetary migration, anchor runtime changes, helper renaming, a generic temporal kernel, report-wide `--as-of`, Daily Capacity wiring, Cube shape changes, source migration, or automatic writes.

## Daily Capacity remains parked

The pure `src_next/daily_capacity.bqn` seam remains unconnected. Its assembler promotion, Candidate B O-bounded balance facts, and Candidate C pool/reservation facts remain independent unselected choices and are not implied by Slice A.
