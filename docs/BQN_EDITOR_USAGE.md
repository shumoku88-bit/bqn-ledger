# BQN Editor & Add-UI Usage Manual

BQN-Ledgerにおける base directory 配下の元データTSV（`journal.tsv`, `plan.tsv` など）を安全に表示・編集・完了処理するための、BQN製エディタ（`tools/edit` / `tools/edit-bqn`）および日常記帳UI（`tools/add-ui.sh`）の使い方説明書です。

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

1.  **`expense` (支出)**: 資産口座から費用口座への支出（例: `assets:bank` $\rightarrow$ `expenses:food`）。`journal.tsv` に追記。
2.  **`move` (資金移動)**: 資産口座間の振替（例: `assets:bank` $\rightarrow$ `assets:cash`）。`journal.tsv` に追記。
3.  **`income` (収入)**: 収入元から資産口座への入金（例: `income:salary` $\rightarrow$ `assets:bank`）。`journal.tsv` に追記。
4.  **`budget` (予算配賦)**: 封筒への予算割り当て（例: `budget:unassigned` $\rightarrow$ `budget:daily`）。`budget_alloc.tsv` に追記。memo 候補は `config/ui_budget_memo_presets.tsv` で管理します。
5.  **`plan-add` (予定の追加)**: 未来の支払い予定を `plan.tsv` に安全追記。必要なら `series` を入力でき、`plan_id` は自動生成。
6.  **`plan-edit` (予定の日付・金額修正)**: 未完了予定を選び、`date` / `amount` だけを差分プレビュー付きで修正。
7.  **`plan-finish` (予定の実績化)**: `tools/plan-finish-replenish-ui.sh` に委譲し、`plan.tsv` で宣言された予定を完了させて実績化。`journal.tsv` に `plan_id` 付きで追記し、必要なら次回予定も追加。
8.  **`reverse` (仕訳取消)**: 既存の `journal.tsv` 行を選び、from/to を入れ替えた反対仕訳を `journal.tsv` に安全追記。
9.  **`issue` (懸案事項・意思決定の追加)**: 財務的な懸案事項や意思決定（例: サブスクリプションの見直し）を `issues.tsv` に安全追記。

---

## 3. 予定の完了（実績化）とライフサイクル

予定（Plan）の消化（`plan-finish`）は、**「予定行を plan.tsv から消さない」** という非破壊設計を採用しています。

### ライフサイクルと Closed 判定の仕組み
*   **非破壊**: 予定を実績化しても、`plan.tsv` から予定行は削除されません。予実ブレ（actual-comparison / planned-payments）の履歴として残されます。
*   **動的クローズ**: 実績 `journal.tsv` に同じ `plan_id` メタデータを持つ行が追記された時点で、BQNエンジンおよびエディタが動的に「この予定は完了（Closed）」と判定します。
*   **自動フィルタリング**: 完了した予定は、`plan list` や `tools/add-ui.sh` の未完了予定リストから自動的に非表示になります。

### 幽霊の防止（安全ゲート）
`plan.tsv` に `plan_id` が存在しない行（`Unplanned` 予定）や、`plan_id` の書式が崩れている予定は、**実績化（finish / apply）がエラーで拒否されます**。これは「完了したはずなのに予定リストに残り続けるゾンビデータ」の発生を防ぐための安全仕様です。

---

## 4. CLI コマンドリファレンス (`tools/edit`)

日常UI（`add-ui.sh`）を介さず、シェルから直接エディタ `tools/edit` を叩いて操作することも可能です。

### グローバルオプション
*   `--base <dir>`: データセットが存在する基準ディレクトリを指定します。既定は `LEDGER_DATA_DIR`、未設定なら `config/system_defaults.tsv` の `DEFAULT_BASE_DIR`（公開 repo では `data/` sandbox）です。

### ジャーナル・予算の安全追記 (`journal add` / `journal reverse` / `budget add`)
```bash
# 支出の安全追記
./tools/edit journal add --date 2026-06-20 --memo "コンビニ" --from assets:cash --to expenses:food --amount 500

# 既存仕訳の取消（反対仕訳を安全追記）
./tools/edit journal reverse --index 12 --date 2026-06-21
./tools/edit journal reverse --id txn-2026-06-20-super --date 2026-06-21

# 予算配賦の安全追記
./tools/edit budget add --date 2026-06-20 --memo "alloc" --from budget:unassigned --to budget:daily --amount 10000

# 予定の安全追記（plan_id は未指定なら自動生成）
./tools/edit plan add --date 2026-06-24 --memo "google-one" --from assets:smbc --to expenses:AIサブスク --amount 1450 --meta series=google-one
```
*   **オプション**:
    *   `--meta key=value`: 拡張列用のメタデータを指定します。
    *   `--dry-run`: 追記プレビューのみを行い、ファイルには書き込みません。
    *   `--yes`: 追記時の確認プロンプト（`y/N`）をスキップします。

### 懸案事項・意思決定の安全追記 (`issue add`)
```bash
./tools/edit issue add --date 2026-06-28 --status open --title "Amazon Prime Review" --amount 5900 --memo "Keep annual subscription or cancel?"
```
*   **オプション**:
    *   `--status`: 状態（`open` / `resolved` / `dropped`）を指定します（デフォルトは `open`）。
    *   `--title`: 懸案事項の簡潔なタイトルを指定します（必須）。
    *   `--amount`: 関連する概算金額を指定します（任意、デフォルトは `0`）。
    *   `--memo`: 詳細なメモや文脈を指定します（任意）。
    *   `--dry-run`: 追記プレビューのみを行い、ファイルには書き込みません。
    *   `--yes`: 追記時の確認プロンプト（`y/N`）をスキップします。

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

書き込みを伴うコマンド（`journal add`、`journal reverse`、`budget add`、`plan add`、`plan finish --apply`、`plan edit`、`issue add`）を実行する際、BQN Editorは以下の安全機構を自動で走らせます。

1.  **事前バリデーション**: 日付フォーマット、金額が整数か、アカウント名が `<base>/accounts.tsv` に存在するか、メタデータ形式に問題がないかを書き込み前に構造検査します。
2.  **プレビューと確認**: 追記または編集される正確なTSV行を画面に出力し、ユーザーが明示的に `y` または `yes` と入力しない限り書き込みません（`--yes` 指定時を除く）。
3.  **自動バックアップ**: 置き換えを実行する直前に、対象ディレクトリ内の `.backup/YYYYMMDD-HHMMSS/<ファイル名>` にオリジナルデータを退避します。
4.  **安全な置き換え**: 追記や編集はBashスクリプト連携で安全に行い、編集中にデータが破損しないように努めます。
5.  **事後チェック (Post-write check)**: 書き込み直後に自動で確認を実行します。既定の `--post-check lint` は `bqn src_next/report.bqn <base>` を実行し、`--post-check full` は `./tools/check.sh` を実行します。もしチェックが失敗した場合は、警告を出した上で、バックアップから戻すための案内を表示します。

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
cat sandbox/journal.tsv
```

検証後の sandbox ディレクトリは、内容を確認してから手元で片付けます。

---

## 7. 開発者向け自動テストの実行

プロジェクト全体の整合性テストパイプラインで自動検証できます。

```bash
# プロジェクト全体のバリデーションを実行する場合
./tools/check.sh
```
