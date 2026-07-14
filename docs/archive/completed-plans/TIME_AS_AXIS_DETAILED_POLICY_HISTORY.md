# 時間を座標軸として扱う設計原則

Status: current policy
Owner: report
Canonical: yes
Exit: keep as the temporal design principle until replaced by a newer time-model contract

- 状態: **今後の設計判断に適用する基幹原則**
- 制定日: 2026-06-11
- 関連:
  - `docs/ARCHITECTURE.md`
  - `docs/CANONICAL_DAILY_CUBE.md`
  - `docs/archive/completed-plans/EVENT_FIRST_PROJECTION_DRAFT_V3.md`（履歴）
  - `docs/archive/completed-plans/BEHAVIOR_DRIFT_REPORT_DECISIONS.md`（履歴）
  - `docs/archive/audits/AS_OF_SECTION_AUDIT.md`（履歴監査）
  - `docs/DAILY_TREND_TEMPORAL_SEMANTICS.md`（Daily Trend historical rows の未解決意味）

## 1. 合言葉

```text
Time is not a label.
Time is an axis.

時間はラベルではなく、座標軸である。
日付は行の飾りではなく、projection上の座標である。
```

この原則は、物理理論を家計簿へ直接持ち込むものではない。

着想として、外側から処理を進める時計と、出来事を配置する座標を分ける。家計簿では、日付順の行を集計するだけでなく、Eventを用途に応じた時間座標へ投影し、その上で残高や観察viewを作る。

## 2. 分離する時間

### 2.1 Coordinate time

Eventやprojectionが配置される時間座標。

例:

- `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` の既存`date`
- Canonical Daily Cubeの`Day`軸
- `occurred_on`: 出来事が起きた日
- `due_on`: 支払圧が現れる予定日
- `paid_on`: 現金が実際に動いた日
- `budget_on` / `belongs_to_period`: 予算上の所属を決める座標候補

同じEventが複数の時間的意味を持つ場合、1つの`date`へ無理に畳み込まない。projectionごとに使う時間属性を明示し、actualの二重計上を防ぐ。

### 2.2 Observation time

レポートをどの時点から観察するかを表す外側の時点。

現在の主な表現は`as_of`である。

```text
event coordinate: 2026-06-20
observer as_of:    2026-06-11
```

この場合、Eventはcoordinate time上の2026-06-20に存在するが、2026-06-11時点ではまだactualとして観測されない。Planやcashflow projectionとして見えるかどうかは、各viewの契約で決める。

`as_of`はEventの日付を書き換えない。projectionをどこまで観察するか、どのsnapshotを切り出すかを決める。

### 2.3 External clock time

プログラムの外側にあるOS時計。現在の実装では`date.bqn`の`Today`が、実行環境の`date +%Y-%m-%d`から日付を取得する。

```text
system clock
  ↓
system_today
  ↓ default only
as_of
```

`system_today`はCubeの座標ではない。`--as-of`が指定されなかった場合に、観察者時点`as_of`の既定値を供給する外部入力である。

設計原則:

- システム時計を計算途中で何度も直接読まない。
- レポート入口で1回取得し、明示的な`as_of`へ変換してから各計算へ渡す。
- fixture、snapshot、再現実行では`--as-of`で外部時計依存を切る。
- timezoneはEvent座標や`as_of`と別の実行環境条件として扱う。
- 日単位の家計簿で時刻精度が不要な間は、時刻列を正データへ追加しない。

現行 `src_next` では、OS時計を直接読める場所を `src_next/date.bqn` に限定する方針を `checks/check-src-next-clock-boundary.sh` で守る。通常の report path は `tools/report` → `src_next/report.bqn` → `src_next/context.bqn` を通り、cycle/as_of 境界は context/cycle 側で解決する。

`tools/add-ui.sh` などの入力UIも、新規Eventの日付候補としてsystem todayを使う場合がある。これはレポート観察時点ではなく入力支援の既定coordinateであり、同じ`today`取得でも責務を分けて考える。

### 2.4 Generation time

`generated_at`は、レポート出力を実際に生成した日時。

```text
as_of:        2026-06-11
generated_at: 2026-06-15T08:30:00+09:00
```

過去時点のレポートを後日再生成する場合、両者は一致しない。

`generated_at`は監査、キャッシュ、exportの再現性で必要になった場合に追加する。現在は未実装であり、`as_of`やEvent座標の代わりにしない。

## 3. 現在の配列モデル

Canonical Daily Cubeは次の座標空間をmaterializeする。

```text
Day × Account × Layer
```

各軸の問い:

- `Day`: いつ
- `Account`: どの口座・費目・封筒で
- `Layer`: どの意味のprojectionとして

Layer:

- `actual`: 確定した実績
- `plan`: 明示された予定Event
- `budget`: 配賦と封筒消費
- `forecast`: 将来の派生projection用。現在は全ゼロ

Cubeは重要な会計materialized viewだが、正データでも唯一の時間モデルでもない。正データTSVからEvent IRを作り、Projection Contractを通して再生成できる。

```text
LoadEvents
  ↓
Project
  ↓
MaterializeDaily
  ↓
AccumulateDaily
  ↓
Observe at as_of
```

## 4. 時間に関する責務境界

### Event date

Eventが持つ元の時間属性。既存5列の`date`は、当面そのEventの既定coordinateとして維持する。

### Projection coordinate

特定のviewがEventを配置する座標。Daily Exactは既存`date`、cashflow due viewは`due_on`を使う。

### `as_of`

観察者の時点。残高snapshot、履歴の切断、未来予定の区別に使う。

### `system_today`

OS時計から得た実行日。`as_of`の既定値を供給するだけで、EventやCubeの座標にはしない。

### `generated_at`

出力生成日時。観察対象の日付ではない。現在は未実装。

### `data_cutoff`

どこまでの入力Eventを採用したかを表す境界候補。

`as_of`は観察者時点、`data_cutoff`は入力集合の採用境界なので同一とは限らない。外部明細が遅れて届く場合や、締め済みデータだけで再計算する場合に必要性を検討する。現在は未実装。

### `last_recorded_on`

採用したjournal Eventのうち、最後に記録されているcoordinateを表す概念。

現行公開フィールドは`last_journal_date`である。現在の `src/views/plan_view.bqn` 実装は、journal行がある場合はjournal Event coordinateの最大日付を返し、空journalではfallbackとして `as_of` を返す。これは記帳状況の文脈であり、Event座標や入力期限そのものではない。将来、名前は最大coordinateであることが明確な `last_recorded_on` へ改める余地がある。

### `horizon_end`

Plan、forecast、cashflow outlookをどこまで先まで観察するかを表す将来側の境界候補。

cycle終端を使うviewもあるが、すべてのviewで同じとは限らない。現在は共通フィールドとして未実装。

### `period` / `cycle`

時間座標上の区間view。基本軸ではない。

```text
cycle = [start, end_exclusive)
```

cycleはEventの日付を変更せず、どの座標範囲を観察・集計するかを選ぶ。

### `cutoff`

単独の曖昧な名前は避ける。入力境界なら`data_cutoff`、観察時点なら`as_of`、将来範囲なら`horizon_end`のように責務を名前へ含める。

### 同時に存在できる時間

```text
occurred_on:     2026-06-20
due_on:          2026-07-27
as_of:           2026-06-11
last_recorded_on: 2026-06-09
horizon_end:     2026-08-01
generated_at:    2026-06-15T08:30:00+09:00
```

これらは互いの代替ではない。

- Eventは6月20日や7月27日のcoordinateへ配置される。
- レポートは6月11日の観察者から見る。
- 実績記録は6月9日までしかない可能性がある。
- outlookは8月1日までを見る。
- 出力自体は6月15日に再生成できる。

## 5. PlanとEnvelope

PlanとEnvelopeは同じ時間座標上に現れても、答える問いが違う。

```text
Plan:
  未来の点または区間に置かれた、具体的に意識した予定Event

Envelope:
  配賦と消費を時間方向に累積した、使用可能枠と残り枠
```

したがって、

- Planは「何を、いつ、いくら行うつもりか」を見る。
- Envelopeは「今ある資金を何に確保し、あといくら使えるか」を見る。
- 日常反復支出をPlanへすべて入力しない。
- PlanにないActualは観察viewで`actual_only`として残せる。
- 同じ意思額をPlanとEnvelopeへ毎回二重入力し始めたら、責務衝突を再評価する。

## 6. ResidualとScenario

ResidualとScenarioは、現時点ではCanonical Daily Cubeの新しい基本軸にしない。

- Residualは、同じ時間座標上のPlanとActualを選択した観察枠で比較する派生view。
- Scenarioは、Planやforecastを異なる規則で投影した派生long view候補。
- ActualをScenarioで増減させない。
- ResidualをEventへ書き戻さない。
- Residualの符号へ成功・失敗などの評価を埋め込まない。

観察枠は`day`、`week`、`cycle`などを選べるが、それらはEventを保存する基本構造ではなく時間座標上のwindowである。

## 7. ClosedとOpen

### Closed

- Actual money
- assets / liabilities
- journal balance check
- budget allocation check
- envelope balance

整数円で閉じ、再計算と検算ができることを優先する。

### Open

- Plan
- forecast
- residual
- behavior margin
- scenario
- unclassified behavior

観察のためのprojectionとして扱い、Actualへ混ぜない。分類しきれない状態を欠損や失敗として消さない。

## 8. 現在の到達点と未完了部分

実装済み:

- `Day × Account × Layer`のDense Cube
- Event IRからDaily Exact Projectionを生成
- 日次更新を時間方向に累積
- `src_next/context.bqn` で cycle/period view を構築
- `src_next/actual_snapshot.bqn` で観察日時点の actual balance snapshot を構築
- `checks/check-src-next-clock-boundary.sh` でOS時計参照境界を検査
- 同じEvent IRから section ごとの観察viewを生成

まだ統一されていない:

- すべてのレポート集計が`as_of`で一貫して切られること
- `occurred_on / due_on / paid_on / belongs_to_period`の本番契約
- future journal rowを許すか、許す場合に各sectionがどう観察するか
- Residualの期間終了前後のstatus
- Scenarioの具体的なprojection規則
- timezoneを含む`system_now` / `generated_at`契約
- 共通`data_cutoff` / `horizon_end`契約

現行 `src_next` では、section ごとの観察境界を一律に「すべて `as_of` で切られる」と説明してはいけない。cycle summary / TBDS / actual snapshot / recent rows / planned payments / actual comparison はそれぞれ入力境界と表示目的が異なる。Daily Trend historical rows の意味は `docs/DAILY_TREND_TEMPORAL_SEMANTICS.md` で未解決として明示している。現行挙動を確認する場合は、`src_next/report.bqn`、該当 section module、`docs/REPORT_CONTRACTS.md`、および `checks/check-src-next-*.sh` を正とする。

cycle の解決規則を変更する場合は、`docs/CYCLE.md` と fixture/check で互換性を確認する。

## 9. 今後の開発判断

時間に関わる変更では、実装前に次を答える。

1. この日付はEvent属性、projection coordinate、observation time、period boundaryのどれか。
2. 同じEventを別時間へ投影したとき、Actualを二重計上しないか。
3. `as_of`より未来のActual、Plan、Budget、Forecastを各viewでどう扱うか。
4. cycleや月は基本軸なのか、座標上のwindowなのか。
5. 新しい時間属性を日常の必須入力にせず導出できるか。
6. Cubeのshapeを変えず、別projectionまたはlong viewで答えられないか。
7. fixtureでEvent座標と観察時点を別々に動かして検査できるか。
8. OS時計を直接読む必要があるか、それとも入口で確定した`as_of`を渡せるか。
9. 入力の採用境界と将来観察範囲を`as_of`へ混ぜていないか。

## 10. 禁止する近道

- `date`、`as_of`、cycle終端、生成時刻を同じ変数意味で使う。
- `today`という曖昧な名前をEvent coordinate、観察時点、生成時刻のすべてに使う。
- report helperが個別にOS時計を読み、1回の出力内で基準時点を暗黙に変える。
- 未来日のjournal行を無条件に現在Actualへ含める。`journal.date > system_today` は記入ミスとしてlint/strict checkで止め、予定は `plan.tsv` に置く。
- 支払予定projectionをActual残高へ再加算する。
- cycleをEventの所属そのものとして固定し、再観察不能にする。
- ScenarioをActualへ混ぜる。
- 複数時間を扱うために既存TSVの必須列を一気に増やす。
- 時間モデルの抽象化だけを先に増やし、fixtureで説明できなくする。
