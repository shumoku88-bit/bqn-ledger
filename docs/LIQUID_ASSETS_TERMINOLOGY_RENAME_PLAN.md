# 流動資産 terminology rename plan

状態: adopted / human-facing labels updated / machine keys unchanged

この文書は、bqn-ledger 内で以前「流動資産」と表示していた概念を、より正確な名前へ変更するための計画です。

現行実装では、人間向け表示は `可用資金` に統一します。内部 metadata / BQN 変数 / machine-readable key は互換性維持のため当面変更しません。

## 背景

bqn-ledger では以前、`role=asset` かつ `type=liquid` の account を「流動資産」として表示していました。

ただし、一般的な会計用語としての「流動資産 / current assets」は、現金・預金だけでなく、売掛金、棚卸資産、短期投資、前払費用などを含み得ます。

一方、bqn-ledger で見たいものは、会計上の current assets 全体ではありません。

実際に見たいものは、次の収入日やサイクル終端までの生活・支払い判断に使う資金概念です。

そのため、表示名としての「流動資産」は会計用語として少し広すぎます。

## 現在の実装上の意味

現状の `type=liquid` は、会計上の current assets ではなく、次のような意味に近いです。

```text
すぐ動かせる資金置き場
生活や支払い判断に使う前提の資金
日割り計算や outlook の基礎になる資金
```

現状の関連概念:

```text
type=liquid
liq_total
liq_daily
liq_safe_daily
liquid_assets_total
src_next_outlook_liq_total
src_next_outlook_liq_daily
```

これらは一気に変更しません。

## 採用語

```text
可用資金
```

この文書では、「流動資産」の代替表示名として `可用資金` を採用します。

`可用資金` は、日本語の一般的な会計用語として採用するものではありません。

bqn-ledger 内で `type=liquid` の残高を生活判断用に読むための project-local term として採用します。

理由:

- 会計上の current assets と混同しにくい
- 生活・支払い判断用の資金概念として定義しやすい
- 家計専用に寄りすぎない
- 造語的であるぶん、bqn-ledger 内の定義語として扱いやすい
- `usable_funds` という英語名に対応しやすい

## 採用しない候補

### 生活用資金

```text
生活用資金
```

理由:

- bqn-ledger の現在の用途にはかなり合う

ただし、正式な表示名としては採用しません。

理由は、将来の用途を家計・生活用途に寄せすぎるためです。

## 当面の方針

表示名とドキュメントでは `可用資金` を使います。

内部 metadata や machine-readable output は、すぐには変更しません。

```text
表示名:
流動資産 -> 可用資金 (implemented for human-facing report labels)

内部 metadata:
type=liquid は維持

内部変数:
liq_total, liq_daily は維持

machine-readable output:
src_next_outlook_liq_total などは維持
```

理由は、`type=liquid` や `liq_*` 系の名前は、計算、fixture、golden check、既存データに広く関係している可能性が高いからです。

## 封筒予算との関係

この用語変更は、封筒予算管理の検討と関係します。

bqn-ledger では、`type=liquid` の資金をそのまま全部自由に使うのではなく、予定支出、固定費、封筒予算、reserve などによって意味づけしていきます。

したがって、「流動資産」という名前のままだと、次のような誤解が起きやすいです。

```text
流動資産 = 全部自由に使ってよいお金
```

しかし実際には、見たいものはより細かく分かれます。

```text
type=liquid の残高
予定支出を差し引いた可用資金
封筒予算で使ってよい資金
reserve として残す資金
貯金・投資として切り離した資金
```

そのため、封筒予算の扱いを整理する前に、「流動資産」という表示名をどう扱うかを別 PR で切り出しておきます。

## 変更段階案

### Phase 1: docs-only で方針を決める

この文書で、用語変更の理由と範囲を整理します。

実装変更はしません。

### Phase 2: 人間向け表示だけ変える

実施済み:

```text
config/report_labels.tsv
```

例:

```text
流動資産 (type=liquid)
```

を、次の表示へ変更しました。

```text
可用資金 (type=liquid)
```

### Phase 3: 固定文字列の整理

BQN コード内に直接書かれている human-readable label を確認し、必要なら表示だけ変えます。

この段階でも、machine-readable key は原則維持します。

### Phase 4: machine-readable key の rename を別途検討する

将来的に、次のような rename を検討するかもしれません。

```text
src_next_outlook_liq_total
-> src_next_outlook_usable_funds_total

liquid_assets_total
-> usable_funds_total
```

ただし、これは互換性への影響が大きいため、この PR の対象外です。

## 非目標

この草案では、次のことはしません。

- `type=liquid` を変更しない
- `liq_total` などの内部変数を変更しない
- machine-readable output を変更しない
- fixture や golden check を変更しない
- 封筒予算の設計そのものを変更しない
- `可用資金` を一般的な会計用語として扱わない

## 未決定事項

- `type=liquid` の説明をどこに明記するか。
- 封筒予算レポートでは「可用資金」と「封筒残高」をどう並べるか。
- 将来 machine-readable key を rename する必要があるか。

## 暫定結論

現時点では、次の方針が安全そうです。

```text
設計文書・表示名:
可用資金

内部 metadata:
type=liquid を維持

machine-readable key:
当面維持
```

この変更は、会計用語の正確性を上げるためだけではありません。

bqn-ledger が本当に見たい「次の収入日まで使う水位」を、より誤解しにくくするための用語整理です。
