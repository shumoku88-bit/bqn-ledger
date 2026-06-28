# MAIN_SECTIONS: `main.bqn` section IO map

> **Status: historical / superseded (2026-06-26)**
> **Note (2026-06-26):** Old engine has been deleted. References in this doc are historical. Current engine is src_next/.
> 現在のエンジン `src_next/` のセクション構成は `src_next/report.bqn` を参照してください。
> この文書は旧エンジンのセクション構成の履歴として残します。

この文書は、`main.bqn` の各セクションが何を読み、何を出し、どんな副作用を持つかの一行地図です。

関連:
- `r.xxx` の詳細な影響範囲: `docs/REPORT_FIELD_MAP.md`
- レポート設計方針: `docs/REPORT_DESIGN.md`

## 前提

- `main.bqn` は起動時に `rep.Build base` または `as_of rep.BuildAt base` を1回呼び、以降は返された `r.xxx` を整形して表示する。
- 各 `Sec*` は **stdout へ人間向け表示を出すだけ**。
- `Sec*` 自体はファイルを書き換えない。
- strict check は `report_engine.Build` 内で行われ、エラー時は表示前に停止する。

## Section map

| function | key | input fields / local helpers | output | filesystem side effects |
|---|---|---|---|---|
| `Sec1` | `snapshot` | `liq_total`, `sav_total`, `inv_total`, `assets_total`, `FmtVal` | 全体サマリを stdout に表示 | none |
| `Sec2` | `ytd` | `all_inc_total`, `all_exp_total`, `all_net`, `fixed_total_all`, `var_total_all`, `fix_*`, `var_*`, `FmtFix`, `FmtVar` | 年初来/全期間サマリ、固定費/変動費内訳を stdout に表示 | none |
| `Sec3` | `balances` | `idx_actual`, `adj_actual`, `names`, `FormatActual` | 勘定科目別の実績残高を stdout に表示 | none |
| `Sec4` | `cycle` | `cycle_mode`, `cycle_start`, `cycle_end`, `cycle_inc_total`, `cycle_exp_total`, `cycle_net`, `sorted_exp_*`, `FmtExp` | 今サイクル集計と支出内訳を stdout に表示 | none |
| `Sec5` | `envelopes` | `idx_budget`, `budget_balances`, `names`, `liq_total`, `trend_fixed_reserve`, `fixed_obligation_reserve`, `next_cycle_start_obligation_reserve`, `cash_out_daily_fund`, `env_*`, `days_left`, `FormatBudget` | 封筒/予算残高、seed可能額、封筒健康診断を stdout に表示 | none |
| `Sec6` | `planned` | `future_payments`, `plan_status_table`, `FormatPayment`, status formatting, width helpers | 未来の支払い等予定と、全plan行の未完了/支払い済み状態を stdout に表示 | none |
| `Sec7` | `recent` | `journal_rows`, `recent_rows`, `FormatRecent` | 直近10件の実績取引を stdout に表示 | none |
| `Sec8` | `check` | `base`, `journal_rows`, `plan_rows`, `names`, `cycle_mode`, `cycle_start`, `cycle_end`, `check_assets_missing_type`, `check_expenses_missing_spend_class`, `check_variable_missing_budget`, `warn_future_journal_rows`, hygiene warnings | strict check OK とレポート表示に必要なメタ整備状況・入力ミス候補を stdout に表示 | none |
| `Sec9` | `outlook` | `as_of`, `last_journal_date`, `journal_lag_days`, `days_left`, `assets_total`, `liq_total`, `sav_total`, `inv_total`, `idx_liquid`, `liq_daily`, `liq_safe_daily`, `fixed_obligation_reserve`, `next_cycle_start_obligation_reserve`, `cash_out_daily`, `idx_budget`, `budget_balances`, `budget_daily` | 見通し・日割り金額を stdout に表示 | none |
| `Sec10` | `daily-trend` | `trend_dates`, `trend_liquid`, `trend_fixed_reserve`, `trend_daily_fund`, `trend_days_left`, `trend_daily`, `trend_delta`, `trend_variable`, `trend_saving`, `trend_fixed_paid`, `trend_drop_idx` | 日割り推移と下落日Top10を stdout に表示 | none |
| `Sec11` | `actual-comparison` | `actual_comparison_*` | 今サイクル経過済みActualと前サイクル同経過日数Actualの比較を stdout に表示 | none |
| `Sec12` | `debug` | `as_of`, `cycle_*`, `journal_rows`, `plan_rows`, `budget_alloc_rows`, `names`, `bal_final`, `liq_total`, `meta` | デバッグ情報、不変条件の検査、数値の由来を stdout に表示 | none |

## 削除済み / 置き換え

- `residual` section は削除済み。Plan vs Actualの履行確認は `planned`、Actual同士の期間比較は `actual-comparison` で見る。
- `residual_table` と `export-residual-summary.bqn` は互換用の派生exportとして当面残す。

## Section aliases

`--section` は安定キーに加えて、普遍的・中庸な別名も受け付ける。
`--list-sections` は canonical key だけを表示する。

| alias | canonical key |
|---|---|
| `overview` | `snapshot` |
| `summary` | `snapshot` |
| `accounts` | `balances` |
| `account` | `balances` |
| `balance` | `balances` |
| `budget` | `envelopes` |
| `budgets` | `envelopes` |
| `plan` | `planned` |
| `plans` | `planned` |
| `schedule` | `planned` |
| `validation` | `check` |
| `trend` | `daily-trend` |
| `compare` | `actual-comparison` |
| `comparison` | `actual-comparison` |
| `actual-compare` | `actual-comparison` |
| `period-delta` | `actual-comparison` |
| `drift` | `actual-comparison` |
| `diff` | `actual-comparison` |
| `provenance` | `debug` |
| `source` | `debug` |

## Dispatch / helper map

| function / value | role | side effects |
|---|---|---|
| `sec_keys` | `--section <key>` と `--list-sections` の安定キー一覧 | none |
| `sec_alias_keys` / `sec_alias_idx` | `--section <alias>` を canonical section index に解決するための別名表 | none |
| `sec_labels` | ToC / list 表示用ラベル | none |
| `Header` | レポート共通ヘッダを stdout に表示 | stdout only |
| `RenderAll` | `Header` + 全 `Sec*` を順に実行 | stdout only |
| `RenderByIdx` | `Header` + 指定 `Sec*` だけ実行 | stdout only |
| `FindSectionIdx` | `all` / 数字 / key を section index に解決 | none |
| `ListSections` | `key<TAB>label` を stdout に出す。fzf等のラッパー向け | stdout only |
| `TocInteractive` | `•GetLine` で選択を受け、指定 section を表示 | stdin/stdout only |
| `Dispatch` | CLI option に応じて `ListSections` / `TocInteractive` / render を選ぶ | stdout only |

## 更新ルール

- `sec_keys` / `sec_alias_keys` / `sec_alias_idx` / `sec_labels` / `Sec*` を増減したら、この文書を更新する。
- 新しい section の raw computation は、できるだけ `report_engine.bqn` に置く。
- `main.bqn` は表示・整形を中心に保つ。
