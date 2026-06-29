# Envelope Target Policy Sketch

Status: docs-only sketch / not implemented
Date: 2026-06-29

This document sketches the future policy boundary for named household envelope targets such as "food-like" spending.  It does not create a new TSV, does not change report behavior, and does not modify source data.

## Purpose

Some reports and AI helper tools need a stable way to ask for a household target such as "食費" without hard-coding account names or envelope names in BQN arithmetic.

The goal is to make target selection policy data, while keeping the arithmetic contract small and explicit.

Non-goal: build a generic report policy DSL.

## Not implemented yet

Do not create this file yet:

```text
envelope_targets.tsv
```

Do not migrate real `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, or `accounts.tsv` for this sketch.

## Candidate shape

Future small TSV shape, name not final:

```tsv
target_id	label	selector_key	selector_value
food_like	食費	budget	食費
```

Meaning:

| field | meaning |
|---|---|
| `target_id` | Stable machine key for a report target. ASCII-like identifier, unique. |
| `label` | Human display label. Policy/presentation data. |
| `selector_key` | How expense accounts are selected. Initial allowed value: `budget` only. |
| `selector_value` | Value matched against account metadata for the selector. For `budget`, this matches `budget=...` on expense accounts and the corresponding budget/envelope label. |

Initial selector semantics:

```text
selector_key=budget
  selected expense accounts: role=expense accounts with budget=<selector_value>
  selected budget account:  role=budget envelope whose display label / budget id corresponds to <selector_value>
```

Account names such as `expenses:食費` must not be used as the rule.

## Arithmetic contract

The first target-level value remains the existing envelope computation contract:

```text
remaining = allocated - actual_spent
```

Where:

- `allocated` is budget allocation to the selected target/envelope in the period.
- `actual_spent` is actual debit-side spending for selected `role=expense` accounts.

Later work, explicitly not part of the first target policy:

```text
safe_remaining = allocated - actual_spent - planned_spending
per_day_allowance = remaining / days_left
```

Do not smuggle `safe_remaining` or daily allowance into the first `remaining` value.

## Fail-visible rules

If this policy file is introduced later, add lint/checks at the same time.

Required diagnostics:

- duplicate `target_id`
- empty `target_id`
- unknown `selector_key`
- selector that matches no expense accounts
- selector that matches no budget/envelope account
- selector that matches multiple budget/envelope accounts when one is expected
- malformed TSV rows

Missing policy should not produce polished numeric household claims.  It should render as `unavailable/no_policy`, `disabled`, `warning`, or another explicit status.

## Boundary decisions

- `target_id` is report policy, not accounting core.
- `label` is presentation/policy data.
- `selector_key` is a small enum, not arbitrary code.
- `selector_value` is policy data and may be Japanese or household-specific.
- Canonical Daily Cube axes and layer names remain fixed and are not target policy.
- Source TSV schemas remain unchanged unless a later approved phase explicitly says otherwise.

## Current relation to implementation

Current `src_next/envelope_computation.bqn` has a fixture/prototype target (`fixture_food_like`) gated to the envelope computation fixture.  Treat that as a proof shape only, not production policy.

Before replacing that prototype with real policy:

1. decide the policy file name and owner,
2. add lint/check fixture for invalid declarations,
3. keep missing policy fail-visible,
4. verify no output claims become polished-but-wrong.

## Related docs

- `docs/archive/active-plans/REPORT_POLICY_EXTERNALIZATION_PLAN.md`
- `docs/archive/audits/REPORT_ASSUMPTION_AUDIT.md`
- `docs/archive/completed-plans/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md`
- `docs/SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md`
