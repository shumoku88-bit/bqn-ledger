# Next session

Status: active plan / temporary repository pointer
Owner: config / ledger policy
Canonical: no; completed decision: `docs/archive/completed-plans/POLICY_RISK_STYLE_DAILY_CAPACITY_DECISION-2026-07-15.md`
Exit: remove or replace after the next finite slice is jointly selected

The `POLICY_RISK_STYLE` meaning and ownership discussion is complete.

Resume by reading:

1. `docs/archive/completed-plans/POLICY_RISK_STYLE_DAILY_CAPACITY_DECISION-2026-07-15.md`;
2. `TODO.md`;
3. `docs/archive/completed-plans/CONFIG_POLICY_CONTINUATION_HANDOFF-2026-07-14.md` only for historical context.

The durable target is an evidence-bearing daily-capacity projection over owner-selected `asset_scope`, `obligation_scope`, and `horizon`. Envelope budgeting allocates by purpose; daily capacity projects an admitted balance across time. Reserved money must not be deducted twice.

No runtime implementation or migration is selected.

The next eligible candidate is a docs-only audit of current `PolicyRiskStyle` consumers and available asset, obligation, horizon, and envelope evidence. Select that finite audit separately before changing runtime behavior, config values, account metadata, fixtures, private data, reports, or machine output.