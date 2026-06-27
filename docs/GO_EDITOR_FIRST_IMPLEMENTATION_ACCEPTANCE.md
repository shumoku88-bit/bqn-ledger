# Go Editor: First Implementation Acceptance Criteria

Status: initial read-only implementation satisfies this criteria as of 2026-06-19.

この文書は、Go で実装される予定編集機能（Go editor）の、最初期フェーズにおける最小の受け入れ条件（Acceptance Criteria）を定義します。

安全のため、この条件を超える破壊的な操作や複雑な状態遷移の実装は、本番環境への導入時には行いません。

---

## 1. 最初のターゲット機能

### A. 予定一覧の表示 (`plan list`)
- `plan.tsv` の行を一覧表示する。
- 履行済み・未履行を判定し、`plan_open`（未履行）のもののみを対象とする（または明確に区別して表示する）。

### B. 予定履行プレビュー (`plan finish preview`)
- 指定した予定（`plan_id` などで指定）を実績化した場合の、追加予定の `journal.tsv` 行を標準出力へプレビュー表示する。
- ユーザーに「予定日」と「実際の日付（実績日）」を指定させることができる。
- 提案する実績行の末尾に、元の `plan_id` をそのまま引き継ぐ。
- `journal.tsv` や `plan.tsv` に対するファイルの書き込み（破壊的操作）は**一切行わない（Read-only プレビューに徹する）**。

---

## 2. 実装してはならないもの（対象外・禁止事項）

- **ファイルの書き込み・削除 (`plan finish apply` の実装禁止)**
  - 2つのファイル（`plan.tsv` と `journal.tsv`）の書き換えトランザクションや、中断時のリカバリ設計が確定するまで、ファイル変更を伴う `apply` モードは実装しません。
- **plan.tsv からの行削除**
  - 履行された予定であっても、履歴観察（Residual）のために `plan.tsv` には予定を残し続けます。`plan.tsv` から予定を削除してはなりません。
- **メタデータへの自動 done 付与 (`status=done` など)**
  - 状態遷移の自動付与（`status=done` や `actual_date=...` などを予定行に追記して `plan.tsv` を破壊的に編集すること）は行いません。
  - 履行確認は、一貫して `journal.tsv` 側に同じ `plan_id` が存在するかどうかのクエリ（第一規則）に基づいて行います。

---

## 3. plan finish preview の判定条件

- **クエリの対象**:
  - `plan_open`（まだ `journal.tsv` に同じ `plan_id` が存在しない予定行）のみを履行候補として提示する。
  - すでに `journal.tsv` に同一 `plan_id` の行が存在する予定は、二重記帳を防ぐため、候補に出さない。
- **メタデータ引き継ぎ**:
  - 提案する実績行では、予定行のメタデータのうち、予定特有のキー（`recur`, `months`, `anchor`, `offset`）を除外する。
  - `series`, `plan_id` およびその他の付帯情報（`tax`, `receipt`, `party`, `note`）はそのまま引き継ぐ。
