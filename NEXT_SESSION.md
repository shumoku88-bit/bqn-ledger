# Next session

Status: active plan / temporary repository pointer
Owner: report
Canonical: no; current plan: `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`
Exit: remove or replace after the next finite slice is jointly selected

The Actual Comparison projection characterization and numeric-owner preimplementation compatibility decision are complete. Current runtime behavior remains unchanged: `src_next/actual_comparison.bqn` still rereads `cycle.tsv`, `journal.tsv`, and `plan.tsv`, independently parses amounts, and has no `BuildAt` boundary.

The completed decision fixes three compatibility choices for a future migration:

1. a rejected actual source row affecting the current/baseline windows makes the section `error` with an empty numeric table; valid-coordinate rejected rows outside both windows remain section-local non-failures, invalid-date applicability fails closed, and diagnostics group debit/credit postings by source identity;
2. Actual Comparison receives an explicit hard-cutoff `O`, with current window `[cycle.start, min(O + 1 day, cycle.end_exclusive))`; `ctx.as_of`, journal maximum date, `L`, cycle end, and generation time do not own observation;
3. unreachable `insufficient_history` is removed from the migrated vocabulary, leaving `ok / unavailable / error`; zero-event valid baselines remain `ok`.

Numeric amounts and counts will be owned by checked ledger-wide Posting IR and local TBDS-family period views, while anchor identity and diagnostics remain evidence concerns. The PR #261 fixtures remain unchanged pre-migration evidence.

Resume by reading:

1. `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`;
2. `docs/archive/completed-plans/ACTUAL_COMPARISON_NUMERIC_OWNER_COMPATIBILITY_DECISION-2026-07-15.md`;
3. `docs/archive/completed-plans/ACTUAL_COMPARISON_PROJECTION_CHARACTERIZATION-2026-07-15.md`;
4. `src_next/actual_comparison.bqn`;
5. `src_next/context.bqn`;
6. `src_next/projection.bqn`;
7. `src_next/cube.bqn`;
8. `src_next/tbds.bqn`;
9. `tests/test_src_next_actual_comparison.bqn`;
10. `docs/TIME_AS_AXIS.md`;
11. `docs/REPORT_CONTRACTS.md`;
12. `TODO.md`.

## Next selectable but unselected slice

The next selectable slice is the **Actual Comparison numeric-owner runtime migration** around:

```text
actual_comparison.BuildAt ⟨ctx, O⟩
```

It is not selected by this pointer. Do not start it automatically. Shared temporal kernels, generic period query abstractions, report-wide `--as-of`, Projection Workbench, Cube shape changes, Outlook / `actual_snapshot`, and another report lane also remain unselected.

## Daily Capacity completed baseline and parked candidates

The `POLICY_RISK_STYLE` meaning decision, Daily Capacity contract, 31-case calculator characterization, production-available pure runtime seam, evidence-adapter ownership audit, and test-only assembler characterization are complete.

The pure boundary remains:

```text
src_next/daily_capacity.bqn
  BuildDailyCapacityFromEvidence
    ⟨observation, horizon, arithmetic_domain, asset_scope, obligation_scope⟩
      -> contract-shaped result
```

It retains the four states `ok`, `deficit`, `unavailable`, and `error`. No adapter or consumer imports it, and current Outlook behavior remains unchanged. No config key, metadata/schema change, report field, JSON, CLI, UI, private-data access, currency conversion, or mixed-currency arithmetic was added.

The test-only assembler characterization remains complete:

```text
AssembleDailyCapacityInputFromResolvedEvidence request
  -> {state, input, diagnostics}
```

It joins explicit in-memory facts and decisions by stable identity and returns empty input under `error > unavailable > resolved`. It does not call the calculator, read source/config, project O-bounded balances, normalize settlement evidence, or invent reservation links.

Daily Capacity remains under `TODO.md` as unselected candidates. The three independent choices remain:

1. promote the characterized pure assembler seam;
2. select Candidate B for O-bounded account-balance facts; or
3. select Candidate C for pool/reservation facts.

Do not promote the test-only assembler, begin Candidate B/C, add config or metadata, wire Outlook/report output, or migrate compatibility behavior automatically.
