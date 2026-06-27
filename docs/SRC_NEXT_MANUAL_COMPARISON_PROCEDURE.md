# src_next Manual Comparison Procedure


> **Note (2026-06-26):** Old engine has been deleted. References in this doc are historical. Current engine is src_next/.
Status: docs-only procedure definition / no implementation changes
Branch: `docs-src-next-manual-comparison-procedure`

この文書は、current engine と `src_next` observation output を手動比較するための手順を定義します。

重要: この文書は Stage 4b daily-use trial の開始を宣言するものではありません。

---

## 1. Purpose

この文書の目的:

- current engine と `src_next` observation output を手動比較する手順を定義する。
- Stage 4b readiness gate の **Gate B: Manual Comparison Procedure** を満たすための前提文書を提供する。
- 比較のワークフロー、記録形式、判定基準を運用者が日本語で読めるようにする。
- `docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` で定義された criteria を、実 production data にどう当てるかを定義する。

明記すること:

- **この文書は Stage 4b daily-use trial を開始する文書ではない。**
- **production default は引き続き `bqn main.bqn` である。**
- **current engine の production report が正本である。**
- **`src_next` は observation target であり、production replacement ではない。**
- **`src_next` は `data/*.tsv` を編集しない。**
- **この文書では新しい command を追加しない。**
- **実装変更が必要な場合は別 PR に分離する。**

---

## 2. Inputs

比較に使う入力を以下に定義する。

| 入力 | 実体 | 用途 |
|:---|:---|:---|
| **production data** | `data/*.tsv` | 比較対象の正本データ。実金額を含むため public repo に commit しない。 |
| **current engine report** | `bqn main.bqn` の出力 | 正本レポート。比較の基準。 |
| **current engine exporters** | `export-report-numbers.bqn`、`export-cycle-summary.bqn`、`export-canonical-snapshot.bqn` 他 | 機械可読な比較用フィールドの抽出。 |
| **src_next summary / observation output** | `tools/report-next-summary data` の出力 | `src_next` の compact observation surface。比較対象。 |
| **src_next full output** | `tools/report-next data` または `bqn src_next/main.bqn data` | 必要に応じて詳細確認に使う。 |
| **Snapshot equivalence criteria** | `docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` | 比較対象 field、判定基準、difference classification の正本。 |
| **Stage 4b readiness gate** | `docs/SRC_NEXT_STAGE4B_READINESS_GATE.md` | Gate B の充足条件。手順の位置づけ。 |
| **fixtures** | `fixtures/basic` 他 | 公開可能な最小 baseline 比較。実金額を含まない。 |

---

## 3. Commands

既存の command だけを使って比較する。

注意:
- **この文書では新しい command を追加しない。**
- command が存在しない場合は、存在する範囲だけを書く。
- 実装変更が必要な場合は別 PR に分離する。

### 3.1 current engine 側

```sh
# 正本レポート（フル）
bqn main.bqn --base data

# 機械可読エクスポート
bqn src/reports/exporters/export-report-numbers.bqn --base data
bqn src/reports/exporters/export-cycle-summary.bqn --base data
bqn src/reports/exporters/export-canonical-snapshot.bqn --base data
bqn src/reports/exporters/export-section-status.bqn --base data
```

### 3.2 src_next 側

```sh
# compact observation surface
tools/report-next-summary data

# フル output（詳細確認用）
tools/report-next data
```

### 3.3 fixture を使った公開可能な比較

```sh
# current engine
bqn main.bqn --base fixtures/basic --as-of 2026-01-03
bqn src/reports/exporters/export-report-numbers.bqn --base fixtures/basic --as-of 2026-01-03

# src_next
tools/report-next-summary fixtures/basic
```

### 3.4 baseline 確認

```sh
rtk bash tools/check.sh
```

---

## 4. Comparison Workflow

以下の手順で手動比較を実施する。

1. **main ブランチが最新であることを確認する。**
   ```sh
   git fetch origin && git log origin/main --oneline -3
   ```

2. **`rtk bash tools/check.sh` を実行して baseline を確認する。**
   - 全チェックが pass していること。
   - pass していない場合は比較を開始せず、先に修正する。

3. **current engine の production report を出力する。**
   ```sh
   bqn main.bqn --base data
   bqn src/reports/exporters/export-report-numbers.bqn --base data
   ```
   - Sec1（全体サマリ / Snapshot）、Sec4（今サイクル集計）、Sec3（勘定科目一覧）、Sec8（チェック）を確認する。
   - `export-report-numbers.bqn` の TSV で key=value を抽出する。

4. **src_next summary / observation output を出力する。**
   ```sh
   tools/report-next-summary data
   ```
   - `--- SrcNext Snapshot ---` section と `--- SrcNext Cycle Summary ---` section を確認する。
   - `src_next_envelope_status`、`src_next_skipped_*`、`src_next_unknown_accounts_*` などの status fields を確認する。

5. **Snapshot 関連 field を並べて比較する。**
   - current engine の Sec1 と `src_next` の SrcNext Snapshot section の対応 fields を抽出する。
   - `export-report-numbers.bqn` の TSV から数値 key を抽出し、対応する `src_next` field と突合する。
   - fixture 比較の場合は `fixtures/basic` を最小 baseline として使う。

6. **結果を記録する。**
   - 一致（match）/ 不一致（mismatch）/ unavailable（値が未提供）/ unsupported（機能未実装）のいずれかを記録する。
   - 記録形式は本文書 §5（Comparison Record Format）に従う。
   - 実金額は public repo に commit しない。private log に記録する。

7. **不一致を difference classification に分類する。**
   - 分類は `docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` §6 を使う。
   - いずれの分類にも入らない差分は未分類として残さず、調査を継続する。

8. **未分類差分がある場合、Stage 4b を開始しない。**
   - すべての差分がいずれかの分類に収まるまで、Stage 4b daily-use trial は開始できない。
   - 未分類差分は別 PR / issue / docs follow-up に分離して調査する。

---

## 5. Comparison Record Format

手動比較結果を残すための記録形式を以下に定義する。

### 5.1 比較テーブル（field-level）

| Item | Current engine | src_next | Result | Classification | Notes |
|:---|---:|---:|:---|:---|:---|
| cycle start | … | … | match / mismatch | — / category | … |
| cycle end | … | … | match / mismatch | — / category | … |
| cycle day_count | … | … | match / mismatch | — / category | … |
| cycle income actual | … | … | match / mismatch | — / category | … |
| cycle expense actual | … | … | match / mismatch | — / category | … |
| cycle net actual | … | … | match / mismatch | — / category | … |
| plan expense total | … | … | match / mismatch | — / category | … |
| valid row count | … | … | match / mismatch | — / category | … |
| skipped row count | … | … | match / mismatch | — / category | … |
| unknown account count | … | … | match / mismatch | — / category | … |
| account balances (nonzero) | … | … | match / mismatch | — / category | account key ごと |
| envelope status | — | unavailable/src_next | unsupported | unsupported/src_next | production data では常に unavailable/src_next |
| liquid assets / savings / investments | … | — | unavailable | unsupported/src_next | `src_next` 未実装 |

Result 列の値:

| Result | 意味 |
|:---|:---|
| `match` | 両 engine の値が整数円で一致する。 |
| `mismatch` | 両 engine の値が一致しない。§5.2 で分類する。 |
| `unavailable` | `src_next` がその値を現在提供していない。値の概念自体は `src_next` に存在するが、出力に surface されていない（fallback/current-engine など）。 |
| `unsupported` | `src_next` がその機能・モデルを実装していない。値の概念自体が `src_next` の現在の architecture に存在しない。 |

**`unavailable` と `unsupported` の使い分け基準:**

| 状況 | 使う Result | 例 |
|:---|:---|:---|
| `src_next` が概念を持っているが値を出力していない | `unavailable` | net_worth（fallback/current-engine）、daily_remaining（fallback/current-engine）、envelope computation（unavailable/src_next） |
| `src_next` が概念・モデル自体を持っていない | `unsupported` | budget totals（src_next に budget layer がない）、valid/skipped row count（projection model が current engine の raw journal と異なる） |
| `src_next` が機能を実装しておらず、将来実装予定も未定 | `unsupported` | actual_comparison（not_implemented） |

項目の詳細と追加項目は `docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` §4（Comparison Scope）および §5（Field-Level Criteria）を参照する。

### 5.2 差分分類テーブル（divergence log）

不一致（mismatch）が発生した場合、以下の形式で private log に記録する。
この形式は `docs/SRC_NEXT_STAGE4_TRIAL_LOG.md` §12 と互換であり、分類は同文書 §13（= `docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` §6）を使う。

| date | item | current engine value | src_next value | classification | notes |
|:---|:---|:---|:---|:---|:---|
| YYYY-MM-DD | 差分のある field | … | … | category | 調査メモ・次の行動 |

分類 categories（`docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` §6 と同一）:

| Classification | 意味 | 次の行動 |
|:---|:---|:---|
| `expected/current-engine-difference` | current engine と `src_next` の責任境界の違いによる既知差分 | 意図的な置き換え理由を記録する。追加修正は不要。 |
| `bug/src_next` | `src_next` 側の計算または投影の誤り | 修正する。修正後、再比較する。 |
| `bug/current-engine` | current engine 側の既知または疑いのある誤り | 両方の engine を安易に変えず、調査する。 |
| `unsupported/src_next` | `src_next` がまだ対応していない field / behavior | 現 stage の blocking gap として扱う。実装計画に反映する。 |
| `policy/not-engine` | household policy data の扱いであり engine equivalence の対象外 | 別の policy contract で扱う。 |
| `requires-contract` | `safe_remaining` / `daily_amount` / `outlook` など、契約なしには判定できないもの | 実装より前に contract doc を作成する。 |

### 5.3 記録場所と注意

- field-level 比較テーブルと差分分類テーブルは、public repo では実金額を除いた形式とする。
- 実金額を含む完全な記録は private log に置く。Stage 4b daily-use trial の future private log path は `docs/SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md` で定義する `private/src-next-stage4b/daily-use-trial-log.md` を使う。
- 公開可能な fixture 比較の結果は、本 repo の PR 本文または docs に記録してもよい。

---

## 6. Required Comparison Areas

手動比較で最低限カバーすべき領域を以下に定義する。
各領域の詳細な判定基準は `docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` §5（Field-Level Criteria）を参照する。

### Cycle Boundary Contract（半開区間）

cycle range は半開区間として扱う:

```text
[cycle_start, cycle_end_exclusive)
```

- `cycle_start` 当日は current cycle に含まれる。
- `cycle_end_exclusive` 当日は current cycle に**含まれない**。
- `cycle_end_exclusive` 当日の rows（journal / plan）は、原則として next cycle 側に属する。

`src_next` の cycle-bounded comparison では、この半開区間契約に従い `cycle_end_exclusive` 上の rows を current cycle から除外する。
current engine の report / export が境界日の予定を含む場合、それは current engine 側の export / display semantics として別扱いする。

| # | Area | 比較内容 | 比較元 |
|:---|:---|:---|:---|
| 0 | **as_of（観測日）** | current engine と `src_next` の観測日を記録する | `main.bqn` Sec9（基準日）↔ `tools/report-next-summary` SrcNext Snapshot（as_of） |
| 1 | **cycle boundary** | cycle start / end / day_count が current engine と一致するか | `main.bqn` Sec4 ↔ `tools/report-next-summary` SrcNext Cycle Summary |
| 2 | **actual totals** | cycle income actual / expense actual / net actual が整数円で一致するか | `export-report-numbers.bqn` ↔ `tools/report-next-summary` |
| 3 | **account balances** | nonzero actual account totals が一致するか | `export-report-numbers.bqn` ↔ `tools/report-next-summary` |
| 4a | **plan totals baseline / cycle-bounded** | 半開区間 `[cycle_start, cycle_end_exclusive)` 内の全 plan rows の合計が一致するか（completed + future）。`cycle_end_exclusive` 当日の rows は**含めない**。 | `main.bqn` Sec6（手動集計）↔ `tools/report-next-summary` SrcNext Cycle Summary（plan_expense）。current engine 側で `cycle_end_exclusive` 当日の rows を除外した subset で比較する。 |
| 4b | **plan totals（export semantics）** | 各 engine が機械可読 export で出力する plan 値の scope が何か。current engine の export が境界日を含むか、src_next が completed+future か future-only か、それぞれ記録する。 | `export-report-numbers.bqn`（将来分のみ）↔ `tools/report-next-summary`（サイクル全体）。scope が異なる場合は `expected/current-engine-difference` として記録する。 |
| 5 | **budget totals** | budget total が一致するか。`src_next` に budget layer がない場合は `unsupported` として記録する。 | `export-report-numbers.bqn` ↔ `tools/report-next-summary` |
| 6 | **skipped rows** | skipped row count と reason（unknown account / out-of-cycle / invalid）が一致するか。current engine と `src_next` で row モデルが異なる（raw journal vs projection cube）場合は `unsupported` として記録する。 | `main.bqn` Sec8 ↔ `tools/report-next-summary` |
| 7 | **valid rows** | production data の valid row count。current engine と `src_next` で row モデルが異なる（raw journal vs projection cube）場合は `unsupported` として記録する。 | `export-report-numbers.bqn` ↔ `tools/report-next-summary` |
| 8 | **unknown accounts** | unknown account list が一致するか | `main.bqn` Sec8 ↔ `tools/report-next-summary` |
| 9 | **envelope production guard status** | production data で envelope status が `unavailable/src_next` のままであるか | `tools/report-next-summary data` |
| 10 | **next income date** | 次回収入日が current engine と一致するか | `main.bqn` Sec4 ↔ `tools/report-next-summary` |
| 11 | **unavailable production advice fields** | `net_worth`, `daily_remaining`, envelopes, `daily_amount`, `safe_remaining`, outlook など、`src_next` production advice に使えない field が unavailable / out-of-scope として明示されているか | `tools/report-next-summary` の status field |
| 12 | **remaining days** | 次回収入日までの残り日数が current engine と一致するか。`as_of` の不一致に起因する差分は `expected/current-engine-difference` として記録する（§7.4 参照）。 | `main.bqn` Sec4 ↔ `tools/report-next-summary` |
| 13 | **actual_comparison** | actual comparison observation の status。`src_next` が `not_implemented` の間は `unsupported/src_next` として記録する。 | `main.bqn` Sec11 ↔ `tools/report-next-summary` |

※ items 10, 12 は `src_next` が計算可能な場合のみ比較する。未実装の場合は `unsupported/src_next` として記録する。
※ area 0（as_of）は比較判定（match/mismatch）ではなく、差分の原因特定のための記録項目である。as_of が異なる場合、remaining_days 等の派生 field に波及する。

---

## 7. Difference Handling

差分が出た場合の扱いを以下に定義する。

### 7.1 差分の分類

すべての差分（mismatch）は、本文書 §5.2 の classification categories のいずれかに分類する。
分類体系は `docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` §6 と同一である。

### 7.2 分類別の対応

| Classification | 対応 |
|:---|:---|
| `expected/current-engine-difference` | 理由を記録する。意図的な置き換えとして認識されているため、Stage 4b 開始の blocker にはならない。 |
| `bug/src_next` | `src_next` 側を修正する。修正後、再比較する。修正が別 PR になる場合は、その PR の merge まで Stage 4b を開始しない。 |
| `bug/current-engine` | current engine 側の調査を行う。両方の engine を同時に変えない。調査結果にかかわらず、current engine 側の修正はこの手順の範囲外。`src_next` 側の動作が正しい場合は `expected/current-engine-difference` に再分類する。 |
| `unsupported/src_next` | blocking gap として扱う。production-equivalent の対象外であることを記録する。 |
| `policy/not-engine` | engine equivalence の対象外として扱う。別の policy contract で扱う。 |
| `requires-contract` | 実装より前に contract doc を作成する。contract が定義されるまで、差分は `requires-contract` のままとする。 |

### 7.3 未分類差分の扱い

未分類の差分（いずれの classification にも入らない差分）が残っている場合:

- **production-equivalent と呼ばない。**
- **Stage 4b daily-use trial を開始しない。**
- 未分類差分は別 PR / issue / docs follow-up に分離して調査する。
- 調査が完了し、いずれかの分類に収まった時点で、改めて Stage 4b 開始を判断する。

### 7.4 as_of 差に起因する差分の扱い

`src_next` は `--as-of` option を未実装であり、最新の in-cycle journal 日付を as_of として使う。
このため、current engine（デフォルトで今日の日付を使う）との間に as_of の不一致が生じることがある。

as_of 差から派生する差分（remaining_days など）の扱い:

- **`expected/current-engine-difference` に分類する。**
- 差分の原因が as_of 差のみであり、計算自体が両 engine で一貫している場合は、追加の修正は不要。
- as_of 差が daily-use trial で運用上の課題になるかどうかは、別途判断する。
- `src_next` に `--as-of` option が実装された時点で、この分類は見直す。

### 7.5 cycle_end_exclusive 上の plan rows に起因する差分の扱い

`src_next` の cycle-bounded comparison では、`cycle_end_exclusive` 当日の plan rows を current cycle から除外する（§6 Cycle Boundary Contract）。
このため、current engine が境界日の plan rows を current cycle の report / export に含む場合、plan totals に差分が生じる。

境界日 plan rows から派生する差分（Area 4a）の扱い:

- **`expected/current-engine-difference` に分類する。**
- 半開区間 `[cycle_start, cycle_end_exclusive)` 内で subset comparison を行い、その範囲では一致することを確認する。
- 境界日 plan rows を除外した subset で一致していれば、`bug/src_next` とは扱わない。
- `cycle_end_exclusive` 当日の rows がどちらの cycle に属すべきか docs 上で未定義の場合は `requires-contract`。
- `src_next` が半開区間契約に反して境界日を含んでいる場合は `bug/src_next`。
- current engine の export が docs 上の契約と矛盾する場合は `bug/current-engine`。
- 判断不能の場合は `unclassified`（Stage 4b blocker）。

Stage 4b readiness への影響:

- 境界日 plan rows による差分が `expected/current-engine-difference` として分類されている限り、それ単独では Stage 4b の blocker ではない。
- ただし daily-use trial で plan totals を production advice として使う場合は、境界日 semantics を利用者が理解できる表示または docs が必要。

---

## 8. Gate B Satisfaction Criteria

Stage 4b readiness gate の **Gate B: Manual Comparison Procedure** が satisfied と呼べる条件を以下に定義する。

Gate B is satisfied when all of the following are true:

- [ ] **`docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` が `main` ブランチに存在する。**
  - 本 PR（`docs-src-next-manual-comparison-procedure`）の merge により充足される。

- [ ] **comparison workflow が定義されている。**
  - 本文書 §4 で numbered list として定義されている。
  - 運用者が日本語で読んで実行できる。

- [ ] **comparison record format が定義されている。**
  - 本文書 §5 で field-level テーブルと差分分類テーブルの形式が定義されている。
  - `docs/SRC_NEXT_STAGE4_TRIAL_LOG.md` §12 の divergence log format と互換である。

- [ ] **required comparison areas が定義されている。**
  - 本文書 §6 で最低限比較すべき 12 領域が定義されている。
  - `docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` §4, §5 と整合している。

- [ ] **difference handling が定義されている。**
  - 本文書 §7 で分類別の対応と未分類差分の扱いが定義されている。

- [ ] **未分類差分が Stage 4b の stop 条件になることが明記されている。**
  - 本文書 §4 step 8、§7.3、および `docs/SRC_NEXT_STAGE4B_READINESS_GATE.md` §7 #3 で明記されている。

- [ ] **`bqn main.bqn` の本番レポートと `src_next` summary/report を比較する手順が存在する。**
  - 本文書 §3, §4 で、`bqn main.bqn`、`tools/report-next-summary data`、`export-report-numbers.bqn` を使った手順が定義されている。

- [ ] **比較対象の sections / fields / fixture / production data が明記されている。**
  - 本文書 §3, §6 で定義されている。
  - fixture 比較は `fixtures/basic` を最小 baseline とする。
  - production data 比較は private log に記録する。

本 PR の merge により、上記の手順定義（criteria 定義）は満たされる。
ただし、**実際の比較実施と差分分類が完了するまでは、Gate B の運用充足とはみなさない。**

Gate 充足状態（本 PR merge 後、実比較実施前）:

| Gate | 内容 | 状態 |
|:---|:---|:---|
| A | Snapshot equivalence readiness | criteria defined — 実 production data での比較結果が記録されるまで Stage 4b 開始条件を満たしたとは扱わない |
| B | Manual comparison procedure | **procedure defined** — 手順は定義されたが、実際の比較実施と差分分類は未完了。完了するまで Stage 4b 開始条件を満たしたとは扱わない |

---

## 9. Non-Goals

この文書では以下を行わないことを明記する。

| # | Non-goal | 理由 |
|:---|:---|:---|
| 1 | BQN 実装変更をしない | この PR は docs-only |
| 2 | fixtures を変更しない | この PR は docs-only |
| 3 | check script の挙動を変更しない | この PR は docs-only |
| 4 | production TSV data を変更しない | `data/*.tsv` は不変 |
| 5 | `main.bqn` を変更しない | 本番 default は不変 |
| 6 | Stage 4b daily-use trial を開始しない | この文書は手順定義であり、開始宣言ではない |
| 7 | production replacement をしない | Stage 5 の作業 |
| 8 | production default switch をしない | `src_next` を `main.bqn` の既定ルートにしない |
| 9 | `safe_remaining` を実装しない | later work。実装前の契約が必要 |
| 10 | `daily_amount` / per-day allowance を実装しない | later work。実装前の契約が必要 |
| 11 | `outlook` を実装しない | missing src_next feature |
| 12 | envelope output を production advice にしない | envelope は `unavailable/src_next` を維持 |
| 13 | 新しい command を追加しない | 既存 command の範囲で手順を定義する |
| 14 | source TSV format を変更しない | `data/*.tsv` の列定義は不変 |

---

## 10. Related Documents

- [SRC_NEXT_STAGE4B_TRIAL_SCOPE.md](SRC_NEXT_STAGE4B_TRIAL_SCOPE.md) — Stage 4b trial scope（observation-only usage, out-of-scope fields, pause conditions）
- [SRC_NEXT_STAGE4B_THIRD_DRY_RUN_PLAN.md](SRC_NEXT_STAGE4B_THIRD_DRY_RUN_PLAN.md) — Public-safe plan for a third manual comparison dry run before any Stage 4b start decision
- [SRC_NEXT_STAGE4B_READINESS_GATE.md](SRC_NEXT_STAGE4B_READINESS_GATE.md) — Stage 4b daily-use trial readiness gate 定義（Gate B の本拠）
- [SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md](SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md) — production-equivalent Snapshot criteria 定義（比較対象 fields、difference classification の正本）
- [SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md](SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md) — Stage 4a 観測面棚卸し
- [SRC_NEXT_REPLACEMENT_READINESS.md](SRC_NEXT_REPLACEMENT_READINESS.md) — 置き換え準備チェックリスト（Stage 1〜5 gate、差分分類体系 §5）
- [SRC_NEXT_STAGE4_TRIAL_LOG.md](SRC_NEXT_STAGE4_TRIAL_LOG.md) — Stage 4 観察ログ template（divergence log format §12、分類 categories §13）
- [SRC_NEXT_CURRENT_ENGINE_COMPARISON.md](SRC_NEXT_CURRENT_ENGINE_COMPARISON.md) — current engine との比較 notes
- [CURRENT_STATE_REFERENCE.md](CURRENT_STATE_REFERENCE.md) — 現行エンジン比較基準（baseline commands、fixtures、exporters）
- [SRC_NEXT_REPORT_SECTION_PARITY.md](SRC_NEXT_REPORT_SECTION_PARITY.md) — レポートセクション適合度マトリクス
- [SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md](SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md) — Snapshot 観測画面設計
