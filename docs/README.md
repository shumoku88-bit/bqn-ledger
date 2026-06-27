# docs README

このディレクトリは、`bqn-ledger` の仕様・設計・運用ルールを置く場所です。

重要: ここでは **現行仕様 / 進行中計画 / 履歴メモ** を分けて扱います。
古いTODOや完了済み計画を、現行仕様として読まないでください。

---

## moko が普段読む場所

普段は全部読まなくてよい。まずこの5つだけを見ます。

1. `TODO.md` - 今やること、次に着手すること
2. `docs/QUALITY_BAR.md` - 判断基準
3. `docs/ARCHITECTURE.md` - 全体構造と責務境界
4. `docs/AI_CODEMAP.md` - コード地図
5. `docs/SAFETY_PROFILE.md` - 壊れた時に止める規格

迷ったら `TODO.md` へ戻ります。過去の長い計画や判断記録は、必要になった時だけ辿ります。

---

## まず読む（pit向け最短ルート）

1. `docs/AI_CODEMAP.md` - pit向けコード地図
2. `TODO.md` - 現在進行中・次に着手する作業だけ
3. `docs/QUALITY_BAR.md` - 一般向けプロダクトにはしないが、production-grade personal tool として扱う品質基準
4. `docs/ENGINEERING_ROADMAP.md` - プロ級へ詰める導線・次の一手
5. `docs/SAFETY_PROFILE.md` - fail closed / 正データ保護 / invariant の小さな安全規格
6. `docs/SAFETY_PROFILE_INVARIANT_MAP.md` - Safety Profile invariant と既存 check / lint / fixture の対応表
7. `docs/ARCHITECTURE.md` - 現行データフローとモジュール責務
8. `docs/CANONICAL_DAILY_CUBE.md` - `Day × Account × Layer` の固定契約
9. `docs/POSTING_IR_CONTRACT.md` / `docs/TBDS_CONTRACT.md` - Posting IR と試算表データセットの境界契約
10. `docs/PLAN_ID_LIFECYCLE.md` - `plan_id` ライフサイクル契約 (Go/BQN 共通契約)
11. 変更内容に応じて、下の「Done / Current Baseline (完了済み・現行仕様として機能)」を読む

---

## Active plans / 進行中計画

### Active (現在着手中の計画)

- `docs/AI_AGENT_EFFICIENCY_PLAN.md`
  - Gemini / Codex / local agent の作業効率化候補を、実装前に優先順位づけする docs-only plan。
- `docs/REPO_INDEX_DESIGN.md` / `docs/REPO_INDEX_IMPLEMENTATION_HANDOFF.md`
  - CodeGraph-lite / repo-index の MVP 仕様と実装指示書。
- `docs/AI_REVIEW_BQN_EVAL_TASK.md`
  - `tools/bqn-eval` をAIに使わせ、レビューを受け、小さく改善するための task packet。
- `docs/HOUSEHOLD_POLICY_LAYER_PLAN.md`
  - 年金・月給・不定期収入・封筒派・口座残高派など、さまざまな生活スタイル/家計管理スタイルへ対応するための policy layer 設計。生活ルールを accounting core に埋め込まないための active design。
- `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md` / `docs/SRC_NEXT_EXPENSE_ACCOUNT_MAPPING.md`
  - `src_next` の household report policy / metadata mapping 契約。既存実装との差分がある場合は、実装・fixture・check を確認してから更新する。

### Backlog (待機中の計画)

- `docs/LEDGER_ENGINE_IDEA_CATALOG.md`
  - Report Lens / provenance / TBDS / scenario overlay / life pressure / txn_id bundle / shape visibility など、面白い ledger engine 化の検討カタログ。
- `docs/LEGACY_FINISH_GO_RETIREMENT_PLAN.md`
  - `src/input/finish.go` legacy standalone preview helper の退役 / 移動計画。
- `docs/SEAM_REDUCTION_PLAN.md`
  - Go/Bash/BQN の境界削減（Seam Reduction）設計。
- `docs/DEBUG_PROVENANCE_DESIGN.md`
  - 主要数値の計算に使用されたデータの出所（provenance）表示の設計。
- `docs/DECISION_TERMINAL_COLOR_CONFIG.md`
  - ANSI カラー出力の制御方法（semantic helper / NO_COLOR / パイプ検出）。Phase 1 実装済み、theme 設定は未導入。

### Done / Current Baseline (完了済み・現行仕様として機能)

- `docs/OLD_ENGINE_REMOVAL_PLAN.md`
  - 旧エンジン (`src/core/`, `src/reports/`, `src/views/`, root `main.bqn`) の除去は完了。`bqn-ledger` は `src_next` 中心の独立プロジェクトに移行済み。
- `docs/ACCOUNTING_ENGINE_QUALITY_PLAN.md`
  - Accounting-grade engine 化の主要 gate は完了。今後は `TODO.md` と `docs/ENGINEERING_ROADMAP.md` の残タスクを優先する。
- `docs/POSTING_IR_CONTRACT.md` / `docs/TBDS_CONTRACT.md`
  - Posting IR と TBDS の境界契約。現行実装の基礎として参照する。
- `docs/REPORT_SCREEN_REVIEW_LOOP.md` / `docs/REPORT_SCREEN_CANDIDATES.md` / `docs/report-mocks/README.md`
  - report screen mock review は完了。採用済み画面の実装・調整は別計画で扱う。
- `docs/QUALITY_BAR.md`
  - 一般向けプロダクトにはしないが、自分の生活会計を預ける production-grade personal tool として扱うための品質基準。
- `docs/SAFETY_PROFILE.md` / `docs/SAFETY_PROFILE_INVARIANT_MAP.md`
  - 予測可能性、fail closed、正データ保護、不変条件の安全規格とその対応表。
- `docs/CUBE_SHAPE_INVARIANT_PLAN.md` / `docs/CUBE_SHAPE_INVARIANT_IMPLEMENTATION_HANDOFF.md`
  - Canonical Daily Cube の shape 検査実装。
- `docs/REPORT_SECTION_STATUS_POLICY.md` / `docs/SECTION_STATUS_IMPLEMENTATION_HANDOFF.md`
  - report section ごとの `OK / WARN / ERROR / SKIPPED / UNAVAILABLE` 方針と初回実装。
- `docs/BQN_CONVENTIONS_FOR_AI.md`
  - pit が BQN を触るときの AI 作業効率化ガイド。
- `docs/BQN_REPL_AND_DUMPER_DESIGN.md`
  - `bqn-eval` / `bqn-probe` / `bqn-dump` の薄い検査ラッパー設計。Phase 1 (`bqn-eval`), Phase 2 (`bqn-dump`) 実装済み。
- `docs/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md`
  - AI開発効率向上のための devtools 提案集。`bqn-eval`, `bqn-dump`, `repo-index`, `query`, `scaffold-check.sh`, `devtools-check.sh` 等。
- `TODO_DEVTOOLS.md`
  - devtools 改善の TODO チェックリスト（2026-06-27 全Phase完了）。
- `docs/AI_TASK_PACKET_TEMPLATE.md`
  - pit に作業を渡すときのテンプレート。
- `docs/OUTPUT_SQUEEZER_DESIGN.md`
  - historical: 旧 `tools/sqz-report` 設計。現在は `tools/query` が `tools/report-next-summary` の machine-readable 出力を薄く絞る。
- `docs/CONVENTIONS.md`
  - 勘定科目の命名、TSVスキーマ、メタデータ定義などの規約。
- `docs/JOURNAL_META.md`
  - `journal.tsv` / `plan.tsv` で使用できるメタデータの一覧。
- `docs/MAINTENANCE.md`
  - データのバックアップやメンテナンス手順。
