# Envelope funding base invariant

状態: draft / design with readonly diagnostic slice

この文書は、封筒予算が「実残高の何に対してバランスしているのか」を明示するための設計草案です。

現行実装では、最初の小さい slice として readonly の backing diagnostic を `src_next/envelope_computation.bqn` に追加しています。schema / write path / source TSV は変更しません。

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

これは、すべての資産とは限りません。

貯金、投資、長期保管資金などを封筒対象に含めるか外すかは、資産の換金可能性だけでは決めません。`type=liquid|savings|invest` の分類名や境界は未解決の別論点として残し、この文書では封筒予算がバランスすべき対象プールを別概念として定義します。

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

`type=liquid` は historical / compatibility name として当面維持します。

ただし、この文書では `type=liquid` の名前や境界を再設計しません。貯金・投資信託なども換金可能性の観点では liquid と見なせるため、`liquid|savings|invest` が本当に liquidity 分類として妥当かは未解決です。

現行実装で固定する境界は、次の一点だけです。

```text
asset classification の名前・境界
  未解決。`type=liquid` は当面互換性のため維持する。

可用資金
  現行 human-facing label。現行実装では主に `type=liquid` の実残高を表示する。

封筒対象資金 / envelope_funding_base
  封筒予算が配分対象として扱う actual asset の範囲。
  `type=liquid` 全額と決め打ちしない。
```

つまり、`type=liquid` と `budget_pool` / `envelope_funding_base` は似ていますが、同じ概念ではありません。

## 可用資金との関係

関連 PR #33 で、人間向け表示名は「流動資産」から「可用資金」に寄せました。

この文書では、それとは別に、封筒予算が何に対してバランスしているかを定義します。

概念の関係は次のように整理できます。

```text
type=liquid の実残高
  現行実装で可用資金表示の基礎になる actual asset の合計。
  ただし分類名・境界は未解決。

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
1. 流動資産という表示名の問題を整理する（#33: 可用資金）
2. `type=liquid` の分類名・境界は未解決として残す
3. 封筒対象資金の invariant を整理する
4. 必要なら実装を変える
5. 最後に machine-readable key / metadata rename を検討する
```

理由:

- 先に「流動資産」という名前のズレを整理すると、可用資金と封筒対象資金を分けやすくなる。
- 次に「封筒対象資金」を定義すると、封筒未割り当てが資産ではないことを明確にできる。
- 実装変更は、概念が固まってからでよい。

## 現行 readonly diagnostic

現行実装では、封筒セクションに次の machine-readable fields を追加しています。

```text
src_next_envelope_funding_base
src_next_envelope_allocated_total
src_next_envelope_cash_backed_unassigned
src_next_envelope_ledger_cash_delta
src_next_envelope_backing_status
src_next_envelope_funding_base_source       (repeated)
src_next_envelope_active_remaining_source  (repeated)
src_next_envelope_ledger_unassigned_source (repeated)
src_next_envelope_active_movement          (repeated)
src_next_envelope_ledger_unassigned_movement (repeated)
```

意味:

```text
envelope_funding_base
  暫定: `role=asset type=liquid` の actual closing balance 合計。

allocated_total
  active envelope remaining balance の合計。
  初期配賦額そのものではなく、支出反映後に封筒内に残っている札付き残高。

cash_backed_unassigned
  envelope_funding_base - allocated_total。

ledger_cash_delta
  cash_backed_unassigned - ledger_unassigned。

backing_status
  OK / MISMATCH / OVER_ALLOCATED / unavailable...。

*_source
  balance provenance rows. machine-readable では `name<TAB>amount` 形式で複数行出る。

*_movement
  budget-layer movement provenance rows. machine-readable では `date<TAB>source_row<TAB>account<TAB>side<TAB>delta<TAB>source_id` 形式で複数行出る。
```

status の意味:

```text
OK
  cash-backed未割当 == 予算台帳未割当。

MISMATCH
  cash-backed未割当 != 予算台帳未割当。
  readonly診断。自動補正しない。

OVER_ALLOCATED
  cash-backed未割当 < 0。
  封筒残高合計が封筒対象資金を超えている。

unavailable... / error...
  unassigned account が未定義・重複などで診断できない。
```

これは readonly 診断です。`budget_alloc.tsv` を自動補正したり、`budget:unassigned` の意味を置き換えたりはしません。

## 現行 human 表示

現行 human report は MISMATCH / OVER_ALLOCATED を追いやすいよう、式を分解して表示します。

```text
[Backing check]
  封筒対象資金(暫定:type=liquid): 81396
  active封筒残高合計:              68655
  cash-backed未割当:               12741

[Budget ledger]
  予算台帳未割当:                   4389

[Delta]
  cash-backed - ledger:              8352
  status: MISMATCH
  NOTE: readonly診断。cash-backed未割当と予算台帳未割当が一致していません。自動補正しません。

[Backing provenance]
  funding_base sources:
    assets:bank                       81396
    assets:cash                           0
  active envelope remaining:
    食費                                ...
    日用品                              ...
    固定費                              ...
    reserve                             ...
  ledger unassigned source:
    budget:unassigned                  4389

[Budget movement provenance]
  ledger unassigned movements:
    2026-.. #.. budget:未割当 credit ...
  active envelope movements:
    2026-.. #.. budget:食費   debit  ...
```

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

- source TSV / schema / write path を変更しない
- `accounts.tsv` の schema を変更しない
- `budget_alloc.tsv` の形式を変更しない
- `journal.tsv` の扱いを変更しない
- `type=liquid` を変更しない
- `type=liquid|savings|invest` の分類名・境界を決定しない
- `liq_total` などの内部変数を変更しない
- machine-readable output を変更しない
- 封筒予算の最終設計を決定しない

## 未決定事項

- 中心用語を「封筒対象資金」とするか。
- 英語内部名を `envelope_funding_base`、`budgetable_funds`、`budget_pool` のどれに寄せるか。
- `budget_pool=main` のような metadata を導入するか。
- `type=liquid|savings|invest` の分類名・境界をどう再設計するか（貯金・投資信託も換金可能性の観点では liquid と見なせるため、この文書では決めない）。
- `type=liquid` と `budget_pool` / `envelope_funding_base` の関係をどう説明するか。
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
