# Fixture: behavior-drift-comparison

Envelope viewとPlan / Actual / Residual候補を、同じActualで比較するfixtureです。

## 運用前提

- 生活管理の主役はEnvelope。
- `plan.tsv`には具体的に意識したEventだけを書く。
- 食費、タバコ、通院などの反復支出をすべてPlan入力しない。
- 学習は`budget:flex`に含める。
- 通院は独立した`budget:medical`に対応させる。
- 通院への配賦は次の収入時に行う想定なので、このfixtureの`budget_alloc.tsv`には`budget:medical`への配賦行を置かない。
- `medical`はfixture内の仮名であり、本番の科目名を確定するものではない。

## Envelope view

`2026-01-06`時点:

```text
daily    allocated 10000  spent 1800  remaining  8200
flex     allocated  5000  spent 1500  remaining  3500
reserve  allocated  2000  spent    0  remaining  2000
medical  allocated     0  spent 3000  remaining -3000
```

通院は独立Envelopeとして観察できるが、まだ配賦していないため残高は負になる。これはActualを消したりPlanへ移したりせず、「次の収入時に補充する必要がある」状態をそのまま表示する。

## Plan / Actual / Residual候補

同じサイクルを`cycle × expense account`で集計した場合の候補:

```text
account             plan  actual  residual  status
expenses:food          0    1200      1200  actual_only
expenses:tobacco       0     600       600  actual_only
expenses:learning   2000    1500      -500  both
expenses:medical       0    3000      3000  actual_only
```

この表は比較候補であり、Residualの正式な列契約やstatus名を確定するものではない。

## 確認する問い

- Envelope viewは「あといくら使えるか」を自然に説明できるか。
- 通院への配賦が0でも、独立Envelopeとして不足を観察できるか。
- 学習Actualがflexから減ることが自然か。
- Planにない通院Actualを`actual_only`候補として残すことが自然か。
- Plan / Residual候補がEnvelopeの代替ではなく補助観察として読めるか。
