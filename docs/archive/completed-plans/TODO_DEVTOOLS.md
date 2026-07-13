# TODO — devtools improvement (2026-06-27)

Status: completed
Owner: docs
Canonical: no
Exit: archived; devtools improvements are fully implemented and integrated.

## Phase A: devtools-check.sh（メタチェック） ✅

- [x] A-1: `tools/devtools-check.sh` 作成
  - [x] repo-index freshness（index出力 vs 実ファイル突合）→ 27 BQN, 23 check scripts
  - [x] query coverage（全src_next_*キーがqueryで取得可能か）
  - [x] bqn-eval liveness（最低限の式で動作確認）
  - [x] bqn-dump liveness（最低限の式で動作確認）
  - [x] rtk / sqz availability（コマンド存在確認）
  - [x] stale tool references（docs/AGENTS.mdに削除済みツールの現役参照がないか）→ 3件検出・修正
- [x] A-2: `checks/check-devtools.sh` として check.sh に統合
- [x] A-3: 全check PASS確認（10/10 PASS）

## Phase B: 個別ツール改善 ✅

- [x] B-1: `tools/query` — `--grep-val` 追加（値側のgrep）
- [x] B-2: `tools/scaffold-check.sh` 作成（boilerplate generator）
- [x] B-3: `tools/repo-index` — `--baseline`保存 + `--diff` 表示
- [x] B-4: `checks/check-bqn-eval.sh` 追加（bqn-evalのユニットテスト、7件）
- [x] B-5: `AGENTS.md` に devtools 使い方セクション追加

## Phase C: 統合 ✅

- [x] C-1: `tools/check.sh` に devtools-check 追加（Phase A-2で実施済み）
- [x] C-2: 全check PASS確認（11/11 devtools-check, 全4ステップPASS）
- [x] C-3: AGENTS.md 更新（devtoolsセクション追加済み）
- [x] C-4: `TODO.md` 更新
- [x] C-5: `docs/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md` 更新
