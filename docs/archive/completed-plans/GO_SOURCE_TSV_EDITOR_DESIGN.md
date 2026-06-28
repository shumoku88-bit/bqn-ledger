# Go Source TSV Editor Design Draft (Historical Stub)

Status: **historical design draft / replaced by NEXT_PLAN**

この文書は、Go 製の source TSV editor (`tools/edit`) を導入する際の初期設計メモです。
安全な追記（single-file safe append）等の初期実装はすでに完了しており、現在の実装境界と次の計画は別文書で管理されています。
現在の制限事項や仕様としてこの文書の長文を読まないでください。
Original long form is preserved in Git history.

## 現在の参照先

- **現在の実装境界と次計画**: [GO_EDITOR_NEXT_PLAN.md](../active-plans/GO_EDITOR_NEXT_PLAN.md)
- **許可された書き込み範囲**: [GO_EDITOR_WRITE_SCOPE_INVENTORY.md](GO_EDITOR_WRITE_SCOPE_INVENTORY.md)
- **過去の決定事項の抜粋**: [GO_SOURCE_TSV_EDITOR_DESIGN_DECISIONS.md](GO_SOURCE_TSV_EDITOR_DESIGN_DECISIONS.md)

## 実装境界の概要 (Reconciliation Snapshot)

*   **実装済み機能**:
    *   読み取り専用の予定（plan）ツール。
    *   `journal add` および `budget add` による安全な追記（safe append）。
    *   `plan finish --apply` による `journal.tsv` への追記（`plan.tsv` は変更なし）。
    *   `tools/add-ui.sh` による日次の追記処理の Go editor 委譲。
*   **制限事項 (Planning-only / Disabled)**:
    *   追加のソース TSV 書き込みや、追記以外の直接編集。
    *   複数ファイルにまたがるトランザクション（単一ファイルのアトミック追記のみ許可）。
    *   削除機能。
*   **不変条件**:
    *   BQN が正本数値エンジンであり、Go は TSV 編集の安全なラッパー（触手）に徹する。
    *   Go が会計論理や生活ルールを持たない。
    *   書き込みはプレビュー確認、アトミック書き込み、バックアップ、差分検知、書き込み後 BQN lint を必須とする。
