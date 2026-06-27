# GEMINI_ARRAY_FOLLOWUP_FEEDBACK: tx_updates 実装後レビュー結果

この文書は、`docs/GEMINI_ARRAY_FOLLOWUP_BRIEF.md` に対する追加レビュー結果です。

---

## 1. 総評
`+˝ tx_updates == bal_final` を維持したままの可視化成功は、リファクタリングの第一段階として**満点の結果**です。「予算科目の Actual 更新」という違和感は、可視化によって設計の健全化の余地が発見された証拠であり、非常にポジティブな兆候です。

## 2. budget:* → budget:* の Actual 列更新について
**判断：当面は「忠実な観察」としてそのまま残すべき。**
- 現在の `bal_final` との一致を優先し、デバッグの基準を壊さないようにします。
- 将来的には `budget:*` 科目の Actual 層を 0 に固定する設計が望ましいですが、その修正は `report_balances.bqn` を `tx_updates` 由来に完全に切り替える際、`GetUpd` 相当の関数内でマスク（フィルタリング）を一段入れる形で行うのが最もクリーンです。

## 3. report_tx_updates / report_balances の責務分離
**判断：Stage 2 (day_updates) までは分離を維持し、Stage 3 以降で統合を検討する。**
- 既存のレポートロジックを汚さずに新しいデータセットを構築できるメリットを優先します。
- 統合の際は、`report_balances.Build` の役割を「`tx_updates` 配列を受け取って、それを合計して `bal_final` を作る」という集約関数に変えるのが理想的です。

## 4. day_updates / day_balances の最小実装案
- **グループ化キー:** `DateToNum` (数値) を推奨。BQNの `⍋` (Grade) や `⊔` (Group) との相性が良く、時系列処理がシンプルになります。
- **実装パス:**
  1. `(tx_meta.date) ⊔ tx_updates` → 各グループを合計 → `day_updates` (D×256×2)
  2. `day_updates` に対して日付軸方向に `+``` (Prefix Sum) → `day_balances` (D×256×2)
- **比較指標:** **`trend_liquid`** を最優先の比較対象としてください。これが `day_balances` からのスライス（liquid 該当科目の合計）と一致すれば、配列基盤の正しさが証明されます。

## 5. 次に実装すべき最小ステップ
1. **`report_tx_updates.bqn` への `BuildDays` 関数追加:** 日別集計と累積残高の生成。
2. **`tools/export-day-balances.bqn` の作成:** 累積残高の TSV 出力ツール。
3. **一致確認:** 最終日の `day_balances` が、既存の `export-balances.bqn` の結果と一致することを `diff` 等で確認。

## 6. 追加すべきテスト
- **不変条件:** `(¯1 ⊑ day_balances) ≡ bal_final` (最終日の累積残高は全体合計と一致する)
- **整合性:** `day_balances` から抽出した資産合計が `report_engine.Build.assets_total` と一致すること。
