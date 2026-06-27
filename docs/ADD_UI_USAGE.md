# ADD_UI_USAGE

`tools/add-ui.sh` は、日常の取引入力用UIです。

fzf / gum / 番号選択で項目を選び、最後の追記だけを Go editor (`tools/edit`) に委譲します。通常利用では Go safe append が裏で動きます。

## 基本の使い方

```sh
tools/add-ui.sh
```

画面の質問に沿って、mode / date / account / amount / memo / meta を入力します。

## mode

| mode | 意味 | 書き込み先 | 内部コマンド |
|---|---|---|---|
| `expense` | 支出 (`assets:` → `expenses:`) | `journal.tsv` | `tools/edit journal add` |
| `move` | 資金移動 (`assets:` → `assets:`) | `journal.tsv` | `tools/edit journal add` |
| `income` | 収入 (`income:` → `assets:`) | `journal.tsv` | `tools/edit journal add` |
| `budget` | 予算配賦 (`budget:` → `budget:`) | `budget_alloc.tsv` | `tools/edit budget add` |

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
- `tools/add-ui.sh` は承認済み範囲の single-file append だけを行います。
- `plan finish apply`、削除、複数ファイル更新はまだ未承認です。
- 詳細設計は `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md` を参照してください。
