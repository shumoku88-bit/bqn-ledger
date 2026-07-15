# Next session

Status: active plan / temporary repository pointer
Owner: report / ledger policy / envelope
Canonical: no; current contract: `docs/DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md`
Exit: remove or replace after the next finite slice is jointly selected

The `POLICY_RISK_STYLE` meaning decision, Daily Capacity contract, synthetic characterization, pure runtime seam, and evidence-adapter pre-implementation ownership audit are complete.

Resume by reading:

1. `docs/archive/audits/DAILY_CAPACITY_EVIDENCE_ADAPTER_PREIMPLEMENTATION_AUDIT-2026-07-15.md`;
2. `docs/DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md`;
3. `docs/DAILY_CAPACITY_CHARACTERIZATION_AMENDMENT.md`;
4. `docs/archive/completed-plans/DAILY_CAPACITY_PURE_RUNTIME_SEAM-2026-07-15.md`;
5. `src_next/daily_capacity.bqn`;
6. `tests/test_src_next_daily_capacity.bqn`;
7. `docs/OUTLOOK_TEMPORAL_CURRENT.md`;
8. `TODO.md`.

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

The audit recommends, but does not select, the smallest next candidate:

```text
AssembleDailyCapacityInputFromResolvedEvidence request
  -> {state, input, diagnostics}
```

Its first slice would characterize assembly over explicit in-memory facts and owner decisions only. It would not read source/config, project O-bounded balances, normalize settlement evidence, invent reservation links, or call the calculator/Outlook.

Do not begin adapter implementation or characterization, config design, metadata/schema work, Outlook wiring, or compatibility migration automatically.
