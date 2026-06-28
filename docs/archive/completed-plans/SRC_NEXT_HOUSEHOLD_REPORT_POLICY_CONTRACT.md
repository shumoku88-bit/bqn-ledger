# src_next household report policy contract

Status: **intended contract / docs-only / no production behavior change**

This document fixes the policy boundary for future `src_next` household reports before implementing food remaining or daily remaining calculations.

`src_next` remains a read-only experimental path. This contract does not change the current production engine, source TSV formats, or current report output.

For the broader lifestyle/profile boundary (pension, monthly salary, irregular income, envelope style, account-balance-first style, etc.), see `docs/HOUSEHOLD_POLICY_LAYER_PLAN.md`. This document is the narrower selector/remaining contract for household report targets.

## Core design rule

Do not hard-code household category names such as `食費` into calculation logic as permanent concepts.

Treat all of these names as changeable policy data:

- envelope names
- budget names
- expense account names
- report target names
- broad group labels such as current daily/flex/reserve-style labels

Calculation code may know stable metadata keys and arithmetic contracts. It must not permanently know that a specific household label is "food", "daily", "reserve", or any other life-policy meaning.

## Stable metadata keys

The intended first contract uses existing account metadata keys. The keys are stable; their concrete values are policy labels unless explicitly documented otherwise.

| metadata | intended meaning in `src_next` household reports | contract boundary |
|---|---|---|
| `role=expense` | Identifies an expense account. | Expense identity comes from role metadata. Prefix fallback may remain compatibility, but account names are not the rule. |
| `budget=...` | Identifies a household category or envelope target for an expense account. | The value is policy data. `budget=食費` is an initial policy value, not a built-in concept. |
| `budget_group=...` | Identifies a broad household grouping. | Concrete group names are policy-level labels. Do not bake specific values into report math as permanent categories. |
| `spend_class=...` | Metadata for later reporting and diagnostics. | It is not a hidden rule. Do not silently infer report inclusion, food-ness, or daily-ness from it unless a report contract says so. |

`fixed=1` or similar legacy hints must not be silently converted into `spend_class=...` in `src_next` unless a separate compatibility contract and tests explicitly require it.

## Configurable report targets

Food-like reporting should be driven by a configurable report target, not by account names.

Initial policy shape, not implemented yet:

```tsv
# future policy shape example, file/name not decided
target_id	label	selector_key	selector_value
food_like	食費	budget	食費
```

Meaning:

- `target_id` / `label` are report policy data.
- `selector_key=budget` says to select expense accounts by their `budget=...` metadata.
- `selector_value=食費` is the initial policy value.
- Renaming accounts, envelopes, or the food-like target should be a policy/data change, not a calculation-code change.

Do not implement food-like reporting by matching account names such as `expenses:食費`, by assuming any envelope name is permanent, or by treating all accounts in a broad group as food.

## First remaining contract

When a target-level remaining amount is implemented, the first meaning of `remaining` should be:

```text
remaining = allocated - actual_spent
```

Where:

- `allocated` is the amount allocated to the configured target/envelope in the relevant period.
- `actual_spent` is actual debit-side spending for `role=expense` accounts selected by the configured target policy.
- Signed ledger-like totals such as `src_next_actual_total` are not household spending totals.

`safe_remaining` that subtracts planned spending is later work:

```text
safe_remaining = allocated - actual_spent - planned_spending   # later, not first implementation
```

Daily remaining / per-day allowance is also later work and must not be smuggled into the first `remaining` value.

The narrower envelope arithmetic terms and output boundary are defined in `docs/SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md`. That document refines this household policy contract for future Section 5 / Section 9 implementation, without changing production behavior.

## Missing and unknown metadata

In `src_next`, missing household metadata remains non-fatal unless a later stricter lint/report contract says otherwise.

Required behavior for the experimental path:

- Missing `budget=`, `budget_group=`, or `spend_class=` must be visible in diagnostics.
- Unknown metadata values should be preserved as policy labels and reported as unknown/other diagnostics where relevant.
- Missing metadata must not be silently converted to a default household category.
- Missing metadata must not make `src_next` produce polished but misleading food/daily remaining numbers.

This differs from projection validity errors such as unknown accounts or out-of-cycle rows. Those may be skipped or fail according to the `src_next` projection/cube safety surface. Household metadata gaps are policy-readiness diagnostics, not automatic source-row invalidity.

## Current diagnostic boundary

The existing `src_next_household_policy_*` fields are diagnostic policy-shape visibility. They are not food remaining, daily remaining, or a production household report.

If current diagnostic fields mention concrete group labels, treat those labels as fixture/current-policy examples only. The compatibility `daily` / `flex` / `reserve` diagnostic keys are labels for visible fields; their current selection should come from `HOUSEHOLD_GROUP_*` policy config rather than fixed engine concepts. A future report contract should route group and target selection through policy data rather than baking those labels into core arithmetic.

### Stage 4a metadata readiness diagnostics (added 2026-06-24)

`src_next/household_metadata.bqn` provides a computation-free diagnostics surface that operates purely on account metadata (no config, no valid_rows). It reports:

- expense account count (via `role=expense` + prefix fallback)
- missing `budget=` / `budget_group=` / `spend_class=` counts
- observed metadata values (deduplicated)
- missing account key lists

This module does not:
- implement food remaining, daily remaining, or safe_remaining
- implement envelope balances
- hard-code household labels (daily/flex/reserve/etc.)
- convert missing metadata to default categories
- require config.tsv

All values are shown as raw policy labels. Unknown budget_group or spend_class values are preserved as-is.

## Non-goals

- Do not implement food remaining yet.
- Do not implement daily remaining yet.
- Do not implement `safe_remaining` with planned spending yet.
- Do not change production engine behavior.
- Do not change existing source TSV formats.
- Do not require current accounts, envelope names, budget names, or report target names to be permanent.

## Related documents

- `docs/HOUSEHOLD_POLICY_LAYER_PLAN.md` — broader lifestyle/profile policy layer boundary.
- `docs/SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md` — envelope computation terms, `remaining` boundary, unavailable / fallback semantics.
- `docs/SRC_NEXT_EXPENSE_ACCOUNT_MAPPING.md` — observed mapping and current diagnostics.
- `docs/SRC_NEXT_GOLDEN_CHECK.md` — compact `src_next` golden check surface.
- `docs/SRC_NEXT_CURRENT_ENGINE_COMPARISON.md` — read-only comparison notes.
- `docs/REPORT_POLICY_EXTERNALIZATION_PLAN.md` — broader report policy externalization track.
- `docs/REPORT_ASSUMPTION_AUDIT.md` — hard-coded report assumption audit.
- `docs/ACCOUNT_ROLE_CONTRACT.md` — account role metadata contract.
