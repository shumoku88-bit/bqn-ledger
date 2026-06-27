# Go Source TSV Editor & Add-UI Usage Manual

BQN-Ledgerにおける元データTSV（`data/journal.tsv`, `data/plan.tsv` など）を安全に表示・編集・完了処理するための、Go製エディタ（`tools/edit`）および日常記帳UI（`tools/add-ui.sh`）の使い方説明書です。

## 1. 基本コンセプト：秤（はかり）と手袋

本プロジェクトでは、データの計算・整合性検証と、ファイル編集・入力UXの責務を以下のように分離しています。

*   **BQN = 秤（Scale）**: 正本データの読み込み、残高・封筒予算・トレンド・予実比較（actual-comparison）の集計・計算、レポート出力、および最終的な会計整合性の検証（Lint）。
*   **Go = 手袋（Gloves）**: 正本TSVファイル群の安全な読み込み、対話的な追加・編集、アトミック書き込み、同時編集の競合検知、自動バックアップ。

Goは会計エンジンとしての計算（残高や封筒の残金計算など）を行わず、データの編集と安全なファイル操作のみに特化します。

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
4.  **`budget` (予算配賦)**: 封筒への予算割り当て（例: `budget:unassigned` $\rightarrow$ `budget:daily`）。`budget_alloc.tsv` に追記。
5.  **`plan-add` (予定の追加)**: 未来の支払い予定を `plan.tsv` に安全追記。必要なら `series` を入力でき、`plan_id` はGo editorが自動生成。
6.  **`plan-edit` (予定の日付・金額修正)**: 未完了予定を選び、`date` / `amount` だけを差分プレビュー付きで修正。
7.  **`plan-finish` (予定の実績化)**: `plan.tsv` で宣言された予定を完了させて実績化。`journal.tsv` に `plan_id` 付きで追記。
8.  **`reverse` (仕訳取消)**: 既存の `journal.tsv` 行を選び、from/to を入れ替えた反対仕訳を `journal.tsv` に安全追記。

---

## 3. 予定の完了（実績化）とライフサイクル

予定（Plan）の消化（`plan-finish`）は、**「予定行を plan.tsv から消さない」** という非破壊設計を採用しています。

### ライフサイクルと Closed 判定の仕組み
*   **非破壊**: 予定を実績化しても、`plan.tsv` から予定行は削除されません。予実ブレ（actual-comparison / planned-payments）の履歴として残されます。
*   **動的クローズ**: 実績 `journal.tsv` に同じ `plan_id` メタデータを持つ行が追記された時点で、BQNエンジンおよびGoエディタが動的に「この予定は完了（Closed）」と判定します。
*   **自動フィルタリング**: 完了した予定は、`plan list` や `tools/add-ui.sh` の未完了予定リストから自動的に非表示になります。

### 幽霊の防止（安全ゲート）
`plan.tsv` に `plan_id` が存在しない行（`Unplanned` 予定）や、`plan_id` の書式が崩れている予定は、**実績化（finish / apply）がエラーで拒否されます**。これは「完了したはずなのに予定リストに残り続けるゾンビデータ」の発生を防ぐための安全仕様です。

---

## 4. CLI コマンドリファレンス (`tools/edit`)

日常UI（`add-ui.sh`）を介さず、シェルから直接Go製エディタ `tools/edit` を叩いて操作することも可能です。

### グローバルオプション
*   `--base <dir>`: データセットが存在する基準ディレクトリを指定します（デフォルトは `data`）。

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

### 予定の実績化適用 (`plan finish`)
```bash
# 1. 完了候補のプレビュー（書き込みは行われません）
./tools/edit plan finish --index 1 --actual-date 2026-06-20

# 2. 実際にジャーナルへ実績行を追記（--apply）
./tools/edit plan finish --index 1 --actual-date 2026-06-20 --apply
```
*   `--index <number>` または `--id <plan_id>` で対象予定を指定します。

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

## 5. Go Editorが保証する安全書き込み機能

書き込みを伴うコマンド（`journal add`、`journal reverse`、`budget add`、`plan add`、`plan finish --apply`、`plan edit`）を実行する際、Go Editorは以下の安全機構を自動で走らせます。

1.  **事前バリデーション**: 日付フォーマット、金額が整数か、アカウント名が `data/accounts.tsv` に存在するか、メタデータ形式に問題がないかを書き込み前に構造検査します。
2.  **プレビューと確認**: 追記または編集される正確なTSV行を画面に出力し、ユーザーが明示的に `y` または `yes` と入力しない限り書き込みません（`--yes` 指定時を除く）。
3.  **自動バックアップ**: 置き換えを実行する直前に、対象ディレクトリ内の `.backup/YYYYMMDD-HHMMSS/<ファイル名>` にオリジナルデータを退避します。
4.  **競合検知 (Stale check)**: 編集開始時から書き込みの瞬間までの間に、ファイルサイズ、更新日時、SHA-256ハッシュが他プロセス等で変更されていないかを確認し、競合があれば書き込みを拒否して元データを守ります。
5.  **アトミックな置き換え**: 一時ファイルに内容をすべて書き込んで `fsync` し、最後に `rename` して元ファイルに上書きします。書き込み途中に停電やクラッシュが起きてもデータが破損しません。
6.  **事後チェック (Post-write check)**: 書き込み直後に自動で BQN の確認を実行します。既定の `--post-check lint` は `bqn src_next/report.bqn <base>` を実行し、`--post-check full` は `./tools/check.sh` を実行します。もしチェックが失敗した場合は、警告を出した上で、バックアップからの復元コマンド（`cp ...`）を親切に提示します。

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

# 4. 検証が終わったらディレクトリごと削除してクリーンアップ
rm -rf sandbox
```

---

## 7. 開発者向け自動テストの実行

Go Editor自体の動作確認（アトミック書き込みやStale check等の堅牢性確認）は、以下のGo単体テスト、またはプロジェクト全体の整合性テストパイプラインで自動検証できます。

```bash
# Go Editor の単体テストのみを実行する場合
cd editor
rtk go test -v ./...

# プロジェクト全体のバリデーション（Goテスト含む）を実行する場合
./tools/check.sh
```
