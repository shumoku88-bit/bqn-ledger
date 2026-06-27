# Fixture: multi-time-card

1つの購入Eventを、異なる時間座標へ投影するPhase 6実験です。

## 時間座標

```text
occurred_on: 購入が起き、会計Actualを更新する日
due_on:      銀行口座への支払圧を観察する日
paid_on:     実際のカード支払Eventが起きた日
```

## 口座メタ

```tsv
liabilities:card	due_day=27	due_month_offset=1	payment_account=assets:bank
```

- 通常の購入行は既存5列のまま。
- 既定の`due_on`は、購入日の翌月27日。
- 例外だけjournalメタの`due_on=YYYY-MM-DD`で上書きする。
- この規則はPhase 6 fixtureの最小実験であり、本番カードの締日規則を確定するものではない。

## 期待する投影

```text
Book
  occurred_on: 2026-01-10
  due_on:      2026-02-27 (account metaから導出)

Computer
  occurred_on: 2026-01-20
  due_on:      2026-03-05 (Event metaで上書き)

Pay card
  paid_on:     2026-02-28 (通常のActual Event)
```

cashflow due projectionは支払圧のlong viewであり、ActualやCanonical Daily Cubeを更新しない。

## 成功条件

- 購入Actualは購入日に一度だけ計上される。
- `2026-02-27`のdue projectionで銀行Actualは減らない。
- 銀行Actualは実際の支払日`2026-02-28`にだけ800減る。
- 同じEvent IRからexact daily projectionとcashflow due projectionを作れる。
- 既存Cube shapeは`Day × 256 × 4`のまま。
