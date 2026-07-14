# Ordinary income to unassigned linkage completion

Status: completed
Owner: envelope / editor
Canonical: no; current operational paths are `docs/BQN_EDITOR_USAGE.md`, `docs/JOURNAL_META.md`, and `docs/ENVELOPE_EXECUTION_AND_PLAN_POLICY.md`
Exit: archived completion record; broader automatic balancing or legacy income migration requires a separately selected plan

## Evidence and scope

The completed plan-payment linkage left ordinary income as a separate candidate because retryable budget companions need durable identity and refunds must not be mistaken for new budgetable income.

This slice implements only explicit `income_budget=unassigned` journal intent. `income_budget=exclude` and missing intent produce no companion. Expense refunds and asset transfers are not inferred as income.

## Result

- `src_edit/txn_id.bqn` generates stable collision-safe `txn_id` values for opted-in income rows.
- `src_edit/journal_add_cmd.bqn` adds the ID only to a valid income-account journal row carrying explicit unassigned intent.
- `src_edit/income_budget_sync_cmd.bqn` validates one journal event, income-to-liquid roles, currency, opening/unassigned accounts, duplicate identity, and legacy exact duplicates before rendering a companion.
- `tools/edit journal income-budget-sync --id ...` provides dry-run, confirmation, idempotent retry, and checked append.
- `journal add` invokes the companion after the observed journal fact is committed; cancellation/failure remains visible as `BUDGET_SYNC_PENDING`.
- `tools/add-ui.sh` asks whether an income is ordinary/unassigned or excluded, so refund-like inputs are not silently classified.
- Generic backing-delta balancing, legacy source migration, silent writes, and multi-file atomic claims remain excluded.

## Verification

- unit coverage for transaction ID generation/extraction;
- synthetic integration coverage for automatic journal+budget linkage, ID collision suffix, idempotent retry, no-intent exclusion, invalid non-income intent, stale failure, and retry;
- repository-wide `tools/check.sh`.
