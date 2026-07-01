# Envelope funding base invariant

状態: draft / discussion-only / docs-only

この文書は、封筒予算が「実残高の何に対してバランスしているのか」を明示するための設計草案です。

この PR では実装変更を行いません。

## 背景

封筒予算では、次の値が同じ「お金っぽいもの」として見えやすいです。

```text
実際の口座残高
封筒に割り当てた金額
封筒未割り当て
固定費や予定支出で拘束されている金額
可用資金
```

しかし、これらは同じ種類の値ではありません。

特に、実際の資産残高と封筒予算の配分を同じレイヤーで混ぜると、複式簿記としてのバランスや家計管理上の意味が壊れやすくなります。

## 問題意識

危ない誤解は次の形です。

```text
封筒未割り当て = 余っている資産
```

しかし、これは正確ではありません。

封筒未割り当ては資産ではなく、封筒対象資金のうち、まだ封筒に割り当てていない残りです。

資産そのものは actual journal から計算される `assets:*` 側にあります。

封筒は、その実資産に対する内部配分・拘束・札付けです。

## 目的

この文書の目的は、次の境界を明確にすることです。

```text
実資産
  実際に銀行・現金・口座などに存在する残高。

封筒対象資金
  封筒予算がバランスすべき実残高プール。

封筒配分済み
  食費、日用品、daily、flex、reserve などに割り当てた金額。

封筒未割り当て
  封筒対象資金のうち、まだどの封筒にも割り当てていない残り。
```

## 提案する中心概念

### 封筒対象資金

```text
封筒対象資金
```

英語候補:

```text
envelope_funding_base
budgetable_funds
budget_pool
```

意味:

```text
封筒予算が配分対象として扱う actual asset balance の合計。
```

これは、すべての資産ではありません。

貯金、投資、長期保管資金などは封筒対象から外れることがあります。

## 中心 invariant

封筒予算の中心 invariant は次の形です。

```text
封筒配分済み + 封筒未割り当て = 封筒対象資金
```

より細かく書くと、次のようになります。

```text
allocated_envelopes_total
+ unassigned_envelope_funds
= envelope_funding_base
```

この invariant により、封筒予算が実残高から浮いた「別のお金」にならないようにします。

## 重要な区別

### 実残高

実残高は actual journal から導かれます。

```text
assets:bank
assets:cash
assets:wallet
```

などの account balance です。

これは複式簿記上の資産です。

### 封筒配分

封筒配分は、実資産の内部的な使途配分です。

```text
budget:food
budget:daily
budget:flex
budget:reserve
```

これは資産そのものではありません。

### 封筒未割り当て

封筒未割り当ては、封筒対象資金のうち、まだ使途ラベルが貼られていない部分です。

```text
unassigned = envelope_funding_base - allocated_envelopes_total
```

これは資産ではなく、予算配分の残りです。

## account metadata 案

将来、封筒対象資金を account metadata で表すなら、次のような形が考えられます。

```tsv
assets:bank	role=asset	type=liquid	budget_pool=main
assets:cash	role=asset	type=liquid	budget_pool=main
assets:savings	role=asset	type=savings	budget_pool=none
assets:investment	role=asset	type=invest	budget_pool=none
```

budget 側は次のような形が考えられます。

```tsv
budget:food	role=budget	budget_pool=main	kind=envelope
budget:daily	role=budget	budget_pool=main	kind=envelope
budget:flex	role=budget	budget_pool=main	kind=envelope
budget:reserve	role=budget	budget_pool=main	kind=reserve
budget:unassigned	role=budget	budget_pool=main	kind=unassigned
```

この metadata 案は未決定です。

この PR では実装しません。

## `type=liquid` との関係

`type=liquid` は「すぐ動かせる資金置き場」を表す分類として当面維持します。

ただし、`type=liquid` のすべてが必ず封筒対象資金になるとは限りません。

将来的には、次のような違いを明確にする必要があります。

```text
type=liquid
  すぐ動かせる actual asset の分類。

budget_pool=main
  封筒予算が配分対象として扱う actual asset の範囲。
```

つまり、`type=liquid` と `budget_pool` は似ていますが、同じ概念ではありません。

## 可用資金との関係

関連 PR では、「流動資産」という表示名を「可用資金」または「使える資金」に変えることを検討しています。

この文書では、それとは別に、封筒予算が何に対してバランスしているかを定義します。

概念の関係は次のように整理できます。

```text
type=liquid の実残高
  すぐ動かせる actual asset の合計。

封筒対象資金
  封筒予算が配分対象にする actual asset の合計。

封筒配分済み
  封筒対象資金のうち、目的別に割り当てた金額。

封筒未割り当て
  封筒対象資金のうち、まだ割り当てていない残り。

可用資金
  予定支出、固定費、reserve、サイクル残日数などを見た生活判断用の値。
```

## 推奨される進行順

この設計は、用語変更 PR と前後関係があります。

推奨される順番は次の通りです。

```text
1. 流動資産という表示名の問題を整理する
2. 封筒対象資金の invariant を整理する
3. 表示名や docs を変える
4. 必要なら実装を変える
5. 最後に machine-readable key の rename を検討する
```

理由:

- 先に「流動資産」という名前のズレを整理すると、可用資金と封筒対象資金を分けやすくなる。
- 次に「封筒対象資金」を定義すると、封筒未割り当てが資産ではないことを明確にできる。
- 実装変更は、概念が固まってからでよい。

## あり得るレポート表示

将来的には、次のような表示が考えられます。

```text
[Actual assets]
  liquid funds                50,000
  savings                     20,000
  investment                   3,000

[Envelope funding]
  envelope funding base       50,000
  allocated envelopes         35,000
  unassigned                  15,000
  check                            OK

[Outlook]
  usable funds                28,000
  days left                       14
  usable / day                 2,000
```

この表示案は未決定です。

## 非目標

この文書では、次のことはしません。

- 実装を変更しない
- `accounts.tsv` の schema を変更しない
- `budget_alloc.tsv` の形式を変更しない
- `journal.tsv` の扱いを変更しない
- `type=liquid` を変更しない
- `liq_total` などの内部変数を変更しない
- machine-readable output を変更しない
- 封筒予算の最終設計を決定しない

## 未決定事項

- 中心用語を「封筒対象資金」とするか。
- 英語内部名を `envelope_funding_base`、`budgetable_funds`、`budget_pool` のどれに寄せるか。
- `budget_pool=main` のような metadata を導入するか。
- `type=liquid` と `budget_pool` の関係をどう説明するか。
- 封筒未割り当てを account として表すか、計算結果としてのみ表すか。
- 複数 budget pool を将来許容するか。
- report label と machine-readable key をいつ変更するか。

## 暫定結論

現時点では、次の考え方が安全そうです。

```text
実残高は actual asset として扱う。
封筒配分は actual asset の内部配分として扱う。
封筒未割り当ては資産ではなく、配分残として扱う。
封筒配分済み + 封筒未割り当て = 封筒対象資金、という invariant を持つ。
```

これは、封筒予算を複式簿記の実残高から浮かせないための安全柵です。
