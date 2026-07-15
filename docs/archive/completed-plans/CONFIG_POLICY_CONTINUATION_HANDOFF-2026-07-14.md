# Config policy continuation handoff — 2026-07-14

Status: completed / historical handoff
Owner: config / ledger policy
Canonical: no; current decision: `POLICY_RISK_STYLE_DAILY_CAPACITY_DECISION-2026-07-15.md`
Exit: archived; do not use as current work authorization

## Purpose

This handoff preserved the repository-only resume path after the completed budget-style policy sequence and selected a joint docs-only discussion about `POLICY_RISK_STYLE`.

It did not authorize runtime changes.

## Sequence carried by this handoff

The following slices were already complete when the handoff was written:

1. PR #248 — personal/profile hardcode inventory;
2. PR #250 — Outlook presentation literal extraction;
3. PR #251 — explicit `POLICY_BUDGET_STYLE` decision;
4. PR #252 — budget-style compatibility audit and enforcement.

The budget-style rationale remains in:

- `POLICY_BUDGET_STYLE_EXPLICIT_CHOICE_DECISION-2026-07-14.md`;
- `POLICY_BUDGET_STYLE_COMPATIBILITY_AUDIT-2026-07-14.md`.

## Question carried forward

The handoff asked whether the current values:

```text
POLICY_RISK_STYLE=conservative
POLICY_RISK_STYLE=simple
```

represented a real household risk-style choice, an engine safety rule, or an inaccurate mixture of arithmetic and value judgment.

It also preserved the current compatibility behavior:

```text
missing -> warning + conservative fallback
```

and explicitly prohibited automatic fallback removal, renaming, fixture sweeps, private-data edits, and unrelated implementation work.

## Resolution

The joint discussion completed on 2026-07-15.

The resulting decision is:

- `risk style` is not the durable semantic owner;
- the target model is an evidence-bearing daily-capacity projection;
- the owner selects `asset_scope`, `obligation_scope`, and `horizon`;
- the engine validates and computes those inputs;
- envelope budgeting allocates by purpose while daily capacity projects an admitted balance over time;
- gross liquidity may remain a diagnostic but must not be mislabeled as safe spending capacity;
- current `simple`, `conservative`, and missing-key fallback behavior remain unchanged for compatibility.

Read:

- `POLICY_RISK_STYLE_DAILY_CAPACITY_DECISION-2026-07-15.md`.

## Historical boundary

This file is retained only so the 2026-07-14 resume path and its safety boundary remain understandable.

It does not select the candidate consumer/input-evidence audit, any runtime migration, a new config key, an account-schema change, a report rewrite, or another TODO candidate.