# Daily Trend Plan Numeric-Owner Runtime Migration — 2026-07-16

Status: completed implementation record
Owner: report
Canonical: no; current behavior is owned by `src_next/daily_trend*.bqn`, `docs/REPORT_CONTRACTS.md`, and executable checks
Exit: retain as implementation history

## Problem

Daily Trend already used checked Cube/projection values for actual balances and future planned income, but fixed reserve reread `plan.tsv`, parsed raw amount text with `•BQN`, and independently treated invalid amounts as zero. Plan completion was also interleaved with that monetary parser.

This created two numeric owners for admitted plan money and could produce a plausible reserve from evidence that the Posting IR boundary had rejected.

## Scope

This slice migrates Daily Trend fixed-reserve money to admitted `plan.tsv` Posting IR while preserving source-derived identity and the existing D-local completion rule.

```text
source plan evidence
  -> source_row + plan identity + date
  -> join exactly one admitted plan debit/credit pair
  -> fixed debit delta owns reserve money
  -> completion identity observed at each Daily Trend D
```

The existing future planned-income path already consumes admitted plan projection rows and remains unchanged.

## Non-goals

- no Daily Trend display redesign;
- no row-membership, header observation, cycle, or completion-policy redesign;
- no historical knowledge boundary K or generic temporal kernel;
- no Outlook, Daily Capacity, envelope, or cycle-policy change;
- no Cube shape, TSV schema, config, editor, or production-default change.

## Ownership model

| Meaning | Owner |
|---|---|
| fixed reserve amount | admitted plan debit Posting IR `delta` |
| future planned income | existing admitted plan projection rows |
| stable source join | `source_file=plan.tsv` plus zero-based `source_row` |
| plan ID / fallback identity | source evidence through the existing overlap contract |
| completed / unfinished at D | matching source completion identity and completion date |
| fixed classification | admitted debit account index plus resolved account metadata |

`src_next/daily_trend_plan.bqn` contains no raw amount parser and does not use `•BQN`.

## Temporal semantics

The migration preserves current-source coordinate replay:

```text
S = current source snapshot
D = rendered Daily Trend row coordinate
O_row = D
C = [cycle.start, cycle.end_exclusive)
L = local actual frontier context
K = unavailable / not claimed
```

A fixed plan is reserved at D when:

```text
D <= plan date < C.end_exclusive
and no matching completion exists at or before D
```

Same-day completion excludes the plan at that D. Completion before due date also excludes it. Future planned income retains its distinct strict `plan date > D` rule. Row membership, header O, and local L behavior did not change.

## Failure behavior

The helper returns `error / rejected_plan_evidence` for:

- an invalid plan date, whose applicability cannot be trusted;
- applicable unknown-account or otherwise rejected Posting IR evidence;
- fewer than five required source evidence fields;
- duplicate `plan_id` metadata or duplicate plan identity;
- duplicate or invalid-date matching completion evidence;
- a source join that is not exactly one debit and one credit with matching date and plan layer.

Daily Trend then emits diagnostics and no numeric trend rows. It does not substitute zero. Invalid trend coordinates use `error / invalid_trend_coordinate`.

## Tests

`tests/test_src_next_daily_trend_plan_numeric_owner.bqn` covers:

- one and multiple admitted plans, inflow/outflow, same-day rows, and multiple days;
- cycle start and `end_exclusive`;
- D-local same-day and before-due completion;
- unfinished identity;
- unknown account, invalid date, missing evidence, duplicate identities, and failed source join;
- the numeric-owner proof where source evidence says `999`, admitted Posting IR says `10`, and reserve is `10`.

Existing Daily Trend temporal tests remain green and characterize unchanged row/header/frontier behavior.

## Fixture

`fixtures/daily-trend-plan-numeric-owner-target/` is public-safe and uses fictional integer amounts. Its README records cycle, header observation, row coordinates, completion cases, expected reserves, and why the synthetic `999` versus `10` mismatch belongs in the test seam rather than a normal one-snapshot fixture.

## Validation

- `bqn tests/test_src_next_daily_trend_plan_numeric_owner.bqn`
- all `tests/test_src_next_daily_trend*.bqn`
- `bash checks/check-src-next-daily-trend-plan-numeric-owner.sh`
- `bash ./tools/check.sh`
- `git diff --check`

The focused check is connected to `tools/check.sh`, and the repo-index baseline includes the new BQN module and check script.

## Remaining work

The next Report Projection Alignment candidate is Envelopes / Cycle remaining-plan monetary ownership. It remains unselected and does not inherit authorization from this completed slice.
