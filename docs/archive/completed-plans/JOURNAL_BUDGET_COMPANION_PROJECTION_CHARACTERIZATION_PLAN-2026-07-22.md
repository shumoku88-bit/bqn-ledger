# Journal Budget Companion Projection Characterization — Completion Record

Status: completed test-only characterization
Owner: journal source migration
Canonical: no; canonical routing remains TODO.md
Date: 2026-07-22
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
- Helper modification: `src_next/journal_read_only_source_carrier.bqn` (test-only read-only carrier module; converted anonymous immediate block to subject function `{𝕊: ...}` so Stage 2A adapter is skipped when Stage 1 fails closed)

## Changed Files

```text
NEXT_SESSION.md
TODO.md
docs/JOURNAL_BUDGET_COMPANION_PROJECTION_CHARACTERIZATION_PLAN.md  # deleted
docs/README.md
docs/archive/completed-plans/JOURNAL_BUDGET_COMPANION_PROJECTION_CHARACTERIZATION_PLAN-2026-07-22.md
src_next/journal_read_only_source_carrier.bqn
tests/test_journal_budget_companion_projection_characterization.bqn
```

## Observed Transaction IR

Parsed 3 transactions from synthetic fixture (`defaults-v1.journal` + `persisted-events.journal`):

1. `event-purchase-2026-08-03-001`
   - date: `2026-08-03`
   - layer: `actual`
   - postings: 4 (`expenses:food:daily` +1400, `expenses:food:stock` +900, `expenses:household` +500, `assets:bank` -2800)
   - deltas: `+1400, +900, +500, -2800`

2. `event-envelope-consumption-2026-08-03-001`
   - date: `2026-08-03`
   - layer: `budget`
   - `actual-event-id`: `event-purchase-2026-08-03-001`
   - postings: 4 (`budget:spent:daily` +2300, `budget:daily` -2300, `budget:spent:flex` +500, `budget:flex` -500)
   - deltas: `+2300, -2300, +500, -500`

3. `event-purchase-2026-08-10-001`
   - date: `2026-08-10`
   - layer: `actual`
   - postings: 4 (`expenses:food:daily` +1400, `expenses:food:stock` +900, `expenses:household` +500, `assets:bank` -2800)
   - deltas: `+1400, +900, +500, -2800`

All 3 transactions balance independently to zero (`+´ {𝕩.delta}¨ postings ≡ 0`).

## Observed Posting IR (Stage 2A)

- **Total Posting Rows**: 12 rows generated across 3 transactions.
- **Layer Distribution**:
  - Actual layer (`layer_index = 0`): 8 rows (4 from Transaction 1, 4 from Transaction 3)
  - Budget layer (`layer_index = 2`): 4 rows (from Transaction 2)
- **Provenance & Sequence**: Durable source event identity (`source_event_id`) and posting order within each event are preserved.

## Observed Actual-Layer TBDS (`cube.layer_actual`)

Period view constructed via `context.BuildPeriodView` (8 accounts × 4 layers = 32 rows):

| Account Key | Opening | Debit | Credit | Movement | Closing |
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

| Account Key | Opening | Debit | Credit | Movement | Closing |
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

All fields (`account_key`, `layer_name`, `opening`, `debit_movement`, `credit_movement`, `movement`, `closing`) match identically across all 8 accounts.

## Historical Stability under Defaults V2

Tested persisted companion events under `defaults-v2.journal` (where all three expense accounts `expenses:food:daily`, `expenses:food:stock`, and `expenses:household` declare `default-envelope: flex`):

```text
future candidate resolution under V2:
  daily = 0
  flex = 2800

persisted historical budget projection:
  budget:spent:daily = +2300
  budget:daily = -2300
  budget:spent:flex = +500
  budget:flex = -500
```

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

## Helper Modification Verification

- Modified `src_next/journal_read_only_source_carrier.bqn` (test-only helper module).
- Converted anonymous immediate block `{ ... }` to subject function `{𝕊: ...}` so Stage 2A adapter is skipped when Stage 1 fails closed, returning 0 posting rows instead of partial rows.
- Production routing remains untouched.

## Production Boundary Verification

- Production parser routing: UNCHANGED.
- Daily Cube & TBDS shapes: UNCHANGED.
- Writers/Editors: NONE.

## Validation Suite

- `bqn tests/test_journal_budget_companion_projection_characterization.bqn`: OK
- `git diff --check`: PASSED cleanly
- `checks/check-docs-lifecycle.sh`: PASSED (4 passed, 0 warnings)
- `checks/check-absolute-links.sh`: PASSED
- `checks/check-repo-index.sh`: PASSED
- `tools/check.sh`: PASSED cleanly (all tests and devtools checks pass)
