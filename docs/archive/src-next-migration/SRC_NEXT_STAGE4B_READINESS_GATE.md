# src_next Stage 4b Readiness Gate

Status: **historical / superseded by `docs/SRC_NEXT_CURRENT.md`**
Branch: `docs-src-next-stage4b-readiness-gate`

> Current daily operation uses `tools/bl` and `tools/report` with `src_next/report.bqn`.
> This document is a historical readiness gate from the migration period. Statements such as "production default is `bqn main.bqn`" and "Stage 4b not started" are not current behavior.
> See `docs/SRC_NEXT_CURRENT.md` and `docs/archive/audits/SRC_NEXT_DOCS_INVENTORY-2026-06-29.md`.

この文書は、`src_next` の **Stage 4b daily-use trial を開始するための readiness gate** を定義していた履歴文書です。

重要: この文書は Stage 4b の開始を宣言するものではありません。

---

## 1. Purpose

この文書の目的:

- Stage 4b daily-use trial に入る前に満たすべき条件を明文化する。
- Stage 4a（観測面整備）と Stage 4b（日常試用）の境界を固定する。
- 準備が整わないまま trial を開始することを防ぐ。
- いきなり実装を増やす前に、入口条件を最初に決める。

明記すること:

- **`src_next` はまだ production default ではない。**
- **production default は引き続き `bqn main.bqn` である。**
- **Stage 4b は trial であり、production replacement ではない。**
- **`src_next` は `data/*.tsv` を編集しない。**
- **この文書の全 gate が satisfied になるまで Stage 4b を開始しない。**

---

## 2. Current Stage

| 段階 | 状態 |
|:---|:---|
| **Stage 4a**: observation surface inventory | **completed**（PR #38 で台帳化済み） |
| **Stage 4b**: daily-use trial | **not started** |
| **Production replacement** (Stage 5) | **not started** |
| **Production default switch** (`main.bqn` → `src_next`) | **not allowed in this stage** |

現在地:

- Stage 4a では、PR #31 から PR #37 にかけて observation surface を拡充した。
- PR #38 で Stage 4a 観測面の棚卸し台帳（`docs/SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md`）を整備した。
- 次にやるべきことは、実装を増やすことではなく、Stage 4b に入る条件を定義することである。

Stage 4a 観測面の現状は `docs/SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md` §2 を参照。

---

## 3. Readiness Gates Before Stage 4b

Stage 4b daily-use trial に入る前に、以下の Gate A から Gate F がすべて satisfied でなければならない。

### Gate A: Snapshot Equivalence Readiness

目的: `src_next` Snapshot を current engine と比較可能にし、partial observation を production-equivalent と混同しない。

条件:

- [ ] `src_next` Snapshot が current engine の Snapshot/全体サマリ（Sec1）と比較可能である。
  - 比較可能とは、同じ as-of date と data set で両方の出力を取得し、field-level の対応を分類できる状態。
  - criteria 文書化だけでは満たされず、実 production data での比較結果が必要。
- [x] production-equivalent Snapshot criteria が定義されている。
  - 「どの fields が揃えば production-equivalent とみなすか」の基準が文書化されている。
  - 基準は `docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` に正本を置く。
  - 本 PR（`docs-src-next-snapshot-equivalence-criteria`）で定義済み。
- [x] partial/minimal Snapshot observation を production-equivalent と呼ばない。
  - 現在の partial Snapshot surface は production-equivalent ではない。
  - criteria 文書でも明記されている。
- [ ] 差分がある場合、expected difference / bug / unsupported のどれかに分類できる。
  - 分類体系は `docs/SRC_NEXT_REPLACEMENT_READINESS.md` §5 を使う。
  - 分類を実際に適用した結果が記録されていること。
  - 「なんとなく違う値」を残さない。
  - 境界日 plan rows による差分（`cycle_end_exclusive` 上の rows の扱い差）が `expected/current-engine-difference` として分類されている限り、それ単独では Gate A の blocker ではない。分類が未確定の場合は `requires-contract` または `unclassified` として扱う。

### Gate B: Manual Comparison Procedure

目的: current engine と `src_next` の出力を人力で比較し、結果を記録できる手順を確立する。

条件:

- [ ] `bqn main.bqn` の本番レポートと `src_next` summary/report を手動比較する手順がある。
  - 手順は `docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` に定義されている。
  - 少なくとも `tools/report-next-summary` と `bqn main.bqn` の出力を対象とする。
  - 手順は運用者が日本語で読めること。
- [ ] 比較対象の section / fields / fixture / production data が明記されている。
  - 比較対象 section: 最低限、Cycle Summary (Sec4)、Snapshot (Sec1)、Balances (Sec3)、Check (Sec8)。
  - 比較対象 fields: `docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` §6 を基準とする。
  - fixture 比較: `fixtures/basic` を最小 baseline として使う手順があること。
  - production data 比較: private log に記録する手順があること。実金額は public repo に commit しない。
- [ ] 手動比較結果を記録できる。
  - 記録形式は `docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` §5 を使う。
  - divergence log format は `docs/SRC_NEXT_STAGE4_TRIAL_LOG.md` §12 と互換。
  - 分類 categories は `docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` §6 を使う。

### Gate C: Envelope Computation Safety

目的: envelope computation prototype を production advice として扱わず、production data の防御を維持する。

条件:

- [ ] envelope computation は production advice として扱わない。
  - `src_next` の envelope output は observation 用であり、家計判断の材料にしない。
  - 「封筒残高が xxx 円だから大丈夫」のような生活判断に使わない。
- [ ] production data では guard が継続している。
  - `checks/check-src-next-envelope-production-guard.sh` が production data に対して通過する。
  - この check は `tools/check.sh` に統合されている。
- [ ] `src_next_envelope_status: unavailable/src_next` が production data で維持される。
  - production data の `tools/report-next-summary data` で、envelope status は `unavailable/src_next` または `fallback/current-engine` に留まる。
  - `computed` は production data に出さない。
- [ ] `computed` は fixture-only / opt-in の範囲に留める。
  - envelope computation が `computed` を返すのは fixture（特に `fixtures/src-next-envelope-computation`）のみ。
  - production route では `computed` に遷移させない。
- [ ] polished remaining を出さない。
  - 本番データ向けに整形された封筒残高（polished remaining）を出さない。
  - `safe_remaining`、`daily_amount`、per-day allowance は未実装のまま。

### Gate D: Household Policy Config Boundary

目的: `食費`、`daily`、`flex`、`reserve` などの家計ラベルを policy data として扱い、engine concept と混ぜない。

条件:

- [ ] `食費`、`daily`、`flex`、`reserve` は engine concept ではなく policy data として扱う。
  - 契約は `docs/SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md` §2 を正本とする。
  - コードがこれらのラベルを直接知ってはならない。
- [ ] household policy config を導入する場合、その契約が先に必要である。
  - policy file の shape、selector key/value、target_id/label の契約を文書化してから実装する。
  - 契約なしの policy config 実装は行わない。
  - 現時点では policy config は未導入。
- [ ] source TSV format を勝手に変更しない。
  - `accounts.tsv`、`journal.tsv`、`plan.tsv`、`budget_alloc.tsv`、`cycle.tsv` の列定義を変更しない。
  - 新しい metadata key が必要な場合は `config/meta_schema.tsv` と `docs/JOURNAL_META.md` を更新してから行う。

### Gate E: `safe_remaining` / `daily_amount` Contract

目的: 未実装の値が、契約なしに実装されることを防ぐ。

条件:

- [ ] `safe_remaining` は未実装である。
  - `safe_remaining = allocated - actual_spent - planned_spending` の計算は実装されていない。
  - `remaining` に planned spending を引いていない。
- [ ] `daily_amount` / per-day allowance は未実装である。
  - 日割り許容額の計算は実装されていない。
- [ ] 将来実装する場合は、実装より前に contract doc が必要である。
  - `safe_remaining` を実装する場合は、定義・境界・unavailable 条件を別途文書化する。
  - `daily_amount` を実装する場合は、`remaining_days` の定義・除外日・cycle end exclusive の扱いを別途文書化する。
  - 契約なしの実装は行わない。
- [ ] planned spending を `remaining` から引くかどうかは、別契約なしに変更しない。
  - 現在の fixture-only prototype は `remaining = allocated - actual_spent`（planned spending 非減算）。
  - この式を変更する場合は envelope computation contract の更新が必要。

### Gate F: Production Data Guard Checks

目的: production data の防御チェックが統合され、Stage 4b 中も弱めない。

条件:

- [ ] production data guard checks が `tools/check.sh` に統合されている。
  - `checks/check-src-next-envelope-production-guard.sh` が `tools/check.sh` のステップに含まれている。
  - guard check が production data に対して自動実行される。
- [ ] Stage 4b 中も guard を弱めない。
  - trial 中に guard を緩和しない。
  - envelope status が production data で `unavailable/src_next` から変わらないことを維持する。
- [ ] guard を外す PR は replacement readiness の別段階で扱う。
  - guard の解除は Stage 5（本番 default switch）の判断に含める。
  - Stage 4b 中は guard を外す PR を出さない。

---

Gate 充足状態の概要:

| Gate | 内容 | 現在の状態 |
|:---|:---|:---|
| A | Snapshot equivalence readiness | **satisfied** — production comparison recorded in `private/src-next-validation/validation-log.md` |
| B | Manual comparison procedure | **satisfied** — manual comparison executed and recorded |
| C | Envelope computation safety | **satisfied** — `unavailable/src_next` が production guard で維持されている |
| D | Household policy config boundary | **satisfied** — policy labels は engine concept ではないことが文書化されている |
| E | `safe_remaining` / `daily_amount` contract | **satisfied** — 未実装であり、実装前の契約要件が文書化されている |
| F | Production data guard checks | **satisfied** — guard が `tools/check.sh` に統合されている |

Gate A, B, C, D, E, F are now all satisfied. Stage 4b started 2026-06-25.

---

## 4. Stage 4b Trial Start Criteria

以下の条件がすべて満たされたとき、Stage 4b daily-use trial を開始してもよい。

- [ ] **この文書（`docs/SRC_NEXT_STAGE4B_READINESS_GATE.md`）が `main` ブランチに merge 済みである。**
- [ ] **Gate A**: Snapshot equivalence criteria が定義済み（`docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` に明記）。かつ、実 production data での比較結果が記録済みであること。
- [ ] **Gate B**: current engine と `src_next` の出力を比較する手動手順が確立されている。
- [ ] **Gate C**: envelope production guard が維持されている（`unavailable/src_next`）。
- [ ] **Gate D**: household policy labels が engine concept として扱われていない。
- [ ] **Gate E**: `safe_remaining` と `daily_amount` が未実装であり、実装前の契約要件が明記されている。
- [ ] **Gate F**: production data guard checks が `tools/check.sh` で維持されている。
- [ ] **`src_next` が production TSV（`data/*.tsv`）を編集しないことが明記・維持されている。**
- [ ] **trial scope が定義されている。**
  - `docs/SRC_NEXT_STAGE4B_TRIAL_SCOPE.md` に、allowed observation areas、out-of-scope areas、prohibited advice usage、pause conditions が明記されている。
  - scope 定義は Stage 4b 開始宣言ではない。
- [ ] **daily-use trial log location が定義されている。**
  - `docs/SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md` に従い、future Stage 4b daily-use trial log は `private/src-next-stage4b/daily-use-trial-log.md` とする。
  - daily-use trial log は private-only とし、public summary は production amounts / private log contents / production advice を含めない。
  - この定義は Stage 4b 開始宣言ではない。
- [ ] **trial の対象 cycle が決まっている。**
  - どの cycle から trial を開始するかが明示されている。
  - 対象 cycle の範囲（start date / end date）が決まっている。
- [ ] **stop / rollback criteria が決まっている。**
  - この文書の §7 の criteria を運用者が確認し、同意している。

---

## 5. Stage 4b Trial Operating Rules

Stage 4b daily-use trial 中は、以下の運用手順を必ず守る。

### 5.1 Production Default の維持

- **本番 default は `bqn main.bqn` のままとする。**
- `src_next` を default にする変更は行わない。
- `main.bqn` は rollback 用に常に利用可能な状態を保つ。

### 5.2 `src_next` の位置づけ

- `src_next` は観察用（observation）であり、production advice として扱わない。
- `src_next` の出力を家計判断の正本材料にしない。
- trial 中に「src_next の方が正しい」という前提で current engine の挙動を変えない。

### 5.3 `src_next` Output の扱い

- `src_next` output を production advice として扱わない。
- envelope 計算結果を生活判断に使わない。
- 「封筒残高が十分」「日割り額が安全」のような判断を `src_next` 出力から下さない。

### 5.4 Production Data の保護

- **`data/*.tsv` は `src_next` が編集しない。**
- `src_next` は read-only のままとする。
- `journal.tsv`、`plan.tsv`、`accounts.tsv`、`budget_alloc.tsv`、`cycle.tsv` への書き込みを一切行わない。

### 5.5 Production Report の正本

- **本番レポートの正本は current engine（`bqn main.bqn`）である。**
- `src_next` の出力を本番レポートの代わりにしない。
- 家計判断に使う数値は current engine から取得する。

### 5.6 差分の記録

- `src_next` と current engine の差分は observation として記録する。
- divergence log format は `docs/SRC_NEXT_STAGE4_TRIAL_LOG.md` §12 を使う。
- 差分の分類は `docs/SRC_NEXT_REPLACEMENT_READINESS.md` §5 を使う。
- 将来 Stage 4b を明示的に開始した場合、daily-use trial log は `private/src-next-stage4b/daily-use-trial-log.md` に置く。
- daily-use trial log は private-only とし、commit しない。
- public summary を作る場合は、production amounts / private log contents / production advice を含めず、status / classification / guardrail summaries のみにする。

### 5.7 禁止事項

- Stage 4b 中に `main.bqn` を `src_next` に切り替えない。
- Stage 4b 中に source TSV format を変更しない。
- Stage 4b 中に production envelope guard を緩和しない。
- Stage 4b 中に `safe_remaining` や `daily_amount` を契約なしに実装しない。
- Stage 4b 中に `食費`、`daily`、`flex`、`reserve` を engine concept として hard-code しない。
- Stage 4b 中に `src_next` の output を polished household advice として出さない。

---

## 6. Stage 4b Trial Exit Criteria

1 cycle の trial を終える条件:

- [ ] **1 cycle 分の production data で current engine と `src_next` を比較した。**
  - trial 対象 cycle の全期間について比較を実施。
  - 比較は cycle-end review として完了している。
- [ ] **差分が分類されている。**
  - すべての差分が `docs/SRC_NEXT_REPLACEMENT_READINESS.md` §5 のいずれかに分類されている。
  - 未分類の差分を残さない。
  - `regression candidate` は調査済みで、resolved または reclassified されている。
- [ ] **unsupported fields が明記されている。**
  - `src_next` がまだ出せない値が把握されている。
  - unsupported fields の一覧が `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` に反映されている。
- [ ] **envelope advice として使っていない。**
  - trial 期間中、`src_next` の envelope output を家計判断に使わなかったことを確認。
- [ ] **次に進むか、Stage 4a/4b に留まるか判断できる。**
  - Stage 5（本番 default switch）へ進むか、Stage 4a/4b でさらに観察を続けるか、運用者が判断できる材料が揃っている。
  - Stage 5 へ進む場合は `docs/SRC_NEXT_REPLACEMENT_READINESS.md` の Stage 5 gate を満たす必要がある。

---

## 7. Stop / Rollback Criteria

Stage 4b trial 中に以下のいずれかが発生した場合、trial を即時停止し、本番判断は `bqn main.bqn` に戻す。

| # | 停止条件 | 説明 |
|:---|:---|:---|
| 1 | `src_next` output が production advice と誤解される | 運用者または第三者が `src_next` の出力を家計判断の正本材料として使ってしまった場合。 |
| 2 | production data に computed envelope values が出る | `src_next_envelope_status` が production data で `computed` になってしまった場合。guard の不備。 |
| 3 | current engine と差分があるのに分類できない | 説明できない差分が残り、expected difference / bug / unsupported のいずれにも分類できない場合。 |
| 4 | source TSV format 変更が必要になった | `src_next` の都合で `data/*.tsv` の列構成を変える必要が生じた場合。 |
| 5 | `main.bqn` default switch を急ぐ圧力が出た | 「そろそろ `src_next` を本番にしよう」という判断圧力が、readiness gate の充足前に発生した場合。 |
| 6 | `safe_remaining` / `daily_amount` が契約なしに実装されそうになった | Gate E の境界を超える実装が提案・開始された場合。 |
| 7 | 本番レポートの情報が欠けて生活判断に支障が出た | `src_next` に切り替えたわけではないが、current engine との比較に集中するあまり本番確認がおろそかになった場合。 |

停止後の手順:

1. trial の停止を宣言する（private log に記録）。
2. 本番判断を `bqn main.bqn` に戻す。
3. 停止理由を分類し、対応方針を決める。
4. 再開する場合は、停止理由が解決したことを確認してから行う。

---

## 8. Explicit Non-Goals

この文書では以下を行わないことを明記する。

| # | Non-goal | 理由 |
|:---|:---|:---|
| 1 | Stage 4b を開始しない | この文書は readiness gate の定義であり、開始宣言ではない |
| 2 | production replacement しない | Stage 5 の作業であり、現在の段階ではない |
| 3 | `main.bqn` を変更しない | 本番 default は変更しない |
| 4 | production default switch しない | `src_next` を `main.bqn` の既定ルートにしない |
| 5 | source TSV format を変更しない | `data/*.tsv` の列定義は不変 |
| 6 | production data を編集しない | `journal.tsv`、`plan.tsv` 等への書き込みは行わない |
| 7 | `safe_remaining` を実装しない | later work であり、実装前の契約が必要 |
| 8 | `daily_amount` / per-day allowance を実装しない | later work であり、実装前の契約が必要 |
| 9 | outlook を production advice として実装しない | Section 9 は missing src_next feature |
| 10 | `食費` / `daily` / `flex` / `reserve` を engine concept にしない | policy labels として扱う（`docs/SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md` §2） |
| 11 | `tools/check.sh` の挙動を変えない | この PR は docs-only |
| 12 | BQN 実装を変更しない | この PR は docs-only |
| 13 | fixtures を変更しない | この PR は docs-only |

---

## 9. Related Documents

- [SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md](SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md) — Public-safe pretrial backlog before any Stage 4b start decision
- [SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md](SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md) — Daily-use trial private log path and public-safe summary rule
- [SRC_NEXT_STAGE4B_THIRD_DRY_RUN_PLAN.md](SRC_NEXT_STAGE4B_THIRD_DRY_RUN_PLAN.md) — Public-safe plan for a third manual comparison dry run before any Stage 4b start decision
- [SRC_NEXT_STAGE4B_THIRD_DRY_RUN_SUMMARY.md](SRC_NEXT_STAGE4B_THIRD_DRY_RUN_SUMMARY.md) — Public-safe summary of the completed private third dry run
- [SRC_NEXT_STAGE4B_TRIAL_SCOPE.md](SRC_NEXT_STAGE4B_TRIAL_SCOPE.md) — Stage 4b daily-use trial scope（observation-only、禁止される advice usage、pause conditions）
- [SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md](SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md) — Stage 4a 観測面棚卸し
- [SRC_NEXT_REPLACEMENT_READINESS.md](SRC_NEXT_REPLACEMENT_READINESS.md) — 置き換え準備チェックリスト（Stage 1〜5 gate）
- [SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md](SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md) — 封筒計算仕様契約
- [SRC_NEXT_REPORT_SECTION_PARITY.md](SRC_NEXT_REPORT_SECTION_PARITY.md) — レポートセクション適合度マトリクス
- [SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md](SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md) — Snapshot 観測画面設計
- [SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md](SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md) — production-equivalent Snapshot criteria 定義（Gate A の criteria 文書）
- [SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md](SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md) — current engine と src_next の手動比較手順（Gate B の手順書）
- [SRC_NEXT_STAGE4_TRIAL_LOG.md](SRC_NEXT_STAGE4_TRIAL_LOG.md) — Stage 4 観察ログ template
- [CURRENT_STATE_REFERENCE.md](../completed-plans/CURRENT_STATE_REFERENCE.md) — 現行エンジン比較基準
- [SRC_NEXT_CURRENT_ENGINE_COMPARISON.md](SRC_NEXT_CURRENT_ENGINE_COMPARISON.md) — current engine との比較 notes
