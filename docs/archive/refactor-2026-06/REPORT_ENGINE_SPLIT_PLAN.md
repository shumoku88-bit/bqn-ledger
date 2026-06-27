# report_engine.bqn split plan

目的: `report_engine.bqn` を、正データTSV・計算仕様・公開返却フィールドを変えずに、派生値のまとまりごとに小さく分ける。

この計画は「行数を減らすため」ではなく、次に触る場所と壊れやすい境界を見えやすくするためのもの。

## 原則

- データ構造を変えない。
  - `bal_final` は引き続き 256×2 matrix。
  - `core.GetTxUpd` の col0=Actual / col1=Budget(Intent) を維持。
  - 256スロット固定設計はこの分割では触らない。
- `report_engine.Build` / `BuildAt` の public record contract を維持する。
  - `r.xxx` の既存フィールド名は削除・改名しない。
  - 追加が必要な場合は docs/REPORT_FIELD_MAP.md を更新する。
- 1コミットにつき原則1モジュールだけ切り出す。
- 各Phaseの最後に `rtk ./tools/check.sh` を実行する。
- 表示単位ではなく、派生値のまとまり単位で分ける。
- `report_engine.bqn` は最終的に入口・読み込み・合成役へ寄せる。

## Baseline checks

分割作業の前後で最低限確認するもの:

```sh
rtk ./tools/check.sh
bqn main.bqn --list-sections
bqn main.bqn --section snapshot
bqn main.bqn --section cycle
bqn main.bqn --section outlook
bqn main.bqn --section daily-trend
bqn main.bqn --section check
bqn tools/summary.bqn >/dev/null
bqn tools/export-balances.bqn >/dev/null
bqn tools/export-planned.bqn >/dev/null
```

通常は `rtk ./tools/check.sh` を必須、個別sectionは該当Phaseで必要に応じて実行する。

## Target module map

```text
report_engine.bqn
  Build / BuildAt の入口
  TSV読み込み、strict check、各 report_* module 呼び出し、record 合成

report_meta.bqn
  accounts.tsv の meta 読み取り
  MetaGetVal / GetMeta
  type / fixed / spend_class / budget 判定 helper

report_readiness.bqn
  check_assets_missing_type
  check_expenses_missing_spend_class
  check_variable_missing_budget

report_balances.bqn
  journal/budget_alloc/plan budget move から bal_final 作成
  actual/budget balances
  assets/liquid/savings/invest totals
  balances section 用 index/adjusted values

report_cycle_metrics.bqn
  cycle.bqn による window 解決結果を使った集計
  cycle income / expense / net
  cycle expense breakdown

report_outlook.bqn
  future payments
  last journal date / journal lag
  days left / daily divisor
  liquid daily / budget daily

report_trend.bqn
  daily-trend
  daily amount trend
  variable/saving/fixed paid per day
  drop top10 index
```

注意: 既存の `cycle.bqn` は「期間解決」。新しい `report_cycle_metrics.bqn` は「期間内集計」。名前を混同しない。

## Phase checklist

### Phase 0: Baseline / field contract確認

- [x] `docs/REPORT_FIELD_MAP.md` と `report_engine.bqn` の返却フィールドを照合する。
- [x] `rtk ./tools/check.sh` を実行する。
- [x] 差分なしの基準を確認する。

完了条件:
- 現状の public record contract が確認済み。
- 分割前チェックが通る。

### Phase 1: `report_meta.bqn`

切り出すもの:
- accounts meta parse
- `MetaGetVal`
- `GetMeta`
- account name predicates / meta-derived helpers の土台

残すもの:
- `report_engine.bqn` の返却フィールド
- 計算結果

確認:
- [x] `rtk ./tools/check.sh`
- [x] `bqn main.bqn --section check`
- [x] `bqn main.bqn --section daily-trend`

完了条件:
- [x] meta helper が `report_meta.bqn` に移る。
- [x] 既存出力が変わらない。

### Phase 2: `report_readiness.bqn`

切り出すもの:
- `check_assets_missing_type`
- `check_expenses_missing_spend_class`
- `check_variable_missing_budget`

確認:
- [x] `rtk ./tools/check.sh`
- [x] `bqn main.bqn --section check`

完了条件:
- [x] readiness/check 用の派生値が独立する。
- [x] check section の出力が変わらない。

### Phase 3: `report_balances.bqn`

切り出すもの:
- `budget_start_dn`
- journal update / budget move update / `bal_final`
- `actual_now`, `budget_balances`
- `assets_total`, `liq_total`, `sav_total`, `inv_total`
- `idx_actual`, `adj_actual`, `idx_budget`

確認:
- [x] `rtk ./tools/check.sh`
- [x] `bqn main.bqn --section snapshot`
- [x] `bqn main.bqn --section balances`
- [x] `bqn tools/export-balances.bqn >/dev/null`

完了条件:
- [x] 256×2 balance 生成と balance表示用派生値が独立する。
- [x] export balances が変わらない。

### Phase 4: `report_cycle_metrics.bqn`

切り出すもの:
- cycle window 呼び出し結果の保持
- `cycle_rows`
- `cycle_inc_total`, `cycle_exp_total`, `cycle_net`
- cycle expense breakdown sorted values

確認:
- [x] `rtk ./tools/check.sh`
- [x] `bqn main.bqn --section cycle`

完了条件:
- [x] `cycle.bqn` は期間解決、`report_cycle_metrics.bqn` は期間内集計、という境界になる。

### Phase 5: `report_outlook.bqn`

切り出すもの:
- `last_journal_date`
- future payments
- `journal_lag_days`
- `days_left`, `daily_divisor`
- `idx_liquid`, `liq_daily`, `budget_daily`

確認:
- [x] `rtk ./tools/check.sh`
- [x] `bqn main.bqn --section outlook`
- [x] `bqn tools/export-planned.bqn >/dev/null`

完了条件:
- [x] outlook/export-planned に必要な派生値が独立する。

### Phase 6: `report_trend.bqn`

切り出すもの:
- `trend_dates`
- `trend_liquid`
- `trend_fixed_reserve`
- `trend_daily_fund`
- `trend_days_left`
- `trend_daily`
- `trend_delta`
- `trend_variable`
- `trend_saving`
- `trend_fixed_paid`
- `trend_drop_idx`

確認:
- [x] `rtk ./tools/check.sh`
- [x] `bqn main.bqn --section daily-trend`

完了条件:
- [x] daily-trend の派生値が独立する。
- [x] `report_engine.bqn` は BuildAt の合成役として読める状態になる。

## Stop conditions

以下が起きたら、そのPhaseで止めて設計を見直す。

- `r.xxx` の既存フィールド名変更が必要になった。
- 256×2 matrix の形を変えたくなった。
- `core.bqn` 変更が必要になった。
- `main.bqn` / `report_sections.bqn` 側の表示仕様変更が必要になった。
- `rtk ./tools/check.sh` の失敗原因が分割以外の仕様差分になった。

## Progress log

- [x] Plan documented.
- [x] Phase 0 complete.
- [x] Phase 1 complete.
- [x] Phase 2 complete.
- [x] Phase 3 complete.
- [x] Phase 4 complete.
- [x] Phase 5 complete.
- [x] Phase 6 complete.
