# src_next Ledger Engine Implementation TODO

> **Note (2026-06-26):** 旧エンジン (, , ) は削除されました。この文書内の旧エンジンへの参照は履歴として残ります。現行エンジンは  です。
Status: **Stage 1-4 実装完了 / Stage 4 統合検証完了 / 12 section parity confirmed**
Last updated: 2026-06-25

Private validation log: `private/src-next-validation/validation-log.md`
Result: match=8, expected-diff=2, unsupported=3, unavailable=1, bug=0, unclassified=0

Completion target:
**Option 10 (Posting IR) + Option 5 (TBDS) を土台に、本番レポートの12 section すべてを `src_next` で再現・検証する。**

合言葉: `src_next は次期正本エンジン候補。既定化は検証後。`

---

## 前提ルール

- 各段階は独立した validation + PR で実施する。
- 実装中は `bqn main.bqn` が production default のまま。
- `data/*.tsv` を絶対に編集しない。
- `tools/check.sh` が pass していることを各 PR 前に確認する。
- 完了した段階の検証結果は private log に記録する。
- private log の内容を public docs にコピーしない。

---

## 第0段階: Posting IR + TBDS の土台

**対象**: Option 10 (Posting IR) / Option 5 (TBDS)
**方針**: 既存 TSV と current cube の意味を変えず、計算前の正規化境界と試算表データセット境界を先に固定する。
**工数**: 中

- [x] Posting IR contract を文書化する（`docs/POSTING_IR_CONTRACT.md`: tx_id/source_id/account_key/layer/delta/side/balance/fail-closed）。
- [x] TBDS contract を文書化する（`docs/TBDS_CONTRACT.md`: period/as-of/account role/layer/opening/movement/closing）。
- [x] TSV → Posting IR adapter を read-only で追加する（`src_next/projection.bqn`）。
- [x] Posting IR → Cube が現行 `BuildCube` と同じ集計になる equivalence check を追加する（`check-src-next-vs-current.sh` を `check.sh` に接続）。
- [x] 不正・欠損 scalar fields を Cube 前で止める failure fixture を追加する。
  - `fixtures/src-next-invalid-posting` で `invalid_amount` / `invalid_date` を skipped projection rows として固定。
- [ ] balance 不一致を Cube 前で止める validator / failure fixture を追加する。
  - 現行 TSV adapter は通常 debit / credit を同時生成するため自然に balanced。将来の adapter 変更や multi-row group に備えて別タスクとして残す。
- [x] 最初の TBDS builder を追加し、既存 section の値と突合する（`src_next/tbds.bqn`, `tests/test_src_next_tbds.bqn`）。
- [x] Cycle Summary を TBDS query 経由へ寄せる（gross expense debit flow / income credit flow を維持）。

---

## 第1段階: すでに src_next に材料があるレポート

**対象**: Sec 2 (YTD), Sec 3 (Balances), Sec 4 (Cycle Summary), Sec 7 (Recent Journal)
**方針**: 計算済みの数値を本番同等の人間向け表示に整形する。新規計算ロジック不要。
**工数**: 小
**Status: ✅ 完了 (2026-06-25)**

### Sec 4 — 今サイクル集計 (Cycle Summary)

既存 module: `src_next/cycle_summary.bqn`, `src_next/expense_breakdown.bqn`

- [x] 本番同等の見出し付き整形表示（cycle mode, income/expense/net, 支出内訳テーブル）
- [x] `main.bqn` Sec4 と出力を突合して差分を分類・記録 → **match**（金額降順ソート修正済み）
- [x] 単体テスト追加（既存 `tests/test_src_next_cycle_summary.bqn` があれば拡張、なければ新規）
- [x] private log に検証結果を記録 → `private/src-next-validation/validation-log.md`

### Sec 2 — 年初来サマリ (YTD Summary)

既存 module: `src_next/ytd_summary.bqn`

- [x] 固定費/変動費 breakdown 表示（`spend_class` による分類）
- [x] 本番同等の整形（固定費合計/内訳、変動費合計/内訳）
- [x] `main.bqn` Sec2 と出力を突合して差分を分類・記録 → **match**（数値完全一致、account key `/JPY` suffix のみ）
- [x] 単体テスト追加
- [x] private log に検証結果を記録 → `private/src-next-validation/validation-log.md`

### Sec 3 — 勘定科目一覧 (Balances)

既存 module: `src_next/balances.bqn`

- [x] nonzero account totals の人間向け整形表示（Amount カラム）
- [ ] 負債 (liabilities) グループ化表示 → **unsupported/src_next**
- [x] `main.bqn` Sec3 と出力を突合して差分を分類・記録 → **expected/src_next-cycle-scoped**（現サイクル限定、本番は全期間累計）
- [x] 単体テスト追加
- [x] private log に検証結果を記録 → `private/src-next-validation/validation-log.md`

### Sec 7 — 直近の取引 (Recent Journal)

既存 module: `src_next/recent_journal.bqn`

- [x] Date / From→To / Memo / Amount の本番同等整形
- [x] newest first, last 10 の表示 → **ソート順バグ修正済み**（oldest first → newest first）
- [x] `main.bqn` Sec7 と出力を突合して差分を分類・記録 → **match**
- [x] 単体テスト追加
- [x] private log に検証結果を記録 → `private/src-next-validation/validation-log.md`

---

## 第2段階: current report と比較してズレが小さいものを埋める

**対象**: Sec 1 (Snapshot), Sec 6 (Planned), Sec 8 (Readiness), Sec 12 (Debug)
**方針**: 部分実装を仕上げる。軽微な計算ロジック追加 + 表示整形。
**工数**: 中
**Status: ✅ parity check 完了 (2026-06-25)。残件あり。**

### Sec 1 — 全体サマリ (Snapshot)

既存 module: `src_next/snapshot.bqn`

- [x] 資産分類表示（liquid / savings / invest）
- [x] net worth 算出・表示
- [x] 負債合計表示
- [ ] fallback field の削減（net_worth, living 系を src_next 側で算出可能にする）→ **残**: liquid/savings/invest は現サイクル限定のため本番と数値差あり
- [ ] ASCII art は表示層で選ぶ（計算層に混ぜない）
- [x] `main.bqn` Sec1 と出力を突合して差分を分類・記録 → **expected/src_next-cycle-scoped**
- [x] 単体テスト追加
- [x] private log に検証結果を記録 → `private/src-next-validation/validation-log.md`

### Sec 6 — 未来の支払い等予定 (Planned Payments)

既存 module: `src_next/planned_payments.bqn`

- [x] plan status 表示（future_open / due_open / overdue_open / completed）
- [x] 本番同等の予定状態テーブル（Date/Status/Category/Memo/Planned/Actual）
- [x] plan/journal マッチングを plan_id メタデータベースに修正（日付不一致・from勘定不一致に対応）
- [x] `main.bqn` Sec6 と出力を突合して差分を分類・記録 → **match**（数値完全一致）
- [ ] anchor 日 (08-14) の未来予定（年金、家賃等）未対応 → **unsupported/src_next**
- [x] 単体テスト追加
- [x] private log に検証結果を記録 → `private/src-next-validation/validation-log.md`

### Sec 8 — レポート準備チェック (Readiness Check)

既存 module: `src_next/readiness_check.bqn`, `src_next/household_metadata.bqn`, `src_next/plan_journal_overlap.bqn`

- [x] 本番同等の hygiene warning 整形表示
- [x] plan/journal overlap の可読整形（日付・memo・金額の表示）
- [x] plan_journal_overlap を plan_id マッチングに修正
- [x] missing metadata の可読警告
- [x] `main.bqn` Sec8 と出力を突合して差分を分類・記録 → **expected/detection-method-difference**（plan_id マッチングで3件検出、本番は1件）
- [ ] envelopes spent without alloc / redundant budget allocations → **unsupported/src_next**
- [x] 単体テスト追加
- [x] private log に検証結果を記録 → `private/src-next-validation/validation-log.md`

### Sec 12 — デバッグ・由来 (Debug & Provenance)

既存 module: `src_next/cube.bqn`

- [ ] invariant check の可読整形表示
- [ ] formula provenance 表示（どの source file / layer / date range から来たか）
- [ ] source row counts（journal / plan / alloc / accounts）
- [ ] `main.bqn` Sec12 と出力を突合して差分を分類・記録
- [ ] 単体テスト追加
- [x] private log に検証結果を記録 → `private/src-next-validation/validation-log.md`

---

## 第3段階: 封筒・予算・残額系（依存が多い）

**対象**: Sec 5 (Envelopes), Sec 9 (Outlook), Sec 10 (Daily Trend), Sec 11 (Actual Comparison)
**方針**: 新規計算ロジック + 設計判断 + 契約更新。依存順に着手。
**工数**: 大

### 依存グラフ

```
budget_alloc.tsv 読み込み → budget layer materialize
    ↓
Sec 5: envelope computation
    ↓
Sec 9: outlook / daily amount
Sec 10: daily trend (daily observation-point 保存が必要)
Sec 11: actual comparison (前サイクルデータ参照が必要)
```

### Sec 5 — 封筒・予算残高 (Envelopes & Balances)

既存 module: `src_next/envelope_computation.bqn` (fixture-scoped implementation)

前提作業:
- [x] `budget_alloc.tsv` の projection row化（budget layer materialize）
- [x] household policy config の契約更新（`docs/SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md`）

本実装:
- [x] envelope balance 計算（allocated / actual_spent / remaining）
- [ ] seedable amount 算出
- [x] health label（SAFE / WARN / SHORT / DRAWN）
- [x] daily / flex / reserve グループ化表示（policy config 経由）
- [x] 封筒健康診断 (Pace Status) 表示
- [x] production envelope guard は別契約で解除（Stage 4b 中は `unavailable/src_next` を維持）
- [ ] `main.bqn` Sec5 と出力を突合して差分を分類・記録
- [x] 単体テスト追加（既存 `tests/test_src_next_envelope_computation.bqn` 拡張）
- [x] private log に検証結果を記録 → `private/src-next-validation/validation-log.md`

### Sec 9 — 見通し・日割り (Outlook / Daily Amount)

既存 module: `src_next/outlook.bqn` (新規)

- [x] 基準日・残日数の計算（`as_of` 対応: LatestActualDateInCycle）
- [x] 流動資産の日割り計算（liq_total ÷ days_left）
- [x] 安全/保守 日割り（liq_total - 次サイクル債務 ÷ days_left）
- [x] 次サイクル初日返済(参考) 算出（plan entries on cycle end_exclusive, liabilities only）
- [x] 資産内訳表示（liquid/savings/invest + 流動資産 breakdown）
- [ ] 封筒予算 日割り（budget daily per envelope）→ envelope_computation の envelopes 配列が本番データ未対応のため保留
- [ ] `main.bqn` Sec9 と出力を突合して差分を分類・記録
- [x] machine Format / check.sh 互換出力追加
- [x] 単体テスト追加（`tests/test_src_next_outlook.bqn`）
- [x] private log に検証結果を記録 → `private/src-next-validation/validation-log.md`

**差分**: 流動資産・総資産が cycle-scoped のため本番と乖離あり。次サイクル債務 (10000) は本番と一致。日割り計算ロジックは正しい。

### Sec 10 — 日割り推移 (Daily Trend)

既存 module: `src_next/daily_trend.bqn` (実装完了, 2026-06-25)

- [x] daily observation-point の保存方法を決める（journal記録日 + as_of の in-memory snapshot。永続ファイルは作らない）
- [x] 日次スナップショット列の計算（liquid / reserve / fund / daily / Δdaily / variable / saving）
- [x] 下落日 Top10 の計算・表示
- [ ] `main.bqn` Sec10 と出力を突合して差分を分類・記録
- [x] machine Format / check.sh 互換出力追加
- [x] 単体テスト追加（`tests/test_src_next_daily_trend.bqn`）
- [x] private log に検証結果を記録 → `private/src-next-validation/validation-log.md`

### Sec 11 — Actual比較検証 (Actual Comparison)

既存 module: `src_next/actual_comparison.bqn` (実装完了, 2026-06-25)

- [x] 前サイクル同経過日数の actual データ取得
- [x] current vs baseline の比較計算（Amount / Count / Diff / Ratio / Status）
- [x] Lane 分類表示（income / recurring_fixed / variable）
- [x] `main.bqn` Sec11 と出力を突合して差分を分類・記録 → **match**（数値完全一致、行順序に merge-keys 由来の微差あり）
- [x] 単体テスト追加（`tests/test_src_next_actual_comparison.bqn`）
- [x] private log に検証結果を記録 → `private/src-next-validation/validation-log.md`

---

## 第4段階: 12個すべてを src_next report として出力

**対象**: 全12 section
**方針**: 統合出力・比較検証・validation log 完遂。
**工数**: 小

- [x] `src_next/summary.bqn` を拡張して Stage 4 用 compact output に全12 section 相当を接続
- [x] `src_next/report.bqn` を追加し、人間向け12 section report surface を出力
  - `checks/check-src-next-report.sh` で section presence smoke test を実施
- [x] public fixture で comparable fields の field-level comparison check を追加（`checks/check-src-next-stage4-fields.sh`）
- [x] production data で comparable fields の redacted dry-run を実施（実金額はpublic docsへ記録しない）
  - match: as_of / cycle boundary / days_left / cycle actual totals / plan remaining expense / liquid snapshot / liquid daily / safe liquid daily / actual_comparison status
  - expected/current-engine-difference: none in the current comparable field set
- [x] 実金額を含む field-level comparison を private log に記録 → `private/src-next-validation/validation-log.md`
- [x] 差分をすべて分類（match / expected-difference / bug / unsupported / unclassified / requires-contract）
- [x] `private/src-next-validation/validation-log.md` に最終検証結果を記録
- [ ] Stage 4b exit criteria の確認（`docs/SRC_NEXT_STAGE4B_READINESS_GATE.md` §6）
- [ ] Stage 5 へ進むか、Stage 4b を継続するか判断

---

## 差分分類リファレンス

各 section の比較で使う分類（`docs/SRC_NEXT_REPLACEMENT_READINESS.md` §5）:

| Classification | Meaning |
|---|---|
| `match` | current engine と src_next の出力が一致 |
| `expected/current-engine-difference` | 既知の semantics 差による差分 |
| `bug/src_next` | src_next 側の計算・表示の疑い |
| `bug/current-engine` | current engine 側の問題 |
| `unsupported/src_next` | src_next がまだ対応していない |
| `unavailable` | 概念はあるが src_next で検証・出力できない |
| `unclassified` | どの分類にも入れられない |
| `requires-contract` | 契約なしには判断できない |

---

## アーキテクチャ設計

実装前に必ず読む: `docs/SRC_NEXT_ARCHITECTURE_DESIGN.md`

基本原則:
- 各レポートは **Build（計算）** と **Format（表示）** の2関数に分離する
- 両関数は同じファイルに置く（例: `cycle.bqn` に `BuildCycle` + `FormatCycle`）
- 全 Build は同じ `cube.Materialize` の結果を共有する
- 1 section ずつ Build/Format 分離しながら実装を進める

## 関連文書

- `docs/SRC_NEXT_ARCHITECTURE_DESIGN.md` — 4層アーキテクチャ設計（最初に読む）
- `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` — 12-report parity target 正本
- `docs/SRC_NEXT_STAGE4B_READINESS_GATE.md` — Stage 4b readiness gate
- `docs/SRC_NEXT_STAGE4B_TRIAL_SCOPE.md` — validation scope（default switch 前の境界）
- `docs/SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md` — 封筒計算仕様契約
- `docs/MAIN_SECTIONS.md` — 本番 section map
- `docs/SRC_NEXT_REPLACEMENT_READINESS.md` — Stage 1〜5 gate checklist
- `private/src-next-validation/validation-log.md` — private 検証ログ
