# Gemini向け指示書: 配列ビュー強化レビュー

この文書は、`bqn-ledger` の配列ビュー強化について、Geminiにレビュー・設計相談を依頼するためのブリーフです。

## 目的

現在の安定した集計核 `bal_final : 256×2` を壊さずに、合計前の中間配列を観察可能にする計画をレビューしてください。

特に次の方針が妥当か確認したいです。

```text
tx_updates : T × 256 × 2
tx_meta    : T × N
```

- `T`: 取引/予算移動の行数
- `256`: accounts.tsv由来の固定勘定科目スロット
- `2`: 残高層。列0 Actual、列1 Budget/Intent
- `tx_meta`: source、row、date、memo、from、to など、由来情報

## 最初に読んでほしいファイル

必須:

1. `docs/ARRAY_AUDIT.md`
2. `core.bqn`
3. `report_balances.bqn`
4. `report_trend.bqn`
5. `docs/ARCHITECTURE.md`

余裕があれば:

- `docs/AI_CODEMAP.md`
- `docs/REPORT_FIELD_MAP.md`
- `docs/MAIN_SECTIONS.md`
- `tools/export-balances.bqn`
- `tools/check.sh`

## 現状の要約

### 現在の核

`core.GetTxUpd` は、1取引を `256×2` の更新行列にします。

```text
列0: Actual
列1: Budget/Intent
```

`report_balances.bqn` は、取引ごとの更新行列を作ったあと、すぐ合計して `bal_final` にします。

```text
journal_upds ← GetUpd ¨ journal_rows
budget_upds ← ...
all_upds ← journal_upds ∾ budget_upds
bal_final ← +˝ > ⟨ 256‿2 ⥊ 0 ⟩ ∾ all_upds
```

### 課題

合計した瞬間に、次の情報が追いにくくなります。

- どの元行がどの勘定科目を動かしたか
- どのsource由来か
  - `journal`
  - `budget_alloc`
  - `plan-budget-move`
- どの日付にどの封筒が減ったか
- `budget:spent` の増加が、どの封筒の減少に対応するか

## 検討中の新方針

### 1. tx_updates を保持する

合計前の更新を次の形で保持します。

```text
tx_updates : T × 256 × 2
```

概念上、現在の `bal_final` は次で得られます。

```text
bal_final = +˝ tx_updates
```

つまり、既存の `bal_final : 256×2` の意味は変えず、その手前の中間配列を観察可能にします。

### 2. tx_meta を横に持つ

日付やmemoなどの由来情報は、数値配列に混ぜず、別の表として持ちます。

```text
tx_meta : T × N
```

候補列:

```text
source, row, date, memo, from, to
```

export時は、`tx_updates` の非ゼロ要素を sparse TSV にして、`tx_meta` と結合します。

想定TSV:

```tsv
source	row	date	memo	from	to	account	layer	amount
journal	12	2026-06-07	買い物	assets:smbc	expenses:食費	assets:smbc	actual	-500
journal	12	2026-06-07	買い物	assets:smbc	expenses:食費	expenses:食費	actual	500
journal	12	2026-06-07	買い物	assets:smbc	expenses:食費	budget:daily	budget	-500
journal	12	2026-06-07	買い物	assets:smbc	expenses:食費	budget:spent	budget	500
```

### 3. day_updates へ進める

`tx_meta` の日付で group し、`tx_updates` を合計して日次更新を作ります。

```text
day_updates : D × 256 × 2
```

### 4. prefix sum で day_balances を作る

`day_updates` を日付方向に prefix sum します。

```text
day_balances : D × 256 × 2
```

これにより、各日終了時点の全勘定科目・全層の残高推移を得ます。

## Geminiに確認してほしいこと

### A. 設計妥当性

1. `tx_updates : T×256×2` と `tx_meta : T×N` の分離は妥当か。
2. `bal_final = +˝ tx_updates` という関係を不変条件にしてよいか。
3. `day_updates` / `day_balances` への拡張は自然か。
4. BQNで扱いやすい形になっているか。

### B. Budget/Intentまわりの注意点

1. 予算消費開始日前の journal 由来 Intent を 0 にする現在仕様を、`tx_updates` でどう表現すべきか。
2. `budget_alloc.tsv` 由来の移動は、Actualではなく Budget/Intent 側として扱えているか。
3. `plan.tsv` に含まれる `budget:* → budget:*` 行を `plan-budget-move` source として扱う案は妥当か。
4. `budget:spent` の増加と、`budget:daily` / `budget:flex` / `budget:reserve` などの減少対応を追えるか。

### C. sparse TSV export

1. 非ゼロ更新だけを出す TSV 形式で十分か。
2. TSV列は以下で足りるか。

```text
source, row, date, memo, from, to, account, layer, amount
```

3. `row` は元ファイルの行番号にすべきか、読み込み後indexで十分か。
4. 将来の差分確認やデバッグのために追加すべき列はあるか。

### D. report_trend 置換への道筋

1. `report_trend.bqn` のどの処理が `day_updates` / `day_balances` 由来に置き換えやすいか。
2. 逆に、当面置き換えないほうがよい処理はどれか。
3. 既存レポートと並べて比較する場合、どの指標から比較すると安全か。

### E. テスト/不変条件

最低限、次を検査したいです。

```text
shape bal_final == 256×2
+˝ tx_updates == bal_final
col0 == Actual
col1 == Budget/Intent
budget_start 前の journal Intent == 0
budget_alloc は Budget/Intent 側に効く
```

追加すべき fixture / check があれば提案してください。

## やらないこと

- いきなり `bal_final` を `256×5` や `256×10` に増やさない。
- `core.GetTxUpd` の列意味を変えない。
- `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` を書き換えない。
- export結果を正データにしない。
- `report_trend.bqn` をすぐ置き換えない。まず横に作って比較する。

## 期待する回答形式

次の形で返してください。

```text
1. 総評
2. 良い点
3. 危険/曖昧な点
4. tx_updates / tx_meta の設計修正案
5. day_updates / day_balances の作り方
6. sparse TSV列へのコメント
7. report_trend置換の優先順位
8. 追加すべきテスト/fixture
9. 次に実装する最小ステップ
```

実装コードそのものより、設計レビューと落とし穴の指摘を優先してください。
