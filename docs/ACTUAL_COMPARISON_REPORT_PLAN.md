# Actual Comparison Report Plan

作成日: 2026-06-21
状態: 決定メモ・実装完了（`actual-comparison` section および `export-actual-comparison.bqn` による TSV export）。

## 目的

`residual` を Plan vs Actual の採点表として肥大化させず、実際に起きた収入・支出イベントを前の期間と並べて、生活の変化を観察する。

このレポートは canonical core の意味を変えない。`BuildCube` や正データ TSV はそのまま読み、そこから再生成可能な派生観察として出す。

```text
Planは、意識した予定を見る。
Envelopeは、今サイクルを生きる箱を見る。
Actual Comparisonは、実際に起きた生活の変化を見る。
```

## 決定

### section 名

section 名は `actual-comparison` とする。

現行 `residual` は Plan vs Actual の語感が残るため、Actual同士を比較する新しい観察枠は別名で始める。`residual` section は削除済み。Plan vs Actual の派生TSV export は互換用として当面残す。

### 比較期間

最初の比較軸は次の1つに絞る。

```text
current_cycle_elapsed
vs
previous_cycle_same_elapsed
```

意味:

- current: 今サイクル開始日から `as_of` まで。
- `current_start = cycle_start`
- `current_end_exclusive = as_of + 1日`
- baseline: 前サイクル開始日から、current と同じ経過日数分。
- `baseline_start = previous_cycle_start`
- `baseline_end_exclusive = previous_cycle_start + (current_end_exclusive - current_start)`
- 前サイクル anchor や比較日数分の履歴が不足する場合は、推測で埋めず `unavailable` とする。

### 比較対象

収入も支出も含める。

ただし、すべてを同じ意味として混ぜない。レーンを分ける。

```text
income
variable spending
recurring / fixed spending
oneoff / irregular spending
```

初期実装の対象範囲:

```text
include:
  role=income   （journalでは通常 from 側に現れる。amountは収入額として正値集計）
  role=expense  （journalでは通常 to 側に現れる。amountは支出額として正値集計）

exclude:
  asset-to-asset transfer
  liability principal transfer
  equity opening balance
  journal rows after as_of
```

負債元本返済や資産間移動は、現金圧力としては重要でも、収入・支出のActual比較とは意味が違うため初期対象に混ぜない。必要なら別laneまたは別レポートで扱う。

## レーンの意味

### income

収入イベントの変化を見る。

例:

- 年金
- 臨時収入
- 返金
- その他の入金

読む問い:

```text
入り口の金額や回数が前期間と比べて変わったか。
```

### variable spending

日々の行動量や買い方の変化を見る。

例:

- 食費
- 日用品
- タバコ
- 本
- 外食

読む問い:

```text
生活行動としての支出が増えたか、減ったか、別の場所に出たか。
```

封筒対象の支出は主にここで見る。ただし、封筒名や割当額は主比較単位ではなく、文脈として添える。

### recurring / fixed spending

毎サイクル・毎月の請求や契約系の変化を見る。

例:

- 家賃
- 通信費
- サブスク
- 保険
- 光熱費

読む問い:

```text
契約額、キャンペーン、乗り換え、請求条件、利用量で変化が起きたか。
```

家賃のようにほぼ変わらないものも、通信費やサブスクのように微妙に変わるものも含める。ただし variable spending と混ぜて「行動ブレ」として読まない。

### oneoff / irregular spending

今回だけの地形変化を見る。

例:

- 病院
- 免許更新
- 家電
- 単発イベント

読む問い:

```text
この期間だけ発生したイベントが全体の圧力になっているか。
```

初期実装では、既存metadataだけで安全に自動判定できない場合、oneoff lane は無理に使わない。必要になったら `accounts.tsv` に次のような明示メタを追加する案を検討する。

```text
compare_lane=oneoff
```

`spend_class=variable` の中から自動で oneoff を推測しない。

## 比較単位

初期実装では、既存 metadata でできる範囲から始める。

優先順:

1. account name
2. `compare_group` metadata（必要になったら導入）
3. envelope / budget group は variable lane の文脈として併記

`budget_group` は現在サイクルを生きるための分類であり、過去比較の安定単位とは限らない。前サイクルで封筒配分や分類が変わっていた場合、封筒名そのものを主比較単位にすると読みが濁る。

必要になったら、`accounts.tsv` に次のような比較用メタを検討する。

```text
compare_group=food
compare_group=tobacco
compare_group=books
compare_group=mobile
```

## 表示値

最小列候補:

```text
period_kind
lane
unit_kind
unit
current_start
current_end_exclusive
baseline_start
baseline_end_exclusive
current_amount
baseline_amount
diff_amount
current_count
baseline_count
diff_count
ratio
status
observation_status
```

`*_count` は対象期間内の該当Event数。金額だけでなく、回数が増えたのか単価が変わったのかを後で読むための補助情報として持つ。

### ratio / status

`baseline=0` の扱いは先に固定する。

```text
baseline = 0, current = 0
  ratio: n/a
  status: no_activity

baseline = 0, current > 0
  ratio: n/a
  status: new

baseline > 0, current = 0
  ratio: 0%
  status: stopped

baseline > 0, current > 0
  ratio: current / baseline
  status: increased / decreased / same
```

生活レポートでは `∞` は使わない。意味より記号の強さが前に出るため、`new` と `n/a` で表現する。

### observation_status

候補:

```text
ok
unavailable
insufficient_history
allocation_changed
group_mapping_changed
```

初期実装では `ok` / `unavailable` / `insufficient_history` だけでもよい。

初期条件:

```text
previous_cycle_start が決められない
  → unavailable

baseline_start >= baseline_end_exclusive など、比較期間として壊れている
  → unavailable

baseline_start >= current_start など、baselineがcurrentより前の期間として成立しない
  → unavailable

earliest_journal_date > baseline_start
  → insufficient_history

baseline期間の一部しかjournal履歴がない
  → insufficient_history
```

履歴が足りない場合は、ある分だけで割り戻したり、日割り推測で埋めたりしない。

## 封筒との関係

封筒は主比較単位ではなく、variable spending の文脈として扱う。

例:

```text
food current actual: 8200
food baseline actual: 7100
current cycle budget: 25000
baseline cycle budget: 20000
```

この形なら、支出が増えたことと、予算を増やしていたことを分けて読める。

## export 方針

作る場合の候補:

```text
out/actual_comparison.tsv
```

これは正データではない。再生成可能な派生観察 TSV として扱う。

canonical / derived / consultation の混線を避けるため、必要なら `status=derived` または `observation` 系の明示を検討する。

## 実装前に決めること / 残課題（すべて合意・実装済み）

1. section名を本当に `actual-comparison` にするか。 -> (採用・実装済み)
2. export名を `actual_comparison.tsv` にするか。 -> (採用・実装済み)
3. 初期分類を account name だけで始めるか、`compare_group` を先に導入するか。 -> (account name 優先で実装)
4. lane 判定に既存 `spend_class` / account metadata をどう使うか。 -> (実装済み)
   - 初期案: `role=income` → income、`spend_class=variable` → variable spending、`spend_class=fixed` または `fixed=1` → recurring / fixed spending。
   - oneoff / irregular は `compare_lane=oneoff` 等の明示metadataを導入するまで自動判定しない。
5. `unavailable` / `insufficient_history` の具体的条件を fixture で固定する。 -> (テストスイートにて固定・検証完了)
6. 初期対象を `role=income` と `role=expense` に限定し、資産移動・負債元本返済・期首残高を除外する方針でよいか。 -> (採用・実装済み)

## 初期fixture候補

最初の fixture は小さくする。

```text
current cycle:
  day 1..7
  income same
  food increased
  mobile increased
  rent same
  hospital new（oneoffを検証する場合は `compare_lane=oneoff` 等の明示metadata付きfixtureにする）

previous cycle:
  day 1..7
  income same
  food lower
  mobile lower
  rent same
  hospital absent
```

期待する読み:

- income は same。
- variable lane の food は increased。
- recurring / fixed lane の mobile は increased。
- rent は same。
- oneoff lane の hospital は new。

## 非目標

初期実装では次をしない。

- AIコメント生成。
- グラフ表示。
- 月次・年次・前年比較。
- Datalog / Prolog 連携。
- 正データ TSV の意味変更。
- `BuildCube` の layer 追加。
