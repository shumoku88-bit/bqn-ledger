# Spend class: 日割り分析用の支出分類

この文書は、`bqn-ledger` の **日割り推移 / 変動費分析** で使う分類ルールです。

目的は税務・会計上の分類ではなく、生活用に「日割り金額を削っているもの」を見やすくすることです。

## 基本方針

- `core.bqn` の会計計算には入れない。
- `accounts.tsv` のメタ情報と fallback ルールで分類する。
- 「使い過ぎ」と断定せず、まずは **日割り推移の材料** として出す。
- 固定費は日割り分析の原因ランキングから除外する。
- `expenses:予備` は **variable** に含める。
  - この家計簿では実質的に現金引き出し・細かい自販機等の生活支出として扱うため。

## class一覧

### `fixed`

サイクル内で予定・予約しておく固定費。

例:
- 家賃
- 光熱費
- 通信
- AIサブスク
- 借金返済
- 保険料
- サブスク

扱い:
- 日割り推移では「未払い固定費」として事前控除する候補。
- 下落日ランキングでは主原因から除外する。

### `variable`

日々の生活で日割り金額を削る主対象。

例:
- 食費
- 食費:ストック
- タバコ
- 缶コーヒー
- 日用品
- 交通
- 予備
- 学習

扱い:
- 日割り下落日ランキングの主対象。
- `expenses:予備` はここに含める。

### `saving`

流動資産から貯金・資産形成へ取り分けたもの。

例:
- `assets:* type=liquid -> assets:* type=savings`
- `assets:* type=liquid -> assets:* type=invest`

扱い:
- 流動資産は減るが、浪費ではない。
- 変動費ランキングとは別表示にする。

### `ignore`

内部移動。分析対象外。

例:
- `assets:smbc -> assets:paypay`
- `assets:paypay -> assets:smbc`

扱い:
- 流動資産合計は変わらないので日割り分析から除外。

### `other`

分類不能・未決定。

扱い:
- レポートでは別枠にして、必要なら `accounts.tsv` に `spend_class=...` を足す。

## `accounts.tsv` メタ

費用科目には必要に応じて `spend_class=...` を付ける。

例:

```tsv
expenses:食費	budget=daily	spend_class=variable
expenses:予備	budget=reserve	spend_class=variable
expenses:通信	fixed=1	spend_class=fixed
```

## fallback ルール案

明示的な `spend_class` がない場合は、日割り分析では次の順で分類する。

1. To account に `spend_class=...` がある → それを採用
2. To account に `fixed=1` がある → `fixed`
3. From/To がどちらも `type=liquid` の資産 → `ignore`
4. From が `type=liquid`、To が `type=savings|invest` → `saving`
5. To が `expenses:*` → `variable`
6. それ以外 → `other`

## 注意

- この分類は生活分析用であり、税務分類ではない。
- `tax=...` や `biz=...` などのメタとは別軸。
- 分類を変えると日割り推移・下落日ランキングの見え方が変わるため、変更時は docs と fixture/snapshot を確認する。
