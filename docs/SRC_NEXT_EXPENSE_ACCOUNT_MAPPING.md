# SRC_NEXT_EXPENSE_ACCOUNT_MAPPING

## Status

This document describes the current observed mapping between accounts, expense totals, and household accounting categories for `src_next`.

The intended configurable household report policy contract is documented in `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md`. This file remains the observed mapping / fixture notes companion.

`src_next` remains read-only and experimental. This document is for analysis and does not define a production replacement yet.

## Why this exists

Before implementing food / daily remaining reports, `src_next` needs a clear mapping for:

- what counts as expense
- what counts as food
- what counts as daily spending
- whether actual and plan use the same classification
- whether account metadata is enough or category data is needed

## Current observations

### What `accounts.tsv` currently provides

Observed production-style account metadata includes:

- `role=asset|liability|equity|income|expense|budget`
- asset `type=liquid|savings|invest`
- expense-to-envelope mapping via `budget=<budget account suffix/name>`
- fixed/variable expense hints via `fixed=1` and `spend_class=fixed|variable`
- budget account metadata via `kind=opening|unassigned|spent|envelope`
- household envelope grouping via `budget_group=daily|flex|reserve`
- optional `currency=...` in some fixtures, currently used by `src_next` AccountKey resolution

The real `data/accounts.tsv` currently uses prefixed account names such as `expenses:食費` and explicit `role=expense`. Some fixtures, such as `fixtures/generalization-moko/accounts.tsv`, use localized unprefixed account names with explicit `role=expense`. Current production helpers can use role metadata or prefix fallback; `src_next` now reads explicit `role=expense` metadata for expense classification while keeping the `expenses:` prefix fallback.

Most earlier `fixtures/src-next-*` accounts are intentionally tiny and mostly prefix-only. `fixtures/src-next-household-mapping-policy` is the first minimal fixture that carries household mapping metadata (`budget=...`, `budget_group=...`, `spend_class=...`) for read-only policy-shape coverage.

### How the current engine appears to classify expense

The current engine uses account metadata helpers from `src/core/account_space.bqn`:

- `GetRole` returns explicit `role=...` when present.
- If `role=` is absent, it falls back to account-name prefixes such as `assets:`, `income:`, `expenses:`, `budget:`.
- `IsExpenseAccName` is true when the resolved role is `expense`.

Cycle actual expense is computed from journal rows whose `to` account is an expense account. Plan expense summary similarly sums plan rows whose `to` account is an expense account within the relevant observation/cycle window. Fixed expense is an additional subset using `fixed=1` on the `to` expense account.

### How `src_next` currently computes expense totals

`src_next/projection.bqn` expands each source row into two ledger-like rows:

- debit row: `to` account, positive delta
- credit row: `from` account, negative delta

`src_next` currently infers `kind` from the `to` account's explicit role metadata plus the existing account-name prefix fallback:

- `to` account has explicit `role=expense` => `expense`
- else `to` starts with `expenses:` => `expense`
- else `from` starts with `income:` => `income`
- otherwise => `transfer`

`src_next/cube.bqn` computes:

- `actual_total` / `plan_total` as signed ledger-like layer totals
- `actual_expense_total` / `plan_expense_total` as valid rows where:
  - `kind = "expense"`
  - `side = "debit"`
  - `layer = actual` or `plan`

Therefore the current `src_next` expense total is a debit-side expense-row total, not the signed layer total. This is the correct field family for household-accounting comparison, while signed `actual_total` / `plan_total` remain reference totals.

### Actual and plan classification

`src_next` uses the same projection and `kind` inference for `journal.tsv` and `plan.tsv`; only the layer differs (`actual` vs `plan`). In that narrow sense, actual and plan use the same classification.

The current production comparison helper uses different observation points for actual and plan because `src_next` does not have a full observation-time model yet. This affects comparison windows, not the basic row classification rule.

### Food / daily remaining signals

There is not yet a single explicit `category=food` or `household_category=daily` field in the source TSV contract.

Observed possible signals are:

- food-like expense accounts, e.g. `expenses:食費`, `expenses:食費:ストック`, `expenses:缶コーヒー`
- expense-to-envelope metadata, e.g. `budget=食費`
- budget envelope accounts, e.g. `budget:食費`
- budget group metadata, e.g. `budget_group=daily|flex|reserve`
- `spend_class=variable|fixed`

For current household reporting, daily/flex/reserve is more clearly represented on budget envelope accounts via `budget_group=...` than on source transaction rows themselves. Food-like classification may need either account mapping (`budget=食費`) or an explicit category policy; guessing from account names alone would be fragile.

## Known safe assumptions

- `src_next` is read-only and experimental.
- Source TSV format remains `date / memo / from / to / amount` plus optional metadata columns.
- A normal source row expands into debit and credit projection rows.
- Debit deltas are positive and credit deltas are negative.
- Signed `actual_total` / `plan_total` are ledger-like reference totals and should not be used as household spending totals.
- `actual_expense_total` / `plan_expense_total` are the current `src_next` household-accounting comparison fields.
- For prefix-based `expenses:*` rows in `fixtures/src-next-*`, `src_next` and the current engine can agree on basic expense totals.
- The current production engine can classify explicit `role=expense` accounts even when account names are not `expenses:*` prefixed.
- `src_next` currently uses `currency=` for AccountKey separation and `role=expense` for expense classification.
- `src_next` also exposes read-only account metadata arrays for `budget=`, `budget_group=`, and `spend_class=`.
- `src_next` has a minimal read-only household policy diagnostic summary that counts mapped expense accounts and shows actual/plan debit expense totals by `budget_group`. These fields are diagnostic policy-shape visibility, not food remaining or daily remaining reports.
- `src_next` does not infer `fixed=true`, `fixed=1`, or any other fixed-cost flag into `spend_class`. `spend_class=` is direct metadata only in this experimental path.

## Proposed household mapping policy

This is a proposed policy shape for later `src_next` household reporting. The stricter configurable report-target and remaining contract lives in `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md`. It is documented now so metadata visibility can be tested before report calculations are added.

- Expense identity:
  - `role=expense` determines whether an account is an expense.
  - The existing `expenses:` prefix fallback remains a compatibility path when `role=` is missing.
  - Transfers between non-expense accounts must not become expenses.
- Household category / food-like mapping:
  - `budget=...` may identify the household category or envelope target for an expense account.
  - Example: an expense account with `budget=食費` is a candidate for later food-like mapping.
  - `budget=...` is not yet a food report rule by itself.
- Envelope group mapping:
  - `budget_group=daily|flex|reserve` may identify the household envelope group.
  - Daily/flex/reserve grouping is not yet a daily remaining calculation.
  - Missing or unknown `budget_group=` should be non-fatal in this read-only experimental path.
- Spend class:
  - `spend_class=variable|fixed` may be useful later for separating variable and fixed household spending.
  - `spend_class=` should not silently drive reports until a report contract explicitly says so.
  - `fixed=true`, `fixed=1`, or similar values should not be inferred into `spend_class` unless existing TSV metadata and a documented compatibility rule require it. Current `src_next` metadata visibility does not do this inference.
- Unknown or missing metadata:
  - Missing `budget=`, `budget_group=`, or `spend_class=` returns an empty string in metadata helpers.
  - Unknown values are preserved as strings and should remain non-fatal until a later lint/report contract defines stricter behavior.

## Fixture coverage

`fixtures/src-next-household-mapping-policy` covers metadata visibility and policy shape only:

- an asset account and a transfer row, proving non-expense transfers stay outside expense classification;
- expense accounts with `role=expense budget=食費 budget_group=daily`, `budget=日用品 budget_group=daily`, `budget=娯楽 budget_group=flex`, and `budget=予備 budget_group=reserve`;
- an expense account with `role=expense` and `budget=...` but no `budget_group=`;
- a prefixed `expenses:*` fallback account with no metadata;
- small actual and plan rows for daily, flex, and reserve examples.

The fixture is wired into `check-src-next-golden.sh` for the visible diagnostic policy summary. Unit tests also cover metadata parsing and policy summary values.

## Open questions

- Should `src_next` eventually warn when an account has no `role=` and no recognized prefix?
- Should food be identified by expense account, budget envelope, explicit category metadata, or a household category mapping?
- Should `expenses:缶コーヒー` count as food because it maps to `budget=食費`, or should it be a separate food-adjacent category?
- Should daily remaining be based on `budget_group=daily`, `spend_class=variable`, specific envelope names, or an explicit policy table?
- Should daily remaining exclude fixed costs, reserve/savings envelopes, and investment envelopes?
- Should reserve / flex / daily envelope names influence expense classification, or only daily remaining classification?
- Should plan expense and actual expense use identical account metadata and category rules?
- How should localized unprefixed role-based fixtures, such as `fixtures/generalization-moko`, be represented in `src_next` fixtures?
- Is the current metadata-aware fixture enough for the first household policy summary, or does that summary need a second fixture with expected diagnostic output?

## Non-goals

- Do not implement food report yet; `src_next` exposes `budget=`, `spend_class=`, and `budget_group=` but does not use them to infer food remaining.
- Do not implement daily remaining yet; `src_next` exposes and summarizes `budget_group=` diagnostics but does not calculate household daily/flex/reserve remaining.
- Do not replace the current production engine.
- Do not change source TSV format.
- Do not wire comparison helper into `tools/check.sh`.
- Do not change production report behavior.
- Do not implement trial balance, multi-posting, or generated entries here.

## Next step

A later PR may implement the deliberately named household report contract from `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md`. Food / daily remaining should wait until that policy is stable and must not calculate remaining amounts from `budget=`, `spend_class=`, `fixed=`, or `budget_group=` until the rule is explicitly implemented and tested.
