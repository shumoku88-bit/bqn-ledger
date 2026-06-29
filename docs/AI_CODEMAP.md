# AI_CODEMAP: pit向けコード地図

この文書は、pit（AI作業相棒）が `bqn-ledger` を触る前に読むための地図です。

## まず読む順番

1. `docs/AI_CODEMAP.md`（このファイル）
2. `TODO.md`（現在進行中・次に着手する作業だけ）
3. `docs/QUALITY_BAR.md`（品質基準）
4. `docs/SRC_NEXT_CURRENT.md`（`src_next` が現在の普段使い report engine であること、旧 migration docs の扱い）
5. `docs/ARCHITECTURE.md`（データフロー・モジュール責務）
6. `docs/CANONICAL_DAILY_CUBE.md`（固定するDaily Cube契約）
7. `docs/TIME_AS_AXIS.md`（時間座標・観察時点・区間view）
8. レポート変更なら `src_next/report.bqn` と該当する `src_next/*` モジュール、および現行の report 関連 docs / check
9. エディタ作業なら `docs/PRODUCTION_EDITOR_DIRECTION.md` / `docs/BQN_EDITOR_USAGE.md` / `src_edit/README.md`
10. 複数ポスティング導入検討なら `docs/archive/completed-plans/DECISION_MULTI_POSTING_INVESTIGATION.md`
11. 変更内容に応じて `docs/CONVENTIONS.md` / `docs/JOURNAL_META.md` / `docs/MAINTENANCE.md`
12. 履歴・背景（非アクティブな計画書、旧エンジン移行期資料、完了済みの計画書など）が必要な場合のみ `docs/archive/` を読む
13. AIによる家計相談計算の設計なら `docs/archive/active-plans/AI_BUDGET_CALCULATOR_DESIGN.md`

`docs/archive/completed-plans/REPORT_FIELD_MAP.md` と `docs/archive/completed-plans/MAIN_SECTIONS.md` は旧エンジンの historical / superseded docs です。現行レポート変更の正本導線としては読まず、旧 `main.bqn` / `report_engine.Build` の履歴確認が必要な場合だけ参照します。

`docs/archive/src-next-migration/` も移行期の履歴です。現在の入口は `docs/SRC_NEXT_CURRENT.md` と `tools/report` を正とし、archive 内の「production default is bqn main.bqn」「Stage 4b 未開始」などの記述を現行仕様として扱わないでください。

## 絶対に守ること

- base directory 配下の `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` が正データ。公開 repo の `data/` は匿名 sandbox、実運用は `LEDGER_DATA_DIR`（例: `/path/to/ledger-data/data`）で外出しする。正データの場所は変わり得るので、pit は `tools/doctor` と `LEDGER_DATA_DIR` で確認し、古いパスを前提にしない。
- pit は実データ TSV を勝手に書き換えない。必要ならユーザー確認を取る。
- journal-like TSV の先頭5列は固定: `date memo from to amount`。
- 6列目以降は `key=value` メタ。会計計算は原則として先頭5列だけを見る。
- 大改造しない。1段階・1目的・小さい差分で進める。
- TODOを進める際は、まず `TODO.md` と該当する active plan を参照する。
- 大きめの相談が来たら、通常TODO/active planを進める話か、BQN editor トラックか、先にmokoへ確認する。

## 全体像

```text
<base>/accounts.tsv / <base>/journal.tsv / <base>/plan.tsv / <base>/budget_alloc.tsv / <base>/cycle.tsv / <base>/issues.tsv
   │
   ├─ src_next/loader.bqn (TSV読み込み)
   │    │
   │    ├─ src_next/context.bqn (BuildContext: issuesもロード)
   │    │    │
   │    │    ├─ src_next/cube.bqn (Canonical Daily Cube: Day × Account × Layer)
   │    │    ├─ src_next/tbds.bqn (Trial Balance Data Set: opening/movement/closing)
   │    │    │
   │    │    └─ src_next/report.bqn (人間向けレポート)
   │    │         ├─ src_next/issues.bqn (懸案事項・意思決定表示)
   │    │         └─ src_next/summary.bqn (機械向けコンパクト出力)
```

## 正データファイル

各ツールは `LEDGER_DATA_DIR`、未設定なら `config/system_defaults.tsv` の `DEFAULT_BASE_DIR` を base directory として読む。公開 repo の `data/` は sandbox fixture として扱う。実データの場所を確認する入口は `docs/DATA_DIR_SETUP.md` と `tools/doctor`。

- `config/meta_schema.tsv` — メタデータキーの定義
- `config/report_labels.tsv` — src_next report の表示ラベル定義。
- `<base>/accounts.tsv` — 勘定科目マスタ
- `<base>/journal.tsv` — 実績取引
- `<base>/plan.tsv` — 未来予定
- `<base>/budget_alloc.tsv` — 封筒/予算の手動配賦
- `<base>/cycle.tsv` — サイクル期間設定
- `<base>/issues.tsv` — 懸案事項・意思決定ログ

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
- `report_labels.bqn` — report presentation labels の正本ローダー (`config/report_labels.tsv`)。
- `issues.bqn` — 懸案事項・意思決定ログの表示フォーマット。
- `util.bqn` — 基本ユーティリティ (Split, ToNum, LoadLines)。
- `date.bqn` — 日付操作 (Today, Parts, Ordinal, DaysBetween)。
- `unavailable.bqn` — unavailable sentinel の正本定義と helper (`IsUnavailable`, `StartsWith`)。
- `config.bqn` — config.tsv 読み込み。
- `report.bqn` — 人間向けレポートの正本入口。セクション構成は実装と `--list-sections` を正とし、`--section <key>` で単一セクションを出力する（UIツールが動的にセクション抽出するための正本）。
- `summary.bqn` — 機械向けコンパクト出力。

### `src_edit/` (BQN editor subsystem)

`tools/edit-bqn` を支える BQN editor subsystem。`src_next/` (report) とは独立。

- `src_edit/README.md` — 責務境界と実装対象の定義。
- `src_edit/journal_add_cmd.bqn` — journal add / budget add 用の検証および TSV 生成。
- `src_edit/issue_add_cmd.bqn` — issue add 用の検証および TSV 生成。
- `src_edit/plan_add_cmd.bqn` — plan add 用の検証および TSV 生成。
- `src_edit/plan_list_cmd.bqn` — plan list 用の BQN 実装。
- `src_edit/plan_finish_cmd.bqn` — plan finish 用の検証、実際のジャーナルアペンド行の生成。
- `src_edit/plan_id.bqn` — plan_id 生成補助。
- `src_edit/render.bqn` / `src_edit/validate.bqn` — 共通レンダリング / バリデーション。

責務: edit intent の受取 → 入力バリデーション → 候補 TSV 行や編集操作の生成 → 機械可読出力。
shell safe-write (`tools/lib/`) が実際のファイル書き込みを担当する。

### `tools/edit`

- 日常の公開 editor コマンド入口。
- `tools/edit-bqn` へそのまま委譲する薄いラッパー。
- CLI 互換の安定点として扱う。

### `tools/edit-bqn`

- 日常 write path の BQN+shell 実装。
- `journal add` / `budget add` / `issue add` / `plan add` / `plan list` / `plan finish` / `plan edit` / `journal reverse` を扱う。
- `src_edit` の機械可読プロトコルを受け、`tools/lib/safe-write.sh` で安全に適用する。
- Go editor の記述や fallback 前提は現行導線では使わない。

### `checks/` (検証スクリプト)

- `check-src-next-golden.sh` — src_next golden fixture チェック。
- `check-src-next-minimal-summary.sh` — 最小サマリチェック。
- `check-src-next-cycle-summary.sh` — サイクルサマリチェック。
- `check-src-next-ytd-summary.sh` — YTD サマリチェック。
- `check-src-next-*.sh` — 各セクションの fixture チェック。
- `check-repo-index.sh` — repo-index ツールのチェック。
- `check-disabled-features.sh` — 無効化機能の隔離チェック。
- `check-edit-bqn-journal-add.sh` — BQN journal/budget/issue add parityチェック。
- `check-edit-bqn-plan-list.sh` — BQN plan list parityチェック。
- `check-edit-bqn-plan-add.sh` — BQN plan add parityチェック。
- `check-edit-bqn-plan-finish.sh` — BQN plan finish parityチェック。
- `check-safe-replace-line.sh` — 安全置換 primitive のアサーションチェック。

### `tests/` (ユニットテスト)

- `test_src_next_*.bqn` — src_next 各モジュールのテスト。
- `test_lib.bqn` — テストフレームワーク (Assert, AssertEq)。
- `test_find_section.bqn`, `test_simple.bqn` — 汎用テスト。

## tools 地図

### 検査・CI

- `tools/check.sh` — テストランナーの正本。ユニットテスト、エンジン不変条件、各セクションの golden 差分、devtools-check などを一括実行する。
- `tools/devtools-check.sh` — 全開発ツールの健全性チェック（`check.sh` のフェーズ4に組み込み済み）。
- `tools/scaffold-check.sh` — 新しい `checks/check-*.sh` スクリプトのボイラープレート（テンプレート）生成用。
- `tools/coverage` — BQN module / editor-check inventory を出力する。

### 開発・検証支援 (devtools)

- `tools/repo-index` — リポジトリの BQN ファイルやチェックスクリプトの索引を管理。ファイル追加・削除時は `--baseline` で更新する。
- `tools/doctor` — 設定とデータディレクトリの整合性診断。
- `tools/bqn-eval` — BQN式の簡易評価用。
- `tools/bqn-dump` — BQN値の型とshape診断用。
- `tools/query` — `report-next-summary` 出力の機械可読検索・抽出フィルタ。
- `tools/envelope-calc` — 封筒予算の対話的計算（P1〜P4 プリミティブ実行）。

### ユーザーインターフェース (UI)

- `tools/main-ui.sh` — 読み込み・閲覧系UI（レポート閲覧・セクション選択、fzf/gumベース）。
- `tools/add-ui.sh` — 書き込み・操作系UI（取引の追加・取消・予定完了処理等、BQN editor への安全な中継）。
- `tools/edit` — 公開 editor コマンドの薄い shell wrapper。
- `tools/edit-bqn` — 現行の BQN+shell editor 入口。`src_edit` の write path を実行する。
- `tools/report` / `tools/report-next` — `src_next` を使用したコマンドラインレポートの正本入口。
- `tools/report-next-summary` — `src_next` データの機械向け要約出力。
- `tools/bl` — 日常操作 Command Hub。report / section / add / check / edit をまとめ、読み取り表示と安全な書き込み導線へルーティングする。

