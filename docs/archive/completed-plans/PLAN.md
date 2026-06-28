# 予算（封筒/箱分け）導入プラン

## 目的
- **複式簿記（現実の帳簿）**は `journal.tsv` を Source of Truth として維持する
- それとは別に、使いすぎを防ぐための **予算レイヤ（封筒/箱分け）**を導入する
- 支払い手段（SMBC/PayPay/将来増えるカード等）が増えても、運用とコードの一貫性が崩れない形にする

## 重要な設計方針
### A. 現実の帳簿（複式簿記）
- 今まで通り
- 例: PayPayで食費を払った
  - `assets:paypay -> expenses:食費 700`

### B. 予算レイヤ（封筒/箱）
- 現実の資産口座とは独立した **`budget:*` 勘定科目**として管理する
- 予算内訳は「どの口座で払ったか」と切り離して、「何に使ったか」で減らす

> これにより、SMBCで払ってもPayPayで払っても、同じ予算箱（例: `budget:daily`）を減らせる。

## 運用ルール（実績1行 + 配賦は別ファイル + 消費は自動導出）
- 支出1件につき、`journal.tsv` には現実の支払いを **1行**だけ書く。
- 予算配賦（`budget:unassigned -> budget:*`、期首投入など）は `budget_alloc.tsv` に書く。
- レポート(`main.bqn --section outlook`)での `budget:unassigned` は、手入力値ではなく、流動資産から封筒配賦額を引いた動的残高として表示される（Asset-Based Dynamic Unassigned Budget）。

- **現実の支払い（複式簿記）**
  - `assets:* -> expenses:* amount`

予算箱の消費（`budget:<箱> -> budget:spent amount`）は、`accounts.tsv` の `budget=...` メタ情報に基づいて **BQN側で自動導出**する。

- 予算運用の開始日は `budget_alloc.tsv` に出てくる最初の日付（最小日付）で決まり、それ以前の支出は予算消費としてはカウントしない（途中開始できる）。
- 必要なら `tools/gen-budget.bqn` で `budget_journal.tsv`（互換用, 生成物/.gitignore）を書き出し可能。

例）タバコ（daily）をPayPayで500円

- `assets:paypay -> expenses:タバコ 500`

---

## 予算運用の始め方（今日から開始）
1) まず「予算レイヤに原資を入れる」行を `budget_alloc.tsv` に書く。
   - 原資は `main.bqn --section envelopes` の `seed可能額` を上限にする。
   - `seed可能額 = 流動資産 - 残り固定費予定(fixed reserve)`。
   - ここでいう fixed reserve は未払い固定費の予約控除で、封筒 `budget:reserve` とは別物。
   - 固定費・貯金・投資は封筒化しないため、daily/flex/reserve に入れるのはこの範囲内にする。

```tsv
YYYY-MM-DD	seed	budget:opening	budget:unassigned	<原資>
```

2) 次に `budget:unassigned -> budget:*` で箱に配賦する。

```tsv
YYYY-MM-DD	alloc	budget:unassigned	budget:daily	10000
YYYY-MM-DD	alloc	budget:unassigned	budget:flex	3000
YYYY-MM-DD	alloc	budget:unassigned	budget:reserve	2000
```

> ポイント: `budget_alloc.tsv` に出てくる最初の日付が「予算運用開始日」になるので、過去の支出を予算消費に含めたくない場合は、開始したい日付で seed を切る。

## 次の収入が入ったら（次サイクル）
収入が入った日に、固定費・貯金・投資を除いて封筒に回す分だけを `budget:unassigned` に追加して、同じように配賦する。

```tsv
YYYY-MM-DD	seed	budget:opening	budget:unassigned	<今期に回す金額>
YYYY-MM-DD	alloc	budget:unassigned	budget:daily	...
YYYY-MM-DD	alloc	budget:unassigned	budget:flex	...
YYYY-MM-DD	alloc	budget:unassigned	budget:reserve	...
```

## 現在の予算箱案
- `budget:daily`（食費 + タバコ + 缶コーヒー）
- `budget:flex`（日用品 + 学習 + 交通などの通常裁量枠）
- `budget:reserve`（予備・安全弁）
- `budget:opening`（予算レイヤの期首/原資の投入元）
- `budget:unassigned`（未配賦の受け皿）
- `budget:spent`（消費先の受け皿）

固定費、貯金、投資は封筒化しない。固定費は `fixed=1` / `spend_class=fixed` と `plan.tsv`、貯金・投資は資産口座として扱う。

## 設定（config）の考え方
- 別ファイルを増やさず、原則 `accounts.tsv` を設定ファイルとして扱う
- 口座の分類（流動/貯金/投資）は `accounts.tsv` の `type=liquid/savings/invest` で管理する
- expenses→予算箱の対応は `expenses:*` に `budget=...` を付けて管理する
- 支払い手段が増えたら `assets:*` を追加して `type=liquid` を付けるだけで良い

## 今後の拡張余地
- `accounts.tsv` のタグを拡張して、`expenses:*` からデフォルトの予算箱を推測する（入力の省力化）
- 収入日（起点）に `budget:unassigned` へ配賦するための補助レポート/スクリプト
