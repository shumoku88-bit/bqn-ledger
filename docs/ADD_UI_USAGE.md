# ADD_UI_USAGE

Status: current operational guide
Owner: editor / UI
Canonical: yes
Exit: revise while `tools/add-ui.sh` remains the Command Hub action UI

通常利用は `tools/bl --base <household-root>` から始めます。`tools/add-ui.sh` は Command Hub のRecord / Plan / Budget / Account / Issue操作が開く日常入力UIです。

fzf / gum / 番号選択で項目を選び、最後の追記だけを BQN editor (`tools/edit`) に委譲します。通常利用では `tools/edit-bqn` と shell safe-write が裏で動きます。

## 基本の使い方

```sh
tools/add-ui.sh
```

画面の質問に沿って、mode / date / account / amount / memo / meta を入力します。

既存 mode を直接開始したい場合は、positional mode を渡せます。mode selector だけをスキップし、その後の入力・確認・BQN editor への委譲は通常フローと同じです。

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

`--check` は source を書き換えません。canonical Household 8ファイル、role 別 account 候補、BQN editor 経路、plan list の読み取りを確認します。

## mode

| mode | 意味 | 書き込み先 | 内部コマンド |
|---|---|---|---|
| `account-add` | Account追加 | `accounts.journal` | `tools/edit account add` |
| `expense` | 支出 (`assets:` → `expenses:`) | `actual.journal` | `tools/edit journal add` |
| `multi` | 1取引に3件以上のポスティングを入力 | `actual.journal` | `tools/edit journal multi-add` |
| `move` | 資金移動 (`assets:` → `assets:`) | `actual.journal` | `tools/edit journal add` |
| `income` | 収入 (`income:` → `assets:`) | `actual.journal` | `tools/edit journal add` |
| `budget` | Budget movement | `budget.journal` | `tools/edit budget add` |
| `plan-add` | 予定の追加 | `plan.journal` | `tools/edit plan add` |
| `plan-edit` | 予定の日付・金額修正 | `plan.journal` | `tools/edit plan edit` |
| `plan-finish` | 予定の実績化・Budget連携・任意の次回補充 | `actual.journal`, 必要時 `budget.journal` / `plan.journal` | qualified Plan workflow |
| `reverse` | 仕訳取消（反対仕訳追記） | `actual.journal` | `tools/edit journal reverse` |
| `issue` | Issues & Decisions の追加 | `issues.tsv` | `tools/edit issue add` |
| `issue-close` | Issues & Decisions を閉じる | `issues.tsv` | `tools/edit issue close` |

### 予定の実績化

`plan-finish`では最初にupcoming / overdue / allを選びます。予定候補は狭いselectorでも内容を識別しやすいよう、`内容（memo） → 予定日 → 金額 → 振替元/先`の順で表示します。

候補を選んだ後、実績日・実績金額を入力する前に、選択した予定の内容、予定日、予定金額、振替、`plan_id`、行状態、選択範囲を再表示します。期限超過予定を実績化するときも、何を選択したか確認してから入力できます。

実績化後は追記された Actual evidence が、履歴の PlanId Fulfillment routing によってEnvelopeへ観察されます。Budget execution movementの同期は行いません。次回予定を補充する場合、description・Account・amount と `recur` / `series` / `anchor` / `offset` などのschedule metadataを既定で引き継ぎ、日付だけを選べます。必要な場合だけ引き継ぎ値を変更します。

Journalへの実績追記が完了する前に `Ctrl+C` を押すと、書き込まずに `add-ui` のmode選択へ戻ります。実績追記が完了した後の `Ctrl+C` は、完了済みの実績を取り消したようには扱わず、次回予定の補充だけを中止して終了します。

### 複数ポスティングの金額

`multi` では各勘定の増減を符号付きで入力し、取引全体の合計を `0` にします。

- 費用など、残高を増やす勘定は正の金額
- SMBCや現金など、支払いによって残高が減る勘定は負の金額

たとえば費用600円と費用150円をSMBCでまとめて支払った場合は、`600`、`150`、`-750` と入力します。

## BQN editor + shell safe-write で行われること

通常の `tools/add-ui.sh` は最後に `tools/edit` を呼びます。

BQN editor 側では次を行います。

- preview
- confirm
- backup 作成
- stale check（読み込み後に対象ファイルが変わっていないか確認）
- atomic write
- post-check lint（既定）

そのため、確認なしに静かに追記する旧方式より安全です。

## BQN editor を直接使う例

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

- Budget movement の source of truth は `budget.journal` です。`budget.toml` は policy であり transaction store ではありません。
- `tools/add-ui.sh --check` は read-only preflight です。入力UIが壊れていないか先に確認できます。
- `tools/add-ui.sh <mode>` は mode selector をスキップするだけです。unknown mode は usage を表示して nonzero で終了します。
- `tools/add-ui.sh` は承認済み範囲の single-file append だけを行います。
- `plan finish --apply` は承認・実装済みです。削除や複数ファイルの一括更新は未承認（機能制限中）です。
- 現在の BQN editor の使い方は [BQN_EDITOR_USAGE.md](BQN_EDITOR_USAGE.md) を参照してください。Go editor 関連の計画・設計文書は historical として扱います。
