# Canonical Journal Surface 001 Plan

- **Date**: 2026-07-24
- **Branch**: `feat/journal-canonical-surface-001`
- **Status**: Completed

## 概要

`bqn-ledger` の native Journal 物理表記からポスティング行の 1 空白間隔や冗長メタデータ (`layer: actual`, `currency: JPY`) を安全に標準化・除去する純粋 BQN 変換エンジン・CLI バックエンド・安全 Apply 機構を実装した。

## 達成成果

1. **BQN 変換・検証モジュール**:
   - `src_edit/journal_canonical_surface_plan.bqn`: 全件分類・表面統計ロジック
   - `src_edit/journal_canonical_surface_rewrite.bqn`: 全文 Candidate 生成および Stage 1 / Stage 2A セマンティック等価性検証エンジン
2. **CLI バックエンド & ディスパッチ**:
   - `src_edit/journal_canonical_surface_plan_cmd.bqn`
   - `src_edit/journal_canonical_surface_preview_cmd.bqn`
   - `src_edit/journal_canonical_surface_apply_cmd.bqn`
   - `tools/edit` (`tools/edit-bqn`) ディスパッチ拡張
3. **安全書き換え・自動ロールバック統合**:
   - `tools/lib/edit-bqn-common.sh`: `edit_bqn_apply_canonical_surface_rewrite_checked` の追加
4. **統合テスト・単体テスト**:
   - `tests/test_journal_canonical_surface_plan.bqn`
   - `tests/test_journal_canonical_surface_rewrite.bqn`
   - `checks/check-edit-bqn-journal-canonical-surface.sh` (8 シナリオ E2E テスト)
   - `tools/check.sh` 組み込み及び `tools/repo-index --baseline` 更新
5. **実運用プライベート Journal リードオンリー検証**:
   - 実データ (410 トランザクション / 822 ポスティング) に対する完全リードオンリー検証を実施。
   - 変換候補適用後の全 410 トランザクションが 100% Canonical化され、`hledger check` を通過することを確認。原本 SHA-256 の未改変を検証済み。
