# Next session

Status: active plan / temporary repository pointer
Owner: report / ledger policy / envelope
Canonical: no; current contract: `docs/DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md`
Exit: remove or replace after the next finite slice is jointly selected

The `POLICY_RISK_STYLE` meaning decision, Daily Capacity contract, calculator characterization, pure runtime seam, evidence-adapter ownership audit, and test-only assembler characterization are complete.

Resume by reading:

1. `docs/archive/audits/DAILY_CAPACITY_EVIDENCE_ADAPTER_PREIMPLEMENTATION_AUDIT-2026-07-15.md`;
2. `docs/DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION_CONTRACT.md`;
3. `docs/DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md`;
4. `docs/DAILY_CAPACITY_CHARACTERIZATION_AMENDMENT.md`;
5. `docs/archive/completed-plans/DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION-2026-07-15.md`;
6. `tests/daily_capacity_evidence_assembler_reference.bqn`;
7. `tests/test_daily_capacity_evidence_assembler_characterization.bqn`;
8. `src_next/daily_capacity.bqn`;
9. `tests/test_src_next_daily_capacity.bqn`;
10. `docs/OUTLOOK_TEMPORAL_CURRENT.md`;
11. `TODO.md`.

The production-available pure boundary is now:

```text
src_next/daily_capacity.bqn
  BuildDailyCapacityFromEvidence
    ⟨observation, horizon, arithmetic_domain, asset_scope, obligation_scope⟩
      -> contract-shaped result
```

It retains all 31 public synthetic characterization cases and the four states:

```text
ok
deficit
unavailable
error
```

The former test-only reference evaluator was moved into the production module rather than duplicated. The characterization now targets the production export directly.

No adapter or consumer imports this module. Current behavior remains unchanged:

```text
POLICY_RISK_STYLE=simple|conservative
missing / empty / unknown handling
liq_daily
liq_safe_daily
src_next_outlook_liq_daily
src_next_outlook_liq_safe_daily
```

No config key, account or plan metadata, source schema, report field, JSON, CLI, UI, private-data access, currency conversion, or mixed-currency arithmetic was added.

The completed audit finds that observation, resolved cycle facts, and a checked arithmetic-domain proof already have candidate fact owners. Account/pool candidates and plan settlement signals also exist, but Daily Capacity asset admission, obligation admission, and exact per-obligation reservation provenance have no current policy owner.

The selected test-only assembler characterization is complete:

```text
AssembleDailyCapacityInputFromResolvedEvidence request
  -> {state, input, diagnostics}
```

It joins explicit in-memory facts and decisions by stable identity, keeps candidate output order deterministic, and returns empty input under `error > unavailable > resolved`. It neither calls the calculator nor reads source/config, projects O-bounded balances, normalizes settlement evidence, or invents reservation links.

No adapter implementation is selected. Do not promote this reference evaluator to `src_next`, begin Candidate B/C, config design, metadata/schema work, Outlook wiring, or compatibility migration automatically.
