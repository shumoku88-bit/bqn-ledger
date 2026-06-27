# bqn-ledger: Event-first Projection 設計調査 指示書ドラフト v3

- 状態: **採用済み (Phase 6最小複数時間実験まで完了)**
- 更新日: 2026-06-10
- 注意: 現行仕様や実装を変更する文書ではない。調査開始前に内容と範囲を再確認する。

## 目的

`bqn-ledger` を、日付を最初から固定次元とする設計から、Eventを必要な時間軸へ投影する設計へ拡張できるか調査してください。

中心思想は次の通りです。

```text
出来事が先にあり、時間軸は用途に応じて後から作られる。
Daily Cubeは正データではなく、Eventから再生成できる静的な投影である。
canonicalなのは保存されたCubeではなく、EventからCubeを作る投影契約である。
時間はラベルではなく、座標軸である。
```

時間モデルの基幹原則は`docs/TIME_AS_AXIS.md`に置きます。この文書では、Eventをどのcoordinateへ投影するかを扱います。`as_of`のような観察者時点はEvent属性と分離します。

現行の `Day × Account × Layer` は廃止しません。

日次レポート、残高、封筒予算、予定支出、検算に有効な形として維持します。ただし、システム全体を固定する中心モデルではなく、問い合わせ時に焼き固める exact view と位置づけます。

## 問題意識

現行の `BuildCube` は、`journal.tsv`、`plan.tsv`、`budget_alloc.tsv` から日付範囲を作り、次の密な配列へ投影します。

```text
Day × Account × Layer
```

Layer:

- actual
- plan
- budget
- forecast

最後に日別更新から累積残高を作ります。

この構造自体は正確で、現在のレポートに適しています。しかし、日付を最初から唯一の時間次元として固定すると、1つの出来事が持つ複数の時間を表しにくくなります。

例:

- 購入した日
- 記録した日
- 請求が確定した日
- 引き落とされる日
- 予算上で所属する期間
- 生活上の影響を観察した日

問題はDaily Cubeが静的であることではありません。

問題は、静的なDaily Cubeを唯一の中心モデルとみなし、すべての時間的意味を1つの `date` に確定させてしまうことです。

## 新しい位置づけ

正データは、引き続き人間が読めるTSVです。

当面は新しいEvent専用TSV群を導入せず、既存のjournal-like TSVの各行をEventとして解釈します。

```text
journal.tsv / plan.tsv / budget_alloc.tsv
                 │
                 └─ Event view
                      │
                      ├─ exact projection(actual time)
                      │      ↓
                      │   Daily Cube
                      │      ↓
                      │   Current Report
                      │
                      ├─ scheduled projection(cashflow time)
                      │      ↓
                      │   Payment Schedule
                      │
                      └─ other projections
                             ↓
                          Cycle / Life / Observation views
```

日付は捨てません。

Eventが持つ属性の1つとして保持し、どの時間的意味を軸にするかを投影ごとに選びます。

さらに、次を区別します。

- Event/projectionの`coordinate`: 出来事が配置される時間
- reportの`as_of`: どの時点からprojectionを観察するか
- cycle/month/week: coordinate axis上の区間view

未来のPlanがcoordinate上に存在することと、`as_of`時点でActualとして確定していることは同じではありません。

## canonical contract

次の3つを分離してください。

### 1. Source Event

人間が直接読み書きする正データです。

初期段階では、既存のjournal-like TSVの1行を1 Eventとして扱います。

```tsv
date	memo	from	to	amount
2026-06-10	本屋	liabilities:card	expenses:book	800
```

既存の5列は変更しません。

### 2. Projection Contract

Eventを、用途に応じた軸・勘定・レイヤーへ変換する規則です。

これを新しいcanonical contractとします。

投影規則には最低でも次を含めます。

- どの入力ファイルをどのlayerへ投影するか
- どの時間属性を投影軸に使うか
- From / Toをどのaccount deltaへ変換するか
- actualの二重計上をどう防ぐか
- 明示メタと自動導出のどちらを優先するか
- 投影結果が整数円・ゼロサムになる条件

### 3. Materialized View

投影結果を、用途に適した静的な形へ焼き固めた派生ビューです。

例:

- `Day × Account × Layer` Daily Cube
- cashflow日次表
- cycle別集計
- 支払予定表
- 生活観察の時系列

Materialized Viewは保存されていてもよいですが、正データにはしません。投影契約から再生成できることを条件とします。

## 入力項目を増やさない

Event-first化によって日常入力を重くしないでください。

通常入力は現在の5列のまま維持します。

```text
date  memo  from  to  amount
```

既定値は既存データと設定から自動導出します。

| 属性 | 既定の導出方法 |
|---|---|
| `event_id` | ファイル種別、行、内容などから内部生成 |
| `occurred_at` | 既存の `date` |
| `paid_on` | 現金、デビット、振込では既存の `date` |
| `belongs_to_period` | `cycle.tsv` と投影規則から導出 |
| account | 既存の From / To |
| layer | 入力ファイルと既存規則から導出 |

例外だけを6列目以降の `key=value` メタで明示できるようにします。

```tsv
2026-06-10	本屋	liabilities:card	expenses:book	800	due_on=2026-07-27
```

ただし、カード口座ごとの締日・支払日ルールから `due_on` を導出できる場合は、追加メタを要求しません。

設計原則:

```text
新しい時間属性は通常入力として要求しない。
既存データ・口座メタ・cycle設定から自動導出する。
明示メタは、自動導出では表せない例外の上書きに限定する。
```

## 複数時間

初期調査では、時間属性を増やしすぎないでください。

候補:

| time kind | 意味 | 初期扱い |
|---|---|---|
| `occurred_at` | 出来事・購入が起きた日 | 既存 `date` を使用 |
| `due_on` | 支払・請求の期日 | 口座規則から導出、例外のみメタ |
| `paid_on` | 現金が実際に動く日 | actualまたは引落イベントから確定 |
| `belongs_to_period` | 予算・生活サイクル上の所属 | cycle規則から導出 |
| `recorded_at` | 記録した時刻 | 必要性が確認できるまで保存しない |

すべてのEventにすべての時間属性を持たせる必要はありません。

## Exact Projection

会計検算用の硬い投影です。

```text
event × projection_rule
  → date × account × layer × integer_yen_delta
```

actualは、確定した整数円として扱い、必ず複式簿記的に検算できる必要があります。

現行互換のDaily Cubeは、このExact Projectionから生成します。

```text
Exact Daily Updates
        ↓
Day × Account × Layer
        ↓
Cumulative Balances
        ↓
Current Report
```

現行レポートと一致すべきもの:

- actual layerの日別更新
- actual layerの累積残高
- budget layerの配分・消化
- plan layerの予定支出
- account validation
- zero-sum invariant

## 同一Eventの複数投影

同じEventを複数の時間面へ投影しても、actualを二重計上してはいけません。

```text
購入日:     2026-06-10
引落予定日: 2026-07-27
```

用途を分けます。

```text
accounting projection:
  購入日に liabilities:card -> expenses:book 800

cashflow projection:
  引落予定日に assets:yucho の支払圧 800
```

cashflow projectionは、購入仕訳をもう一度actualへ加算するものではありません。

どのprojectionが会計残高を更新し、どのprojectionが予定・観察だけを表すかを契約で固定してください。

## 柔らかい観察ビュー

将来的には、予定、予算所属、生活ログ、不確実性などを柔らかく観察するビューを追加できます。

候補:

- 時間幅
- 確度
- 支払圧
- 不足圧
- 生活上の影響
- Event間の因果・順序

ただし、初期段階では以下を導入しません。

- `weight / margin / tension` の共通データモデル
- `events.tsv` / `event_times.tsv` / `event_links.tsv` などへの全面分割
- Event graphを正データにすること
- `event_mesh.tsv` の手入力
- R処理系の追加

これらは、具体的な問いと安定した意味が見つかった後の候補とします。

## 最小実験

初期実験は、クレジットカードの1ユースケースに限定します。

実験fixtureは`fixtures/multi-time-card`、読み取り専用projectionは`report_cashflow_due.bqn`として実装済みです。

### 目的

1つのEventが複数の時間的意味を持てることを確認しつつ、現行会計結果を変えないことを証明します。

### 対象

- 購入日
- 引落予定日
- 実際の引落日

### 実験条件

- 既存5列入力を維持する
- カード口座メタから引落予定日を導出する
- 例外時だけ `due_on=...` で上書きする
- actual accounting projectionは購入仕訳を一度だけ計上する
- cashflow projectionは支払予定を見るための派生ビューとする
- 現行Daily Cubeのactual更新・累積残高と一致する

### 成功条件

- 通常入力項目が増えない
- actualが二重計上されない
- 投影規則が小さく説明できる
- Daily Cubeを同じ結果で再生成できる
- 別の時間軸を追加しても既存Cubeのshapeや意味を変えずに済む

## 実装方針

### Phase 1: 文書化

コードを変更せず、次を明文化します。

1. 現行 `BuildCube` の入力と投影規則
2. Source Event / Projection Contract / Materialized Viewの境界
3. 既存 `date` の意味
4. actual accounting timeとcashflow timeの分離
5. 自動導出と明示メタの優先順位
6. actual二重計上を防ぐ規則
7. クレジットカード最小実験
8. 移行リスクと撤回条件

### Phase 2: 隔離された実験

現行システムを変更せず、fixtureまたは実験ディレクトリで投影器を試します。

例:

```text
experimental/event_projection/
  README.md
  accounts.tsv
  journal.tsv
  expected_exact_daily.tsv
  expected_cashflow_daily.tsv
  project_events.bqn
```

専用のEvent正データ群はまだ作りません。

### Phase 3: 現行実装との比較

実験投影器から作ったexact daily updatesと、現行 `report_tx_updates.BuildCube` の結果を比較します。

一致が証明できるまで、現行の読み込み経路やレポートを置き換えません。

## 絶対に守る制約

### actualを曖昧にしない

現実の口座残高、支出、収入は整数円で確定し、ゼロサム検査ができること。

### 正データはTSV

正データは人間が直接読める・書けるTSVであること。

### 通常入力を増やさない

Event-first化のために、日常的な必須入力欄を追加しないこと。

### 現行システムを壊さない

`journal.tsv`, `plan.tsv`, `budget_alloc.tsv` をいきなり廃止・変換しないこと。

### 日付を捨てない

日付は重要な属性として保持する。ただし、唯一の主軸として固定しないこと。

### Cubeを正データにしない

Daily Cubeは、投影契約から再生成可能な派生ビューとすること。

### 抽象化を先行させない

具体的な複数時間ユースケースで価値を証明するまで、汎用Event graphやElastic Meshを実装しないこと。

## 移行リスク

- 自動生成Event IDが行の並べ替えで不安定になる
- `date` の既存意味を変更して過去レポートとズレる
- account ruleによる期日導出が例外を隠す
- accounting projectionとcashflow projectionを混ぜて二重計上する
- 投影器が増え、どれがcanonicalか分からなくなる
- 抽象化のためのメタ情報が通常入力へ漏れ出す

調査では、各リスクに対して検査方法と撤回可能な実装境界を示してください。

## 判断基準

この方向を採用するのは、最小実験で次を確認できた場合に限ります。

- 現行レポート互換を自動検査できる
- 通常入力が増えない
- `BuildCube` の条件分岐を減らせる、または責務を明確に分離できる
- 新しい時間ビューを既存Cubeの変更なしで追加できる
- 投影規則がデータ形式より明確で、保守可能である

満たせない場合は、現行Daily Cubeを維持し、必要な時間メタだけを限定的に追加します。

## BQN実装の黄色信号

BQNの配列処理が複雑になった場合は、実装上の工夫で押し通さず、設計を見直す黄色信号とします。

特に次の状態を警戒してください。

- projectionごとに異なるshape変換や軸の並べ替えが増える
- rank、transpose、reshapeの連鎖を追わないと意味を説明できない
- Eventの意味より、配列の位置やindex規約の理解が先に必要になる
- 1つの時間ビュー追加のために既存Daily Cubeのshapeを変更する
- 同じ投影規則を複数のBQN式で重複実装する
- テストfixtureを見ても、入力Eventと出力deltaの対応が読み取れない

黄色信号が出た場合は、次の順で単純化を検討します。

1. Eventをlong tableのまま保持し、投影後だけ配列化する
2. 1つのprojectionを小さな純粋変換として分離する
3. 中間結果を名前付きrecordまたはTSVとして観察可能にする
4. Daily Cubeへ入れる前のexact daily updatesを検査境界にする
5. BQNが適さない観察処理は、別処理系への分離を再検討する

判断原則:

```text
BQNの配列処理は、投影を簡潔にするために使う。
配列を維持するためにEventの意味を曲げない。
入力から出力までを小さなfixtureで説明できなくなったら、一段戻る。
```

## この設計の合言葉

```text
Eventが先、時間軸は後。
時間はラベルではなく、座標軸である。
日付は属性であり、唯一の固定次元ではない。
Cubeは意図的に静的だが、いつでも再投影できる。
正データはEvent、canonicalなのは投影契約。
actualは硬く、観察ビューは必要に応じて柔らかくする。
```

## v2からの変更点

v2:

```text
Event graph
  ↓
Elastic mesh
  ↓
Daily cube
```

v3:

```text
Existing TSV as Events
  ↓
Canonical Projection Contract
  ↓
Purpose-specific Materialized Views
```

Elastic Meshは中心モデルから外し、将来の観察ビュー候補へ下げます。

最初に解く問題は、汎用メッシュではなく次の2点です。

```text
1つのEventを、用途ごとに異なる時間軸へ投影できること。
Daily Cubeを、正データではなく再生成可能なexact viewとして扱うこと。
```
