# Next session

Status: active plan / temporary repository pointer
Owner: report / ledger policy / envelope
Canonical: no; selected contract: `docs/DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md`
Exit: remove or replace after the next finite slice is jointly selected

The `POLICY_RISK_STYLE` meaning decision, current consumer/input-evidence audit, and Daily Capacity minimal input/result contract are complete.

Resume by reading:

1. `docs/DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md`;
2. `docs/OUTLOOK_TEMPORAL_CURRENT.md`;
3. `docs/archive/audits/DAILY_CAPACITY_CURRENT_CONSUMER_INPUT_EVIDENCE_AUDIT-2026-07-15.md` only for current-main audit evidence;
4. `TODO.md`.

Selected boundary:

```text
BuildDailyCapacityFromEvidence
  ⟨observation, horizon, arithmetic_domain, asset_scope, obligation_scope⟩
```

The contract requires:

- explicit Outlook observation `O` and cycle horizon `C`;
- one proven arithmetic domain;
- one owner-resolved non-overlapping asset basis;
- owner-resolved open obligations;
- per-obligation proof of any amount already outside the selected asset basis;
- exact-once deduction of reserved obligations;
- signed `capacity_balance`;
- `daily_capacity` for a nonnegative result or `daily_shortfall` for a deficit;
- structured diagnostics and no partial calculation after fatal evidence failure.

No runtime implementation, config key, metadata field, report field, JSON, private-data change, or compatibility migration is selected.

The next eligible candidate is a test-only synthetic Daily Capacity contract characterization. Select it separately before adding a BQN builder, changing `POLICY_RISK_STYLE`, changing current Outlook arithmetic, or wiring new output.