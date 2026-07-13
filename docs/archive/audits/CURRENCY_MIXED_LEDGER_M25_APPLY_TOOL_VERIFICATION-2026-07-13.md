# Currency Mixed-Ledger M2.5 Apply Tool Verification

Date: 2026-07-13

## Scope

This verification covers the safe-write tooling merged by PR #200. It does not claim that production source data has already been migrated.

Implementation under review:

- `tools/currency-setup apply`
- `tools/currency_setup_apply.py`
- the extended `checks/check-currency-m15-setup.sh`

Plan owner:

- `docs/archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md`

## Claim-to-evidence review

### 1. BQN dry-run remains source authority

Verified.

The apply helper invokes the existing read-only BQN dry-run and rejects any malformed or inconsistent protocol. It does not independently decide which source rows need migration.

### 2. Proposal shape is finite and exact

Verified.

Every accepted changed row must satisfy:

```text
new_row = old_row + TAB + currency=JPY
```

A proposal with any other shape fails closed before backup or replacement.

### 3. Missing ledger default is handled separately

Verified.

A missing `DEFAULT_CURRENCY` may be resolved by appending exactly:

```text
DEFAULT_CURRENCY=JPY
```

The default is not used to reinterpret missing row currency. Row migration remains independently fixed to JPY.

Duplicate defaults and explicit non-JPY defaults fail closed.

### 4. Source identity and journal-like first columns remain stable

Verified.

The contract check proves that:

- account names and account order remain exact;
- the first five columns of `journal.tsv`, `plan.tsv`, and `budget_alloc.tsv` remain exact;
- comments, blank rows, unrelated metadata, row order, and line endings are retained;
- existing explicit currency metadata is not rewritten.

### 5. Stale source protection exists before replacement

Verified.

Snapshots cover:

- `config.tsv`
- `accounts.tsv`
- `journal.tsv`
- `plan.tsv`
- `budget_alloc.tsv`

All snapshots are checked before backups and again immediately before replacement. A concurrent edit causes an abort without the migration overwriting that edit.

### 6. Recoverable backups exist

Verified.

Every changed file receives a timestamped `.backup/*.currency-m25.bak` copy before replacement.

### 7. Multi-file failure is recoverable

Verified.

A replacement failure restores files already replaced. A post-check failure restores the complete changed source set from backups.

### 8. Post-migration checks and idempotence exist

Verified.

A successful apply requires:

- post-migration `tools/currency-setup audit` with `state=ok`;
- `changed_count=0`;
- `error_count=0`;
- successful ledger report construction;
- optional full repository checks.

A second apply is a no-op and creates no additional backup.

### 9. Explicit production confirmation remains required

Verified.

`apply` requires an interactive `y/yes` response or an explicit `--yes`. The recommended production operation uses the interactive confirmation path.

## Executable evidence

GitHub Actions run #734 completed successfully with the normal repository workflow:

- `tools/check.sh`: success;
- extended audit/dry-run/apply contract: success;
- successful apply path: success;
- idempotent rerun: success;
- stale-source abort path: success;
- post-check rollback path: success;
- existing BQN/editor/MCP regressions: success;
- `tools/coverage`: success.

## Decision

The M2.5 apply tooling is verified for the explicit production checkpoint.

The production migration itself remains **not performed** in this verification. The next operation is:

1. update the local clone to the verified main branch;
2. rerun audit and dry-run against the actual `LEDGER_DATA_DIR`;
3. invoke `tools/currency-setup apply` without `--yes`;
4. review the summary and explicitly confirm in the terminal;
5. capture the successful output and final audit;
6. only then consider M2.5 complete.

Strict missing-currency enforcement and M3 reporting remain separate decisions.