# AI_CODEMAP: pit向けコード地図

この文書は、pit（AI作業相棒）が `bqn-ledger` を触る前に読むための地図です。

## まず読む順番

1. `docs/AI_CODEMAP.md`（このファイル）
2. `TODO.md`（現在進行中・次に着手する作業だけ）
3. `docs/OLD_ENGINE_REMOVAL_PLAN.md`（旧エンジン除去計画）
4. `docs/ARCHITECTURE.md`（データフロー・モジュール責務）
5. `docs/CANONICAL_DAILY_CUBE.md`（固定するDaily Cube契約）
6. `docs/TIME_AS_AXIS.md`（時間座標・観察時点・区間view）
7. レポート変更なら `src_next/report.bqn` と該当する `src_next/*` モジュール、および現行の report 関連 docs / check
8. 設定駆動化なら `docs/GENERALIZATION_TODO.md`
9. Goによる元データTSV編集なら `docs/GO_EDITOR_USAGE.md` / `docs/GO_EDITOR_NEXT_PLAN.md`
10. 複数ポスティング導入検討なら `docs/DECISION_MULTI_POSTING_INVESTIGATION.md`
11. 変更内容に応じて `docs/CONVENTIONS.md` / `docs/JOURNAL_META.md` / `docs/MAINTENANCE.md`
12. 履歴・背景が必要な場合のみ `docs/archive/` を読む
13. AIによる家計相談計算の設計なら `docs/AI_BUDGET_CALCULATOR_DESIGN.md`

`docs/REPORT_FIELD_MAP.md` と `docs/MAIN_SECTIONS.md` は旧エンジンの historical / superseded docs です。現行レポート変更の正本導線としては読まず、旧 `main.bqn` / `report_engine.Build` の履歴確認が必要な場合だけ参照します。

## 絶対に守ること

- base directory 配下の `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` が正データ。公開 repo の `data/` は匿名 sandbox、実運用は `LEDGER_DATA_DIR`（例: `moko/data`）で外出しする。
- pit は実データ TSV を勝手に書き換えない。必要ならユーザー確認を取る。
- journal-like TSV の先頭5列は固定: `date memo from to amount`。
- 6列目以降は `key=value` メタ。会計計算は原則として先頭5列だけを見る。
- 大改造しない。1段階・1目的・小さい差分で進める。
- TODOを進める際は、まず `TODO.md` と該当する active plan を参照する。
- 大きめの相談が来たら、通常TODO/active planを進める話か、Go editor トラックか、先にmokoへ確認する。

## 全体像

```text
<base>/accounts.tsv / <base>/journal.tsv / <base>/plan.tsv / <base>/budget_alloc.tsv / <base>/cycle.tsv
   │
   └─ src_next/loader.bqn (TSV読み込み)
        │
        └─ src_next/context.bqn (BuildContext)
             │
             ├─ src_next/cube.bqn (Canonical Daily Cube: Day × Account × Layer)
             ├─ src_next/tbds.bqn (Trial Balance Data Set: opening/movement/closing)
             │
             └─ src_next/report.bqn (人間向けレポート)
                  └─ src_next/summary.bqn (機械向けコンパクト出力)
```

## 正データファイル

各ツールは `LEDGER_DATA_DIR`、未設定なら `config/system_defaults.tsv` の `DEFAULT_BASE_DIR` を base directory として読む。公開 repo の `data/` は sandbox fixture として扱う。

- `config/meta_schema.tsv` — メタデータキーの定義
- `<base>/accounts.tsv` — 勘定科目マスタ
- `<base>/journal.tsv` — 実績取引
- `<base>/plan.tsv` — 未来予定
- `<base>/budget_alloc.tsv` — 封筒/予算の手動配賦
- `<base>/cycle.tsv` — サイクル期間設定

## コード地図

### `src_next/` (BQN 会計エンジン)

- `context.bqn` — BuildAllRows / BuildPeriodView / BuildContext。cycle は読み込み境界ではなく report query parameter。
- `loader.bqn` — TSV ファイル読み込み (`•FChars` 使用)。
- `cube.bqn` — Canonical Daily Cube (`Day × Account × Layer`) の構築。
- `tbds.bqn` — Trial Balance Data Set (period/account/layer/opening/movement/closing)。
- `trial_balance.bqn` — 試算表エクスポート。debit/credit 符号付き。
- `cycle.bqn` — サイクル期間の解決。date.bqn を使用。
- `account_key.bqn` — 勘定科目のキー解決。
- `projection.bqn` — Posting IR 投影。
- `snapshot.bqn` — Balance Sheet / Snapshot。TBDS closing を使用。
- `balances.bqn` — 残高表示。
- `ytd_summary.bqn` — YTD 集計。
- `cycle_summary.bqn` — サイクル収支 (Income Statement)。
- `expense_breakdown.bqn` — サイクル支出内訳。
- `envelope_computation.bqn` — 封筒予算計算。
- `planned_payments.bqn` — 予定支払い表示。
- `recent_journal.bqn` — 最近の仕訳表示。
- `readiness_check.bqn` — データ品質チェック。
- `outlook.bqn` — 見通し・日割り計算。
- `daily_trend.bqn` — 日次トレンド。
- `actual_comparison.bqn` — 前期比較。
- `actual_snapshot.bqn` — as_of 時点スナップショット。
- `household_policy.bqn` — 家計ポリシーレイヤ。
- `household_metadata.bqn` — 家計メタデータ診断。
- `plan_journal_overlap.bqn` — plan/journal 重複検出。
- `format.bqn` — テキスト整形、ANSI color helper、semantic color/no-color制御。
- `util.bqn` — 基本ユーティリティ (Split, ToNum, LoadLines)。
- `date.bqn` — 日付操作 (Today, Parts, Ordinal, DaysBetween)。
- `unavailable.bqn` — unavailable sentinel の正本定義と helper (`IsUnavailable`, `StartsWith`)。
- `config.bqn` — config.tsv 読み込み。
- `report.bqn` — 人間向け12セクションレポート。
- `summary.bqn` — 機械向けコンパクト出力。

### `editor/` (Go source TSV editor)

source-of-truth TSV を安全に編集する Go ツール。

- `tools/edit` — Go editor のビルド兼実行ラッパー。
- `editor/main.go` — CLI入口。`journal add` / `journal reverse` / `budget add` / `plan list` / `plan add` / `plan finish` / `plan edit`。
- `editor/journal.go` — single-file safe append 基盤。
- `editor/*_test.go` — fixture/tmpdir ベースのテスト。

承認済み書き込み範囲: `journal.tsv` / `budget_alloc.tsv` / `plan.tsv` への single-file safe append、`journal reverse`、`plan finish --apply`、open plan の `date`/`amount` 限定既存行編集。

### `checks/` (検証スクリプト)

- `check-src-next-golden.sh` — src_next golden fixture チェック。
- `check-src-next-minimal-summary.sh` — 最小サマリチェック。
- `check-src-next-cycle-summary.sh` — サイクルサマリチェック。
- `check-src-next-ytd-summary.sh` — YTD サマリチェック。
- `check-src-next-*.sh` — 各セクションの fixture チェック。
- `check-repo-index.sh` — repo-index ツールのチェック。
- `check-disabled-features.sh` — 無効化機能の隔離チェック。

### `tests/` (ユニットテスト)

- `test_src_next_*.bqn` — src_next 各モジュールのテスト。
- `test_lib.bqn` — テストフレームワーク (Assert, AssertEq)。
- `test_find_section.bqn`, `test_simple.bqn` — 汎用テスト。

## tools 地図

### 検査・CI
- `tools/check.sh` — 全チェックの一括実行 (ユニットテスト + golden + セクションチェック + エンジン独立チェック)。

### レポート・表示
- `tools/report` — 日次レポート (`bqn src_next/report.bqn <base>`)。
- `tools/report-next-summary` — 機械向けコンパクトサマリ (`key: value` 形式)。
- `tools/query` — `report-next-summary` の thin filter（`--list`/`--keys`/`--grep`/`--grep-val`）。

### UI 操作
- `tools/add-ui.sh` — 仕訳追加・取消・予定管理。
- `tools/main-ui.sh` — レポート表示系。
- `tools/edit` — Go editor ラッパー。

### AI 開発支援（devtools）
- `tools/bqn-eval` — BQN 式の簡易評価（Phase 1、repo module不可）。
- `tools/bqn-dump` — BQN 値の型・shape診断（Phase 2、kind/shape/preview/boxed hint）。
- `tools/repo-index` — リポジトリ索引。`--baseline` で保存、`--diff` で差分表示。
- `tools/scaffold-check.sh` — 新規 check スクリプトの boilerplate 生成。
- `tools/devtools-check.sh` — **全devtoolsの健全性メタチェック**（check.sh [4/4] に組み込み済み）。
- `rtk` / `sqz` — 長出力のトークン節約ラッパー（`rtk git diff`, `sqz compress`）。

→ 詳しい使い方は `AGENTS.md` の「AI開発ツール（devtools）の使い方」セクションを参照。
