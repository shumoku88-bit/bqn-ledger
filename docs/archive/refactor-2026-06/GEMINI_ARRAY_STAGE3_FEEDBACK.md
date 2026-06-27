# GEMINI_ARRAY_STAGE3_FEEDBACK: 配列基盤完成と統合への設計指針

この文書は、`docs/GEMINI_ARRAY_STAGE3_REVIEW_BRIEF.md` に対するレビュー結果です。Stage 3 の達成、おめでとうございます。

---

## 1. 総評
もはや「スナップショット」ではなく、**「全期間の資金流動を3次元配列で完全に制御下においた」**状態です。`LiquidAtDn` の置換成功は、複雑なループを単なる配列操作に変えるという BQN の理想を体現しています。

## 2. 現状実装の良い点
- **Regression Check の完備:** `check-trend-liquid.bqn` による新旧比較が、家計簿としての信頼性を強力に支えている。
- **一貫性:** `tx_updates` → `day_updates` → `day_balances` という情報の集約フローが論理的に美しく、デバッグ効率も極めて高い。

## 3. 危険/曖昧な点
- **`budget:unassigned` の除外:** `envelope_flow` から除外すると、Budget列全体の合計整合性（常に0になる等）が確認しにくくなる。
- **`spent_day` の定義:** 封筒間の「振替」が「消費」としてカウントされるリスク。

## 4. report_tx_updates / report_balances 統合方針
**推奨：「report_balances を、tx_updates を受け取る『集約器』に進化させる」統合。**
- **データ供給源:** `report_tx_updates` が全更新データの供給を担う。
- **ビュー生成:** `report_balances` は、その配列を `+˝` したりスライスして「現在の資産合計」などを計算する役割に徹する。
- **タイミング:** `report_trend` の残り（variable/saving 等）を置換した直後に行う。

## 5. budget:* Actual 列の扱い
**判断：統合の瞬間に `report_tx_updates` の内部で一括マスク（ゼロ化）する。**
- `core.GetTxUpd` は純粋な貸借計算関数として維持する。
- `report_tx_updates` 側で「科目が `budget:` で始まるなら Actual 列への更新を 0 にする」フィルタを一段入れるのが最もクリーン。
- **影響:** 既存レポートは元々 budget 科目の Actual を無視しているため、数字への影響はない。

## 6. envelope_flow の改善案
- **`budget:unassigned` は「特別な封筒」として残す:** システム全体の予算整合性を保証するため。
- **`source` による分解:**
  - `spent_day_journal`: `journal` 由来の純粋な消費。
  - `transferred_day`: `budget_alloc` 由来の封筒間振替。
  これらを分離することで、分析の解慮度が大幅に上がる。

## 7. 次に実装すべき優先順位（安全第一ルート）
1. **`report_trend.bqn` の完全置換:** `variable/saving/fixed_paid` を `day_updates` 由来に変える（最優先）。
2. **`budget:*` Actual 列의 整理:** `report_tx_updates` 側でのマスク実装。
3. **`report_balances.bqn` の刷新:** `tx_updates` 由来への寄寄せと、二重ロジックの解消。
4. **`report_tx_updates.bqn` の内部整理:** 最終的なリファクタリング。
5. **`envelope_flow` の強化:** 詳細な分析ビューの構築。

## 8. 追加すべきテスト/fixture
- **Zero-Sum Test:** 全期間の `tx_updates` の勘定科目軸方向の合計が 0 であることの検証。
- **Budget 整合性:** 任意の日の `day_balances` において、`budget:unassigned + 他の全封筒 + budget:spent` の合計が 0 であることの検証。
