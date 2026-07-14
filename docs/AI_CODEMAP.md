# AI_CODEMAP: pit向けコード地図

Status: current operational guide
Owner: docs
Canonical: yes
Exit: keep current while this remains the pit code/data-flow entry point

この文書は、pit（AI作業相棒）が `bqn-ledger` を触る前に読むための地図です。
人間が読む場合も、コードの入口・データフロー・どのファイルが正本かを短時間で確認するための索引として使えます。外部向けの最初の入口は `docs/README.md` と `CONTRIBUTING.md` です。

## まず読む順番

1. `docs/AI_CODEMAP.md`（このファイル）
2. `TODO.md`（現在進行中・次に着手する作業だけ）
3. `docs/QUALITY_BAR.md`（品質基準）
4. `docs/SRC_NEXT_CURRENT.md`（`src_next` が現在の普段使い report engine であること、旧 migration docs の扱い）
5. `docs/ARCHITECTURE.md`（データフロー・モジュール責務）
6. `docs/CANONICAL_DAILY_CUBE.md`（固定するDaily Cube契約）
7. `docs/TIME_AS_AXIS.md`（時間座標・観察時点・区間view）
8. レポート変更なら `src_next/report.bqn` と該当する `src_next/*` モジュール、`docs/REPORT_CONTRACTS.md` / `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md`、および現行の report 関連 check
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
   │    │         ├─ src_next/issues.bqn (Issues & Decisions 表示)
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
- `<base>/issues.tsv` — Issues & Decisions ログ

## コード地図

### `src_next/` (BQN 会計エンジン)

- `context.bqn` — BuildAllRows / BuildPeriodView / BuildContext。1つの共有 posting snapshot から B1 row evidence を構築し、pure arithmetic owner へ渡す orchestration owner。cycle は読み込み境界ではなく report query parameter。
- `exact_decimal.bqn` — source amount text の exact-decimal parse、canonical coefficient / scale、parsed coefficient exact-range 診断の owner。
- `currency_arithmetic.bqn` — pre-built B1 row evidence だけを入力に、single-domain 検査、snapshot-wide `amount_scale`、exact normalization、normalized overflow evidence を返す pure B2 owner。source file や projection は扱わない。
- `source_currency_admission.bqn` — supplied account lines と posting snapshot のみを検査する pure source-currency admission owner。closed strict/compatibility policy、privacy-safe diagnostics、no-partial-admission を持ち、I/Oなし・public runtime未配線。
- `friend_travel_jpy_finalization.bqn` — pending friend-travel source-event descriptor、明示 finalization date / JPY amount、既存account descriptor、既存finalization IDだけを入力にするpure validator。成功時は既存JPY liability → JPY expenseのcanonical previewを正確に1行返し、失敗時はprivacy-safe diagnosticsと0行を返す。I/O、status/index mutation、writer、public runtime配線は持たない。
- `friend_travel_source_event.bqn` — Israel用friend-paid pending source eventの固定9列、ILS精度、固定payer/trip/status、既存全行検査、ID一意性、exact preview rowを所有するpure validator。I/Oとfinalizationを持たない。
- `travel_exchange_event.bqn` — Israel用JPY→ILS exchangeの2観測amount、既存account descriptor、ID一意性を検査しstructured previewを返すpure owner。I/O、rate、journal row、valuationを持たない。
- `loader.bqn` — TSV ファイル読み込み (`•FChars` 使用)。
- `cube.bqn` — Canonical Daily Cube (`Day × Account × Layer`) の構築。
- `tbds.bqn` — Trial Balance Data Set (period/account/layer/opening/movement/closing)。
- `trial_balance.bqn` — 試算表エクスポート。debit/credit 符号付き。
- `cycle.bqn` — サイクル期間の解決。date.bqn を使用。
- `account_key.bqn` — 勘定科目のキー解決。
- `projection.bqn` — Posting IR 投影。
- `snapshot.bqn` — Balance Sheet / Snapshot。TBDS closing を使用。構造化された ViewModel JSON 出力（FormatJson）もサポート。
- `balances.bqn` — 残高表示。human `--section balances` では `DEFAULT_CURRENCY` または明示 `--currency JPY|ILS` を解決し、checked selected-currency projection 後の単一通貨残高だけを表示する。carrierは calculation scale と presentation scale を分離し、ILSはsource precision 2桁超をfail closedして常に2桁表示する。既存JSONは非selectedのフラットリストと合計の契約を維持する。
- `ytd_summary.bqn` — YTD 集計。
- `cycle_summary.bqn` — サイクル収支 (Income Statement)。
- `expense_breakdown.bqn` — サイクル支出内訳。
- `envelope_computation.bqn` — 封筒予算計算。封筒ごとの allocated/spent/remaining に加え、`accounts.tsv` の `role=budget kind=unassigned` から未割当 budget pool 残高と OVER_ALLOCATED status を出す。human section は `envelope_role=dynamic|execution`（未指定 `kind=envelope` は dynamic fallback）で Dynamic / Execution / Unassigned / Backing diagnostic に分ける。さらに readonly 診断として、暫定 `type=liquid` ベースの `envelope_funding_base` と active 封筒残高合計との差分（現金裏付け未割当 / backing_status）を出す。`EXECUTION_PLANNED_PAYMENTS_ENVELOPE` 設定時は、指定 execution envelope と未了 planned payments の coverage 差分も readonly で出す。
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
- `issues.bqn` — Issues & Decisions ログの表示フォーマット。
- `util.bqn` — 基本ユーティリティ (Split, ToNum, LoadLines)。
- `json.bqn` — 汎用 BQN JSON シリアライザ（数値、文字列、エスケープ、リスト、オブジェクトのネストに対応）。
- `date.bqn` — 日付操作 (Today, Parts, Ordinal, DaysBetween)。
- `unavailable.bqn` — unavailable sentinel の正本定義と helper (`IsUnavailable`, `StartsWith`)。
- `config.bqn` — config.tsv 読み込み。
- `report.bqn` — 人間向けレポートの正本入口。セクション構成は実装と `--list-sections` を正とし、`--section <key>` で単一セクションを出力する（UIツールが動的にセクション抽出するための正本）。M3の `--currency` はhuman `balances` 専用で、full report・他section・cache・JSONとの組合せはfail closed。
- `report_section_metadata.bqn` — UI向け structured report section metadata export（TSV default / JSON）。source TSV は読まず、section key / label / category / owner / output mode を出す。
- `summary.bqn` — 機械向けコンパクト出力。

### `src_edit/` (BQN editor subsystem)

`tools/edit-bqn` を支える BQN editor subsystem。`src_next/` (report) とは独立。

- `src_edit/README.md` — 責務境界と実装対象の定義。
- `src_edit/account_add_cmd.bqn` — 明示role・名前空間・重複・asset typeを検証し、accounts.tsv追記候補を生成。
- `src_edit/account_list_cmd.bqn` — UI向け account candidate export。`accounts.tsv` の role メタ解釈を BQN 側に閉じ込める。
- `src_edit/journal_add_cmd.bqn` — journal add / budget add 用の検証および TSV 生成。
- `src_edit/journal_source_integrity.bqn` / `journal_source_check.bqn` — ordinary journal `lint` のmixed-safe source integrity owner。row単位のdate/exact amount/metadata/currency/account整合性をall-or-nothingで検査し、report arithmeticを行わない。
- `src_edit/travel_friend_add_cmd.bqn` — `friend_travel_events.tsv` の既存全行検査とpending候補APPEND protocol生成。意味検査はpure source-event ownerへ委譲。
- `src_edit/travel_exchange_add_cmd.bqn` — accountsと`travel_exchange_events.tsv`をpure exchange ownerへ渡し、固定10列候補APPEND protocolを生成。
- `src_edit/journal_list_cmd.bqn` — journal reverse UI向け read-only journal selection export。
- `src_edit/journal_reverse_cmd.bqn` — journal reverse 用の検証および反対仕訳 APPEND protocol 生成。
- `src_edit/issue_add_cmd.bqn` — issue add 用の検証および TSV 生成。
- `src_edit/issue_list_cmd.bqn` — issue close UI向けの open issue 候補 export。
- `src_edit/issue_close_cmd.bqn` — issue close 用の検証および safe replace TSV 生成。
- `src_edit/plan_add_cmd.bqn` — plan add 用の検証および TSV 生成。
- `src_edit/plan_list_cmd.bqn` — plan list 用の BQN 実装。`tools/edit plan list --format tsv` の unfinished plan candidate export 契約は `docs/UNFINISHED_PLAN_ENTRIES_EXPORT_CONTRACT.md`。
- `src_edit/plan_related_cmd.bqn` — plan finish replenishment UI 用の read-only 関連予定抽出。`series=` → `plan_id` series → exact fallback の順序を所有する。
- `src_edit/plan_finish_cmd.bqn` — plan finish 用の検証、実際のジャーナルアペンド行の生成。
- `src_edit/plan_budget_sync_cmd.bqn` — 完了済み固定費予定の `plan_id`、actual、設定、execution envelope、通貨、既存budget linkageを検査し、冪等なbudget companion候補を生成。曖昧な対応や通常収入は扱わない。
- `src_edit/plan_edit_cmd.bqn` — plan edit 用の検証および exact REPLACE protocol 生成。
- `src_edit/plan_id.bqn` — plan_id 生成補助。
- `src_edit/render.bqn` / `src_edit/validate.bqn` — 共通レンダリング / バリデーション。

責務: edit intent の受取 → 入力バリデーション → 候補 TSV 行や編集操作の生成 → 機械可読出力。
shell safe-write (`tools/lib/`) が実際のファイル書き込みを担当する。

### `tools/edit`

- 日常の公開 editor コマンド入口。
- `tools/edit-bqn` へそのまま委譲する薄いラッパー。
- CLI 互換の安定点として扱う。
- UI向け read-only export として `tools/edit account list [--role ROLE]` も提供する。

### `tools/edit-bqn`

- 日常 write path の BQN+shell 実装。
- `account add` / `account list` / `journal add` / `journal list` / `travel friend add` / `travel exchange add` / `budget add` / `issue add` / `issue list` / `issue close` / `plan add` / `plan list` / `plan related` / `plan finish` / `plan budget-sync` / `plan edit` / `journal reverse` を扱う。
- `src_edit` の機械可読プロトコルを受け、`tools/lib/safe-write.sh` で安全に適用する。
- Dispatcher boundary の現行メモは `docs/EDIT_BQN_DISPATCHER.md`。共通 shell helper は `tools/lib/edit-bqn-common.sh`、`issue add` handler は `tools/lib/edit-bqn-issue.sh`。
- Go editor の記述や fallback 前提は現行導線では使わない。

### `mcp-server/` (confirmation-gated adapter)

- `core.js` — transport非依存のread/prepare/commit境界。BQN report/editorをsubprocess配列で呼び、draft、fingerprint、期限、重複警告を所有する。会計計算は持たない。
- `server.js` — localhost既定・Bearer必須のStreamable HTTP `/mcp` transport。legacy SSEは提供しない。
- `test/` — 匿名fixtureの一時コピーだけを使うcore/transport回帰テスト。
- 正本運用契約は `docs/MCP_RECEIPT_ENTRY.md`。

### `checks/` (検証スクリプト)

- `check-src-next-golden.sh` — src_next golden fixture チェック。
- `check-src-next-minimal-summary.sh` — 最小サマリチェック。
- `check-src-next-cycle-summary.sh` — サイクルサマリチェック。
- `check-src-next-ytd-summary.sh` — YTD サマリチェック。
- `check-src-next-*.sh` — 各セクションの fixture チェック。
- `check-report-section-metadata.sh` — report section metadata TSV export の契約チェック。
- `check-repo-index.sh` — repo-index ツールのチェック。
- `check-disabled-features.sh` — 無効化機能の隔離チェック。
- `check-edit-bqn-account-list.sh` — BQN account list export チェック。
- `check-edit-bqn-journal-add.sh` — BQN journal/budget/issue add parityチェック。
- `check-edit-bqn-journal-post-check-recovery.sh` — mixed JPY/ILS journal source lint、post-check失敗時のexact rollback、後続writer保護チェック。
- `check-edit-bqn-travel-friend-add.sh` — friend pending source-eventのdry-run、exclusive first-write、checked append、stale/duplicate拒否、rollback回帰チェック。
- `check-travel-exchange-pure.sh` — exchange structured previewのpure contractとI/O/rate/journal output不在チェック。
- `check-edit-bqn-travel-exchange-add.sh` — exchange sourceのexclusive first-write、全行検査、checked append、stale/duplicate拒否、rollback回帰チェック。
- `check-israel-travel-four-path-rehearsal.sh` — exchange → ILS cash journal → confirmed-JPY card journal → friend pendingを一つのsynthetic baseで公開入口から実行する統合回帰。
- `check-edit-bqn-issue-close.sh` — BQN issue list/close の履歴保持・dry-run・fail-closed チェック。
- `check-edit-bqn-journal-list.sh` — BQN journal list read-only selection exportチェック。
- `check-edit-bqn-plan-list.sh` — BQN plan list parity / unfinished plan candidate export 契約チェック。
- `check-edit-bqn-plan-add.sh` — BQN plan add parityチェック。
- `check-edit-bqn-plan-finish.sh` — BQN plan finish parityチェック。
- `check-edit-bqn-plan-budget-sync.sh` — `plan_id` linked execution-envelope companionのdry-run、actual amount、冪等retry、NOT_LINKED、stale failure後retryを検証。
- `check-safe-replace-line.sh` — 安全置換 primitive のアサーションチェック。

### `tests/` (ユニットテスト)

- `test_src_next_*.bqn` — src_next 各モジュールのテスト。
- `test_lib.bqn` — テストフレームワーク (Assert, AssertEq)。
- `test_find_section.bqn`, `test_simple.bqn` — 汎用テスト。

## tools 地図

### 検査・CI

- `tools/check.sh` — テストランナーの正本。ユニットテスト、エンジン不変条件、各セクションの golden 差分、MCP core/transport、devtools-check などを一括実行する。
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
- `tools/plan-finish-replenish-ui.sh` — 予定実績化後に次回予定補充を案内する任意の対話補助。`tools/edit plan finish` と `tools/edit plan add` を合成するだけで、低層 TSV 契約は持たない。
- `tools/edit` — 公開 editor コマンドの薄い shell wrapper。
- `tools/edit-bqn` — 現行の BQN+shell editor 入口。`src_edit` の write path を実行する。
- `tools/report` / `tools/report-next` — `src_next` を使用したコマンドラインレポートの正本入口。
- `tools/report-next-summary` — `src_next` データの機械向け要約出力。
- `tools/report-section-metadata` — source TSV を読まない report section metadata export（TSV default / JSON）。UI は human report 文字列を parse せず、このような structured export を使う。
- `tools/bl` — 日常操作 Command Hub。report / section / add / check / edit をまとめ、読み取り表示と安全な書き込み導線へルーティングする。`edit` の対話モードは TSV 選択サブメニューを持ち、編集後は同じサブメニューへ戻り、`back` / cancel / Ctrl-C で hub 上位へ戻る。

