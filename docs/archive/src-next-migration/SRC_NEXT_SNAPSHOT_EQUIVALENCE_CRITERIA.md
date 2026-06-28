# src_next Snapshot Equivalence Criteria


> **Note (2026-06-26):** Old engine has been deleted. References in this doc are historical. Current engine is src_next/.
Status: docs-only criteria definition / no implementation changes
Branch: `docs-src-next-snapshot-equivalence-criteria`

この文書は、`src_next` の Snapshot observation が **production-equivalent Snapshot** と呼べる条件を定義します。

重要: この文書は実装ではなく、criteria（判定基準）の定義です。

---

## 1. Purpose

この文書の目的:

- `src_next` Snapshot observation が「production-equivalent Snapshot」と呼べる条件を定義する。
- 現在の minimal Snapshot observation と production-equivalent Snapshot の境界を固定する。
- Stage 4b daily-use trial に入る前に Gate A を満たすための前提文書を提供する。
- 比較・検証の基準を運用者が日本語で読めるようにする。

明記すること:

- **現在の `src_next` Snapshot は minimal observation である。**
- **production-equivalent とはまだ呼ばない。**
- **この文書は実装ではなく criteria 定義である。**
- **Stage 4b daily-use trial は開始しない。**
- **production default は引き続き `bqn main.bqn` である。**
- **`src_next` は observation target のままである。**

---

## 2. Current Snapshot Status

現在の `src_next` Snapshot の状態:

| 項目 | 状態 |
|:---|:---|
| Snapshot observation screen | **存在する**（PR #32 で追加済みの最小観測画面） |
| current engine との完全比較 criteria | **未定義**（本 PR で定義する） |
| unsupported fields | あり（Daily remaining, food remaining, flex/reserve, envelope balances, outlook, daily trend, actual comparison 本実装, liquid assets / savings / investments / net worth 相当） |
| partial fields | あり（nonzero actual account totals は `src_next/partial`、status label は保守的な範囲のみ、ASCII art は未表示） |
| fallback fields | あり（envelope, food, daily, outlook, daily trend, actual comparison は fallback/current-engine として明示） |
| production report の正本 | current engine（`bqn main.bqn`） |
| `src_next` Snapshot の位置づけ | 観察用（observation target） |

現在の Snapshot は、`src_next/snapshot.bqn` と `tools/report-next-summary` に実装された最小観測画面です。
表示項目の詳細は `docs/SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md` §7 を参照してください。

---

## 3. Definition of Production-Equivalent Snapshot

### 3.1 定義

A `src_next` Snapshot **may be called production-equivalent** only when all of the following conditions are met:

1. **current engine の同等 section と比較できる。**
   - `bqn main.bqn` の Sec1（全体サマリ / Snapshot）と `src_next` Snapshot の対応 fields を並べて比較できる。
   - 比較対象の fields が明記されており、field-level の対応関係が定義されている。

2. **同じ production data から生成される。**
   - current engine と `src_next` が同じ `data/*.tsv` を読み、同じ as-of date で計算する。
   - fixture 比較の場合は同じ fixture セットを使う。

3. **amount fields の意味が一致している。**
   - cycle income actual / expense actual / net actual / plan expense 等、共通する金額 fields が整数円で一致する。
   - 意味の違いがある場合は意図的な置き換えとして文書化されていること。

4. **account / label / display mapping の意味が一致している。**
   - source TSV の account key と同じ意味を保つ。
   - display mapping に差分がある場合は明記されていること。

5. **cycle boundary の扱いが一致している。**
   - current engine と同じ cycle start / end / day_count を使う。
   - `incomeAnchor` cycle mode の解決が current engine と同等である。

6. **missing / unknown / skipped rows の扱いが明示されている。**
   - skipped rows の reason（unknown account / out-of-cycle / invalid）が分類されている。
   - unknown accounts が `unknown` として観察できる。

7. **差分が expected difference / bug / unsupported のいずれかに分類できる。**
   - 分類体系は `docs/SRC_NEXT_REPLACEMENT_READINESS.md` §5 および本文書 §6 を使う。
   - 未分類の差分を残さない。

8. **unsupported がある場合、それを production-equivalent の対象外として明記できる。**
   - unsupported fields の一覧が本文書 §4.2（out of scope）に反映されている。
   - unsupported を黙って 0 にしたり、推測で値を作ったりしない。

### 3.2 現在の状態に対する判定

現在の `src_next` Snapshot は、以下の理由により **production-equivalent とは呼べない**。

| 条件 | 判定 | 理由 |
|:---|:---|:---|
| current engine との比較可能 | **未充足** | 比較 criteria が未定義（本 PR で定義する）。比較手順が未確立（Gate B）。 |
| 同じ production data から生成 | **充足** | 同じ `data/*.tsv` を読み込む。 |
| amount fields の意味一致 | **一部充足** | cycle income/expense/net/plan は一致確認済み。ただし envelope / liquid assets 等はまだ未比較。 |
| account / label mapping の一致 | **一部充足** | account key は一致。display mapping の差分は未調査。 |
| cycle boundary の扱い一致 | **充足** | `incomeAnchor` cycle 解決は current engine と同等（PR #20）。 |
| skipped rows の扱いの明示 | **充足** | skipped reason 分類が実装済み。 |
| 差分の分類 | **未充足** | 分類体系はあるが、production data での全 field 比較が未完了。 |
| unsupported の明示 | **充足** | fallback/current-engine として明示されている。 |

---

## 4. Comparison Scope

### 4.1 In Scope（比較対象）

production-equivalent Snapshot criteria の比較対象:

| カテゴリ | 内容 |
|:---|:---|
| **production data** | `data/*.tsv` から生成される Snapshot observation |
| **current engine Snapshot** | `bqn main.bqn` の Sec1（全体サマリ / Snapshot）、および相当する exporter output（`export-canonical-snapshot.bqn`, `export-report-numbers.bqn`） |
| **account balances** | nonzero actual account totals |
| **cycle actual totals** | cycle income actual / expense actual / net actual |
| **plan totals** | plan expense |
| **cycle range** | cycle start / end / day_count |
| **readiness counts** | valid / skipped / unknown account counts |
| **status 表示** | skipped / unavailable / unknown の status |
| **next income / remaining days** | next income date、remaining days（`src_next` が計算可能な場合） |

### 4.2 Out of Scope（比較対象外）

以下は production-equivalent Snapshot criteria の比較対象外とし、別の criteria で扱う:

| カテゴリ | 理由 |
|:---|:---|
| **envelope production advice** | envelope computation は fixture-only prototype。production data では `unavailable/src_next` を維持。 |
| **safe_remaining** | 未実装。実装前の契約が必要（Gate E）。 |
| **daily_amount** | 未実装。実装前の契約が必要（Gate E）。 |
| **per-day allowance** | 未実装。 |
| **outlook** | Section 9 相当は missing src_next feature。 |
| **forecast** | missing src_next feature。 |
| **daily trend** | Section 10 相当は missing src_next feature。 |
| **actual comparison 本実装** | Section 11 相当は missing src_next feature。 |
| **production replacement** | Stage 5 の作業。現在の段階ではない。 |
| **data/*.tsv 編集** | `src_next` は read-only。 |
| **UI polish** | ASCII art、表示整形は表示層の作業。 |
| **automatic migration** | 自動移行は行わない。 |

---

## 5. Field-Level Criteria

各 field class について、equivalence の判定方法を定義する。

| Field class | Criteria | 判定方法 |
|:---|:---|:---|
| **date / cycle fields** | current engine と同じ cycle boundary を使う | cycle start / end / day_count が一致することを確認。`incomeAnchor` 解決も同等であること。 |
| **account identifiers** | source TSV の account key と同じ意味を保つ | account key が current engine の account_space と一致することを確認。 |
| **labels** | display mapping の差分があれば明記する | account label、group label の差分を分類する。意図的な置き換えであれば理由を記録する。 |
| **actual amounts** | current engine と整数円で一致する | `export-report-numbers.bqn` と `src_next` の出力を突合。 |
| **plan amounts** | current engine と同じ plan source を使う。cycle は半開区間 `[cycle_start, cycle_end_exclusive)` で扱い、`cycle_end_exclusive` 当日の plan rows は current cycle に含めない。 | `plan.tsv` から projection された金額が一致することを確認。境界日 plan rows は cycle-bounded comparison の対象外。境界日を含めた export semantics は別途比較する（手順書 §6 Area 4b）。 |
| **budget amounts** | current engine と同じ budget source を使う | `budget_alloc.tsv` から導出した金額が一致することを確認。 |
| **unavailable fields** | production-equivalent 対象外として明示する | unavailable fields の一覧を本文書 §4.2 に反映。値は `unavailable/src_next` または `fallback/current-engine` と表示する。 |
| **skipped rows** | skipped reason を分類できる | unknown account / out-of-cycle / invalid 等の reason を current engine の lint/check と比較する。 |
| **unknown accounts** | unknown として観察できる | `src_next` と current engine の unknown account list が一致することを確認。 |

---

## 6. Difference Classification

`src_next` Snapshot と current engine の差分が出た場合、必ず次のいずれかに分類する。
分類体系は `docs/SRC_NEXT_REPLACEMENT_READINESS.md` §5 と同一とする。

| 分類 | 意味 | 次の行動 |
|:---|:---|:---|
| `expected/current-engine-difference` | current engine と `src_next` の責任境界の違いによる既知差分 | 意図的な置き換え理由を記録する。追加修正は不要。 |
| `bug/src_next` | `src_next` 側の計算または投影の誤り | 修正する。修正後、再比較する。 |
| `bug/current-engine` | current engine 側の既知または疑いのある誤り | 両方の engine を安易に変えず、調査する。 |
| `unsupported/src_next` | `src_next` がまだ対応していない field / behavior | 現 stage の blocking gap として扱う。実装計画に反映する。 |
| `policy/not-engine` | household policy data の扱いであり engine equivalence の対象外 | 別の policy contract で扱う。 |
| `requires-contract` | `safe_remaining` / `daily_amount` / `outlook` など、契約なしには判定できないもの | 実装より前に contract doc を作成する。 |

### Boundary-Day Plan Row Classification

`cycle_end_exclusive` 上の plan rows が原因で差分が出た場合の分類指針:

| 状況 | 分類 |
|:---|:---|
| `src_next` が半開区間契約に従って境界日 rows を除外し、subset では一致する | `expected/current-engine-difference` |
| どちらの cycle に属すべきか docs 上で未定義 | `requires-contract` |
| `src_next` が半開区間契約に反して境界日を含んでいる、または誤って除外している | `bug/src_next` |
| current engine の export が docs 上の契約と矛盾する | `bug/current-engine` |
| 判断不能 | `unclassified`（Stage 4b blocker） |

**未分類の差分を残したまま、production-equivalent とは呼ばない。**

---

## 7. Manual Comparison Procedure

Stage 4b 前に使う手動比較手順を定義する。
この手順は Gate B（Manual Comparison Procedure）の充足にも使う。

**正本手順書:** 完全な手順・記録形式・Gate B 充足条件は `docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` を参照すること。
このセクションは概要であり、実際の比較実施時は正本手順書に従う。

### 手順

1. **current engine の production report を出す。**
   ```sh
   bqn main.bqn --base data
   ```
   必要に応じて `--as-of DATE` を指定する。

2. **current engine の機械可読 export を出す。**
   ```sh
   bqn src/reports/exporters/export-report-numbers.bqn --base data
   bqn src/reports/exporters/export-canonical-snapshot.bqn --base data
   ```

3. **`src_next` の Snapshot observation を出す。**
   ```sh
   tools/report-next-summary data
   ```
   必要に応じて fixture で比較する場合は `fixtures/basic` 等を使う。
   ```sh
   bqn main.bqn --base fixtures/basic --as-of 2026-01-03
   tools/report-next-summary fixtures/basic
   ```

4. **Snapshot 関連 section / fields を並べて確認する。**
   - Sec1（全体サマリ / Snapshot）と `--- SrcNext Snapshot ---` section を比較する。
   - `export-report-numbers.bqn` の TSV と `src_next` の summary から抽出可能な fields を比較する。

5. **一致 / 不一致 / unsupported / unavailable を記録する。**
   - divergence log format は `docs/SRC_NEXT_STAGE4_TRIAL_LOG.md` §12 を使う。
   - 実金額は public repo に commit しない。private log に記録する。

6. **不一致は §6 の分類に入れる。**
   - `expected/current-engine-difference`
   - `bug/src_next`
   - `bug/current-engine`
   - `unsupported/src_next`
   - `policy/not-engine`
   - `requires-contract`

7. **未分類差分が残る場合、production-equivalent とは呼ばない。**
   - すべての差分が分類されるまで、production-equivalent Snapshot とは宣言しない。

### 注意

- **この PR では command を新規追加しない。**
- **既存 command（`bqn main.bqn`, `tools/report-next-summary`）の範囲で比較手順を書く。**
- **実装変更が必要な場合は別 PR に分離する。**

---

## 8. Gate A Satisfaction Criteria

Stage 4b readiness gate の **Gate A: Snapshot Equivalence Readiness** が satisfied と呼べる条件。

Gate A is satisfied when all of the following are true:

- [ ] **`docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` が `main` ブランチに存在する。**
- [ ] **comparison scope が定義されている。**（本文書 §4）
- [ ] **field-level criteria が定義されている。**（本文書 §5）
- [ ] **difference classification が定義されている。**（本文書 §6）
- [ ] **manual comparison procedure が定義されている。**（本文書 §7）
- [ ] **unsupported fields の扱いが定義されている。**（本文書 §4.2）
- [ ] **production-equivalent と呼んではいけない状態が明記されている。**（本文書 §3.2）

本 PR の merge により、上記の criteria 定義は満たされる。
ただし、実際の比較実施と差分分類（Gate B）は別途必要である。

Gate 充足状態（本 PR merge 後）:

| Gate | 内容 | 状態 |
|:---|:---|:---|
| A | Snapshot equivalence readiness | **satisfied** — criteria 定義済み |
| B | Manual comparison procedure | **not satisfied** — 手動手順は定義されたが、実際の比較実施は未完了 |

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
| 6 | Stage 4b daily-use trial を開始しない | この文書は criteria 定義であり、開始宣言ではない |
| 7 | production replacement をしない | Stage 5 の作業 |
| 8 | production default switch をしない | `src_next` を `main.bqn` の既定ルートにしない |
| 9 | envelope computation を production advice にしない | envelope は `unavailable/src_next` を維持 |
| 10 | `safe_remaining` を実装しない | later work。実装前の契約が必要 |
| 11 | `daily_amount` / per-day allowance を実装しない | later work。実装前の契約が必要 |
| 12 | `outlook` を実装しない | missing src_next feature |
| 13 | source TSV format を変更しない | `data/*.tsv` の列定義は不変 |

---

## 10. Related Documents

- [SRC_NEXT_STAGE4B_TRIAL_SCOPE.md](SRC_NEXT_STAGE4B_TRIAL_SCOPE.md) — Stage 4b trial scope（allowed observation areas / out-of-scope areas / prohibited advice usage）
- [SRC_NEXT_STAGE4B_READINESS_GATE.md](SRC_NEXT_STAGE4B_READINESS_GATE.md) — Stage 4b daily-use trial readiness gate 定義（Gate A の本拠）
- [SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md](SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md) — Stage 4a 観測面棚卸し
- [SRC_NEXT_REPLACEMENT_READINESS.md](SRC_NEXT_REPLACEMENT_READINESS.md) — 置き換え準備チェックリスト（Stage 1〜5 gate、差分分類体系 §5）
- [SRC_NEXT_REPORT_SECTION_PARITY.md](SRC_NEXT_REPORT_SECTION_PARITY.md) — レポートセクション適合度マトリクス
- [SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md](SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md) — Snapshot 観測画面設計（実装済み範囲 §7）
- [SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md](SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md) — 手動比較手順の正本（Gate B 充足の手順書）
- [SRC_NEXT_STAGE4_TRIAL_LOG.md](SRC_NEXT_STAGE4_TRIAL_LOG.md) — Stage 4 観察ログ template（divergence log format §12）
- [SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md](SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md) — 封筒計算仕様契約
- [SRC_NEXT_CURRENT_ENGINE_COMPARISON.md](SRC_NEXT_CURRENT_ENGINE_COMPARISON.md) — current engine との比較 notes
- [CURRENT_STATE_REFERENCE.md](../completed-plans/CURRENT_STATE_REFERENCE.md) — 現行エンジン比較基準
