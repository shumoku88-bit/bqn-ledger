# Outlook / Actual Snapshot Numeric-Owner Runtime Migration

Status: completed runtime slice
Owner: report
Decision: `OUTLOOK_ACTUAL_SNAPSHOT_NUMERIC_OWNER_COMPATIBILITY_DECISION-2026-07-16.md`
Characterization: `OUTLOOK_ACTUAL_SNAPSHOT_CHARACTERIZATION-2026-07-16.md`

## Completed boundary

Slice A moves `actual_snapshot.BuildAt ⟨ctx,O⟩` away from its independent raw `journal.tsv` amount parser.

The numeric path is now:

```text
ctx.posting_rows
  -> journal.tsv / actual-layer rows
  -> applicable rejected-source check
  -> local [O,O+1) TBDS view
  -> actual-layer closing balances
  -> snapshot totals and Outlook
```

The local period start at O makes rows before O TBDS opening and rows on O period movement. Therefore closing remains ledger-cumulative through inclusive O without applying the selected cycle as a balance cutoff.

## Preserved behavior

- pre-cycle actual history contributes to the O snapshot;
- an actual row on O is included;
- an actual row after O is excluded;
- O later than `cycle.end_exclusive` may include end-exclusive and later out-of-cycle rows;
- account-role/type metadata continues to own liquid, savings, investment, liability, and net-worth classification;
- both latest-date compatibility helpers retain their existing exports and different bounds;
- remaining-plan amount parsing and anchor behavior are unchanged in this slice.

## Fail-closed behavior

`actual_snapshot.BuildAt` now returns `state`, `reason`, and source-row diagnostics.

- invalid O -> `error / invalid_observation`;
- valid-coordinate rejected actual with `D <= O` -> `error / rejected_actual_evidence`;
- valid-coordinate rejected actual with `D > O` -> outside this snapshot;
- invalid-date actual evidence -> applicability-unknown and `error`;
- debit/credit posting duplicates are reduced to one diagnostic per `source_file + source_row`;
- a valid empty journal remains `ok` with real zero balances.

Amount/currency authorization failures may still stop at context construction before the section is reached. This slice does not introduce a nonfatal checked-result carrier.

## Outlook propagation

Outlook now exposes `state`, `reason`, and diagnostics. When its actual snapshot is invalid:

- actual and derived monetary fields are `unavailable`;
- plan values are not combined with an invalid balance to create daily allowance numbers;
- machine output includes `src_next_outlook_status`, `src_next_outlook_reason`, and source diagnostics;
- human output shows a visible error instead of a normal daily-allowance dashboard.

Normal Outlook plan and anchor calculations remain unchanged when the snapshot is `ok`.

## Evidence

- fixture: `fixtures/actual-snapshot-numeric-owner-target/`;
- focused test: `tests/test_src_next_actual_snapshot_numeric_owner.bqn`;
- compatibility tests: `tests/test_src_next_actual_snapshot.bqn`, `tests/test_src_next_outlook.bqn`, and `tests/test_src_next_outlook_actual_snapshot_characterization.bqn`;
- integration guard: `checks/check-src-next-actual-snapshot.sh`;
- suite routing: `tools/check.sh`.

Covered cases include pre-cycle opening history, O-day inclusion, O-after-cycle behavior, invalid O, rejected rows before and after O, invalid-date evidence, empty journal, diagnostic deduplication, and Outlook fail-closed rendering.

## Intentional visible contract change

Outlook machine output gains additive status/reason fields. On error it no longer prints normal numeric daily-capacity values. This is an approved fail-closed change, not output parity with the former raw parser.

## Next selectable slice

The next Report Projection Alignment candidate is Slice B: Outlook remaining-plan monetary ownership and the already approved asymmetric anchor policy.

Slice B remains unselected. It must not be inferred from completion of Slice A. It may later migrate admitted plan amounts while retaining plan-ID completion/source evidence, reserving valid anchored outflows even when unmet, and admitting valid anchored inflows only after their actual income anchor is observed through O.

## Non-goals retained

- no plan amount migration;
- no anchor runtime change;
- no latest-date helper rename;
- no Daily Capacity connection;
- no Cube shape change;
- no report-wide `--as-of`;
- no source/config/metadata migration;
- no automatic advice or write;
- no private production-data access.
