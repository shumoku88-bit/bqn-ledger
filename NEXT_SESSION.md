# Next session

Status: active plan / temporary repository pointer
Owner: report
Canonical: no; current plan: `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`
Exit: remove or replace after the next finite slice is jointly selected

The Actual Comparison projection characterization foundation is complete. Current runtime behavior remains unchanged: `src_next/actual_comparison.bqn` still rereads `cycle.tsv`, `journal.tsv`, and `plan.tsv` and independently parses amount-bearing journal rows.

Current characterization evidence fixes these compatibility gaps:

- a row rejected by checked Posting IR can still be aggregated by the raw parser when its recognized side is an income or expense account;
- caller-owned `ctx.as_of` is not a hard cutoff because Actual Comparison independently selects the maximum journal date at or after the cycle start;
- `insufficient_history` is not reachable from valid source under the current anchor algorithm;
- numeric-owner migration is not selected;
- compatibility decisions are required before any runtime migration.

Resume by reading:

1. `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`;
2. `docs/archive/completed-plans/ACTUAL_COMPARISON_PROJECTION_CHARACTERIZATION-2026-07-15.md`;
3. `src_next/actual_comparison.bqn`;
4. `tests/test_src_next_actual_comparison.bqn`;
5. `src_next/context.bqn`;
6. `src_next/projection.bqn`;
7. `src_next/cube.bqn`;
8. `src_next/tbds.bqn`;
9. `docs/TIME_AS_AXIS.md`;
10. `docs/REPORT_CONTRACTS.md`;
11. `TODO.md`.

## Next selectable but unselected slice

The next selectable slice is an **Actual Comparison numeric-owner migration preimplementation compatibility decision**. It is not selected by this pointer.

Before implementation, decide at least:

1. When a checked-Posting-IR-rejected row falls inside the target period:
   - make the report unavailable/error;
   - exclude the rejected row and emit a diagnostic; or
   - preserve the current raw-parser value for compatibility.
2. Observation ownership:
   - use caller-owned explicit `O` as a hard cutoff; or
   - preserve the current maximum-journal-date behavior.
3. `insufficient_history`:
   - make it reachable through explicit history evidence;
   - remove it; or
   - redefine it as another status.

Do not start the numeric-owner migration, shared temporal kernel, generic period query abstraction, Projection Workbench, Cube shape change, or another report lane automatically.

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
