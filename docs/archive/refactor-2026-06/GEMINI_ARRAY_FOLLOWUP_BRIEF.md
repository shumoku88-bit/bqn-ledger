# Gemini向け追加相談: tx_updates実装後レビュー

`tx_updates : T×256×2` の最小実装が入りました。次に、設計上の違和感や次段階へ進む前の確認をお願いします。

## 読んでほしいファイル

1. `docs/ARRAY_AUDIT.md`
2. `docs/GEMINI_ARRAY_REVIEW_FEEDBACK.md`
3. `report_tx_updates.bqn`
4. `tools/export-tx-updates.bqn`
5. `tools/check-tx-updates.bqn`
6. `report_balances.bqn`
7. `core.bqn`

## 実装済みの内容

- `report_tx_updates.bqn`
  - `tx_updates : T×256×2`
  - `tx_meta`
  - tx由来 `bal_final`
- `tools/export-tx-updates.bqn`
  - 非ゼロ更新だけ sparse TSV 出力
  - 列: `source row date memo from to account layer amount`
- `tools/check-tx-updates.bqn`
  - `+˝ tx_updates` が `report_engine.Build.bal_final` と一致するか確認
- `tools/check.sh`
  - tx_updates export/check を追加

## 追加で確認してほしい論点

### 1. budget:* → budget:* の Actual列更新

現在の `core.GetTxUpd` は、すべての from/to 転送について Actual列を更新し、その後 Budget/Intent列も作ります。

そのため、`budget_alloc.tsv` のような `budget:* → budget:*` 行は、`export-tx-updates` では次のように見えます。

```text
budget_alloc ... budget:unassigned actual -30000
budget_alloc ... budget:rent       actual  30000
budget_alloc ... budget:unassigned budget -30000
budget_alloc ... budget:rent       budget  30000
```

これは既存の `bal_final` に含まれていた挙動を可視化したものです。

確認してほしいこと:

1. `+˝ tx_updates == bal_final` を優先して、このまま「忠実な観察」として残すべきか。
2. 将来的に `budget:*` 科目の Actual列はゼロにする設計へ変えるべきか。
3. 変える場合、`core.GetTxUpd` を変えるのか、`budget_alloc` 専用の update 関数を作るのか。
4. 既存レポートや export への影響がどこに出そうか。

### 2. report_tx_updates.bqn の責務

今は `report_balances.bqn` とは別に、横で tx_updates を作っています。

確認してほしいこと:

1. 当面はこの分離でよいか。
2. いつ `report_balances.bqn` を `tx_updates` 由来へ寄せるべきか。
3. 共通化するなら、どの関数境界がよいか。

### 3. 次の day_updates 設計

次は `tx_meta` の日付で group して、次を作る予定です。

```text
day_updates : D×256×2
day_balances : D×256×2
```

確認してほしいこと:

1. 日付は文字列 `YYYY-MM-DD` でgroupすべきか、`DateToNum` の数値でgroupすべきか。
2. 出力TSVに必要な列は何か。
3. `day_balances` は全日付だけでよいか、取引のない日も埋めるべきか。
4. `report_trend` 置換前に比較すべき指標は何か。

## 期待する回答形式

```text
1. 総評
2. budget:* → budget:* の Actual列更新についての判断
3. report_tx_updates / report_balances の責務分離について
4. day_updates / day_balances の最小実装案
5. 次にpitが実装すべき最小ステップ
6. 追加すべきテスト
```
