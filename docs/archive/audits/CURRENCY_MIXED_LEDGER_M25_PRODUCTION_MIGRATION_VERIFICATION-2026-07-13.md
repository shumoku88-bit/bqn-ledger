# Currency Mixed-Ledger M2.5 Production Migration Verification

Date: 2026-07-13

## Scope

This record verifies the separately approved production JPY source migration against the actual `LEDGER_DATA_DIR`. It records operational evidence only. It does not copy private ledger rows or amounts into the repository.

## Preconditions and reviewed preview

The actual ledger was inspected with:

```text
tools/currency-setup audit
tools/currency-setup dry-run
```

Observed before apply:

- `DEFAULT_CURRENCY` was absent.
- `accounts.tsv`: 40 missing currency rows, 0 explicit, 0 row errors.
- `journal.tsv`: 355 missing currency rows, 0 explicit, 0 row errors.
- `plan.tsv`: 16 missing currency rows, 0 explicit, 0 row errors.
- `budget_alloc.tsv`: 22 missing currency rows, 0 explicit, 0 row errors.
- total proposed source changes: 433 rows.
- an independent raw-output check counted 433 proposal rows and 0 proposals missing the required TAB before `currency=JPY`.

The migration proposal was therefore reviewed as an exact append of `TAB + currency=JPY` to each untagged JPY source row, plus `DEFAULT_CURRENCY=JPY` in ledger config.

## Apply operation

The user explicitly approved and ran:

```text
tools/currency-setup apply "$base" --post-check full
```

The confirmation preview reported:

- `DEFAULT_CURRENCY: append JPY`
- accounts: 40 rows
- journal: 355 rows
- plan: 16 rows
- budget allocation: 22 rows
- source rows: 433
- files to replace: 5
- post-check: full

The operation completed with `Migration applied successfully.`

Recoverable timestamped backups were created for all five changed files:

- `config.tsv`
- `accounts.tsv`
- `journal.tsv`
- `plan.tsv`
- `budget_alloc.tsv`

Backup file paths and private source directory details were shown locally and are intentionally not copied here.

## Post-migration audit

The actual ledger then reported:

```text
state=ok
default_key=DEFAULT_CURRENCY
default_state=ok
default_currency=JPY
default_provenance=ledger_config
migration_target=JPY
changed_count=0
error_count=0
file=accounts.tsv state=ok missing=0 explicit=40 errors=0
file=journal.tsv state=ok missing=0 explicit=355 errors=0
file=plan.tsv state=ok missing=0 explicit=16 errors=0
file=budget_alloc.tsv state=ok missing=0 explicit=22 errors=0
```

## Claim-to-evidence result

| Claim | Result | Evidence |
|---|---|---|
| Actual production source was audited before write | verified | initial audit and dry-run completed |
| Proposal shape was exact and tab-delimited | verified | 433 proposals, separator check 0 bad |
| Apply required explicit user confirmation | verified | interactive `y` approval |
| Only missing JPY currency metadata was added | verified | post-audit counts match pre-audit missing counts |
| Ledger default became explicit JPY | verified | `default_state=ok`, `default_currency=JPY` |
| All five changed files received recovery copies | verified | successful apply output listed five backups |
| Full post-check passed | verified | apply completed successfully with `--post-check full` |
| Migration is idempotent | verified | `changed_count=0` after apply |
| Duplicate, unknown, or invalid currency states remain | rejected | `error_count=0`, per-file errors 0 |

## Boundary after completion

M2.5 production migration is complete.

This does not automatically authorize:

- strict rejection of missing currency in every legacy fixture or compatibility path;
- removal of legacy compatibility fixtures;
- Currency axis work;
- FX, conversion, valuation, or mixed-currency totals;
- M3 currency-selected balances reporting.

M3 and any strict-source runtime slice remain separate candidates requiring explicit selection and authorization.
