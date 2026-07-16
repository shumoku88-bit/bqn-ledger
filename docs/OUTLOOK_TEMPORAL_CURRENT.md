# Outlook Temporal Current Contract

Status: current operational contract
Owner: report
Canonical: no; the canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Exit: revise when `src_next/report.bqn`, `src_next/outlook.bqn`, or `src_next/outlook_remaining_plan.bqn` changes Outlook observation, frontier, cycle, or remaining-plan ownership

This document is the short current entry point for Outlook temporal and checked-money meaning.

The earlier household-question, transport, frontier-relation, production-source, characterization, compatibility-decision, and Slice A/Slice B runtime records remain design history. This file states the current runtime boundary.

## Household question

Outlook answers:

> At observation date `O`, what liquid spending room can the household rely on through active cycle end `C` under the selected Outlook policy, while separately showing that actual records are current only through `L`?

The pure policy calculation boundary is `docs/DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md`, implemented by the unconnected `src_next/daily_capacity.bqn` seam. It defines explicit asset admission, obligation admission, and reservation provenance without changing current Outlook runtime behavior.

The meanings remain distinct:

```text
O = caller-selected Outlook observation date
L = recorded-actual coordinate frontier
C = selected cycle boundary
```

`O` and `L` may differ. A journal frontier does not become the household observation clock merely because it is the latest recorded date.

## Production observation source

The human report owns Outlook `O`:

```text
--outlook-as-of YYYY-MM-DD supplied
  -> O = supplied date

otherwise
  -> report entry reads system today once
  -> O = report_today
```

The report then calls:

```text
outlook.BuildAt(ctx, O)
```

`--outlook-as-of` affects Outlook only. It does not redefine Daily Trend, cycle selection, `ctx.as_of`, or another report section.

## Record frontier

Outlook classifies the relation of `L` to `O` as exactly one of:

```text
before_observation
at_observation
after_observation
unavailable
```

When both values exist, it also exposes a nonnegative distance in days.

The relation does not claim that records are complete or reconciled through `L`. It describes only the position of the admitted recorded-actual frontier relative to `O`.

## O-relative behavior

The explicit observation date owns Outlook terms such as:

- actual snapshot cutoff;
- remaining-plan window;
- anchor activation cutoff;
- days remaining through `C.end_exclusive`;
- displayed Outlook observation date.

The current implementation keeps cycle construction separate:

```text
ctx = BuildContext(base)
O = explicit --outlook-as-of or report_today
outlook.BuildAt(ctx, O)
```

A later report-wide observation contract must not be inferred merely because two sections happen to receive equal dates.

## Checked actual ownership

`actual_snapshot.BuildAt(ctx,O)` derives ledger-cumulative inclusive-O actual balances from checked ledger-wide Posting IR through a local `[O,O+1)` actual-layer TBDS closing view.

```text
D < O  -> opening
D = O  -> movement
closing -> cumulative actual balance through O
```

Pre-cycle actual history remains part of opening balance. `C.end_exclusive` is not an actual-snapshot cutoff when O is later.

Actual evidence fails closed as follows:

- invalid O -> `error / invalid_observation`;
- valid-coordinate rejected actual with `D <= O` -> `error / rejected_actual_evidence`;
- valid-coordinate rejected actual with `D > O` -> outside that snapshot;
- invalid-date actual evidence -> applicability-unknown and `error`;
- valid empty journal -> `ok` with real zero balances.

## Checked remaining-plan ownership

`outlook_remaining_plan.BuildAt(ctx,O)` joins source evidence to admitted `plan.tsv` Posting IR by stable source row.

Ownership is split deliberately:

| Meaning | Owner |
|---|---|
| amount and liquid-account delta | checked plan Posting IR |
| source metadata and stable identity | plan source evidence |
| completed / unfinished | existing `plan_rows.PlanId` evidence |
| anchor activation | admitted actual income-credit evidence through O |
| horizon | explicit O and C |

The current remaining horizon is:

```text
O <= plan date < C.end_exclusive
```

Completed plans do not contribute.

Anchor activation requires an admitted actual journal credit for the exact anchor account with `role=income` in the current cycle at or before O.

The policy is intentionally asymmetric:

- unanchored outflow -> reserved;
- valid anchored outflow, met or unmet -> reserved;
- unanchored inflow -> included;
- valid anchored inflow -> included only after its actual income anchor is observed through O;
- anchor event after O -> not active at O.

Unknown, non-income, duplicate, or empty anchor metadata is applicable invalid evidence and fails Outlook closed.

## Outlook status and rendering

Outlook exposes `ok / error` evidence.

On actual-snapshot or remaining-plan error:

- `reason` identifies the rejected boundary;
- source-row diagnostics are retained;
- actual and derived monetary fields are `unavailable`;
- plan values are not combined with an invalid actual balance;
- normal daily-allowance numbers are not rendered.

Machine output includes `src_next_outlook_status`, `src_next_outlook_reason`, and source-row diagnostics.

Cycle-end next-obligation rendering remains a separate compatibility surface. Slice B migrates the current remaining-plan aggregate, not every plan-text consumer.

## Read order

1. `docs/TIME_AS_AXIS.md` for the canonical temporal principle.
2. This document for the current Outlook temporal and checked-money contract.
3. `docs/DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md` for the pure, currently unconnected policy calculation boundary.
4. `src_next/actual_snapshot.bqn`, `src_next/outlook_remaining_plan.bqn`, and `src_next/outlook.bqn` for implementation truth.

## Current evidence

- `tests/test_src_next_outlook_observation_sensitivity.bqn`;
- `tests/test_src_next_actual_snapshot_numeric_owner.bqn`;
- `tests/test_src_next_outlook_remaining_plan_numeric_owner.bqn`;
- `tests/test_src_next_outlook_actual_snapshot_characterization.bqn`;
- `checks/check-src-next-actual-snapshot.sh`;
- `checks/check-src-next-outlook-remaining-plan.sh`;
- report CLI validation for `--outlook-as-of`;
- explicit `outlook.BuildAt(ctx, O)` dispatch.

## Non-goals

- no generic report-wide `--as-of` flag;
- no automatic historical replay or knowledge cutoff;
- no change to cycle selection;
- no claim that `L` proves completeness;
- no migration of the separate cycle-end next-obligation parser in Slice B;
- no Outlook runtime connection, output, or policy change from the pure Daily Capacity seam;
- no automatic advice or writes.
