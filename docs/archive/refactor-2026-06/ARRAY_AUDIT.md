# ARRAY_AUDIT: 256×2 配列核の現状監査

この文書は、BQN家計簿の配列構造を壊さず育てるための観察メモです。

目的は、いま安定している `256×2` の集計核を固定しつつ、将来追加したい「取引軸」「日付軸」「封筒軸」の派生ビューを整理することです。

---

## 現在地

ここまでで、配列ビュー強化は Stage 3 の入口まで進んでいます。

完了済み:

- `tx_updates : T×256×2`
- `tx_meta`
- `tools/export-tx-updates.bqn`
- `day_updates : D×256×2`
- `day_balances : D×256×2`
- `tools/export-day-balances.bqn`
- `tools/check-tx-updates.bqn`
- `tools/check-trend-liquid.bqn`
- `tools/check-tx-updates.bqn` の zero-sum / budget closed 検査
- `tools/export-envelope-flow.bqn` の `budget:unassigned` 特別封筒対応
- `tools/export-envelope-flow.bqn` の `spent_day_journal` / `transferred_day` 分離
- `report_trend.bqn` の `LiquidAtDn` を `day_balances` 由来に置換
- `report_trend.bqn` の `variable` / `saving` / `fixed_paid` を `day_updates` 由来に置換

現在の段階:

- Stage 2.5 は完了。
- Stage 3 として、封筒専用の観察ビュー `envelope_flow` を作り始めたところ。
- ただし `report_balances.bqn` と `report_tx_updates.bqn` の統合や、`budget:*` の Actual列整理はまだ行わない。

Gemini Stage 3レビュー後の優先順位:

1. 統合タイミングで、`budget:*` の Actual列を `report_tx_updates` 側で一括マスクする。
2. `report_balances.bqn` を `tx_updates` を受け取る集約器へ寄せる。

---

## 現在の安定した核

### 形

```text
bal_final : 256×2
```

- 256: `accounts.tsv` 由来の固定スロット勘定科目空間
- 2: 残高の層

### 列の意味

```text
列0: Actual
列1: Budget/Intent
```

- **Actual** は現実の資産・収入・支出の流れ。
- **Budget/Intent** は封筒・予算意図の流れ。

この2層構造は現在の重要な不変条件です。

---

## 現在の流れ

`core.GetTxUpd` は、1取引を `256×2` の更新行列に展開します。

```text
取引 → 256×2 update
```

`report_balances.Build` は、実績行と予算移動行から更新行列を作り、それらを合計して最終残高を得ます。

```text
journal_rows / budget_alloc_rows / budget plan moves
  → 取引ごとの 256×2 update
  → 合計
  → bal_final : 256×2
```

おおまかな実装上の流れ:

```text
journal_upds ← GetUpd ¨ journal_rows
budget_upds ← ...
all_upds ← journal_upds ∾ budget_upds
bal_final ← +˝ > ⟨ 256‿2 ⥊ 0 ⟩ ∾ all_upds
```

---

## 良いところ

- `Actual` と `Budget/Intent` が列で分離されている。
- `core.bqn` の低レベル会計計算がシンプルに保たれている。
- `report_balances.bqn` が `bal_final` の生成責務を集中して持っている。
- `bal_final` は、`main.bqn`・summary・export から使いやすい最終形になっている。
- 予算消費開始日より前は Intent 側をゼロにする設計により、途中導入が許されている。

---

## もったいないところ

現在は、取引ごとの `256×2` 更新行列をすぐに合計してしまいます。

そのため、次の中間形を直接観察しづらいです。

- `tx_updates`: 取引ごとの更新
- `day_updates`: 日付ごとの更新
- `envelope_flow`: 封筒ごとの時間推移
- `cycle × envelope`: サイクル内で封筒がどう動いたか

いまの形は安全ですが、時間軸・封筒軸の呼吸が見えにくい状態です。

### pit視点の追加評価

さらに勿体ないのは、合計時に「由来」が消えることです。

取引を更新行列へ展開する瞬間には、次の情報を持っています。

- source: `journal` / `budget_alloc` / `plan-budget-move` など
- row: 元TSV内の行番号または処理上の行index
- date
- memo
- from / to
- amount

しかし `bal_final` に合計した後は、どの行がどの勘定・どの層を動かしたかを追いにくくなります。

また、`budget:spent` は消費の受け皿として便利ですが、合計後の `budget:spent` だけを見ると、どの封筒から消費されたかが薄くなります。`tx_updates` / `day_updates` では、`budget:daily` などの負側更新と `budget:spent` の正側更新を両方残すことが重要です。

内部表現は dense な `256×2` のままでよい一方、人間が観察する export はゼロを省いた sparse / coordinate form が向いています。

```text
source × row × date × account × layer × amount
```

この形にすると、BQN内部の配列核と、人間が読むTSVの橋が強くなります。

---

## 将来作る派生ビュー

### 1. tx_updates

```text
tx_updates : T × 256 × 2
```

- T: 取引/予算移動の行数
- 256: 勘定科目スロット
- 2: Actual / Budget(Intent)

あわせて、配列本体とは別に `tx_meta` を持ちます。

```text
tx_meta : T × N
```

`tx_meta` には、日付・source・元行番号・memo・from・to など、配列の由来を追うための情報を置きます。

目的:

- 合計前の取引単位の更新を観察する。
- `core.GetTxUpd` の結果を、人間が確認できる TSV に橋渡しする。

想定TSV:

```tsv
source	row	date	memo	from	to	account	layer	amount
journal	12	2026-06-07	買い物	assets:smbc	expenses:食費	assets:smbc	actual	-500
journal	12	2026-06-07	買い物	assets:smbc	expenses:食費	expenses:食費	actual	500
journal	12	2026-06-07	買い物	assets:smbc	expenses:食費	budget:daily	budget	-500
journal	12	2026-06-07	買い物	assets:smbc	expenses:食費	budget:spent	budget	500
```

方針:

- 内部更新行列は dense な `256×2` のままにする。
- export は非ゼロ更新だけを出す sparse TSV にする。
- `source` と `row` を出して、合計後に消える由来を追跡できるようにする。

最初は `tools/export-tx-updates.bqn` のような観察用ツールとして作り、既存レポートの核には入れないのが安全です。

### 2. day_updates

```text
day_updates : 日付数 × 256 × 2
```

目的:

- 日付ごとに Actual / Budget の変化を見る。
- daily / flex / reserve / spent の増減を日単位で確認する。
- `report_trend.bqn` の個別集計を、将来的に配列由来の集計へ置き換える土台にする。

### 3. envelope_flow

```text
envelope_flow : date × envelope view
```

想定TSV:

```tsv
date	envelope	allocated	spent	remaining	daily_amount
2026-06-07	daily	10000	1200	8800	800
2026-06-07	flex	3000	500	2500	227
2026-06-07	reserve	2000	0	2000	181
```

目的:

- `budget:daily` / `budget:flex` / `budget:reserve` を増やすのではなく、見え方を増やす。
- 封筒残高、今日までの消費、前日との差、残日数での日割りを同じレンズで見る。

### 4. cycle × envelope

```text
cycle_envelope_flow : サイクル × 封筒 × 層/指標
```

目的:

- 収入サイクル内で封筒がどう減るかを見る。
- 次の収入日までの安心材料を作る。

---

## BQNらしい実装ヒント

### 3次元配列として保持する

現在の最終形は `256×2` ですが、中間形を次のように残すと、BQNが得意な一括処理に寄せられます。

```text
tx_updates : T × 256 × 2
```

このとき、`bal_final` は `tx_updates` を取引軸 T で合計したものです。

```text
bal_final = +˝ tx_updates  # 概念上
```

つまり、`bal_final` の意味を変えずに、その手前の「映画フィルム」を保持する形です。

### meta は配列本体と分けて持つ

日付・source・行番号・memo などは、数値行列に無理に混ぜず、別の `tx_meta` として持ちます。

```text
tx_updates : T × 256 × 2
tx_meta    : T × N
```

これにより、数値計算は配列で速く保ち、デバッグやexportでは meta と結合できます。

### group と prefix sum を使う

`tx_updates` があれば、主な派生ビューは配列操作で作れます。

```text
日次集計: tx_meta の date で group して合計 → day_updates
残高推移: day_updates を日付方向に prefix sum → day_balances
カテゴリ集計: 勘定科目maskで slice / filter して合計
```

`report_trend.bqn` のように、目的別に元データを何度もすくい直す処理を、将来的にはこの流れへ寄せられます。

---

## 壊してはいけない不変条件

- `bal_final` は当面 `256×2` のままにする。
- 列0は `Actual`、列1は `Budget/Intent` のままにする。
- `core.GetTxUpd` の返す形を表示都合で変えない。
- `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` を派生ビューのために書き換えない。
- journal-like TSV の先頭5列を変えない。
- export や観察ツールの出力を正データにしない。
- いきなり `256×5` や `256×10` に層を増やさない。

---

## 立て直した段階的計画

### Stage 0: 配列核の不変条件を固定する

`bal_final : 256×2` と、列0 Actual / 列1 Budget/Intent を守ります。

できれば fixture / check で次を確認できるようにします。

- `bal_final` は必ず `256×2`
- 列0は Actual
- 列1は Budget/Intent
- 予算開始日前の journal 由来 Intent は 0
- `budget_alloc.tsv` 由来の移動は Budget/Intent 側に効く

### Stage 1: 合計前の tx_updates を観察可能にする

最優先の実装候補です。

```text
取引行 → 256×2 update → T×256×2 tx_updates → 非ゼロ更新TSV
```

配列本体は `tx_updates : T×256×2` として保持し、由来情報は `tx_meta : T×N` として横に持ちます。

まずは `report_tx_updates.bqn` と `tools/export-tx-updates.bqn` として、既存レポートから独立した read-only 観察レイヤを作ります。

実装メモ:

- `report_tx_updates.bqn` が `tx_updates` / `tx_meta` / tx由来 `bal_final` を作る。
- `tools/export-tx-updates.bqn` が非ゼロ更新だけを sparse TSV として出す。
- `tools/check-tx-updates.bqn` が tx由来 `bal_final` と既存 `report_engine.Build.bal_final` の一致を確認する。

補足:

現在の `core.GetTxUpd` は、`from` / `to` の科目種別に関係なく、まず Actual列にも更新を作ります。そのため、`budget:* → budget:*` の予算移動行は、`export-tx-updates` 上では `actual` 層にも `budget` 層にも現れます。

これは新実装で増えた挙動ではなく、既存の `bal_final` に含まれていた更新が見えるようになったものです。現段階では `+˝ tx_updates == bal_final` を優先し、表示上の違和感がある場合もすぐには削らず、将来「budget科目のActual列を仕様としてどう扱うか」を別途検討します。

重要な列:

```text
source, row, date, memo, from, to, account, layer, amount
```

### Stage 2: day_updates を作る

`tx_updates` を日付で畳みます。

```text
day_updates : D × 256 × 2
```

- D: 日付数

Geminiレビューでは、group key は文字列日付より `DateToNum` の数値日付を推奨しています。BQN の grade / group と相性が良く、時系列順に扱いやすくなるためです。

```text
tx_meta.date → DateToNum → group → +˝ → day_updates
```

これにより、日ごとの Actual / Budget 変化、封筒減少、`budget:spent` 増加を同じ土台で観察します。

### Stage 2.5: prefix sum で残高推移を作る

`day_updates` ができたら、日付方向に prefix sum します。

```text
day_balances : D × 256 × 2
```

これにより、各日終了時点の全勘定科目・全層の残高推移を、ループではなく配列操作で得られます。

実装メモ:

- `report_tx_updates.BuildDays` が `day_updates` と `day_balances` を返す。
- `tools/export-day-balances.bqn` が累積残高を `date\taccount\tactual\tbudget` で出す。
- `tools/check-tx-updates.bqn` が最終日の `day_balances`、assets_total、liquid total を既存 `report_engine.Build` と比較する。
- `tools/check-tx-updates.bqn` が `tx_updates` の勘定科目軸合計（layerごと）が 0 であることを確認する。
- `tools/check-tx-updates.bqn` が各日の `budget:*` Intent 合計が 0 であることを確認する。

追加の不変条件:

```text
¯1 ⊑ day_balances == bal_final
```

比較の最優先指標は `report_trend.bqn` の `trend_liquid` です。`day_balances` から liquid 科目をスライスして合計した値が `trend_liquid` と一致すれば、配列基盤への移行はかなり安全になります。

`tools/check-trend-liquid.bqn` は、この比較を行うための橋渡しツールです。`trend_dates` に取引のない `as_of` 日が含まれる場合は、その日以前の最新 `day_balances` を使って liquid 合計を比較します。

この比較が通ったため、`report_trend.bqn` の `LiquidAtDn` は `day_balances` 由来に置き換え済みです。変動費・貯蓄/投資移動・支払い済み固定費も `day_updates` 由来に置き換え済みです。固定費予約は、未払い予定の見積もりを含むため、引き続き journal/plan 行ベースで計算します。

### Stage 3: envelope_flow を作る

`day_updates` から封筒専用ビューを作ります。

```text
date × envelope × allocated/spent/remaining/daily_amount
```

`budget:daily` / `budget:flex` / `budget:reserve` という封筒数を増やすのではなく、見え方を増やします。

最小実装として `tools/export-envelope-flow.bqn` を追加します。

初期TSV:

```tsv
date	envelope	allocated_day	spent_day_journal	transferred_day	balance	daily_change
2026-01-04	food	0	1200	0	8800	-1200
```

実装方針:

- `report_tx_updates.BuildDays` の `day_updates` / `day_balances` を使う。
- 対象は `budget:*` のうち、通常封筒と特別封筒 `budget:unassigned`。
- `budget:opening` / `budget:spent` は除外する。
- `balance` は `day_balances` の Budget/Intent列。
- `daily_change` は `day_updates` の Budget/Intent列。
- `spent_day_journal` は `tx_meta.source="journal"` 由来の封筒減少を正値にしたもの。
- `transferred_day` は `budget_alloc` / `plan-budget-move` 由来の封筒純移動。
- `allocated_day` は正の `transferred_day`。

注意:

`spent_day_journal` と `transferred_day` を分けたことで、純粋な journal 由来消費と、配賦・封筒間移動の純額を別々に観察できます。将来、封筒間移動が増えたら `transferred_in_day` / `transferred_out_day` のような gross 表示を追加できます。

### Stage 4: report_trend を少しずつ置き換える

`report_trend.bqn` の個別集計をすぐ消さず、配列由来ビューと並べて比較します。

数字が一致した部分だけ、段階的に置き換えます。

新しい配列ビューは、まず既存レポートの横に作ります。

```text
新しい配列ビューを作る
↓
既存レポートと並べて比較する
↓
数字が一致するか見る
↓
一致した部分だけ置き換える
```

家計簿は生活の床板なので、床を抜きながら踊らないこと。
