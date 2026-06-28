# src_next / current engine comparison notes


> **Note (2026-06-26):** Old engine has been deleted. References in this doc are historical. Current engine is src_next/.
Status: experimental read-only observation point

`src_next` is not a production replacement and does not yet implement the full
current report. This comparison exists only to see whether the minimal
`src_next` compact summary is becoming numerically comparable with selected
current engine outputs.

For account and expense classification notes before food / daily remaining work,
see `docs/SRC_NEXT_EXPENSE_ACCOUNT_MAPPING.md`.

## Manual comparison helper

```sh
bash checks/check-src-next-vs-current.sh fixtures/src-next-golden
```

The helper is read-only. It runs:

- `bqn src_next/main.bqn <fixture>` and extracts `src_next_*` compact summary
  fields.
- `bqn src/reports/exporters/export-cycle-summary.bqn --base <fixture> --as-of <cycle_end_exclusive>`
  for current actual cycle expense.
- `bqn src/reports/exporters/export-plan-summary.bqn --base <fixture> --as-of <cycle_start>`
  for current plan expense remaining in the cycle.

The two `--as-of` values are intentionally different because `src_next` has no
observation-time concept yet. It materializes all valid rows in the fixed cycle,
while the current engine reports actuals and remaining plans from an `as_of`
observation point.

You can override them for investigation:

```sh
SRC_NEXT_CURRENT_ACTUAL_AS_OF=2026-06-16 \
SRC_NEXT_CURRENT_PLAN_AS_OF=2026-06-15 \
  bash checks/check-src-next-vs-current.sh fixtures/src-next-golden
```

## Initial comparison surface

Keep the first comparison small:

| metric | src_next field | current engine field | comparison role |
|---|---|---|---|
| cycle range | `src_next_cycle_range` | `cycle_start..cycle_end_exclusive` from `export-cycle-summary.bqn` | primary comparable field |
| actual expense total | `src_next_actual_expense_total` | `cycle_expense_actual` from `export-cycle-summary.bqn` | primary household-accounting field |
| plan expense total | `src_next_plan_expense_total` | `planned_expense_remaining_current_cycle` from `export-plan-summary.bqn` | primary household-accounting field |
| valid projection row count | `src_next_valid_projection_rows` | no direct current equivalent | src_next partition evidence |
| skipped projection row count | `src_next_skipped_projection_rows` | no direct current equivalent | src_next partition evidence |
| signed actual total | `src_next_actual_total` | no direct current equivalent | reference only |
| signed plan total | `src_next_plan_total` | no direct current equivalent | reference only |

`src_next_actual_total` and `src_next_plan_total` are ledger-like signed totals.
Because debit rows are positive and credit rows are negative, balanced rows
usually sum to `0` or near `0`. Do not use them as household spending totals.
For household expense comparison, use `src_next_actual_expense_total` and
`src_next_plan_expense_total` instead.

## Difference classification

Do not treat a mismatch as a bug by default. Classify it first:

| category | use when | action |
|---|---|---|
| regression candidate | A primary comparable field differs and no documented design or fixture reason explains it. | Investigate before changing either engine; do not silently bless the diff. |
| expected design difference | The two paths intentionally expose different semantics or different failure surfaces. | Record the reason; do not treat as production regression. |
| fixture/data coverage gap | The fixture does not contain the data needed for a fair comparison, or one path lacks a matching public export field. | Add or adjust public fixtures / docs before judging engine behavior. |
| unknown / needs investigation | The helper output is not enough to decide whether the diff is expected, fixture-related, or a bug. | Preserve evidence and investigate with smaller fixtures or direct exporters. |

Known early examples:

- **Expected design difference:** `src_next` exposes valid/skipped projection
  partitions; the current engine does not expose the same ledger-like partition
  surface.
- **Expected design difference / regression candidate if promoted unchanged:**
  unknown-account or out-of-cycle rows may be observable as skipped rows in
  `src_next`, while the current engine may fail closed or filter through
  different checks depending on the fixture and command. This is acceptable for
  the experimental read-only comparison surface, but would need a separate
  production safety decision before replacement.
- **Fixture/data coverage gap:** valid/skipped row counts currently have no
  direct current-engine export field, so a count difference cannot be judged as
  an engine regression without adding a comparable production observation point.
- **Unknown / needs investigation:** any mismatch in `cycle_range`,
  `actual_expense_total`, or `plan_expense_total` on a fixture intended to model
  the same household-accounting semantics.
- **Reference-only, not a regression:** signed `actual_total` / `plan_total`
  being `0` while expense totals are nonzero. This is normal for balanced
  ledger-like rows.

Small public fixtures already covering useful categories:

| fixture | useful for | current comparison note |
|---|---|---|
| `fixtures/src-next-golden` | baseline matching household expense totals plus skipped out-of-cycle plan rows | actual and plan expense totals should match current engine for the cycle; signed totals remain `0`. |
| `fixtures/src-next-unknown-account` | skipped unknown-account evidence | current engine is expected to fail closed; classify this as a design/failure-surface difference for src_next analysis, not as a production regression. |
| `fixtures/src-next-out-of-cycle-journal` | skipped out-of-cycle journal evidence | may also trigger current-engine strict future-journal checks depending on wall-clock date; classify the helper status before acting. |
| `fixtures/src-next-missing-plan` | optional `plan.tsv` coverage | useful for distinguishing absent-plan fixture coverage from plan-total regressions. |

## Replacement readiness gap classification (Stage 2)

Results from running `checks/check-src-next-vs-current.sh` against all
`fixtures/src-next-*` fixtures and `data/` on 2026-06-24.

### Field-level classification

| field | current status | classification | next action |
|---|---|---|---|
| `cycle_range` | comparable | comparable field | keep observing; incomeAnchor support landed in PR #20; production data comparison confirmed matched |
| `actual_expense_total` | comparable | comparable field | keep observing; matches on all fixed-mode fixtures |
| `plan_expense_total` | comparable | comparable field | keep observing; matches on all fixed-mode fixtures |
| `valid_projection_rows` | src_next only | src_next partition evidence | no current equivalent; non-regression |
| `skipped_projection_rows` | src_next only | src_next partition evidence | no current equivalent; non-regression |
| `signed_actual_total` | src_next only | reference-only | balanced ledger rows sum to 0; non-regression |
| `signed_plan_total` | src_next only | reference-only | balanced ledger rows sum to 0; non-regression |

### Fixture-level results

Each fixture uses `mode fixed` cycle.tsv. All comparable fields match exactly.

| fixture | cycle_range | actual_expense_total | plan_expense_total | valid_proj | skipped_proj | signed_actual | signed_plan | note |
|---|---|---|---|---|---|---|---|
| `src-next-golden` | ✅ match | ✅ 120 = 120 | ✅ 30 = 30 | 6 (n/a) | 2 (n/a) | 0 (n/a) | 0 (n/a) | baseline; 2 skipped = out-of-cycle plan rows |
| `src-next-currency-accountkey` | ✅ match | ✅ 150 = 150 | ✅ 0 = 0 | 6 (n/a) | 0 (n/a) | 0 (n/a) | 0 (n/a) | empty plan fixture |
| `src-next-empty-projection` | ✅ match | ✅ 0 = 0 | ✅ 0 = 0 | 0 (n/a) | 0 (n/a) | 0 (n/a) | 0 (n/a) | empty journal + empty plan |
| `src-next-expense-role-metadata` | ✅ match | ✅ 300 = 300 | ✅ 700 = 700 | 12 (n/a) | 0 (n/a) | 0 (n/a) | 0 (n/a) | role= metadata coverage |
| `src-next-household-mapping-policy` | ✅ match | ✅ 670 = 670 | ✅ 240 = 240 | 20 (n/a) | 0 (n/a) | 0 (n/a) | 0 (n/a) | config.tsv household mapping |
| `src-next-missing-plan` | ✅ match | ✅ 120 = 120 | ✅ 0 = 0 | 4 (n/a) | 0 (n/a) | 0 (n/a) | 0 (n/a) | no plan.tsv; plan_total is 0 for both |
| `src-next-out-of-cycle-journal` | ✅ match | ✅ 100 vs ERROR | ✅ 0 vs ERROR | 2 (n/a) | 2 (n/a) | 0 (n/a) | 0 (n/a) | current engine fails closed on future journal rows; see error-case table |
| `src-next-unknown-account` | ✅ match | ✅ 100 vs ERROR | ✅ 0 vs ERROR | 2 (n/a) | 2 (n/a) | 0 (n/a) | 0 (n/a) | current engine fails closed on unknown account; see error-case table |

### Error-case classification

| fixture / data | error in | classification | details | next action |
|---|---|---|---|---|
| `data/` | src_next | **resolved** | `cycle.tsv` uses `mode incomeAnchor`. Previously blocked — `src_next/cycle.bqn` only supported `fixed` mode. **Addressed by PR #20** — minimal `incomeAnchor` support is now implemented. Production `data/` comparison was retried after PR #20 / #21 / #22. Helper completed without error. All comparable fields matched. | No immediate action; keep helper manual. |
| `src-next-out-of-cycle-journal` | current engine | **expected design difference** | Journal row dated 2026-06-30 is after system_today 2026-06-24; current engine fails closed with strict future-journal lint. src_next gracefully classifies it as out-of-cycle and reports 2 skipped rows. | Document as intentional failure-surface difference; no action required for Stage 2 |
| `src-next-unknown-account` | current engine | **expected design difference** | Journal row references `unknown:ghost` account not in accounts.tsv; current engine fails closed with unknown-account lint. src_next gracefully classifies it as skipped and reports 2 skipped rows. | Document as intentional failure-surface difference; no action required for Stage 2 |

### Summary

- **All 8 fixed-mode fixtures**: `cycle_range`, `actual_expense_total`, `plan_expense_total` match exactly between src_next and current engine.
- **1 incomeAnchor fixture** (`src-next-income-anchor-golden`): added via PR #20, golden check passes in `tools/check.sh`.
- **No regression candidates found** on any comparable field.
- **~~1 missing feature~~**: `incomeAnchor` cycle mode was blocking production data comparison. **Addressed by PR #20** — minimal `incomeAnchor` support is now implemented in `src_next/cycle.bqn`. Production `data/` comparison can now be retried manually via `checks/check-src-next-vs-current.sh`.
- **Production comparison result**: retried after incomeAnchor support (PR #20 / #21). All comparable fields matched. See [Production comparison retry](#production-comparison-retry-after-incomeanchor-support) below.
- **2 expected design differences**: failure-surface divergence on out-of-cycle and unknown-account fixtures (current engine fails closed, src_next skips gracefully).
- **4 src_next-only fields**: `valid_projection_rows`, `skipped_projection_rows`, `signed_actual_total`, `signed_plan_total` — all reference-only, non-regression.

## Production comparison retry after incomeAnchor support

Status: manual production comparison retried after PR #20 / #21.

Privacy note:
Production values are intentionally omitted from this public document.

### Summary

Both `bqn src_next/main.bqn data` and `bash checks/check-src-next-vs-current.sh data`
completed without error.

| field | result | classification | next action |
|---|---|---|---|
| `cycle_range` | matched | comparable field | no action |
| `actual_expense_total` | matched | comparable field | no action |
| `plan_expense_total` | matched | comparable field | no action |
| `valid_projection_rows` | observed (112) | src_next partition evidence | no current equivalent |
| `skipped_projection_rows` | observed (486) | src_next partition evidence | no current equivalent |
| `signed_actual_total` | observed (0) | reference-only | not household spending total |
| `signed_plan_total` | observed (0) | reference-only | not household spending total |

### Notes

- Private values omitted.
- The comparison helper remains manual and is not wired into `tools/check.sh`.
- No production default switch is made.
- No regression candidates found on any comparable field.
- The 486 skipped rows include pre-cycle journal rows (day_index < 0) and
  post-cycle plan rows (day_index >= 60) — expected under src_next's current
  cycle window semantics.

## Automation policy

`checks/check-src-next-vs-current.sh` is intentionally not wired into
`tools/check.sh` yet. Keep it as a manual check until the comparison semantics
are stable enough that a mismatch means a real regression rather than a known
prototype/current-engine difference.

## Related documents

- `docs/SRC_NEXT_INCOME_ANCHOR_CYCLE_CONTRACT.md` — incomeAnchor cycle mode
  contract for src_next (design gate before implementation).
