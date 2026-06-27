# GEMINI_ARRAY_REVIEW_FEEDBACK: 配列ビュー強化の設計レビュー結果

この文書は、Gemini CLI による `docs/GEMINI_ARRAY_REVIEW_BRIEF.md` に対するレビュー結果を記録したものです。`coex(pit)` はこのフィードバックを基に実装を進めてください。

---

## 1. 総評
この設計変更は、BQN家計簿の「背骨（行列計算）」を太くし、柔軟性と透明性を劇的に向上させる**極めて優れた方針**です。現状の「スナップショット集計」から「取引の時系列配列」への転換は、BQNの真価（一括処理・Prefix Sum）を引き出すための正しいアーキテクチャの進化と言えます。

## 2. 良い点
- **次元の分離:** メタデータ（文字列・日付）を `tx_meta` に、数値計算を `tx_updates` に分けることで、BQNのベクトル演算速度を最大化しつつ、人間の読みやすさを確保できている。
- **不変条件の明快さ:** `bal_final = +˝ tx_updates` という関係を定義することで、既存の安定したレポート表示と新しい時系列ビューの整合性が数学的に保証される。
- **計算効率の飛躍:** `report_trend.bqn` が現在行っている $O(N \times D)$ の処理を、Prefix Sum（累計）による $O(N)$ の処理に置き換えられるため、将来的なパフォーマンス劣化を防げる。

## 3. 危険/曖昧な点
- **メモリ効率と密行列:** `T × 256 × 2` の配列は BQN なら軽快に扱えるが、疎行列（大半がゼロ）であるため、人間が観察する際は sparse TSV などのフィルタリングが必須。
- **`budget_start_dn` の適用:** 予算開始日前の Intent ゼロ化ロジックは、集計時ではなく `tx_updates` 生成時に適用し、`+˝` した結果が常に正しい `bal_final` になるようにすべき。

## 4. tx_updates / tx_meta の設計修正案
- **`tx_meta` への数値タグ追加:** `source` (journal=0, budget_alloc=1...) を文字列だけでなく数値インデックスとしても保持すると、BQN側で `(source=0) / tx_updates` のように高速にスライスできる。
- **行番号の保持:** `row` は 0-based index ではなく、**元ファイルの 1-based 行番号**を保持すべき。エラー時に `vim +12 journal.tsv` のように即座にジャンプできる利点が大きい。

## 5. day_updates / day_balances の作り方
BQNでの推奨実装パス：
1. **`day_updates`**: `(tx_metaの日付) ⊔ tx_updates` でグループ化し、各グループを `+˝` する。
2. **`day_balances`**: `day_updates` に対して日付軸（第0軸）方向に `+``` (Prefix Sum) を適用する。

## 6. sparse TSV列へのコメント
- 列構成 `source, row, date, memo, from, to, account, layer, amount` は十分。
- `layer` 列は、出力時に `"actual"` / `"budget"` という文字列に変換する処理を `tools/export-tx-updates.bqn` 側に持たせる。

## 7. report_trend 置換の優先順位
1. **最優先 (Liquid推移):** `LiquidAtDn` のループ処理を、`day_balances` からのスライスに置き換える。
2. **次点 (Variable/Saving):** 同様に日次の増減を `day_updates` から抽出する。
3. **保留 (Fixed Reserve):** 予算の「将来の予定」を含む集計は現在のロジックが安定しているため、実績ベースの移行が完了した後に着手する。

## 8. 追加すべきテスト/fixture
- **整合性チェック:** `(+˝ tx_updates) ≡ bal_final` を `tools/check.sh` の検査項目に追加する。
- **境界条件テスト:** `budget_start_dn` 当日の取引が正しく `Intent` 列に反映されるかを確認する専用の fixture。

## 9. 次に実装する最小ステップ
1. **`tools/export-tx-updates.bqn` の新設:** 既存コードを壊さず、中間配列を生成して sparse TSV で出す「観察ツール」をまず作る。
2. **`report_balances.bqn` のリファクタリング:** `all_upds` を合計して捨てるのではなく、`tx_updates` として外部に返すように変更する。
3. **`bal_final` の再定義:** `bal_final` を「`tx_updates` の合計値」として定義し直し、既存の全レポートの数字が変わらないことを確認する。
