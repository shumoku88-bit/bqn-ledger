# BQN Editor & Add-UI Usage Manual

Status: current operational guide
Owner: editor
Canonical: yes
Exit: keep current while `tools/edit` and `tools/add-ui.sh` remain the daily write paths.

BQN-Ledgerにおける base directory 配下のconfigured native Journalとsource TSV（`plan.tsv` など）を安全に表示・編集・完了処理するための、BQN製エディタ（`tools/edit` / `tools/edit-bqn`）および日常記帳UI（`tools/add-ui.sh`）の使い方説明書です。

## 1. 基本コンセプト：秤（はかり）と手袋

本プロジェクトでは、データの計算・整合性検証と、ファイル編集・入力UXの責務を以下のように分離しています。

*   **BQN = 秤（Scale）**: 正本データの読み込み、残高・封筒予算・トレンド・予実比較（actual-comparison）の集計・計算、レポート出力、および最終的な会計整合性の検証（Lint）。
*   **BQN Editor = 手袋（Gloves）**: 正本TSVファイル群の安全な読み込み、対話的な追加・編集、自動バックアップ、事後チェック。

BQN Editor は会計エンジンとしての計算（残高や封筒の残金計算など）を行わず、データの編集と安全なファイル操作に特化します。

---

## 2. 日常の記帳ワークフロー (`tools/add-ui.sh`)

日常の記帳や予定の消化は、対話式のUIランチャー `tools/add-ui.sh` を通して一元的に行えます。
`fzf` または `gum` がインストールされている場合、インクリメンタルサーチ（あいまい検索）で直感的に選択可能です。

### 起動方法
```bash
./tools/add-ui.sh
```

### モード一覧
起動すると、まず以下の記帳モードを選択します。

1.  **`account-add` (アカウント追加)**: `asset / liability / income / expense` を選び、明示的な `role=` と一致する名前空間で `accounts.tsv` に安全追記します。assetでは任意で `type=liquid|savings|invest` を選べます。
2.  **`expense` (支出)**: 資産口座から費用口座への支出。明示選択されたActual sourceへ追記。
3.  **`multi` (複数ポスティング)**: native Journal mode専用。勘定と符号付き整数金額を2件以上入力し、合計ゼロの1取引として選択Actual Journalへ安全追記します。TSV modeでは書き込まず拒否します。
4.  **`move` (資金移動)**: 資産口座間の振替。明示選択されたActual sourceへ追記。
5.  **`income` (収入)**: 収入元から資産口座への入金。明示選択されたActual sourceへ追記。
6.  **`budget` (予算配賦)**: 封筒への予算割り当て（例: `budget:unassigned` $\rightarrow$ `budget:daily`）。`budget_alloc.tsv` に追記。memo 候補は `config/ui_budget_memo_presets.tsv` で管理します。
7.  **`plan-add` (予定の追加)**: 未来の支払い予定を `plan.tsv` に安全追記。必要なら `series` を入力でき、`plan_id` は自動生成。
8.  **`plan-edit` (予定の日付・金額修正)**: 未完了予定を選び、`date` / `amount` だけを差分プレビュー付きで修正。
9.  **`plan-finish` (予定の実績化)**: `plan.tsv` の予定を、選択Actual sourceへ `plan_id` 付き実績として追記し、必要なら次回予定も追加。
10.  **`reverse` (仕訳取消)**: 選択Actual sourceの取引を選び、反対postingを新しい取引として安全追記。
11.  **`issue` (Issues & Decisions の追加)**: 財務的な issue / decision（例: サブスクリプションの見直し）を `issues.tsv` に安全追記。

`plan-edit` と `plan-finish` の予定選択では、`今日以降 / 期限超過 / すべてのOPEN予定`を先に選びます。Shellは日付を比較せず、今日を明示 `as-of` としてBQN editorへ渡し、BQNの `overdue / due / future` 分類で候補を絞ります。

---

## 3. 予定の完了（実績化）とライフサイクル

予定（Plan）の消化（`plan-finish`）は、**「予定行を plan.tsv から消さない」** という非破壊設計を採用しています。

### ライフサイクルと Closed 判定の仕組み
*   **非破壊**: 予定を実績化しても、`plan.tsv` から予定行は削除されません。予実ブレ（actual-comparison / planned-payments）の履歴として残されます。
*   **動的クローズ**: 選択Actual sourceに同じ `plan_id` / `plan-id` を持つ実績が追記された時点で、BQNエンジンおよびエディタが動的に「この予定は完了（Closed）」と判定します。
*   **自動フィルタリング**: 完了した予定は、`plan list` や `tools/add-ui.sh` の未完了予定リストから自動的に非表示になります。

### 幽霊の防止（安全ゲート）
`plan.tsv` に `plan_id` が存在しない行（`Unplanned` 予定）や、`plan_id` の書式が崩れている予定は、**実績化（finish / apply）がエラーで拒否されます**。これは「完了したはずなのに予定リストに残り続けるゾンビデータ」の発生を防ぐための安全仕様です。

---

## 4. CLI コマンドリファレンス (`tools/edit`)

日常UI（`add-ui.sh`）を介さず、シェルから直接エディタ `tools/edit` を叩いて操作することも可能です。

### グローバルオプション
*   `--base <dir>`: データセットが存在する基準ディレクトリを指定します。既定は `LEDGER_DATA_DIR`、未設定なら `config/system_defaults.tsv` の `DEFAULT_BASE_DIR`（公開 repo では `data/` sandbox）です。

### アカウントの安全追記 (`account add`)
```bash
./tools/edit account add --name 'income:友人精算' --role income
./tools/edit account add --name 'assets:PayPay' --role asset --type liquid
```

`role` は `asset|liability|income|expense`、名前空間はそれぞれ `assets:|liabilities:|income:|expenses:` に一致する必要があります。重複、空の名前部分、矛盾する名前空間、asset以外への `type=`、未知のtypeは書き込み前に拒否されます。通常の追記と同様に `--dry-run`、`--yes`、`--post-check` を利用できます。

### ジャーナル・予算の安全追記 (`journal add` / `journal reverse` / `budget add`)
```bash
# 支出の安全追記
./tools/edit journal add --date 2026-06-20 --memo "コンビニ" --from assets:cash --to expenses:food --amount 500

# native Journalへ複数ポスティングを安全追記（符号付き金額の合計はゼロ）
./tools/edit journal multi-add --date 2026-06-20 --description "まとめ買い" \
  --posting expenses:food=800 --posting expenses:household=300 --posting assets:cash=-1100

# 既存仕訳の取消（反対仕訳を安全追記）
./tools/edit journal reverse --index 12 --date 2026-06-21
./tools/edit journal reverse --id txn-2026-06-20-super --date 2026-06-21

# 予算配賦の安全追記
./tools/edit budget add --date 2026-06-20 --memo "alloc" --from budget:unassigned --to budget:daily --amount 10000

# 予定の安全追記（plan_id は未指定なら自動生成）
./tools/edit plan add --date 2026-06-24 --memo "google-one" --from assets:smbc --to expenses:AIサブスク --amount 1450 --meta series=google-one

# current native Journal production pathはexplicit exact-integer JPYのみ
```
*   **オプション**:
    *   `--meta key=value`: 拡張列用のメタデータを指定します。
    *   `--dry-run`: 追記プレビューのみを行い、ファイルには書き込みません。
    *   `--yes`: 追記時の確認プロンプト（`y/N`）をスキップします。

### JPY→ILS exchange eventの安全追記 (`travel exchange add`)

JPYを渡してILSを受け取った事実は、expense/incomeやordinary journalではなく専用sourceへ記録します。

```bash
./tools/edit travel exchange add \
  --date 2026-07-20 --memo "synthetic airport exchange" \
  --source-account assets:bank-jpy --source-amount 10000 --source-currency JPY \
  --target-account assets:cash-ils --target-amount 250.00 --target-currency ILS \
  --exchange-id israel-2026-exchange-0001 --trip-id israel-2026 --dry-run
```

確認後は`--dry-run`を`--yes`へ替えます。両amountを保持する固定10列契約は [ISRAEL_TRAVEL_EDITOR_USAGE.md](ISRAEL_TRAVEL_EDITOR_USAGE.md) を参照してください。rate計算、journal projection、account作成は行いません。

### 友人立替pending eventの安全追記 (`travel friend add`)

Israel旅行中に友人がILSで立て替えた観測事実は、ordinary journalへ入れず専用sourceへ記録します。

```bash
./tools/edit travel friend add \
  --date 2026-07-20 --party "synthetic friend" --item "meal" \
  --amount 42.50 --currency ILS --payer friend \
  --trip-id israel-2026 --source-event-id israel-2026-friend-0001 \
  --dry-run
```

確認後は`--dry-run`を`--yes`へ替えます。固定9列契約と安全上の制限は [ISRAEL_TRAVEL_EDITOR_USAGE.md](ISRAEL_TRAVEL_EDITOR_USAGE.md) を参照してください。この入口はJPY finalizationやjournal projectionを行いません。

### Issues & Decisions の安全追記 (`issue add`)
```bash
./tools/edit issue add --date 2026-06-28 --status open --title "Amazon Prime Review" --amount 5900 --memo "Keep annual subscription or cancel?"
```
*   **オプション**:
    *   `--status`: 状態（`open` / `resolved` / `dropped`）を指定します（デフォルトは `open`）。
    *   `--title`: issue / decision の簡潔なタイトルを指定します（必須）。
    *   `--amount`: 関連する概算金額を指定します（任意、デフォルトは `0`）。
    *   `--memo`: 詳細なメモや文脈を指定します（任意）。
    *   `--dry-run`: 追記プレビューのみを行い、ファイルには書き込みません。
    *   `--yes`: 追記時の確認プロンプト（`y/N`）をスキップします。

### Issues & Decisions を閉じる (`issue close`)
```bash
./tools/edit issue list --format tsv
./tools/edit issue close --index 1 --status resolved --decision "2026-07-09 解約済み。固定支出/plan化しない。" --dry-run
./tools/edit issue close --index 1 --status resolved --decision "2026-07-09 解約済み。固定支出/plan化しない。" --yes
```

`issue close --index N` の `N` は、現在の open issue list に表示される 1-based ordinal です（物理 TSV 行番号ではありません）。`issue close` は open issue の title と元 memo を保持し、memo 末尾へ `Decision: ...` を追記したうえで `status` を `resolved` または `dropped` に変更します。直接 TSV を手編集する代わりに、preview / backup / stale check 付きの replace path を使います。Decision memo は必須で、`2026-07-09 ` のような日付だけの入力は拒否されます。

### 予定の追加 (`plan add`)
```bash
./tools/edit plan add \
  --date 2026-06-24 \
  --memo "google-one" \
  --from assets:smbc \
  --to expenses:AIサブスク \
  --amount 1450 \
  --meta series=google-one
```
*   `plan_id` は未指定なら `plan-YYYY-MM-DD-<series-or-memo-slug>` で自動生成されます。
*   `series=...` があれば memo より優先して slug に使います。
*   重複時は `-02`, `-03` のように枝番を付けます。
*   明示したい場合は `--id <plan_id>` を使います。`--meta plan_id=...` は拒否します。

### 完了済み予定と固定費封筒の同期 (`plan budget-sync`)

`plan finish` で実績化した固定費予定は、設定された execution envelope の消化候補を確認付きで同期できます。

```bash
./tools/edit plan budget-sync --id plan-2026-07-08-wifi --dry-run
./tools/edit plan budget-sync --id plan-2026-07-08-wifi
```

- BQN が `plan_id`、対応する実績行、`spend_class=fixed`、`EXECUTION_PLANNED_PAYMENTS_ENVELOPE`、budget spent sink、通貨を検査して正確な1行を生成します。
- 同じ `plan_id` の budget row が既にあれば `already applied` として成功し、重複追記しません。
- plan-finish UI は実績化後にこの同期を案内します。取消・失敗時は `BUDGET_SYNC_PENDING` と表示され、同じコマンドで再試行できます。
- memo・日付・金額の類似だけでは対応付けません。曖昧な場合は書き込みません。
- 通常収入の未割当連動はこのコマンドの対象外です。

### 予定リストの表示 (`plan list`)
```bash
# 未完了（Open）の予定のみを表示
./tools/edit plan list

# 完了（Closed）や ID欠損行も含めてすべて表示
./tools/edit plan list --all
```

### 関連予定の表示 (`plan related`)
```bash
./tools/edit plan related --id plan-2026-01-10-phone --actual-date 2026-01-12 --format tsv
./tools/edit plan related --index 1 --actual-date 2026-01-12 --format tsv
```

`plan related` は read-only の選択補助コマンドです。`series=...` → `plan_id` 由来の series → `memo/from/to/amount` 完全一致の順に関連キーを決め、`actual-date` より後の未完了予定を TSV で出力します。`tools/plan-finish-replenish-ui.sh` はこの出力を表示に使い、Bash 側では source TSV のメタデータ意味解釈を行いません。

### 予定の実績化適用 (`plan finish`)
```bash
# 1. 完了候補のプレビュー（書き込みは行われません）
./tools/edit plan finish --index 1 --actual-date 2026-06-20

# 2. 実際にジャーナルへ実績行を追記（--apply）
./tools/edit plan finish --index 1 --actual-date 2026-06-20 --apply
```
*   `--index <number>` または `--id <plan_id>` で対象予定を指定します。

### 予定の実績化 + 次回予定補充 (`tools/plan-finish-replenish-ui.sh`)
```bash
./tools/plan-finish-replenish-ui.sh
./tools/plan-finish-replenish-ui.sh --base sandbox
./tools/plan-finish-replenish-ui.sh --check
```

この補助UIは、`tools/edit plan finish` で予定を実績化したあと、必要なら `tools/edit plan add` で次回予定を追加します。低層の `plan finish` / `plan add` の TSV 契約は変更しません。

関連予定の判定は `tools/edit plan related`（BQN editor 側）が所有します。補充前には、同じ関連キーを持つ未消化の未来予定を `date` / `memo` / `from -> to` / `amount` / `plan_id` 付きで表示します。`extend` モードでは、その関連予定一覧の最新日付を基準に次回日付を提案します。関連予定がない場合は `No related active future plans found.` と表示し、fuzzy な意味推測は行いません。

### 予定の日付・金額の修正 (`plan edit`)
```bash
# 差分プレビューのみ（書き込みなし）
./tools/edit plan edit --index 1 --date 2026-07-05 --amount 3500 --dry-run

# 確認プロンプト付きで plan.tsv の対象1行だけを書き換え
./tools/edit plan edit --id plan-2026-07-01-phone --date 2026-07-05 --amount 3500
```
*   編集できるのは未完了予定の `date` と `amount` だけです。
*   `plan_id`、memo、from/to、メタ列は変更しません。
*   closed 済み予定、`plan_id` 欠損、invalid `plan_id` は拒否します。

---

## 5. BQN Editorが保証する安全書き込み機能

書き込みを伴うコマンド（`account add`、`journal add`、`journal multi-add`、`journal reverse`、`travel friend add`、`travel exchange add`、`budget add`、`plan add`、`plan finish --apply`、`plan budget-sync`、`plan edit`、`issue add`）を実行する際、BQN Editorは以下の安全機構を自動で走らせます。

1.  **事前バリデーション**: 日付フォーマット、金額が整数か、アカウント名が `<base>/accounts.tsv` に存在するか、メタデータ形式に問題がないかを書き込み前に構造検査します。
2.  **プレビューと確認**: 追記または編集される正確なTSV行を画面に出力し、ユーザーが明示的に `y` または `yes` と入力しない限り書き込みません（`--yes` 指定時を除く）。
3.  **自動バックアップ**: 置き換えを実行する直前に、対象ディレクトリ内の `.backup/YYYYMMDD-HHMMSS/<ファイル名>` にオリジナルデータを退避します。
4.  **安全な置き換え**: 追記や編集はBashスクリプト連携で安全に行い、編集中にデータが破損しないように努めます。
5.  **事後チェック (Post-write check)**: 書き込み直後に自動で確認を実行します。native Journalの既定 `--post-check lint` は `src_edit/journal_validate_cmd.bqn` でconfigured Journal parse、account registry parity、Posting IR、統合contextをfail closedに検査します。`--post-check full` は別の広い検証modeとして `./tools/check.sh` を実行します。Journal post-check失敗時は、post-write digestが一致する場合だけbackupからoriginal bytesへ自動rollbackし、後続writerが変更した場合はrollbackを拒否してrecovery-requiredを表示します。

---

## 6. 安全なテスト・動作確認手順 (Sandbox)

実データを汚すことなく、ローカルで書き込みや予定の消化テストを安全に行うには、以下のサンドボックス（一時フォルダ）を使った検証を推奨します。

```bash
# 1. テスト用の一時ディレクトリを作成し、ダミーのフィクスチャデータをコピーする
mkdir -p sandbox
cp fixtures/plan-completion/*.tsv sandbox/

# 2. --base sandbox を指定して安全に予定完了（実績化）を実行してみる
./tools/edit --base sandbox plan finish --index 1 --actual-date 2026-01-12 --apply

# 3. sandbox 内のデータが正しくアトミック更新され、Closedになったか確認する
./tools/edit --base sandbox plan list
cat sandbox/actual.journal
```

検証後の sandbox ディレクトリは、内容を確認してから手元で片付けます。

---

## 7. 開発者向け自動テストの実行

プロジェクト全体の整合性テストパイプラインで自動検証できます。

```bash
# プロジェクト全体のバリデーションを実行する場合
./tools/check.sh
```
