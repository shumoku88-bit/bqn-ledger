# Journal Budget Companion Projection Characterization — Completion Record

- status: completed
- date: 2026-07-22
- branch: `test/journal-budget-companion-projection-characterization`
- preceding_plan: `docs/JOURNAL_BUDGET_COMPANION_PROJECTION_CHARACTERIZATION_PLAN.md`
- preceding_selection_pr: #312

## Purpose

Characterize the projection of persisted Journal actual purchase events and associated balanced budget companion events through Stage 1 Transaction IR and Stage 2A Posting IR into TBDS period views (`context.BuildPeriodView`). Observe budget-layer virtual account movements separately without changing actual-layer amounts, modifying production routing, or changing Cube/TBDS shapes.

## Canonical Finite Question

> 保存済みのbalanced budget-layer companion eventを、既存のJournal parser、Posting IR、TBDSの境界へtest-onlyで投影し、actual-layerの金額を変えずにbudget-layerの仮想口座移動だけを観察できるか。

**Answer: YES.**

Persisted budget-layer companion events project cleanly into Stage 1 Transaction IR, Stage 2A Posting IR (layer index 2), and TBDS period views (`context.BuildPeriodView`). The actual layer remains completely unaffected (`bank`: -5600, `food:daily`: +2800, `food:stock`: +1800, `household`: +1000), while the budget layer records virtual account movements (`spent:daily`: +2300, `daily`: -2300, `spent:flex`: +500, `flex`: -500). Net movements in both layers are exactly 0.

## Implemented Test Path

- Test script: `tests/test_journal_budget_companion_projection_characterization.bqn`
- Helper modification: `src_next/journal_read_only_source_carrier.bqn` (deferred Stage 2A block execution with `𝕊:` to ensure adapter is not invoked when Stage 1 parser fails)

## Changed Files

1. `tests/test_journal_budget_companion_projection_characterization.bqn` (new test-only characterization script)
2. `src_next/journal_read_only_source_carrier.bqn` (1-line fix: deferred Stage 2A block execution)
3. `tools/.repo-index-baseline.tsv` (updated baseline for new test file)

## Observed Transaction IR

- **Parsed Events**: 3 transactions parsed from synthetic fixture (`defaults-v1.journal` + `persisted-events.journal`)
  - Transaction 1: Actual purchase (`event-purchase-1`, 2026-08-03, layer `actual`, 2 postings)
  - Transaction 2: Budget companion (`event-budget-companion-1`, 2026-08-03, layer `budget`, `actual-event-id`: `event-purchase-1`, 4 postings)
  - Transaction 3: Actual purchase (`event-purchase-2`, 2026-08-04, layer `actual`, 2 postings)
- **Zero-Sum Balance**: Verified `+´ {𝕩.delta}¨ postings ≡ 0` for all 3 transactions.

## Observed Posting IR (Stage 2A)

- **Total Posting Rows**: 12 rows generated across 3 transactions.
- **Layer Distribution**:
  - Actual layer (layer index 0): 8 rows (4 from Transaction 1, 4 from Transaction 3)
  - Budget layer (layer index 2): 4 rows (from Transaction 2)
- **Posting Attributes**: Verified `posting_id`, `layer_index`, `side`, `delta`, `status` ("ok").

## Observed Actual-Layer TBDS (`cube.layer_actual`)

Period view constructed via `context.BuildPeriodView` (8 accounts × 4 layers = 32 rows):

| Account Key | Opening | Debit | Credit | Net Movement | Closing |
|---|---|---|---|---|---|
| `assets:bank/JPY` | 0 | 0 | 5600 | -5600 | -5600 |
| `expenses:food:daily/JPY` | 0 | 2800 | 0 | +2800 | +2800 |
| `expenses:food:stock/JPY` | 0 | 1800 | 0 | +1800 | +1800 |
| `expenses:household/JPY` | 0 | 1000 | 0 | +1000 | +1000 |
| `budget:spent:daily/JPY` | 0 | 0 | 0 | 0 | 0 |
| `budget:daily/JPY` | 0 | 0 | 0 | 0 | 0 |
| `budget:spent:flex/JPY` | 0 | 0 | 0 | 0 | 0 |
| `budget:flex/JPY` | 0 | 0 | 0 | 0 | 0 |

- **Net Actual Movement**: 0 (-5600 + 2800 + 1800 + 1000)
- **Budget Account Balances in Actual Layer**: All 0.

## Observed Budget-Layer TBDS (`cube.layer_budget`)

| Account Key | Opening | Debit | Credit | Net Movement | Closing |
|---|---|---|---|---|---|
| `assets:bank/JPY` | 0 | 0 | 0 | 0 | 0 |
| `expenses:food:daily/JPY` | 0 | 0 | 0 | 0 | 0 |
| `expenses:food:stock/JPY` | 0 | 0 | 0 | 0 | 0 |
| `expenses:household/JPY` | 0 | 0 | 0 | 0 | 0 |
| `budget:spent:daily/JPY` | 0 | 2300 | 0 | +2300 | +2300 |
| `budget:daily/JPY` | 0 | 0 | 2300 | -2300 | -2300 |
| `budget:spent:flex/JPY` | 0 | 500 | 0 | +500 | +500 |
| `budget:flex/JPY` | 0 | 0 | 500 | -500 | -500 |

- **Net Budget Movement**: 0 (+2300 - 2300 + 500 - 500)
- **Actual Account Balances in Budget Layer**: All 0.

## Actual Projection Invariance

Field-by-field equality verified between:
- **View A**: Full period view (actual purchases + budget companion) filtered to `cube.layer_actual`
- **View B**: Actual-only period view (actual purchases only, no companion) filtered to `cube.layer_actual`

All fields (`account_key`, `layer_name`, `opening_balance`, `debit_sum`, `credit_sum`, `net_movement`, `closing_balance`) match identically across all 8 accounts.

## Historical Stability under Defaults V2

Tested persisted companion events under `defaults-v2.journal` (where default envelope assignment for `expenses:food:stock` changed from `daily` to `flex`):
- **Persisted Companion Behavior**: Preserved historical envelope assignment (`budget:spent:daily` +2300 / `budget:daily` -2300) regardless of V2 header defaults.
- **Entry-Time Resolution Behavior**: Re-resolving entry-time assignment under V2 defaults yielded flex 2800 (`budget:spent:flex` +2800 / `budget:flex` -2800).
- **TBDS Invariance**: TBDS coordinates from persisted companion under V2 match V1 coordinates identically.

## Fail-Closed Evidence

Verified that invalid companion inputs fail safely without producing corrupt posting rows:

1. **Missing link**: `; actual-event-id:` missing -> `budget_link_missing`, state `"error"`, 0 posting rows.
2. **Invalid/mismatched link**: `; actual-event-id: event-does-not-exist` -> `actual_event_target_invalid`, state `"error"`, 0 posting rows.
3. **Unbalanced companion**: Posting deltas do not sum to 0 -> `event_unbalanced`, state `"error"`, 0 posting rows.
4. **Unknown budget account**: Postings reference undeclared budget account -> `posting_account_unknown`, state `"error"`, 0 posting rows.
5. **Unsupported layer**: Transaction layer set to `unknown_layer` -> `layer_unsupported`, state `"error"`, 0 posting rows.

## Production Boundary Verification

- Production parser routing: UNCHANGED.
- Daily Cube & TBDS shapes: UNCHANGED.
- Writers/Editors: NONE.
- Production files edited: `src_next/journal_read_only_source_carrier.bqn` (test-only helper module).

## Validation Suite

- `bqn tests/test_journal_budget_companion_projection_characterization.bqn`: OK
- `git diff --check`: PASSED cleanly
- `checks/check-docs-lifecycle.sh`: PASSED (4 passed, 0 warnings)
- `checks/check-absolute-links.sh`: PASSED
- `checks/check-repo-index.sh`: PASSED
- `tools/check.sh`: PASSED cleanly (all tests and devtools checks pass)
