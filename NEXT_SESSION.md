# Next session

Status: active plan / temporary repository pointer
Owner: report / config / envelope
Canonical: no; completed audit: `docs/archive/audits/DAILY_CAPACITY_CURRENT_CONSUMER_INPUT_EVIDENCE_AUDIT-2026-07-15.md`
Exit: remove or replace after the next finite slice is jointly selected

The `POLICY_RISK_STYLE` meaning decision and current consumer/input-evidence audit are complete.

Resume by reading:

1. `docs/archive/completed-plans/POLICY_RISK_STYLE_DAILY_CAPACITY_DECISION-2026-07-15.md`;
2. `docs/archive/audits/DAILY_CAPACITY_CURRENT_CONSUMER_INPUT_EVIDENCE_AUDIT-2026-07-15.md`;
3. `TODO.md`.

Current-main audit result:

- `src_next/outlook.bqn` is the one direct behavioral consumer found in the inspected canonical surfaces;
- `simple` and `conservative` do not select two human-facing daily formulas;
- the current switch controls whether the secondary machine field `liq_safe_daily` is numeric or `unavailable/policy`;
- the human Outlook continues to render `liq_daily` under both values;
- reusable evidence exists for balances, account role/type, plan identity/completion, cycle boundaries, envelope backing, and aggregate execution coverage;
- owner-selected asset admission, canonical obligation admission, and per-obligation reservation provenance are still missing.

No runtime implementation or migration is selected.

The next eligible candidate is a docs-only **Daily Capacity minimal input/result contract** for the current Outlook consumer. Select it separately before adding config keys, account or plan metadata, runtime arithmetic, fixtures, report fields, JSON, private-data changes, or compatibility migration.
