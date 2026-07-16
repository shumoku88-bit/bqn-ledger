# Cycle Remaining-Plan Numeric-Owner Characterization

Status: completed characterization / no runtime behavior change
Owner: report
Canonical: yes; parent plan: `REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`
Exit: completed; next step is a compatibility decision candidate

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

## Completion Record (2026-07-16)

The characterization has been completed. The observed current behavior was verified via unit tests and check integration, and recorded as follows:

### Observed Current Behavior

1. **Normal and Temporal Boundaries**:
   - Only expense plans (`role=expense` on destination account) within the remaining cycle window `O <= D < C.end_exclusive` contribute to the remaining total.
   - `O` (LatestActualDateInCycle) is derived as the maximum Gregorian date of all actual journal postings inside cycle `C`. This derivation is independent of source-row ordering in `journal.tsv`.
2. **Completion**:
   - A plan matching an actual completion record (i.e. having a corresponding `plan_id` posting in `journal.tsv`) **remains** in the remaining total, as the current local parser does not check completion evidence.
3. **Invalid and Rejected Source Evidence**:
   - **Exact decimal & Non-integer amount**: Under single-currency settings, `fixtures/currency-usd-single` registry-backed checked amount is `4999`. However, the current local parser fails `IsIntegerText("49.99")` and substitutes it with `0` (zero-substitution). Other non-integer amount strings like `"abc"` also fallback to `0`.
   - **Unknown destination accounts**: Locally excluded from the total as their role falls back to `""` (non-expense). In contrast, the checked Posting IR path yields a debit status = unknown_account and credit status = unknown_account (due to transaction-wide validation error propagation) for the same source identity (source_file = plan.tsv, source_row = 0).
   - **Invalid dates**: Non-digit date text (e.g. `"abc"`) crashes execution on `ToNum` inside `proj.DaysFromEpoch`. This halt is observed both in-process via `⎊` exception catching and out-of-process via subprocess non-zero exit code.
4. **Structural Join**:
   - The current local parser does not utilize Posting IR join boundaries and directly sums the plan values. If we simulate a structural gap by dropping one side of a debit/credit pair (e.g. the credit row) in the checked posting rows, the local parser still calculates the amount correctly, whereas a future checked-owner candidate would face an unjoinable structural evidence gap.
5. **Empty and Fallback Boundaries**:
   - If the context has no base path, `fallback_total` (derived from checked TBDS plan totals) is retained.
   - Empty `plan.tsv` yields `0` as the remaining plan total.
   - If there are no actual postings in cycle `C`, `O` falls back to `cy.start`, admitting all plan postings from `cy.start` onward. Postings outside `C` do not affect `O`.
6. **Identity & Source Order**:
   - No duplicate `plan_id` policy is enforced by the local parser; identical IDs are accumulated in full.
   - The sums are order-independent (verified by reversing duplicate rows).
7. **Admitted Source Identities**:
   - For the contributing normal cycle remaining-plan amount, while the current local parser outputs a total of `500` through direct file parsing, the corresponding checked Posting IR admitted evidence for the contributing source identities is:
     - `plan.tsv` source_row `1` (`amount = 200`, `memo = today-expense`): exact debit/credit pair exists, debit status is `ok`.
     - `plan.tsv` source_row `2` (`amount = 300`, `memo = future-expense`): exact debit/credit pair exists, debit status is `ok`.

### Verification Evidence
- **Public Fixture Family**: [fixtures/cycle-remaining-plan-characterization/](../../../fixtures/cycle-remaining-plan-characterization/)
- **Unit Tests**: [tests/test_src_next_cycle_remaining_plan_characterization.bqn](../../../tests/test_src_next_cycle_remaining_plan_characterization.bqn) (PASSED)
- **Check Script**: [checks/check-src-next-cycle-remaining-plan-characterization.sh](../../../checks/check-src-next-cycle-remaining-plan-characterization.sh) (PASSED, integrated into `tools/check.sh`)
