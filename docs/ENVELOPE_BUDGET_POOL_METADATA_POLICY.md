# Envelope budget_pool metadata policy

状態: adopted direction / docs-only / implementation pending

この文書は、封筒予算の backing 対象を将来 `budget_pool=main` metadata で明示する方針を固定する設計メモです。

この文書では実装変更、source TSV schema 変更、実データ変更は行いません。

## 結論

`budget_pool=main` は概念として採用します。

ただし、現時点では実装しません。

```text
short-term
  現行 fallback を維持する。

future direction
  budget_pool=main により、封筒予算の backing 対象 asset / budget account を明示する。
```

現行 fallback:

```text
envelope_funding_base
  暫定: role=asset type=liquid の actual closing balance 合計。

active envelope remaining
  暫定: role=budget kind=envelope の budget layer remaining 合計。

ledger unassigned
  role=budget kind=unassigned の budget layer remaining。
```

## 背景

現行実装では、封筒対象資金を暫定的に `role=asset type=liquid` で求めています。

これは短期運用としては十分ですが、概念としては次が混ざりやすいです。

```text
type=liquid
  生活判断に使いやすい資産分類の historical / compatibility metadata。

budget_pool=main
  封筒予算が backing 対象にする資金プール。
```

この2つは似ていますが、同じ概念ではありません。

## 将来の metadata sketch

将来導入するなら、asset 側と budget 側の両方に `budget_pool=main` を付けます。

```tsv
assets:smbc role=asset type=liquid budget_pool=main
assets:paypay role=asset type=liquid budget_pool=main
assets:ゆうちょ role=asset type=savings budget_pool=none

budget:未割当 role=budget kind=unassigned budget_pool=main
budget:食費 role=budget kind=envelope budget_pool=main
budget:固定費予定 role=budget kind=envelope budget_pool=main
budget:オルカン投資 role=budget kind=envelope budget_pool=main
```

この場合の意味:

```text
budget_pool=main asset
  封筒予算の backing 対象に含める actual asset。

budget_pool=main budget envelope
  main pool の札付き封筒として active envelope に含める budget account。

budget_pool=main unassigned
  main pool の未割当 budget account。

budget_pool=none
  backing 対象外として明示する account。
```

## 導入しない理由（短期）

今すぐ導入しない理由:

```text
実データ accounts.tsv migration が必要になる。
config/meta_schema.tsv / docs/JOURNAL_META.md 更新が必要になる。
fixture / check / BQN 実装の変更が必要になる。
現行運用は type=liquid fallback で十分に安全に回る。
```

したがって、今回の封筒設計 slice では docs-only の方向性固定に留めます。

## 将来導入時の方針

導入する場合は、次を同じ小さな変更単位で行います。

```text
1. config/meta_schema.tsv に budget_pool を追加する。
2. docs/JOURNAL_META.md に budget_pool の意味と許容値を追加する。
3. fixture accounts.tsv に budget_pool=main / none を追加する。
4. BQN 側で budget_pool を読んだ backing diagnostic を実装する。
5. missing / unknown / duplicate pool を diagnostic に出す check を追加する。
6. 実データ accounts.tsv migration は moko 確認後の別作業にする。
```

AI は、明示指示なしに実データ `accounts.tsv` へ `budget_pool` を追加しません。

## missing / unknown の扱い

短期:

```text
budget_pool 未指定
  現行 fallback を使う。
```

将来導入後:

```text
missing budget_pool
  diagnostic に出す。
  必要なら fallback を維持するが、silent にはしない。

unknown budget_pool
  fail-closed diagnostic にする。
  自動で main 扱いしない。

budget_pool=none
  backing 対象外として明示的に扱う。
```

## 複数 pool

短期では複数 pool は扱いません。

```text
supported now
  main の設計だけ。

future possible
  tax
  business
  family
  long_term
```

複数 pool が必要になった場合は、同じ Event IR から別 projection / view として設計します。既存の Canonical Daily Cube の shape や Layer 契約を利用者設定で変えません。

## 他文書との関係

- `docs/ENVELOPE_FUNDING_BASE_INVARIANT.md`
  - 封筒対象資金 / backing diagnostic の中心 invariant。
- `docs/ENVELOPE_ROLE_DESIGN.md`
  - dynamic / execution / unassigned role の方針。
- `docs/ENVELOPE_CYCLE_SEED_POLICY.md`
  - cycle seed はサイクル収入系を主原資にする方針。
- `docs/ENVELOPE_EXECUTION_AND_PLAN_POLICY.md`
  - execution envelope と plan.tsv の二重計上リスク整理。

## 非目標

この文書では、次のことはしません。

- `budget_pool=main` を実データに追加しない
- `budget_pool` を config/meta_schema.tsv に追加しない
- BQN 実装を変更しない
- fixture / check を変更しない
- 複数 pool を実装しない
- `type=liquid` を rename しない

## 暫定結論

```text
budget_pool=main は将来の明示 metadata として採用する。
今は実装しない。
現行 fallback は type=liquid / kind=envelope / kind=unassigned のまま維持する。
導入時は missing / unknown を diagnostic として見えるようにする。
```
