# Old Engine Removal Plan

Status: **completed**
Date: 2026-06-26

## 背景

`bqn-ledger` の旧エンジン (`src/core/`, `src/reports/`, `src/views/`) の本体は別ディレクトリの `bqn-kakeibo` で動いている。
新エンジン `src_next/` が本番 default（`tools/report`）として稼働済みであり、`bqn-ledger` を旧エンジン無しの独立プロジェクトに移行する。

## 原則

- source TSV を触らない
- `src_next/` のコード・出力を変えない
- `bqn-kakeibo` 側の旧エンジン本番動作に影響しない
- コミットは小さく1フェーズずつ

## Phase 計画

### Phase 1: 計画文書の整理（コード変更なし）✅

- [x] `docs/CANONICAL_ENGINE_HARDENING_TODO.md` → `docs/archive/completed-plans/` へ移動
- [x] `docs/CANONICAL_ENGINE_HARDENING_TODO.status.md` → `docs/archive/completed-plans/` へ移動
- [x] `TODO.md` から旧エンジン向けセクションを削除・圧縮
- [x] `docs/README.md` の導線を更新
- [x] `AGENTS.md` の参照を更新

### Phase 2: 旧エンジンコード削除 ✅

- [x] `src/core/` 削除
- [x] `src/reports/` 削除
- [x] `src/views/` 削除
- [x] `main.bqn` 削除

### Phase 3: ツール・チェック再編 ✅

- [x] `tools/check.sh` → src_next check のみに再構築
- [x] `checks/` → 旧エンジン向け削除、src_next向け・汎用は残す
- [x] `tools/export-*.bqn` → 旧エンジンラッパー全削除
- [x] `tools/add.bqn`, `tools/txn.bqn`, `tools/gen-budget.bqn` → 削除（src/core/ 依存）
- [x] `tools/sqz-report`, `tools/update-golden.sh` → 削除
- [x] `src/input/` → 全削除（src/core/ 依存）
- [x] `src_next/util.bqn`, `src_next/date.bqn`, `src_next/config.bqn` 作成（旧依存解決）
- [x] `tests/test_lib.bqn` 移設、旧エンジンテスト削除

### Phase 4: Go editor / docs / 残存参照の更新 ✅

- [x] `editor/` の旧エンジン参照を切る
- [x] `docs/` 主要文書の `src/` 参照を `src_next/` に更新
- [x] 歴史的文書にステータス注記を追加
- [x] `AGENTS.md` / `README.md` の記述を更新

## 完了条件

- `src/core/`, `src/reports/`, `src/views/`, `main.bqn` が存在しない ✅
- `tools/check.sh` が src_next の check だけを通す
- `docs/README.md` から旧エンジンへの導線がない ✅
- コミット履歴が細かく追える ✅
