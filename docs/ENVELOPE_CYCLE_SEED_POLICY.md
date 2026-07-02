# Envelope cycle seed policy

状態: adopted operating policy / docs-only

この文書は、封筒予算のサイクル開始時 seed を何を基準に入れるかを固定する運用メモです。

この文書では実装変更、source TSV schema 変更、自動計算は行いません。

## 結論

サイクル開始時の seed は、サイクルの収入系を主原資にします。

```text
cycle seed
  = そのサイクルで封筒配分の原資にすると人間が決めた収入・繰越・調整
```

`type=liquid` actual closing 全額は、cycle seed の正本にはしません。

```text
cycle income / carryover / explicit adjustment
  budget:未割当 へ seed する原資。

actual liquid closing
  封筒合計が実残高に裏付けられているかを見る readonly backing diagnostic。
```

## seed に含めるもの

サイクル seed に含めてよいもの:

```text
年金
給与
臨時収入
前サイクルからの明示繰越
人間が確認した backing 差分調整
```

これらは、budget layer 上ではまず `budget:未割当` に入れます。

例:

```text
income:年金 -> budget:未割当
income:給与 -> budget:未割当
budget:opening -> budget:未割当
```

`budget:opening -> budget:未割当` は、収入そのものではなく、繰越・差分調整・初期化などを明示するための調整元として使います。

## seed にしないもの

次の値をそのまま cycle seed として扱いません。

```text
role=asset type=liquid の actual closing 全額
銀行口座残高そのもの
現金残高そのもの
予定支出控除後の可用資金
```

理由:

```text
actual closing には、前サイクル残、未実行の固定費予定、貯金・投資前の一時滞留、記録差分などが混ざる。
```

したがって、actual closing は seed の入力ではなく、seed と配分結果が実残高から浮いていないかを見る照合先です。

## 基本フロー

```text
1. サイクルの収入系を確認する。
2. 必要なら繰越・差分調整を確認する。
3. seed row として budget:未割当 に入れる。
4. 未割当から dynamic / execution envelope へ配分する。
5. backing diagnostic で actual closing と照合する。
6. MISMATCH があっても自動補正しない。
```

例:

```text
income:年金 -> budget:未割当       119846
budget:未割当 -> budget:食費       40000
budget:未割当 -> budget:タバコ     30000
budget:未割当 -> budget:固定費予定 12692
```

## execution envelope との関係

固定費、支払い予定、貯金、投資などは、サイクル中の執行待ちであれば execution envelope として確保できます。

```text
budget:未割当 -> budget:固定費予定
budget:未割当 -> budget:ゆうちょ貯金
budget:未割当 -> budget:オルカン投資
```

これらの remaining は safe-to-spend surplus ではありません。

```text
execution remaining
  まだ実行されていない確保額。
```

## backing diagnostic との関係

backing diagnostic は readonly check です。

```text
envelope_funding_base
  暫定: role=asset type=liquid actual closing

active envelope remaining
  dynamic + execution の remaining 合計

cash-backed unassigned
  envelope_funding_base - active envelope remaining

ledger unassigned
  budget:未割当 の budget layer 残高
```

この差分が 0 でない場合でも、自動で seed や配分を変更しません。

差分を調整する場合は `docs/ENVELOPE_ADJUSTMENT_ROW_POLICY.md` に従い、人間が明示的な adjustment row を入れます。

## なぜ予定支出控除後を seed にしないか

予定支出控除後の可用資金は、生活判断には有用です。

しかし、seed の正本にすると次の危険があります。

```text
plan.tsv の予定支出
execution envelope の固定費予定
可用資金計算
```

が混ざり、同じ予定支出を二重に控除する可能性があります。

そのため、予定支出は seed から直接控除せず、必要な支払い予定を execution envelope として明示的に確保します。

## 非目標

この文書では、次のことはしません。

- seed amount の自動計算を実装しない
- plan.tsv から固定費予定 envelope を自動生成しない
- `budget_pool=main` metadata を導入しない
- `type=liquid` の分類名や境界を変更しない
- 実データ TSV を移行しない

## 次に決めること

次の docs-only slice では、固定費予定を封筒に含める方式と、予定支出引当として別枠にする方式の二重計上リスクを整理します。
