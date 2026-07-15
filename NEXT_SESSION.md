# Next session

Status: active plan / temporary repository pointer
Owner: report / ledger policy / envelope
Canonical: no; completed characterization: `docs/archive/completed-plans/DAILY_CAPACITY_CONTRACT_CHARACTERIZATION-2026-07-15.md`
Exit: remove or replace after the next finite slice is jointly selected

The `POLICY_RISK_STYLE` meaning decision, current consumer/input-evidence audit, Daily Capacity minimal contract, and test-only synthetic characterization are complete.

Resume by reading:

1. `docs/DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md`;
2. `docs/DAILY_CAPACITY_CHARACTERIZATION_AMENDMENT.md`;
3. `docs/archive/completed-plans/DAILY_CAPACITY_CONTRACT_CHARACTERIZATION-2026-07-15.md`;
4. `docs/OUTLOOK_TEMPORAL_CURRENT.md`;
5. `TODO.md`.

The selected evidence boundary remains:

```text
BuildDailyCapacityFromEvidence
  ⟨observation, horizon, arithmetic_domain, asset_scope, obligation_scope⟩
```

Permanent executable characterization now covers 31 synthetic cases, including:

- resolved-empty, included, excluded, negative, account-balance, and pool-remaining asset bases;
- open, completed, overdue, optional, transfer, and out-of-horizon obligations;
- full, partial, missing, ambiguous, excessive, and duplicate reservation provenance;
- `ok`, `deficit`, `unavailable`, and `error` results;
- floor/ceiling rounding and exhausted-horizon behavior;
- unchanged current `simple` and `conservative` compatibility outputs.

Characterization added two explicit carrier states through the companion amendment:

```text
horizon.state = resolved | unavailable | error
reservation_state = none | proven | ambiguous
```

No `src_next` Daily Capacity runtime, policy adapter, config key, metadata field, report field, JSON, private-data change, or compatibility migration is selected.

The next eligible candidate is a pure `src_next/daily_capacity.bqn` seam implementing only the contract-shaped calculation over already-resolved evidence. Select it separately before reading config or source files, resolving owner policy, changing Outlook, or wiring output.