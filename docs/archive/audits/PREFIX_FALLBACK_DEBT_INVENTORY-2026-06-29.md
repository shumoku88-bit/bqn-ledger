# Prefix Fallback Debt Inventory 2026-06-29

Status: current audit / no behavior change
Date: 2026-06-29

## Purpose

Inventory remaining prefix-based compatibility in current `src_next` before removing any code. This prevents ad-hoc cleanup and keeps the boundary clear:

- explicit `role=` is the accounting contract,
- prefix detection may remain only as a documented compatibility shim, diagnostic, or display helper,
- code removal should happen one module at a time with a named fixture/check.

This audit does not edit source TSVs and does not change report output.

## Search used

```bash
rtk rg -n "StartsWith|\"assets:|\"income:|\"expenses:|\"budget:|Prefix|fallback" src_next tests checks
```

## Classification

| Class | Meaning | Removal stance |
|---|---|---|
| diagnostic counter | Detects missing `role=` / compatibility use. | Keep until the missing-role fixture/check is redesigned. |
| accounting classification fallback | Prefix affects account kind/role used by numeric report logic. | Remove only with explicit-role fixture coverage and golden comparison. |
| presentation helper | Prefix stripping or grouping for display only. | Candidate for cleanup after output drift is understood. |
| non-role fallback | `plan_id` or `fallback/current-engine` sentinel, not account role inference. | Out of scope for this audit. |

## Current inventory

| Module | Site | Class | Current guard | Safe next step |
|---|---|---|---|---|
| `src_next/household_metadata.bqn` | missing-role prefix counters for `assets:` / `income:` / `expenses:` / `liabilities:` / `budget:` | diagnostic counter | `checks/check-missing-role-fallback.sh`; `checks/check-src-next-household-metadata.sh` asserts standard fixtures have total count 0 | Keep for now. This is the detector that proves fallback use is gone in normal fixtures. |
| `src_next/household_policy.bqn` | `expense_accounts ← role_expense ∨ prefix_fallback` and `prefix_fallback_expense_account_count` | diagnostic / policy-shape compatibility | `tests/test_src_next_household_policy.bqn`; compact summary checks | Keep until household policy diagnostic no longer reports fallback counts. |
| `src_next/envelope_computation.bqn` | `ExpenseAccountMask` and `BudgetAccountMask` include missing-role prefix fallback; `BudgetLabel` strips `budget:` | fixture/prototype policy compatibility | `checks/check-src-next-envelope-computation.sh`; production guard | Do not remove before target policy contract exists. Budget label stripping is presentation/selector compatibility, not role inference. |
| `src_next/tbds.bqn` | `IsExpenseAccount` / `IsIncomeAccount` prefer role, then prefix | accounting classification fallback | TBDS unit tests and golden checks | Candidate only after verifying callers still need these helpers. If used for numeric classification, remove with dedicated TBDS fixture. |
| `src_next/actual_snapshot.bqn` | asset/liability masks: role OR prefix | accounting classification fallback | `checks/check-src-next-snapshot.sh`; actual snapshot tests | ✅ Removed 2026-06-29. Matching only explicit roles; missing-role becomes unknown. |
| `src_next/snapshot.bqn` | asset mask: role OR `assets:` prefix | accounting classification fallback / snapshot grouping | snapshot fixture and production envelope guard | ✅ Removed 2026-06-29. Matching only explicit roles; missing-role becomes unknown. |
| `src_next/daily_trend.bqn` | asset and income masks include prefix fallback | accounting classification fallback | compact summary / daily trend checks | Later candidate. Needs daily trend fixture with explicit roles and a missing-role negative case. |
| `src_next/ytd_summary.bqn` | `GetRole` and expense mask include prefix fallback | accounting classification fallback | YTD summary checks | Later candidate. Remove only with YTD fixture proving explicit `role=expense` path. |
| `src_next/balances.bqn` | display grouping derived role from prefix if metadata was missing | presentation helper / grouping fallback | `tests/test_src_next_balances.bqn`; balances section checks | ✅ Removed 2026-06-29. Missing role now stays `unknown`; explicit roles still group normally. |
| `src_next/expense_breakdown.bqn` | repayment detection uses `liabilities:` prefix on `account_key` | accounting/report classification fallback | expense breakdown checks | Later candidate. Prefer explicit `role=liability` via account metadata/TBDS row when available. |
| `src_next/actual_comparison.bqn` | income uses `income:` prefix; expense uses role OR `expenses:`; `CleanName` strips prefixes | accounting classification + presentation helper | actual-comparison checks; report plan | Do not remove in one step. First split presentation `CleanName` from classification. Income should move to explicit role or configured income anchor. |
| `src_next/planned_payments.bqn` | `CleanName` prefix stripping; income category via `income:` | presentation helper + income classification | planned payments checks | Later candidate. Display cleanup should wait for account label strategy; income classification should use role/config. |
| `src_next/outlook.bqn` | active income detection via `income:` prefix | accounting/report policy fallback | outlook compact checks | Later candidate. Should use `role=income` or cycle/config income anchor rather than name prefix. |

## Recommended next cleanup order

1. ✅ **`src_next/balances.bqn` role display fallback** — removed 2026-06-29; missing role now remains `unknown`.
2. ✅ **`src_next/actual_snapshot.bqn` + `src_next/snapshot.bqn` asset/liability masks** — removed 2026-06-29; matching only explicit roles.
3. **`src_next/ytd_summary.bqn` expense mask** — numeric report classification; requires explicit fixture proof.
4. **`src_next/daily_trend.bqn` and `src_next/outlook.bqn` income logic** — more policy-sensitive because income anchors and future income interact with cycle logic.
5. **`src_next/actual_comparison.bqn`** — split display prefix stripping from classification first.
6. Keep **`household_metadata.bqn`** and **missing-role fallback check** until the final removal phase, because they are the detector.

## Implemented cleanup

### `src_next/balances.bqn`

2026-06-29:

- Standard fixture output remains unchanged under `checks/check-src-next-balances.sh`.
- Missing-role behavior is explicitly accepted: prefix-only accounts are not silently grouped as asset/liability/budget/income/expense; they stay `unknown`.
- `tests/test_src_next_balances.bqn` asserts both missing-role `unknown` behavior and explicit-role grouping.
- `checks/check-missing-role-fallback.sh` remains the compatibility detector and still passes.

### `src_next/actual_snapshot.bqn` + `src_next/snapshot.bqn`

2026-06-29:

- Removed prefix fallback from assets/liabilities masks in both files.
- Verified that unit tests `tests/test_src_next_actual_snapshot.bqn` and `tests/test_src_next_snapshot.bqn` continue to pass.
- Standard fixture check `checks/check-src-next-snapshot.sh` passes successfully.

Next code cleanup should be a new small step, not a broad sweep.
