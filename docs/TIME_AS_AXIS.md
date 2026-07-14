# 時間を座標軸として扱う設計原則

Status: current policy
Owner: report
Canonical: yes
Exit: keep until replaced by a newer time-model contract

## Purpose

時間を単なる表示ラベルとして扱わず、Eventとprojectionを配置する座標として扱う。

```text
Time is not a label.
Time is an axis.

時間はラベルではなく、座標軸である。
```

この文書は時間モデルの共通原則だけを所有する。section固有の現在の挙動は次を読む。

- Daily Trend: `docs/DAILY_TREND_TEMPORAL_CURRENT.md`
- Outlook: `docs/OUTLOOK_TEMPORAL_CURRENT.md`
- report全体の入口: `docs/REPORT_CONTRACTS.md`

以前の詳細なpolicy snapshotは次へ保存している。

- `docs/archive/completed-plans/TIME_AS_AXIS_DETAILED_POLICY_HISTORY.md`

## 1. 分離する時間の役割

| 役割 | 記号・例 | 意味 |
|---|---|---|
| Event / projection coordinate | `D`, `date`, `occurred_on`, `due_on`, `paid_on` | 出来事やprojectionが置かれる座標 |
| Observation time | `O`, `as_of` | どの時点からprojectionを観察するか |
| External clock input | `system_today` | OS時計から一度だけ取得し、既定の観察時点や入力候補を供給する |
| Generation time | `generated_at` | 出力を生成した日時。観察対象の日付ではない |
| Input frontier | `L`, `last_recorded_on` | 採用した記録の局所的な最終coordinate |
| Input cutoff | `data_cutoff` | どこまでの入力Eventを採用したか |
| Future horizon | `horizon_end` | 将来projectionをどこまで観察するか |
| Period window | `cycle = [start, end_exclusive)` | 座標軸上の観察・集計window |
| Historical knowledge boundary | `K` | その時点で何が既知だったか。現在のDaily Trendでは未実装 |

これらは互いの代替ではない。

```text
Event coordinate != observation time
observation time != generation time
input frontier != historical knowledge boundary
cycle boundary != Event ownership
```

同じEventが複数の時間的意味を持つ場合、1つの曖昧な`date`へ無理に畳み込まない。projectionごとに使用する時間属性を明示し、actualの二重計上を防ぐ。

## 2. 現在の配列モデル

Canonical Daily Cubeは次の座標空間をmaterializeする。

```text
Day × Account × Layer
```

- `Day`: projection coordinate
- `Account`: 口座・費目・封筒
- `Layer`: `actual / plan / budget / forecast`

Cubeは重要なmaterialized viewだが、正データでも唯一の時間モデルでもない。

```text
source TSV
  -> Event IR
  -> projection
  -> materialize / accumulate
  -> observe
```

cycleや月は基本軸そのものではなく、時間座標上のwindowとして扱う。

## 3. 外部時計の境界

OS時計は計算途中で繰り返し読まない。

```text
system clock
  -> system_today を入口で一度取得
  -> 明示的な観察値または入力候補へ変換
  -> 各consumerへ渡す
```

現在の主な境界は次で守る。

- `src_next/date.bqn`
- `checks/check-src-next-clock-boundary.sh`
- fixtureや再現実行では明示的な日付引数を使う

`system_today`はCubeの座標ではない。入力UIが新しいEventの日付候補として使う場合と、reportが観察時点として使う場合も責務を分ける。

## 4. Daily Trendの現在契約

Daily Trendは**current-source coordinate replay**である。

```text
S = このrunへ渡されたsource snapshot
D = rendered row coordinate
O_row = D
C = selected cycle
L = local recorded-actual frontier context
K = unavailable / not claimed
```

つまり、現在のsource snapshot `S`を使って各coordinate `D`を再生する。これはhistorical knowledge replayではないため、sourceへbackdated Eventが加われば過去rowが変化し得る。

- ordinary row membershipはaccepted actual projection coordinatesから作る
- accepted in-cycle coordinateが空なら`cycle.start`をempty-state anchorにする
- `L`はfrontier contextでありordinary row membershipを所有しない
- row-local future incomeは`D`をcutoffとして使う
- `K`を実装していないため「D時点で知られていた状態」とは主張しない

human headerはrowとは別の観察ownerを持つ。

```text
report_today
  -> daily_trend.BuildAt(ctx, report_today)
  -> header observation
```

詳細な現在依存は`docs/DAILY_TREND_TEMPORAL_DEPENDENCY_MAP.md`を読む。

## 5. Outlookの現在契約

Outlookは明示的な観察時点`O`を受け取る。

```text
outlook.BuildAt(ctx, O)
```

production entryでは、`--outlook-as-of`が指定されればそれを使い、指定されなければ入口で一度だけ取得したsystem todayを使う。

Outlookの`O`は、Daily Trendのrow coordinate `D`、Daily Trend header observation、local frontier `L`と同一ではない。

詳細は`docs/OUTLOOK_TEMPORAL_CURRENT.md`を読む。

## 6. Plan、Envelope、Residual、Scenario

同じ時間軸上に現れても答える問いを混ぜない。

- Plan: 何を、いつ、いくら行う予定か
- Envelope: 配賦と消費を累積した使用可能枠
- Residual: 選択したwindowでPlanとActualを比較する派生view
- Scenario: 別規則でprojectionした派生view候補

PlanとEnvelopeへ同じ意思額を習慣的に二重入力し始めた場合は責務衝突を再評価する。

ResidualをEventへ書き戻さない。ScenarioでActualを増減させない。

## 7. 現在まだ共通化しないもの

次は必要なconsumerとfixtureが現れるまで、report-wideの共通契約へ昇格しない。

- `generated_at`
- timezoneを含む`system_now`
- 共通`data_cutoff`
- 共通`horizon_end`
- stored historical knowledge boundary `K`
- すべてのsectionを一律に切る単一`as_of`
- `occurred_on / due_on / paid_on / belongs_to_period`の必須入力列化

sectionごとの観察境界は、該当module、`docs/REPORT_CONTRACTS.md`、fixture/checkを正とする。

## 8. 時間変更前の確認

1. その日付はEvent coordinate、observation time、period boundary、generation timeのどれか。
2. 同じEventを別時間へ投影してActualを二重計上しないか。
3. future Actual、Plan、Budget、Forecastを各viewでどう扱うか。
4. cycleや月を基本軸ではなくwindowとして扱えるか。
5. 新しい時間属性を日常の必須入力にせず導出できないか。
6. Cubeのshapeを変えず、別projectionやlong viewで答えられないか。
7. fixtureでEvent coordinateとobservation timeを独立に動かせるか。
8. OS時計をconsumerが直接読まず、入口から値を渡せるか。
9. input frontier、data cutoff、future horizon、knowledge boundaryを混ぜていないか。

## 9. 禁止する近道

- `date`、`as_of`、cycle終端、生成時刻を同じ意味で使う
- `today`をEvent coordinate、observation、generationのすべてに使う
- helperごとにOS時計を読み、一回の出力内で基準時点を変える
- future journal rowを現在Actualへ無条件に含める
- 支払予定projectionをActual残高へ再加算する
- cycleをEventの固定所属として扱い、再観察不能にする
- 複数時間を扱うために既存TSVの必須列を一気に増やす
- abstract temporal kernelをfixtureより先に増やす
- archived decisionをcurrent runtime実装指示として再利用する
