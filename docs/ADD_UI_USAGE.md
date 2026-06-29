# ADD_UI_USAGE

`tools/add-ui.sh` は、日常の取引入力用UIです。

fzf / gum / 番号選択で項目を選び、最後の追記だけを Go editor (`tools/edit`) に委譲します。通常利用では Go safe append が裏で動きます。

## 基本の使い方

```sh
tools/add-ui.sh
```

画面の質問に沿って、mode / date / account / amount / memo / meta を入力します。

既存 mode を直接開始したい場合は、positional mode を渡せます。mode selector だけをスキップし、その後の入力・確認・Go editor への委譲は通常フローと同じです。

```sh
tools/add-ui.sh expense
tools/add-ui.sh income
tools/add-ui.sh plan-finish
tools/add-ui.sh reverse
```

入力画面を開く前に read-only で確認したい場合:

```sh
tools/add-ui.sh --check
```

`--check` は source TSV を書き換えません。base directory、主要 TSV、role 別 account 候補、Go editor 経路、plan list の読み取りを確認します。

## mode

| mode | 意味 | 書き込み先 | 内部コマンド |
|---|---|---|---|
| `expense` | 支出 (`assets:` → `expenses:`) | `journal.tsv` | `tools/edit journal add` |
| `move` | 資金移動 (`assets:` → `assets:`) | `journal.tsv` | `tools/edit journal add` |
| `income` | 収入 (`income:` → `assets:`) | `journal.tsv` | `tools/edit journal add` |
| `budget` | 予算配賦 (`budget:` → `budget:`) | `budget_alloc.tsv` | `tools/edit budget add` |
| `plan-add` | 予定の追加 | `plan.tsv` | `tools/edit plan add` |
| `plan-edit` | 予定の日付・金額修正 | `plan.tsv` | `tools/edit plan edit` |
| `plan-finish` | 予定の実績化 | `journal.tsv` | `tools/edit plan finish --apply` |
| `reverse` | 仕訳取消（反対仕訳追記） | `journal.tsv` | `tools/edit journal reverse` |
| `issue` | 懸案事項・意思決定の追加 | `issues.tsv` | `tools/edit issue add` |

## Go safe append で行われること

通常の `tools/add-ui.sh` は最後に `tools/edit` を呼びます。

Go editor 側では次を行います。

- preview
- confirm
- backup 作成
- stale check（読み込み後に対象ファイルが変わっていないか確認）
- atomic write
- post-check lint（既定）

そのため、確認なしに静かに追記する旧方式より安全です。

## 旧BQN backendへ一時的に戻す

問題切り分けなどで旧BQN追記を使いたい場合だけ、次のように実行します。

```sh
ADD_UI_BACKEND=bqn tools/add-ui.sh
```

通常は指定不要です。

## Go editor を直接使う例

UIを通さず、直接 append したい場合は `tools/edit` を使えます。

```sh
tools/edit journal add \
  --date 2026-06-19 \
  --memo "スーパー" \
  --from "assets:現金" \
  --to "expenses:食費" \
  --amount 1200
```

予算配賦:

```sh
tools/edit budget add \
  --date 2026-06-19 \
  --memo alloc \
  --from "budget:未配分" \
  --to "budget:食費" \
  --amount 3000
```

metadata を付ける場合:

```sh
tools/edit journal add \
  --date 2026-06-19 \
  --memo "消耗品" \
  --from "assets:現金" \
  --to "expenses:雑費" \
  --amount 500 \
  --meta tax=private \
  --meta biz=0
```

## dry-run

実際に書き込まず preview したい場合:

```sh
tools/edit journal add \
  --date 2026-06-19 \
  --memo "テスト" \
  --from "assets:現金" \
  --to "expenses:雑費" \
  --amount 1 \
  --dry-run
```

## 注意

- `journal.tsv` / `budget_alloc.tsv` は source-of-truth TSV です。
- `tools/add-ui.sh --check` は read-only preflight です。入力UIが壊れていないか先に確認できます。
- `tools/add-ui.sh <mode>` は mode selector をスキップするだけです。unknown mode は usage を表示して nonzero で終了します。
- `tools/add-ui.sh` は承認済み範囲の single-file append だけを行います。
- `plan finish --apply` は承認・実装済みです。削除や複数ファイルの一括更新は未承認（機能制限中）です。
- 現在の計画や境界は [GO_EDITOR_NEXT_PLAN.md](archive/active-plans/GO_EDITOR_NEXT_PLAN.md)、過去の設計経緯は [GO_SOURCE_TSV_EDITOR_DESIGN.md](archive/completed-plans/GO_SOURCE_TSV_EDITOR_DESIGN.md) を参照してください。
