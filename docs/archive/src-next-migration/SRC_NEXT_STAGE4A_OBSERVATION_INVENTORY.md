# src_next Stage 4a 観測面棚卸し (Stage 4a Observation Inventory)

Status: docs-only inventory / no implementation changes
Branch: `docs-src-next-stage4a-observation-inventory`

この文書は、`src_next` の Stage 4a において追加された観測面（observation surface）の現在地を整理するための棚卸し台帳です。

---

## 1. Current Stage (現在のステージ)

* **`src_next` は Stage 4a 観測面の整備フェーズ**にあります。
* **Stage 4b（日常試用/daily-use trial）は開始していません**。
* 本番の既定エンジン（production default）は現在も変わらず **`bqn main.bqn`** です。
* `src_next` はまだ本番の代替（production replacement）ではありません。

---

## 2. Observation Surfaces (観測面一覧)

PR #31 から PR #37 にかけて追加された観測面（observation surface）の状況は以下の通りです。

| Area | Added by | What it observes (何観測するか) | Current status (現在の状況) | Boundary (境界範囲・不変条件) |
| :--- | :--- | :--- | :--- | :--- |
| **Cycle Summary** | PR #31 | cycle income / expense / net / plan expense | compact summary available (サマリ出力可能) | not full production report (本番のフルレポートではない) |
| **Snapshot observation** | PR #32 | status / fallback / readiness counts | partial (一部) | not production-equivalent Snapshot (本番同等のスナップショットではない) |
| **Household metadata readiness** | PR #33 | `budget=`, `budget_group=`, `spend_class=` | diagnostics (診断) | labels are policy data (ラベル群はポリシー側データでありエンジン概念ではない) |
| **Plan journal overlap** | PR #34 | exact source-field overlap | diagnostics (診断) | no fuzzy matching (あいまい一致なし), no mutation (データ改変なし) |
| **Envelope contract** | PR #35 | allocated / actual_spent / remaining contract | docs-only (仕様策定のみ) | no production advice (本番向けの助言なし) |
| **Envelope fixture prototype** | PR #36 | remaining = allocated - actual_spent | fixture-only / opt-in (テストのみ) | no safe_remaining (安全残額計算なし), no daily_amount (日割り額計算なし) |
| **Production unavailable guard** | PR #37 | production data remains unavailable/src_next | guard check (防御チェック) | no polished remaining (本番向け整形残高なし) |

---

## 3. Production Boundaries (本番環境との境界)

本稼働のデータを保護し、既存エンジンの挙動を壊さないための境界を以下のように定義・維持しています。

* **本番の既定エンジンは `bqn main.bqn` のまま不変です。**
* `main.bqn` は Stage 4a の観測面に関するいかなる作業によっても変更されていません。
* **本番の TSV データ（`journal.tsv`, `plan.tsv` 等）は、`src_next` によって直接・間接を問わず編集されることはありません。**
* ソース TSV のフォーマット（列の定義等）は一切変更されていません。
* `食費`, `daily`, `flex`, `reserve` などの家計簿上のラベルは**ポリシーデータ（policy data）**であり、エンジンにハードコードすべき概念（engine concepts）ではありません。
* 本番データに対して、封筒プロトタイプから整形された家計アドバイス（polished household advice）を出力してはなりません。

---

## 4. Envelope Computation Status (封筒計算の現状)

プロトタイプにおける封筒計算の対応状況は以下の通りです。

* テスト環境限定（fixture-only）のプロトタイプが計算する対象：
  * `allocated` (配賦額)
  * `actual_spent` (実績支出額)
  * `remaining = allocated - actual_spent` (単純差額としての残高)
* 予定支払い（planned spending）は `remaining` から**差し引かれません**。
* `safe_remaining`（予定を引いた安全残高）の計算は、**後続作業（later work）**です。
* `daily_amount`（日割り許容額）および日当たり手元の計算は、**後続作業（later work）**です。
* 見通し（outlook）の計算は、**後続作業（later work）**です。
* 本番データに対する封筒計算ステータスは引き続き **`unavailable/src_next`** に維持されます。

---

## 5. Stage 4b Not Yet Started (Stage 4b 未開始の要件)

Stage 4b（日常試用）へ進む前に、以下の要件を満たす必要があります（現在はまだ満たされていません）。

* **本番同等のスナップショット判定基準（production-equivalent Snapshot criteria）の確立**
* **テスト環境（fixture-only）を超えた、実稼働向けの封筒計算準備**
* **明示的な家計ポリシー設定（explicit household policy configuration）の導入**
* **`safe_remaining` や `daily_amount` の仕様合意（追加する場合のみ）**
* **本番データに対する防御策（production-data guard checks）の繰り返し検証**
* **既存エンジンと `src_next` の出力に関する、手動による厳密な比較レビュー**

*(注: 現時点で Stage 4b は開始していません)*

---

## 6. Related Documents (関連文書)

* [SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md](SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md) — production-equivalent Snapshot criteria 定義
* [SRC_NEXT_STAGE4B_READINESS_GATE.md](SRC_NEXT_STAGE4B_READINESS_GATE.md) — Stage 4b readiness gate 定義
* [SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md](SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md) — 手動比較手順の正本（Gate B 充足の手順書）
* [SRC_NEXT_REPLACEMENT_READINESS.md](SRC_NEXT_REPLACEMENT_READINESS.md) — 置き換え準備チェックリスト
* [SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md](SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md) — 封筒計算仕様契約
* [SRC_NEXT_REPORT_SECTION_PARITY.md](SRC_NEXT_REPORT_SECTION_PARITY.md) — レポートセクション適合度マトリクス
* [SRC_NEXT_GOLDEN_CHECK.md](SRC_NEXT_GOLDEN_CHECK.md) — fixture 期待値検証
* [CURRENT_STATE_REFERENCE.md](../completed-plans/CURRENT_STATE_REFERENCE.md) — 現行エンジン比較基準
