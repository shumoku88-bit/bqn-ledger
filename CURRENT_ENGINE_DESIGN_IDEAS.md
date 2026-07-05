# 現行エンジン拡張設計案 比較評価書 (Current Engine Design Ideas)

Status: design comparison / exploratory docs-only
Owner: architecture / docs
Canonical: no; related current paths: docs/ARCHITECTURE.md, docs/SRC_NEXT_CURRENT.md, docs/STRUCTURED_UI_EXPORT_CONTRACT.md
Exit: archive or replace with a focused active plan when one option is selected for implementation

この文書は、旧 `ENGINE_DESIGN_COMPARISON.md` と同じ位置づけで、現行 `src_next` エンジンに対して「次に足すと良くなる / 面白くなる設計案」を比較するためのメモです。

重要: これは実装指示ではありません。現行エンジンを作り直す提案でもありません。今の `Posting IR / Cube / TBDS / ViewModel / structured export` の土台を維持しながら、どの層を足すと価値が高いかを比較します。

---

## 1. 現在地

旧エンジン設計比較で強く推奨されていた方向性の多くは、現行エンジンですでに土台化されています。

```text
source TSV
  -> loader / projection
  -> Posting IR-like normalized rows
  -> Canonical Daily Cube
  -> TBDS
  -> section BuildViewModel / FormatHuman / FormatJson
  -> report / summary / UI export
```

現時点の強み:

- source TSV と派生ビューの境界が明確。
- Cube / TBDS により残高・期間 flow の意味が整理されている。
- `src_next` が普段使い report engine になっている。
- `tools/report --section <key>` や `tools/report-section-metadata` があり、UI が human report を parse しない方向に寄っている。
- `planned` / `balances` / `snapshot` / `envelopes` など、一部 section は JSON ViewModel export を持つ。
- fail-closed / readiness / lint / golden check が増えている。

したがって、次の設計テーマは「新エンジン刷新」ではなく、**現行エンジンの上にどの projection / policy / proof / registry を足すか**です。

---

## 2. 解決したい次の課題

現行エンジンで残っている課題は、旧エンジン時代の「巨大ハブをどう壊すか」ではなく、次のようなものです。

```text
・as_of 時点ごとの意味を、section 個別実装ではなく projection として安定させたい
・家計相談や what-if を正データに混ぜず、安全に試したい
・会計的不変条件が守られていることを、レポートとは別に説明可能にしたい
・section ViewModel / human / JSON / metadata の対応関係を増えても迷わないようにしたい
・生活ルールを accounting core へ混ぜず、policy layer として説明可能にしたい
```

---

## 3. 設計案一覧

### Option A: Temporal Projection Layer

`as_of` を明示した時間状態 projection を作る案。

```text
Plan / Actual / TBDS
  -> Temporal Projection(as_of)
  -> future / due / overdue / completed / active / expired ...
```

狙い:

- 予定支払いの `future / due / overdue / completed` を section 個別ロジックから切り出す。
- 封筒、予定、残高、相談計算で「いつ見た状態か」を揃える。
- core の途中で時計を読まない方針を強める。

現状との関係:

- PR #64 で `src_next/plan_status.bqn` と明示 `as_of` の小さな projection が入り始めた。
- 次にやるなら、他 section へ広げる前に plan status の契約を安定させる。

向いている用途:

- planned payments
- overdue / due diagnostics
- execution envelope coverage
- AI 相談での「今日時点」「支給日前時点」の切り替え

リスク:

- 時間状態を増やしすぎると policy と accounting core が混ざる。
- `as_of` 既定値を曖昧にすると再現性が落ちる。

---

### Option B: Scenario / What-if Projection

正データを変えずに仮想イベントを重ね、未来や節約案を試算する案。

```text
Actual + Plan + Budget
  + hypothetical events
  -> Scenario Projection
  -> report / advice / envelope-calc
```

例:

- 「食費を1日500円にしたら次の支給日まで足りるか」
- 「この固定費を来月にずらしたらどうなるか」
- 「臨時収入が入ったら未割当と封筒 backing はどう変わるか」
- 「年金支給日まで、このペースで枯渇するか」

狙い:

- 家計相談を canonical source TSV に混ぜない。
- AI が提案する仮説を read-only projection として検証できる。
- `tools/envelope-calc` の方向性をより一般化できる。

現状との関係:

- `tools/envelope-calc` は封筒相談の小さな read-only 計算として先行例になっている。
- Canonical Daily Cube の shape は変えず、同じ Event IR から別 projection/view を作る方針に合う。

リスク:

- 便利すぎて canonical engine に「おすすめ」や生活判断を混ぜたくなる。
- scenario の入力形式を先に広げると、source TSV と誤認されやすい。

安全な進め方:

1. まず docs-only で scenario input は read-only / ephemeral と固定する。
2. 実データ TSV への write path を持たない。
3. 最初は envelope-calc の既存プリミティブの延長だけにする。

---

### Option C: Invariant Proof Report

通常レポートとは別に、「この数字が成立している理由」を機械的に出す案。

```text
TBDS / Cube / Projection
  -> invariant checks
  -> proof report / machine summary
```

例:

- `opening + movement = closing`
- `budget:*` の Actual layer は 0
- unknown account があれば fail / skipped として出る
- `UNAVAILABLE` と `0` を混ぜていない
- plan/journal overlap の扱いが明示されている
- source TSV の列ずれが検出されている

狙い:

- 人間向け report の見やすさと、会計エンジンの説明責任を分離する。
- CI / check が守っている invariant を、必要時に読む report として出せる。
- 「きれいな間違い」を防いでいる根拠を表示できる。

現状との関係:

- 既に readiness / lint / golden / section checks はある。
- それらを user-facing / AI-facing に要約する層はまだ薄い。

リスク:

- check と proof report が二重正本になる。
- proof report のために engine が複雑化する。

安全な進め方:

- まず既存 check / summary keys を一覧化するだけ。
- 新しい invariant を増やす前に、既存 invariant の owner を明確にする。

---

### Option D: Report ViewModel Registry

各 section の `BuildViewModel` / `FormatHuman` / `FormatJson` / metadata の対応関係を登録制にする案。

```text
section key
  -> module
  -> supports human/json/cache?
  -> BuildViewModel
  -> FormatHuman / FormatJson
```

狙い:

- section が増えても、report / metadata / UI / docs の対応を追いやすくする。
- `tools/report-section-metadata` と implementation の drift を減らす。
- JSON export 対応 section の一覧を機械的に出せる。

現状との関係:

- `tools/report-section-metadata` は既に structured section metadata を出す。
- section JSON export は増えているが、registry としての一元管理はまだ限定的。

リスク:

- registry が巨大ハブ化すると、旧 `report_engine` 的な問題に戻る。
- BQN の動的 dispatch を複雑化しすぎると保守性が落ちる。

安全な進め方:

- まず metadata のみの registry に留める。
- section の計算本体は各 module に置き、registry は意味を持ちすぎない。

---

### Option E: Policy Layer v2

生活ルールを accounting core ではなく household policy projection として明示する案。

```text
Accounting core facts
  + household policy metadata
  -> policy projection
  -> diagnostics / advice / report labels
```

扱う候補:

- 年金の偶数月隔月支給
- 支給日連動固定費
- execution envelope / dynamic envelope / reserve の違い
- savings / investment / reserve をどの report に含めるか
- due / late / missing をどう診断するか

狙い:

- accounting core は簿記・期間・残高に集中させる。
- 家計固有ルールを説明可能にする。
- 設定駆動化しても core contract を壊さない。

現状との関係:

- `household_policy.bqn` / `household_metadata.bqn` / envelope policy docs が既にある。
- 設定値を増やす場合は meta schema / docs / lint の整備が必要。

リスク:

- policy が増えると「便利な家計アプリ」方向に膨らみやすい。
- 未設定や unknown 値を黙って補正すると fail-closed に反する。

安全な進め方:

- policy は always explicit / diagnosable にする。
- unknown は warning/error/unavailable として出す。
- source TSV migration は急がない。

---

## 4. 比較マトリクス

| 評価軸 | A Temporal | B Scenario | C Proof | D Registry | E Policy v2 |
|---|---:|---:|---:|---:|---:|
| 日常実用性 | ◎ | ◎ | ◯ | ◯ | ◎ |
| 会計エンジン品質 | ◎ | ◯ | ◎ | ◯ | ◯ |
| AI相談との相性 | ◎ | ◎ | ◎ | ◯ | ◎ |
| 実装の小ささ | ◎ | △ | ◯ | ◯ | △ |
| 正データ保護 | ◎ | ◎ if read-only | ◎ | ◎ | ◯ |
| 面白さ | ◯ | ◎ | ◯ | △ | ◯ |
| drift削減 | ◯ | △ | ◎ | ◎ | ◯ |
| 複雑化リスク | ◯ | △ | ◯ | △ | △ |
| 最初のslice適性 | ◎ | ◯ | ◯ | △ | △ |

凡例:

- ◎: 強い
- ◯: 良い
- △: 注意が必要

---

## 5. 推奨順

### 1位: Temporal Projection Layer

すでに PR #64 で小さく始まっており、現行設計と相性が良い。

最初の発展例:

- `plan_status.bqn` の契約を docs に明文化する。
- planned payments 以外へ広げる前に `as_of` と status words を固定する。
- execution envelope coverage と join するかは別 slice で判断する。

### 2位: Scenario / What-if Projection

一番面白い。家計相談ツールとして価値が高い。

ただし canonical engine へ混ぜないことが重要。

最初の発展例:

- docs-only で scenario input の境界を定義する。
- ephemeral / read-only / no source TSV mutation を明記する。
- `tools/envelope-calc` の既存計算を使って小さく始める。

### 3位: Invariant Proof Report

品質を一段上げる案。

最初の発展例:

- 既存 checks と machine summary keys の invariant inventory を作る。
- 新しい check を足さず、まず「何が既に守られているか」を見える化する。

### 4位: Report ViewModel Registry

整理効果はあるが、早くやりすぎると registry 自体がハブ化する。

最初の発展例:

- metadata registry の表示/検査だけに留める。
- section module の責務を registry へ吸い上げない。

### 5位: Policy Layer v2

重要だが、設定・生活ルール・lint・docs が絡むため大きくなりやすい。

最初の発展例:

- execution envelope の due/late/missing 設計だけに切る。
- unknown policy の fail-closed diagnostics を先に置く。

---

## 6. いま選ぶなら

今すぐ実装に進むなら、最も安全なのは Temporal Projection の続きです。

```text
Temporal status projection docs/contract
  -> small fixture
  -> one section integration
  -> no broad policy expansion
```

面白さを優先して設計だけ作るなら、Scenario / What-if Projection が良いです。

```text
Scenario input boundary
  -> read-only guarantee
  -> no source TSV mutation
  -> first use case: envelope-calc what-if
```

品質を一段上げるなら、Invariant Proof Report です。

```text
Existing invariant inventory
  -> proof summary sketch
  -> only then decide if new checks are needed
```

---

## 7. この文書の扱い

この文書は option catalog です。ここに書かれた案を直接実装しないでください。

採用する場合は、次の順に進めます。

1. `TODO.md` で小さい slice を選ぶ。
2. 必要なら `docs/archive/active-plans/` に active plan を作る。
3. acceptance criteria と non-goals を固定する。
4. 実装するなら checks / docs / fixtures を同じ単位にする。
5. 完了したらこの文書を更新するのではなく、選ばれた plan / contract へ正本を移す。
