# Currency Mixed-Ledger M1.5 Post-implementation Verification — 2026-07-13

Status: audit snapshot
Owner: currency
Canonical: no; current plan remains `docs/archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md`
Exit: retain as point-in-time evidence; use the active plan and `TODO.md` for current authorization

## 1. Reviewed lineage

```text
PR #196  feat: add M1.5 default carrier and migration preview
head     d51441dd523defa9f3bc212ed17e1df188354579
merge    efdc798983771f48d97425da32c282f62f8d637a
```

GitHub Actions evidence:

```text
workflow: check
run:      #715
status:   completed
result:   success
```

Overall result:

```text
M1.5 selected claims -> verified
material unresolved plan/runtime mismatch -> none
production source mutation -> not performed
M1.5 -> complete
next finite slice -> M2 editor currency-aware account and journal input
```

## 2. Actual implementation diff

PR #196 changed exactly eleven paths:

```text
src_next/currency_setup.bqn
src_next/currency_setup_cli.bqn
tools/currency-setup
tests/test_src_next_currency_setup.bqn
checks/check-currency-m15-setup.sh
tools/check.sh
fixtures/currency-m15-migration/config.tsv
fixtures/currency-m15-migration/accounts.tsv
fixtures/currency-m15-migration/journal.tsv
fixtures/currency-m15-migration/plan.tsv
fixtures/currency-m15-migration/budget_alloc.tsv
```

`tools/currency-setup` is executable. The implementation contains no production source edit, editor widening, public report change, strict-source enforcement, human currency formatting, FX, conversion, valuation, Currency axis, or mixed-currency aggregation.

Temporary CI artifact diagnostics used during implementation were removed. `.github/workflows/check.yml` is absent from the final base-to-head diff.

## 3. Claim-to-evidence review

| # | M1.5 claim | Current evidence | Classification |
|---|---|---|---|
| 1 | Ledger-level default owner and exact key are explicit | `<ledger>/config.tsv` and `DEFAULT_CURRENCY` are selected and returned in the default carrier. | **verified** |
| 2 | Default selection is separate from source currency authority | `ResolveSelection` reports `ledger_default` or `explicit_selection`; migration target is a separate argument. A focused case proves `DEFAULT_CURRENCY=ILS` still produces an explicitly requested JPY migration preview. | **verified** |
| 3 | Missing, duplicate, unknown, empty, and unsupported states fail or classify explicitly | Focused tests cover default-key failure states and source-row duplicate/unknown states. Invalid file state produces no proposed replacement list. | **verified** |
| 4 | Audit is read-only | `tools/currency-setup audit` emits summary/classification only. The shell check verifies no replacement records are emitted. | **verified** |
| 5 | Dry-run proposes only absent `currency=JPY` additions | The fake four-source fixture has five missing currency locations; the preview appends `currency=JPY` only to those rows and preserves existing explicit JPY and ILS rows byte-for-byte. | **verified** |
| 6 | Proposal is idempotent | Re-running the pure builder over the first proposed lines produces `changed_count=0`. | **verified** |
| 7 | Journal-like first five columns remain exact | The focused test compares the first five fields before and after preview, including an empty memo field. | **verified** |
| 8 | Account/reference identity and unrelated metadata remain exact | Account names, From/To values, `party=`, `series=`, `allocation_id=`, role/type/report metadata, comments, blank lines, and row order remain in place. | **verified** |
| 9 | CLI path handling is deterministic | The shell wrapper validates the base directory and passes an absolute path into BQN. | **verified** |
| 10 | No source file is changed | The command owns no apply mode; the shell check compares fixture digests before and after dry-run. Production data was not supplied or edited. | **verified** |
| 11 | Existing repository behavior remains green | Final clean workflow run #715 passed `tools/check.sh`, MCP tests, and `tools/coverage`. | **verified** |

## 4. Exact fake migration evidence

The fixture contains four source families and an explicit ledger default:

```text
DEFAULT_CURRENCY=JPY
accounts.tsv
journal.tsv
plan.tsv
budget_alloc.tsv
```

The first preview asserts exactly five additions:

```text
accounts.tsv      2
journal.tsv       1
plan.tsv          1
budget_alloc.tsv  1
-------------------
total             5
```

Existing explicit JPY and ILS rows are unchanged. A second preview proposes zero additions.

## 5. Operational boundary retained

M1.5 did not migrate actual `LEDGER_DATA_DIR` data. Production migration remains a later explicit, user-approved checkpoint. The current command is intentionally limited to:

```text
tools/currency-setup audit [base-dir]
tools/currency-setup dry-run [base-dir]
```

There is no apply or commit mode.

Strict missing-currency rejection is also not enabled. Legacy compatibility remains where current production behavior still requires it.

## 6. Routing decision

M1.5 is complete and verified. The concrete July travel requirement now authorizes only the next finite slice from the active plan:

```text
M2: Editor currency-aware account and journal input
```

M2 may implement:

- `account add --currency`;
- `account list --role --currency`;
- exact-decimal editor amount validation;
- at most two fractional digits for ILS;
- matching-currency From/To candidate filtering;
- automatic explicit `currency=` metadata for every new account and journal row, including JPY;
- rejection of mismatched account currencies;
- explicit ledger default as initial selection only.

M2 must not:

- mutate existing production source rows;
- run or add an automatic production migration;
- enable strict missing-currency rejection for historical source;
- change report balances or human currency formatting;
- implement FX, conversion, valuation, Currency axis, or mixed aggregation;
- automatically authorize M2.5 or M3.
