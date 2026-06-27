# Event Projection Engine 移行計画

> **Note (2026-06-26):** 旧エンジン (, , ) は削除されました。この文書内の旧エンジンへの参照は履歴として残ります。現行エンジンは  です。
- 状態: **Phase 6の最小複数時間projection実験まで完了**
- 作成日: 2026-06-10
- 方針ドラフト: `docs/EVENT_FIRST_PROJECTION_DRAFT_V3.md`

## 目的

既存の入力形式とレポート出力を維持したまま、`report_tx_updates.BuildCube` に同居している責務を次の4段階へ分離できるか検証します。

```text
Parse       : TSV → Event IR
Project     : Event IR → Projection IR
Materialize : Projection IR → Daily Cube
Accumulate  : Daily Updates → Daily Balances
```

目標は抽象化を増やすことではありません。

日付を唯一の固定次元にせず、Daily Cubeを複数のmaterialized viewの1つとして扱えるようにしながら、現行エンジン全体を説明しやすく、検査しやすくすることです。

## 現状確認

現在の `engine/report_tx_updates.bqn` は、主に次の責務を持っています。

1. `accounts.tsv` とjournal-like TSVを読み込む
2. 空フィールドを保持して行をparseする
3. account、列数、`budget:*` 境界を検証する
4. journal行をactual / budget更新へ変換する
5. budget allocationをbudget更新へ変換する
6. plan行をplan更新へ変換する
7. 最小日から最大日までのdense day axisを作る
8. 更新を `Day × Account × Layer(4)` へ配置する
9. 日次更新を累積して残高を作る
10. legacy用の `Build` / `BuildDays` も提供する

既存の次の形は、Event IRとProjection IRの原型として利用できます。

```text
tx_meta       : Eventの出典・行番号・日付・摘要・From・To
tx_updates    : Eventごとのaccount delta
cube_updates  : 日付へmaterializeしたdelta
cube_balances : 累積結果
```

ただし、現在はjournal / budget allocationとplanの生成経路が揃っておらず、`BuildCube` 内でplan更新を再生成しています。この非対称性を最初の観察対象とします。

## 守る契約

移行中も次を変更しません。

- 通常入力は既存の先頭5列
- `journal.tsv`, `plan.tsv`, `budget_alloc.tsv` が正データ
- journal-like TSVは `lib.SplitKeepEmpty` で読む
- actualは整数円
- account軸の更新はゼロサム
- `budget:*` accountはactual layerへ入れない
- planはactual残高へ影響させない
- forecast layerは未使用でもzero-safe
- `report_engine.Build` の公開フィールド
- `main.bqn` のセクションと表示
- 現行fixtureとsnapshot

## 最小IR

初期段階では汎用DSLや新しい保存形式を作りません。

### Event IR

既存TSVから実行時に作るrecordです。

**Field Contract**:

- `source`  : 出典ファイル名 (例: `"journal.tsv"`)
- `line_no` : 1ベースの行番号 (整数)
- `date`    : TSV 0列目 (日付文字列)
- `memo`    : TSV 1列目 (摘要文字列)
- `from`    : TSV 2列目 (勘定名文字列)
- `to`      : TSV 3列目 (勘定名文字列)
- `amount`  : TSV 4列目 (金額文字列、数値変換前)
- `meta`    : TSV 5列目以降の文字列リスト

制約:
...

- 保存しない
- Event IDを必須にしない
- 既存5列から生成できる
- 6列目以降は失わない

### Projection IR

Eventをaccount deltaへ変換したlongな中間表現です。

概念形:

```text
coordinate
account
layer
delta
source
line_no
projection_kind
```

初期実装では、必ずしも文字列のlong tableとして保持する必要はありません。BQNで簡潔になるなら、名前付きrecordと配列を並置します。

重要なのは、dense day axisを作る前に次を観察・検査できることです。

- どのEventが
- どの時間座標へ
- どのaccount / layerの
- いくらのdeltaとして
- どのprojection規則で出たか

## 目標パイプライン

```text
accounts.tsv + journal-like TSV
              ↓
LoadEvents / ValidateEvents
              ↓
Event IR
              ↓
ProjectDailyExact
              ↓
Projection IR
              ↓
MaterializeDaily
              ↓
cube_updates : D×256×4
              ↓
AccumulateDaily
              ↓
cube_balances : D×256×4
              ↓
既存 report_engine / reports
```

2つ目のprojectionとして、クレジットカードのcashflow予定を隔離されたfixtureで試します。

```text
Event IR
   ├─ ProjectDailyExact    → 現行互換Cube
   └─ ProjectCashflowDue  → 支払予定long view
```

`ProjectCashflowDue` はactual layerを更新しません。

## 段階計画

### Phase 0: 現行挙動の固定

目的:

リファクタリング前の出力を比較可能にします。

作業:

- **BQN集約戦略の選定**: `long projection rows -> daily cube` への変換において、`Group` などの高階関数をどう組み合わせるか、読みやすさと性能のバランスを小規模なベンチマークで確認する

完了条件:

- journal / plan / budget allocationの代表行について、入力行からcube deltaまで追跡できる
- actual / plan / budget / forecastのlayer契約がfixtureで固定される
- empty、future-only、cycle境界の既存fixtureが通る
- `./tools/check.sh` が通る

### Phase 1: Event IRの明文化と観察

目的:

現在のrows / `tx_meta`を、全入力ファイルに共通するEvent IRとして揃えます。

作業:

- Event IRのfield contractを文書化する
- journal / plan / budget allocationを同じEvent loaderから返せるか試す
- 6列目以降のmetaを保持する
- 既存のstrict validationを変えない
- 読み取り専用exportまたはcheckでEvent IRを観察可能にする

完了条件:

- 既存5列入力が変わらない
- 3入力ファイルのEventを同じfield contractで説明できる
- 既存エラーのfile / line表示が維持される
- 実データTSVを書き換えない

### Phase 2: Exact Projection IRの分離

目的:

入力行の意味解釈とdense cube化を分けます。

作業:

- journal actual projectionを純粋変換として分離する
- journal budget consumption projectionを分離する
- budget allocation projectionを分離する
- plan projectionを分離する
- **Plan合成規則の明文化**: Layer 1 (Plan) が Actual と Intent の和であることを、ソースコード上のマジックナンバーではなく投影契約として定義する
- **時間依存規則の投影化**: `budget_start_dn` による Intent 抑制を、Projection Contract の「フィルター規則」として定義する
- forecast zero projectionの扱いを固定する
- 投影結果にsource / line / projection kindを対応づける

完了条件:

- dense day axisなしでEventからdeltaを検査できる
- Eventごとのaccount軸合計がlayerごとにゼロ
- plan更新を`BuildCube`内で再parseしない
- `budget_start_dn`規則の適用箇所が1か所
- actualの`budget:*` mask規則の適用箇所が1か所

### Phase 3: Daily Materializerの分離

目的:

Projection IRをdense daily cubeへ変換する責務だけを独立させます。

作業:

- projection座標からmin / max dayを決める
- dense ordinal axisを生成する
- `coordinate × account × layer × delta`を同日で合算する
- empty projectionを `0×256×4` として扱う
- forecast zero layerを維持する

完了条件:

- MaterializerはTSVやFrom / Toを知らない
- Materializerはprojection rowsだけから `cube_updates` を作る
- 現行 `BuildCube.cube_dates`, `cube_ordinals`, `cube_updates` と完全一致する

### Phase 4: Accumulatorの分離

目的:

日次更新と累積残高を別契約にします。

作業:

- `cube_balances ← +\` cube_updates` 相当を小さな関数へ分ける
- empty cubeのshapeを固定する
- snapshot lookupとの境界を確認する

完了条件:

- AccumulatorはEventやTSVを知らない
- `cube_balances`が現行結果と完全一致する
- `report_engine`以下の変更なしで全checkが通る

### Phase 5: 現行BuildCubeの置換判断

目的:

新パイプラインが本当に単純化になったか判定します。

採用条件:

- 現行出力との完全一致を自動検査できる
- 通常入力とレポートが変わらない
- journal / plan / budgetの重複変換が減る
- 各段階のinput / output shapeを一文で説明できる
- 同じ規則の実装箇所が1つになる
- `BuildCube`が薄いorchestratorになる

撤回条件:

- 関数とIRが増えただけで条件分岐が減らない
- shape変換の追跡が現状より難しい
- 1つのEventを理解するために複数ファイルを横断する
- 既存レポートへ互換処理が漏れ出す
- Projection IRをfixtureで読み解けない

### Phase 6: 2つ目の時間projection実験

目的:

抽象化がDaily Cube専用の言い換えではないことを確認します。

対象:

- クレジットカード購入日
- 引落予定日
- 実際の引落日

制約:

- 通常入力を増やさない
- account metaから期日を導出する
- 例外だけ `due_on=...` で上書きする
- cashflow projectionはactualへ加算しない
- 現行Daily Cubeを変更しない

成功条件:

- 同じEvent IRからdaily exactとcashflow dueを生成できる
- actualの二重計上がない
- 既存reportを変更せずに新しい観察viewを追加できる

実装結果 (2026-06-11):

- `fixtures/multi-time-card`で購入日、引落予定日、実支払日を分離した。
- `engine/report_cashflow_due.bqn`でEvent IRから支払圧のlong viewを生成した。
- 通常購入行は既存5列のまま維持した。
- fixture内のカード口座メタ`due_day=27`, `due_month_offset=1`, `payment_account=assets:bank`から既定期日を導出した。
- 例外行の`due_on=...`が口座メタ由来の期日を上書きすることを確認した。
- cashflow due projectionはCanonical Daily CubeとActualを更新しない。
- `tools/check-multi-time-card.bqn`で購入日のActual、due日のActual不変、実支払日のActual、Cube shapeを検査する。

注意:

- 上記口座メタはPhase 6 fixtureの実験契約であり、本番カードの締日・支払日規則を確定するものではない。
- 汎用的な`occurred_on / due_on / paid_on / belongs_to_period`モデルはまだ実装していない。

## ファイル配置案

最初から分割数を固定しません。責務が実証できた段階でのみ分けます。

候補:

```text
report_events.bqn
report_projection.bqn
report_materialize_daily.bqn
report_tx_updates.bqn
```

ただし、最初の実験は `experimental/event_projection/` または専用fixture内で行い、現行コードへ早期統合しません。

## 検査方針

各Phaseで、次の順に証明します。

1. Event単位のprojection delta
2. 同日集約後のdaily update
3. 累積後のdaily balance
4. `as_of` snapshot
5. 既存report出力

最低限の比較対象:

- `cube_dates`
- `cube_ordinals`
- `cube_updates`
- `cube_balances`
- actual / plan / budget / forecast layer
- zero-sum
- `budget:*` actual zero
- `./tools/check.sh`

## BQNの黄色信号

次の状態になったら実装を止め、計画へ戻ります。

- rank / transpose / reshapeの連鎖が意味より先に立つ
- projectionごとに別のshape規約が必要になる
- 同じ時間選択規則を複数箇所へ書く
- longなEventを早く配列化しすぎて由来を失う
- fixtureを見ても入力Eventと出力deltaの対応が分からない

対処順:

1. Event / Projection IRをlongなまま保つ
2. 1 Eventの純粋変換へ戻す
3. 中間結果をexportして観察する
4. materialize境界を後ろへずらす
5. 複雑さが減らなければ現行BuildCubeを維持する

## 今回は行わないこと

- 実データTSVの変換
- 新しい必須入力列
- Event graph
- Elastic Meshの共通モデル
- projection DSL
- IRの永続保存
- R処理系の追加
- 既存reportの表示変更
- legacy `Build` / `BuildDays` の即時削除

## 完了の定義

この計画全体は、コードを分割しただけでは完了としません。

次をすべて満たしたときに完了です。

- 既存入力がそのまま使える
- 既存reportが同じ結果を返す
- Event → Projection → Materialize → Accumulateの各契約が文書化される
- 現行より条件分岐または重複計算が減る
- 2つ目の時間projectionを既存Cube変更なしで追加できる
- 全fixtureと`./tools/check.sh`が通る
- `docs/ARCHITECTURE.md`, `docs/AI_CODEMAP.md`, `docs/CANONICAL_DAILY_CUBE.md`が実装と同期する
