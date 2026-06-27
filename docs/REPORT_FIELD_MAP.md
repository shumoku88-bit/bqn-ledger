# REPORT_FIELD_MAP: `report_engine.Build` return fields

> **Status: historical / superseded (2026-06-26)**
> **Note (2026-06-26):** Old engine has been deleted. References in this doc are historical. Current engine is src_next/.
> 現在のエンジン `src_next/` では `BuildContext → ViewModel → Format` パターンを使います。
> この文書は旧エンジンのフィールド依存マップの履歴として残します。

この文書は、`report_engine.bqn` が返す `r.xxx` の影響範囲マップです。

目的:
- pit が「この値を変えると、どの表示/ツールに影響するか」を素早く確認する。
- `main.bqn` を縦断せずに、セクションごとの依存を把握する。

関連:
- セクション単位の入出力: `docs/MAIN_SECTIONS.md`
- データフロー全体: `docs/ARCHITECTURE.md`

> NOTE: 現在の return field は 99 個。増減したらこの表も更新する。`tools/check-docs-drift.sh` が実装との差分を検出する。

## 影響範囲表

| field | produced in `report_engine.bqn` | used by `main.bqn` | used by tools | notes |
|---|---|---|---|---|
| `accs` | `core.InitAccounts` result | assigned, currently not rendered | none | account metadata/id map. Future extensions may use it. |
| `names` | `accs.names` | Sec3 balances, Sec8 check, formatting widths | `export-balances.bqn` | 256-slot account names. Empty slots are `""`. |
| `journal_rows` | parsed `journal.tsv` | Sec7 recent, Sec8 check | none | strict-checked actual rows. |
| `plan_rows` | parsed `plan.tsv` | Sec8 check | none | strict-checked planned rows. Future payments are separately filtered into `future_payments`. |
| `residual_table` | `rres.Build` result | none (section removed) | `export-residual-summary.bqn` | Compatibility Plan vs Actual comparison table for the current cycle observed through `as_of`; excludes `future_open` plans and actual rows after `as_of`. |
| `actual_comparison_period_kind` | `ractcmp.Build` result | Sec11 actual-comparison | none | Initial value `current_cycle_elapsed`; compares current cycle elapsed Actuals with previous cycle same elapsed days. |
| `actual_comparison_current_start` | `ractcmp.Build` result | Sec11 actual-comparison | none | Current comparison window start, equal to current `cycle_start`. |
| `actual_comparison_current_end_exclusive` | `ractcmp.Build` result | Sec11 actual-comparison | none | Exclusive current window end, `as_of + 1 day`. |
| `actual_comparison_baseline_start` | `ractcmp.Build` result | Sec11 actual-comparison | none | Previous cycle start used as comparison baseline, or `unavailable`. |
| `actual_comparison_baseline_end_exclusive` | `ractcmp.Build` result | Sec11 actual-comparison | none | Exclusive baseline window end with the same elapsed day count as current. |
| `actual_comparison_observation_status` | `ractcmp.Build` result | Sec11 actual-comparison | none | `ok`, `unavailable`, or `insufficient_history`; no ratio backfill is done when history is insufficient. |
| `actual_comparison_table` | `ractcmp.Build` result | Sec11 actual-comparison | none | Actual-vs-actual comparison rows: period/lane/unit/window amounts/counts/ratio/status. |
| `budget_alloc_rows` | parsed `budget_alloc.tsv` | none | none | exposed for diagnostics/future use. Manual budget allocation source rows. |
| `bal_final` | `BuildCube` snapshot at `as_of` | assigned, currently not rendered directly | none | raw 256×4 matrix (`actual`, `plan`, `budget`, `forecast`). Prefer derived fields for display/export. Legacy checks compare only actual/budget layers. |
| `meta` | Account metadata predicates and values | Sec5 envelopes | none | Object returned by `report_meta.bqn`. |
| `assets_total` | asset actual balances | Sec1 snapshot | `summary.bqn` (`assets_total`) | Sum of `assets:*` actual balances. |
| `liabilities_total` | liability actual balances | Sec1 snapshot | none | Sum of `liabilities:*` actual balances. |
| `liq_total` | account meta `type=liquid` | Sec1 snapshot, Sec5 envelopes seedable amount | `summary.bqn` (`assets_liquid`) | Liquid assets. |
| `sav_total` | account meta `type=savings` | Sec1 snapshot | `summary.bqn` (`assets_savings`) | Savings assets. |
| `inv_total` | account meta `type=invest` | Sec1 snapshot | `summary.bqn` (`assets_invest`) | Investment assets. |
| `all_inc_total` | journal income rows in `as_of` year up to `as_of` | Sec2 YTD | `summary.bqn` (`ytd_income`) | Year-to-date: `YYYY-01-01 <= journal date <= as_of`. |
| `all_exp_total` | journal expense rows in `as_of` year up to `as_of` | Sec2 YTD | `summary.bqn` (`ytd_expense`) | Sum of `expenses:*` To rows in YTD window. |
| `all_net` | `all_inc_total - all_exp_total` | Sec2 YTD | `summary.bqn` (`ytd_net`) | Income minus expense. |
| `fixed_total_all` | expense rows whose account has `fixed=1` | Sec2 YTD | `summary.bqn` (`ytd_fixed_expense`) | Fixed expense total. |
| `var_total_all` | `all_exp_total - fixed_total_all` | Sec2 YTD | `summary.bqn` (`ytd_variable_expense`) | Variable expense total. |
| `fix_names_sorted` | fixed expense breakdown | Sec2 YTD | none | Sorted descending by amount. |
| `fix_sums_sorted` | fixed expense breakdown | Sec2 YTD | none | Parallel to `fix_names_sorted`. |
| `var_names_sorted` | variable expense breakdown | Sec2 YTD | none | Sorted descending by amount. |
| `var_sums_sorted` | variable expense breakdown | Sec2 YTD | none | Parallel to `var_names_sorted`. |
| `cycle_start_dn` | `cycle.bqn` resolver | none | none | Numeric cycle start date for filtering current-cycle recorded rows. |
| `cycle_end_excl_dn` | `cycle.bqn` resolver | none | none | Numeric exclusive end date for filtering current-cycle recorded rows and plan ranges. |
| `cycle_start` | `cycle.bqn` resolver | Sec4 cycle, Sec8 check | `summary.bqn` (`cycle_start`) | Display string date. |
| `cycle_end` | `cycle.bqn` resolver | Sec4 cycle, Sec8 check | `summary.bqn` (`cycle_end_exclusive`) | Display string date, exclusive end. |
| `cycle_mode` | `cycle.tsv` via `cycle.bqn` | Sec4 cycle, Sec8 check | `summary.bqn` (`cycle_mode`) | `incomeAnchor` / `fixed` / `calendarMonth`. |
| `cycle_inc_total` | journal rows in current cycle up to `as_of` | Sec4 cycle | `summary.bqn` (`cycle_income`) | Income total inside cycle window with observation cutoff. |
| `cycle_exp_total` | journal rows in current cycle up to `as_of` | Sec4 cycle | `summary.bqn` (`cycle_expense`) | Expense total inside cycle window with observation cutoff. |
| `cycle_net` | `cycle_inc_total - cycle_exp_total` | Sec4 cycle | `summary.bqn` (`cycle_net`) | Cycle income minus expense up to `as_of`. |
| `sorted_exp_names` | cycle expense breakdown | Sec4 cycle | none | Sorted descending by amount. |
| `sorted_exp_sums` | cycle expense breakdown | Sec4 cycle | none | Parallel to `sorted_exp_names`. |
| `idx_actual` | visible actual account indexes | Sec3 balances | none | Accounts to show in human balance list. |
| `idx_liabilities` | visible liability account indexes | Sec3 balances | none | Liabilities to show in their own section. |
| `adj_actual` | signed actual balances | Sec3 balances | `export-balances.bqn` | Income/equity sign adjusted for display/export. |
| `idx_budget` | visible budget account indexes | Sec5 envelopes | none | Budget accounts with activity, excluding `budget:spent`. |
| `budget_balances` | budget/intent column of `bal_final` | Sec5 envelopes | `export-balances.bqn` | 256-length budget balances. |
| `future_payments` | open `plan.tsv` rows with `date >= as_of`, sorted by date | Sec6 planned | `export-planned.bqn` | Excludes budget↔budget plan moves, completed `plan_id` rows, and overdue rows before `as_of` (shown in `plan_status_table`). |
| `plan_status_table` | all `plan.tsv` rows with derived lifecycle status | Sec6 planned | none | Row shape: `date memo from to planned_amount actual_amount status plan_id`. Status: `future_open`, `due_open`, `overdue_open`, `completed`. |
| `as_of` | system today via `Build`, or explicit value via `BuildAt` | Sec5 exhaustion prediction, Sec9 outlook | none | Observation date. System today is only its default source; `main.bqn --as-of` can override. It is not Event coordinate or generation time. |
| `last_journal_date` | max journal coordinate, with `as_of` fallback for empty journal | Sec9 outlook | none | Context only; a gap from `as_of` is not automatically an error. Future rename to `last_recorded_on` may be clearer. |
| `journal_lag_days` | `as_of - last_journal_date` via `date.bqn` | Sec9 outlook | none | Displayed as context. Can be negative if journal contains future-dated rows. |
| `days_left` | `cycle_end_exclusive - as_of`, clamped at 0 | Sec5 envelopes, Sec9 outlook | none | Residual cycle days, including `as_of` day. |
| `daily_divisor` | `max(1, days_left)` | assigned, currently not rendered directly | none | Avoids division by zero; daily fields are zero when `days_left=0`. |
| `idx_liquid` | indexes of accounts with `type=liquid` | Sec9 outlook | none | Liquid asset breakdown. |
| `liq_daily` | `floor(projected_liq / daily_divisor)` | Sec9 outlook | none | Includes ALL future plans in cycle (income + expenses). |
| `liq_safe_daily` | `floor(safe_liq / daily_divisor)` | Sec9 outlook | none | Conservative: deducts future expenses but ignores future income. |
| `budget_daily` | `floor(budget_balances / daily_divisor)` | Sec9 outlook | none | 256-length vector parallel to `budget_balances`. |
| `trend_dates` | journal dates in current cycle up to `as_of`, plus `as_of` | Sec10 daily-trend | none | Journal-date based trend, not full calendar-day enumeration. |
| `trend_liquid` | liquid asset balance at each trend date | Sec10 daily-trend | none | Parallel to `trend_dates`. |
| `trend_fixed_reserve` | fixed expenses still reserved after each trend date | Sec5 envelopes seedable amount, Sec10 daily-trend | none | Uses `spend_class=fixed` / `fixed=1`; includes planned future fixed after `as_of`. |
| `trend_daily_fund` | `trend_liquid + planned_future_income - trend_fixed_reserve` | Sec5 envelopes seedable amount, Sec10 daily-trend | none | Living daily amount / seedable budget base. |
| `planned_future_income` | future planned income inside current cycle | Sec5 envelopes seedable amount | none | Used in seedable budget derivation. |
| `trend_days_left` | cycle end exclusive minus trend date | Sec10 daily-trend | none | Includes the trend date. |
| `trend_daily` | `floor(trend_daily_fund / max(1, trend_days_left))` | Sec10 daily-trend | none | Zero when no days are left. |
| `trend_delta` | change in `trend_daily` from previous trend row | Sec10 daily-trend | none | First row is 0. |
| `trend_variable` | same-day `spend_class=variable` expense Actual update from `day_updates` | Sec10 daily-trend | none | `expenses:予備` is variable by convention. |
| `trend_saving` | same-day savings/investment net flow, from `day_updates` | Sec10 daily-trend | none | Positive means moved into savings/investment; negative means drawdown. |
| `trend_fixed_paid` | same-day fixed expense Actual update from `day_updates` | Sec10 daily-trend | none | Display context; fixed is excluded from variable cause analysis. |
| `trend_drop_idx` | Top 10 indexes sorted by negative `trend_delta` | Sec10 daily-trend | none | Used for drop ranking. |
| `fixed_obligation_rows` | `cashflow=fixed_obligation` open plan rows in current cycle | assigned, currently not rendered directly | none | Non-expense cashouts such as debt principal repayment; filtered to liquid-account outflows. |
| `fixed_obligation_reserve` | sum of `fixed_obligation_rows` amounts | Sec5 envelopes, Sec9 outlook | `export-report-numbers.bqn`, `export-liquid-assets-summary.bqn` when non-zero | Reserved cashflow obligations kept separate from expense totals. |
| `next_cycle_start_obligation_rows` | `cashflow=fixed_obligation` open plan rows exactly on `cycle_end_exclusive` | none | none | Next-cycle-start obligations shown as reference, not included in current-cycle reserve. |
| `next_cycle_start_obligation_reserve` | sum of `next_cycle_start_obligation_rows` amounts | Sec5 envelopes, Sec9 outlook | `export-report-numbers.bqn`, `export-liquid-assets-summary.bqn` when non-zero | Useful for income-day payments on the next cycle boundary. |
| `fixed_cash_out_reserve` | `current_fixed_reserve + fixed_obligation_reserve` | assigned, currently not rendered directly | `export-report-numbers.bqn` when non-zero | Combined fixed cashout reserve. |
| `cash_out_daily_fund` | `trend_daily_fund at as_of - fixed_obligation_reserve` | Sec5 envelopes | none | Seed/living fund after non-expense fixed obligations. |
| `cash_out_safe_liquid_assets` | `liq_total - fixed_cash_out_reserve` | assigned, currently not rendered directly | `export-report-numbers.bqn`, `export-liquid-assets-summary.bqn` when non-zero | Liquid assets after fixed expenses and fixed obligations. |
| `cash_out_daily` | `cash_out_daily_fund / days_left` | Sec9 outlook | `export-report-numbers.bqn` when non-zero | Daily amount after fixed cashflow obligations. |
| `env_names` | filtered budget account names | Sec5 envelopes | none | Envelopes targeted for envelope report/health status. |
| `env_groups` | account metadata `budget_group` for each envelope | Sec5 envelopes | none | Parallel to `env_names`; values include `daily`, `flex`, `reserve`. |
| `env_history_bal` | cumulative daily balance for envelopes | none | none | History for graph/analysis. |
| `env_history_daily` | daily fund (balance - future plan) | none | none | History for graph/analysis. |
| `env_current_bal` | current envelope balance at `as_of` | Sec5 envelopes | none | Current envelope balance. |
| `env_cycle_allocated` | current-cycle allocation by envelope | Sec5 envelopes | none | Derived from budget layer allocation sum. |
| `env_cycle_spent` | current-cycle spent by envelope | Sec5 envelopes | none | Pure mapped consumption; budget moves are not counted as spend. |
| `env_avg_spend` | cycle-to-date average daily spend | Sec5 envelopes | none | `env_cycle_spent / elapsed_days`; not a 3-day rolling value. |
| `env_target_daily` | target daily spend | none | `export-envelope-summary.bqn` | `env_cycle_allocated / cycle_total_days` |
| `env_days_until_empty` | `(current_bal + future plan updates) / avg_spend` | Sec5 diagnostics | none | Supplemental exhaustion estimate. |
| `env_status` | Pace Status | Sec5 envelopes | none | `SAFE` / `WARN` / `SHORT` / `DONE`. |
| `warn_future_journal_rows` | hygiene warning | Sec8 check | none | `journal.tsv` rows after `as_of`; journal is actual-only, so these are likely input mistakes. |
| `warn_spent_no_alloc` | hygiene warning | Sec8 check | none | Spent but no allocation in current cycle. |
| `warn_duplicate_plans` | hygiene warning | Sec8 check | none | Plans matching existing journal entries. |
| `warn_stale_plans` | hygiene warning | Sec8 check | none | Plans dated before current cycle start. |
| `warn_redundant_allocs` | hygiene warning | Sec8 check | none | Redundant budget allocations. |
| `warn_no_cycle_end` | hygiene warning | Sec8 check | none | Cycle mode is incomeAnchor but no cycle end found. |
| `check_accounts_missing_role` | accounts metadata readiness check | Sec8 check | none | accounts without explicit `role=...` metadata. |
| `check_assets_missing_type` | accounts metadata readiness check | Sec8 check | none | `assets:*` without `type=liquid|savings|invest`. |
| `check_expenses_missing_spend_class` | accounts metadata readiness check | Sec8 check | none | `expenses:*` without explicit `spend_class=...`. |
| `check_variable_missing_budget` | accounts metadata readiness check | Sec8 check | none | `spend_class=variable` expenses without `budget=...`. |
| `section_status_keys` | keys list for section statuses | none | none | Status-enabled section keys, initially `⟨"check", "actual-comparison"⟩`. |
| `section_status_values` | status value for each section | none | none | Status value mapping to keys. Values are `OK`, `WARN`, `ERROR`, `UNAVAILABLE`. |
| `section_status_messages` | descriptive status message | none | none | Detail messages explaining the status choice (e.g. hygiene warning details). |


## 更新ルール

- `report_engine.Build` の return record を増減したら、この表を更新する。
- `tools/summary.bqn` の metric key は下流互換があるため、改名より追加を優先する。
- 人間向け表示だけの変更なら `docs/MAIN_SECTIONS.md` も確認する。
