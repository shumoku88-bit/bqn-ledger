# Gemini向け追加相談: Stage 3 配列ビュー実装レビュー

> NOTE: この文書はレビュー依頼時点の履歴メモです。現在は `report_trend.bqn` の `variable` / `saving` / `fixed_paid` も `day_updates` 由来へ置換済みで、`export-envelope-flow` は `budget:unassigned` を特別封筒として含み、`spent_day_journal` / `transferred_day` も分離済みです。最新状態は `docs/ARRAY_AUDIT.md` を参照してください。

`tx_updates` / `day_updates` / `day_balances` / `envelope_flow` まで実装が進みました。次に進む前に、設計レビューと優先順位の確認をお願いします。

## 読んでほしいファイル

必須:

1. `docs/ARRAY_AUDIT.md`
2. `report_tx_updates.bqn`
3. `report_balances.bqn`
4. `report_engine.bqn`
5. `report_trend.bqn`
6. `tools/export-tx-updates.bqn`
7. `tools/export-day-balances.bqn`
8. `tools/export-envelope-flow.bqn`
9. `tools/check-tx-updates.bqn`
10. `tools/check-trend-liquid.bqn`

参考:

- `docs/GEMINI_ARRAY_REVIEW_FEEDBACK.md`
- `docs/GEMINI_ARRAY_FOLLOWUP_FEEDBACK.md`
- `docs/ARCHITECTURE.md`
- `docs/AI_CODEMAP.md`
- `tools/check.sh`

## 現在できていること

### 1. tx_updates

```text
tx_updates : T×256×2
tx_meta    : T×N
```

`report_tx_updates.bqn` が生成します。

- `source`
- `row`
- `date`
- `memo`
- `from`
- `to`

を `tx_meta` に保持し、`tools/export-tx-updates.bqn` が非ゼロ更新だけ sparse TSV にします。

### 2. day_updates / day_balances

`report_tx_updates.BuildDays` が生成します。

```text
day_updates  : D×256×2
day_balances : D×256×2
```

- 日付は `DateToNum` で group
- `day_balances` は日付方向 prefix sum
- `tools/export-day-balances.bqn` で TSV 出力

### 3. checks

`tools/check-tx-updates.bqn` で以下を確認します。

```text
+˝ tx_updates == report_engine.Build.bal_final
final day_balances == report_engine.Build.bal_final
assets_total一致
liquid total一致
```

`tools/check-trend-liquid.bqn` で、既存 `trend_liquid` と `day_balances` 由来 liquid 合計を比較します。

### 4. report_trend の一部置換

`report_trend.bqn` の `LiquidAtDn` は、行ベース集計から `day_balances` 由来へ置き換え済みです。

まだ行ベースのまま:

- fixed reserve
- variable spending
- saving transfer
- fixed paid

### 5. envelope_flow

`tools/export-envelope-flow.bqn` を追加しました。

出力列:

```tsv
date	envelope	allocated_day	spent_day	balance	daily_change
```

現状の定義:

- 対象: `budget:*` のうち `budget:opening` / `budget:unassigned` / `budget:spent` を除く
- `balance`: `day_balances` の Budget/Intent列
- `daily_change`: `day_updates` の Budget/Intent列
- `allocated_day`: 正の `daily_change`
- `spent_day`: 負の `daily_change` を正値にしたもの

注意: 現在の `spent_day` は「封筒から出ていった日次額」であり、純粋な支出だけとは限りません。将来、封筒間移動が増えた場合は transfer out も含む可能性があります。

## 既知の注意点

### budget:* → budget:* の Actual列更新

現在の `core.GetTxUpd` は、すべての from/to 転送について Actual列を更新し、その後 Budget/Intent列も作ります。

そのため、`budget_alloc.tsv` のような `budget:* → budget:*` 行は、`export-tx-updates` では `actual` 層にも `budget` 層にも現れます。

これは既存 `bal_final` に含まれていた挙動の可視化です。

現方針:

- 当面は「忠実な観察」として残す
- `+˝ tx_updates == bal_final` を優先
- Stage 3以降の統合時に、必要なら `budget:*` Actual列のマスク/整理を検討

## Geminiに確認してほしいこと

### A. 現状レビュー

1. `tx_updates` / `day_updates` / `day_balances` / `envelope_flow` の設計は一貫しているか。
2. `report_trend.bqn` の `LiquidAtDn` だけを先に置換した判断は妥当か。
3. `tools/check-trend-liquid.bqn` は regression check として残す価値があるか。

### B. report_tx_updates と report_balances の統合

1. いつ統合すべきか。
2. 統合するならどちらを中心にすべきか。
   - `report_tx_updates` が更新行列を生成し、`report_balances` が集約・残高派生値を作る？
   - それとも `report_balances` 内に tx/day view を取り込む？
3. 現時点では分離維持が安全か。

### C. budget:* Actual列の扱い

1. 当面はこのまま忠実な観察でよいか。
2. 将来ゼロ化/マスクするなら、どの段階で行うべきか。
3. `core.GetTxUpd` を変更するべきか、budget move専用 update を作るべきか。
4. 既存レポートに与える影響の見積もり。

### D. envelope_flow の定義

1. 現在の `spent_day = negative daily_change` は観察用として妥当か。
2. `journal` 由来消費だけに絞った `spent_day_journal` のような列を追加すべきか。
3. `allocated_day` / `spent_day` / `balance` / `daily_change` 以外に必要な列はあるか。
4. `budget:unassigned` を除外してよいか、別ビューで残すべきか。

### E. 次に進む優先順位

候補:

1. `report_tx_updates.bqn` の内部整理・共通化
2. `report_balances.bqn` を `tx_updates` 由来に寄せる
3. `report_trend.bqn` の variable/saving/fixed_paid を `day_updates` 由来に置換
4. `envelope_flow` を強化する
5. `budget:*` Actual列の仕様整理

どの順番が安全か提案してください。

## 期待する回答形式

```text
1. 総評
2. 現状実装の良い点
3. 危険/曖昧な点
4. report_tx_updates / report_balances 統合方針
5. budget:* Actual列の扱い
6. envelope_flow の改善案
7. 次に実装すべき最小ステップ
8. 追加すべきテスト/fixture
```

実装コードよりも、設計判断・優先順位・落とし穴の指摘を優先してください。
