# Cycle Remaining-Plan Numeric-Owner Characterization

Status: selected finite characterization / no runtime behavior change
Owner: report
Canonical: no; parent plan: `REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`; current authorization: `TODO.md`
Exit: move to completed plans after public synthetic characterization, executable checks, and a separate compatibility decision identify the next implementation boundary

## Purpose

Characterize the current `src_next/cycle_summary.bqn` remaining-plan calculation before changing its monetary owner.

The selected question is intentionally narrow:

```text
For Cycle Summary plan_expense_remaining,
which current source rows contribute money,
which temporal boundary is applied,
and what happens when source evidence is invalid, rejected, completed, or structurally unjoinable?
```

This slice does not implement the checked Posting IR migration. It creates the evidence needed for a later compatibility decision.

## Current code path under observation

```text
cycle_summary.Build(ctx)
  -> tbds.PlanExpenseAmount(ctx.tbds)              # whole-cycle fallback / total
  -> PlanExpenseRemaining(ctx, fallback_total)
       -> read current plan.tsv source rows
       -> derive local O from latest actual date in C
       -> select destination accounts with role=expense
       -> select O <= plan date < C.end_exclusive
       -> parse source amount text locally
       -> sum selected source amounts
```

Current implementation evidence:

- `src_next/cycle_summary.bqn`
- `tests/test_src_next_cycle_summary.bqn`
- `docs/archive/audits/TEMPORAL_CONSUMER_SENSITIVITY_OBSERVATION-2026-07-06.md`
- `docs/TIME_AS_AXIS.md`
- `docs/REPORT_CONTRACTS.md`

## Temporal roles to preserve during characterization

```text
C = selected cycle [start, end_exclusive)
O = current local latest-actual date inside C
D = plan event coordinate
L = current source frontier; no historical-knowledge replay is claimed
```

The current remaining window is:

```text
O <= D < C.end_exclusive
```

Characterization must not silently replace this with `D > O`, system today, report generation time, or a report-wide observation clock.

## Current numeric-owner concern

`PlanExpenseRemaining` independently reads `plan.tsv` and parses column 5. This duplicates monetary interpretation that checked plan Posting IR already owns.

The local parser currently has a zero-substitution branch for non-integer amount text. Characterization must expose that behavior rather than treating the resulting zero as admitted accounting data.

The code also selects source rows by destination account role and date before any explicit source-row-to-Posting-IR join. Completion identity and rejected evidence therefore require independent observation.

## Required public synthetic characterization cases

Create one focused fixture family and executable test/check coverage for at least these cases.

### A. Normal admitted expense plans

- one in-window expense plan contributes its admitted debit amount;
- multiple in-window expense plans sum deterministically;
- a plan before O is excluded;
- a plan on O is included;
- a plan on `C.end_exclusive` is excluded;
- income and non-expense plans do not contribute.

### B. Completion evidence

- characterize whether a completed plan currently remains in `plan_expense_remaining`;
- preserve plan identity evidence separately from money;
- do not decide the target completion policy inside the fixture implementation.

### C. Invalid and rejected source evidence

- invalid amount text;
- valid amount text with unknown account;
- invalid date text whose applicability cannot be safely determined;
- a source row that does not produce exactly one admitted debit/credit plan Posting IR pair;
- supported exact-decimal plan input where relevant to the current registry-backed parser.

Expected characterization output must distinguish a real admitted zero from invalid or rejected evidence. Do not normalize rejected evidence into a successful numeric zero.

### D. Empty and fallback boundaries

- no `base` in the synthetic pure/test context retains the existing TBDS fallback behavior;
- empty `plan.tsv` produces the observed current result;
- no actual row in C fixes the current O fallback behavior;
- rows outside C do not move the local O.

### E. Source-order and identity boundaries

- row identity remains stable through `source_file` / `source_row` or another already-established Posting IR identity;
- characterization records whether result membership depends on source order;
- no duplicate plan-ID policy is invented.

## Characterization result shape

The executable characterization may use a test-only result namespace, but it must expose enough evidence to assert:

```text
status
observation O
window [O, C.end_exclusive)
admitted contributing source identities
rejected applicable source identities
numeric total only when evidence is valid
```

Preferred status vocabulary for the characterization seam:

```text
ok / unavailable / error
```

This vocabulary is test evidence only until a later compatibility decision selects the runtime contract.

## Compatibility questions reserved for the next decision

The characterization must provide evidence for, but must not answer automatically:

1. whether completed plans are excluded from the target remaining total;
2. whether applicable rejected plan evidence fails Cycle Summary closed;
3. whether the current `O <= D` boundary is intentionally retained;
4. whether the public machine field remains a scalar or gains companion status/diagnostic fields;
5. whether no-base fallback remains test-only compatibility or a supported runtime boundary;
6. whether the future owner is a local Posting IR join, a re-based Cube view, or a TBDS-family plan movement view.

## Explicit non-goals

- no runtime migration in `cycle_summary.bqn`;
- no envelope allocation or execution-plan coverage changes;
- no shared `LatestActualDateInCycle` extraction;
- no report-wide `--as-of` or generic temporal kernel;
- no Cube shape change;
- no source TSV, account, currency-registry, config, metadata, or editor change;
- no Daily Capacity connection;
- no automatic advice or write path;
- no private production-data access.

## Completion gate

This characterization slice is complete only when:

- public synthetic fixture coverage exists for normal, boundary, completion, invalid/rejected, empty/fallback, and identity behavior;
- executable tests and a dedicated check pass through `tools/check.sh`;
- current output behavior is documented without calling rejected evidence valid zero;
- `TODO.md`, `NEXT_SESSION.md`, and the parent Report Projection Alignment plan route to a separate compatibility decision;
- no runtime behavior has changed.
