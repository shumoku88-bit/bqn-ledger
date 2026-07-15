# Next session

Status: active plan / temporary repository pointer
Owner: report / ledger policy / envelope
Canonical: no; current contract: `docs/DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md`
Exit: remove or replace after the next finite slice is jointly selected

The `POLICY_RISK_STYLE` meaning decision, input-evidence audit, Daily Capacity contract, synthetic characterization, and pure runtime seam are complete.

Resume by reading:

1. `docs/DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md`;
2. `docs/DAILY_CAPACITY_CHARACTERIZATION_AMENDMENT.md`;
3. `docs/archive/completed-plans/DAILY_CAPACITY_PURE_RUNTIME_SEAM-2026-07-15.md`;
4. `src_next/daily_capacity.bqn`;
5. `tests/test_src_next_daily_capacity.bqn`;
6. `docs/OUTLOOK_TEMPORAL_CURRENT.md`;
7. `TODO.md`.

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

The smallest next candidate is a test-only characterization of one concrete evidence adapter boundary that constructs the five-part input carrier without connecting Outlook output. It remains unselected. Before selecting it, name the exact evidence owner and prove that it does not infer owner policy from account names, prefixes, salary cadence, country, or aggregate envelope labels.

Do not begin adapter implementation, config design, Outlook wiring, or compatibility migration automatically.
