# src_next Comparison Record Template

Status: docs-only template / no actual comparison data
Branch: `docs-src-next-comparison-record-template`

この文書は、`docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` に従って current engine と `src_next` の出力を手動比較した結果を記録するための **template** です。

重要:
- **これは記録用 template であり、実 comparison result ではない。**
- **Stage 4b daily-use trial を開始する文書ではない。**
- **current engine（`bqn main.bqn`）が production source of truth である。**
- **`src_next` は observation target のままである。**
- **実 comparison はまだ実施していない。**

---

## 1. Purpose

この文書の目的:

- `docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` §5 の Comparison Record Format に従い、手動比較結果を記録するための template を提供する。
- comparison 実施者がこの template を複製し、空欄を埋めることで比較記録を作成できるようにする。
- 記録形式を統一し、比較結果の読みやすさと分類の一貫性を保つ。

明記すること:

- **この文書自体は空の template である。**
- **実 comparison result を含まない。**
- **comparison 実施時にこの template を複製して使用する。**
- **複製先は private log（例: `~/notes/stage4-comparison-YYYY-MM-DD.md`）を推奨する。**
- **実金額を含む記録は public repo に commit しない。**

---

## 2. Usage

この template の使い方:

1. この文書を複製する。
   ```sh
   cp docs/SRC_NEXT_COMPARISON_RECORD_TEMPLATE.md ~/notes/stage4-comparison-YYYY-MM-DD.md
   ```
2. `docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` §4 の Comparison Workflow に従って比較を実施する。
3. 複製したファイルの空欄を埋める。
4. 実金額を含む記録は private log にのみ残す。public repo には commit しない。
5. 公開可能な fixture 比較の結果は、PR 本文または docs follow-up として記録してもよい。

---

## 3. Metadata Template

comparison 実施時に以下の表を埋める。

| Field | Value |
|:---|:---|
| comparison date | YYYY-MM-DD |
| cycle | （例: 2026-06 / 2026-07） |
| production data revision | （`git rev-parse HEAD` の短縮形、または data snapshot の識別子） |
| current engine command | `bqn main.bqn --base data` （as-of 指定があれば記載） |
| current engine as_of | （`main.bqn` Sec9 基準日、または `--as-of` 指定値） |
| src_next command | `tools/report-next-summary data` （as-of 指定があれば記載） |
| src_next as_of | （`tools/report-next-summary` の SrcNext Snapshot as_of 行） |
| as_of match? | `yes` / `no`（`no` の場合、remaining_days 等の派生差分の原因になる） |
| operator | （比較実施者名） |
| result status | `draft` / `complete` / `blocked` |
| blocker reason | （`blocked` の場合のみ記入。例: unsupported fields 多数、契約未定義、data 不備） |

---

## 4. Field-Level Comparison Table

`docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` §6 の Required Comparison Areas に従い、各 field を記録する。

比較元:
- Current engine: `bqn main.bqn --base data` の Sec1 / Sec4 / Sec8、および `export-report-numbers.bqn` の TSV
- src_next: `tools/report-next-summary data` の `--- SrcNext Snapshot ---` / `--- SrcNext Cycle Summary ---` section

| Area | Current engine | src_next | Result | Classification | Notes |
|:---|:---|:---|:---|:---|:---|
| as_of（観測日） | | | `match` / `mismatch` | — | 記録用。mismatch の場合、remaining_days 等の派生差分の原因を Notes に記録。 |
| cycle boundary (start/end/day_count) | | | `match` / `mismatch` / `unavailable` / `unsupported` | | |
| actual totals (income/expense/net) | | | `match` / `mismatch` / `unavailable` / `unsupported` | | |
| account balances (nonzero) | | | `match` / `mismatch` / `unavailable` / `unsupported` | | account key ごとに記録 |
| plan totals baseline / cycle-bounded (4a) | | | `match` / `mismatch` / `unavailable` / `unsupported` | | **4a-1**: current engine value（半開区間内の手動集計）を記録。**4a-2**: src_next value（plan_expense）を記録。**4a-3**: strict cycle-bounded match?（yes/no）。**4a-4**: boundary rows present on cycle_end_exclusive?（列挙）。**4a-5**: subset comparison performed?（yes/no + 結果）。**4a-6**: result（match/mismatch）。**4a-7**: classification。半開区間 `[cycle_start, cycle_end_exclusive)` で比較する。境界日 rows は含めない。 |
| plan totals export semantics (4b) | | | `match` / `mismatch` / `unavailable` / `unsupported` | | **4b-1**: current engine export includes boundary rows?（yes/no）。**4b-2**: src_next export/observation includes boundary rows?（yes/no）。**4b-3**: current engine export scope（future-only / cycle-total 等）。**4b-4**: src_next export scope（cycle-total / future-only 等）。**4b-5**: result（match/mismatch）。**4b-6**: classification。scope が異なる場合は `expected/current-engine-difference`。
| budget totals | | | `match` / `mismatch` / `unavailable` / `unsupported` | | src_next に budget layer がない場合は `unsupported` |
| skipped rows (count / reason) | | | `match` / `mismatch` / `unavailable` / `unsupported` | | reason 分類を含む。モデル差（raw journal vs projection）の場合は `unsupported` |
| valid rows | | | `match` / `mismatch` / `unavailable` / `unsupported` | | モデル差（raw journal vs projection）の場合は `unsupported` |
| unknown accounts | | | `match` / `mismatch` / `unavailable` / `unsupported` | | unknown account list を比較 |
| envelope production guard | — | | `unavailable/src_next` 維持確認 | | `computed` になっていないこと |
| next income | | | `match` / `mismatch` / `unavailable` / `unsupported` | | `src_next` が計算可能な場合のみ |
| unavailable production advice fields | — | | `unavailable` / `unsupported` | | `net_worth`, `daily_remaining`, envelopes, `daily_amount`, `safe_remaining`, outlook など、`src_next` production advice に使えない fields を列挙。概念あり/なしで unavailable/unsupported を使い分ける |
| remaining days | | | `match` / `mismatch` / `unavailable` / `unsupported` | | as_of 差に起因する mismatch は `expected/current-engine-difference` に分類 |
| actual_comparison | | | `match` / `mismatch` / `unavailable` / `unsupported` | | `not_implemented` の間は `unsupported/src_next` |

Result 列の値は `docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` §5.1 に従う:

| Result | 意味 |
|:---|:---|
| `match` | 両 engine の値が整数円で一致する。 |
| `mismatch` | 両 engine の値が一致しない。§5 で差分分類し、§6 に記録する。 |
| `unavailable` | `src_next` がその値を現在提供していない。 |
| `unsupported` | `src_next` がその機能を実装していない。 |

---

## 5. Difference Classification Table

`mismatch` が発生した field について、`docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` §6 の分類体系に従って記録する。

分類 categories は `docs/SRC_NEXT_REPLACEMENT_READINESS.md` §5 と同一。

| Difference | Classification | Action | Blocking? |
|:---|:---|:---|:---|
| （差分のある field 名と値） | `expected/current-engine-difference` | document（理由を記録） | no |
| | `bug/src_next` | fix before Stage 4b（修正 PR を作成） | yes |
| | `bug/current-engine` | document separately（調査し、必要に応じて reclassify） | maybe |
| | `unsupported/src_next` | document unsupported scope（§4.2 の一覧に追加） | maybe |
| | `policy/not-engine` | exclude from engine equivalence（別契約で扱う） | no |
| | `requires-contract` | define contract first（実装より前に契約文書を作成） | yes |

Blocking 列の意味:

| Blocking? | 意味 |
|:---|:---|
| `yes` | この差分が解決されるまで Stage 4b を開始できない。 |
| `no` | Stage 4b 開始の blocker ではない。文書化のみでよい。 |
| `maybe` | 状況による。調査結果次第で blocking に変わる可能性がある。 |

調査メモや追加の詳細は Notes 列に記録する。

---

## 6. Summary Verdict Template

比較結果全体の verdict を以下に記録する。

```text
Overall result:
- [ ] match
- [ ] match with documented differences
- [ ] blocked by unsupported fields
- [ ] blocked by unclassified differences
- [ ] blocked by src_next bug
```

選択した verdict に `[x]` を付ける。該当する verdict を太字で示す。

verdict の意味:

| Verdict | 意味 | Stage 4b への影響 |
|:---|:---|:---|
| `match` | 全 field が一致。unsupported / unavailable もない。 | 理論上は blocker なし。ただし現実には unsupported fields が存在するため、この verdict が出る可能性は低い。 |
| `match with documented differences` | 差分はあるが、すべて `expected/current-engine-difference` または `policy/not-engine` に分類済み。`bug/*` や未分類差分はない。 | 文書化された差分のみであれば Stage 4b 開始の blocker にはならない。 |
| `blocked by unsupported fields` | `unsupported/src_next` の差分が残っており、production-equivalent の対象外 fields がある。 | unsupported fields を許容して trial に入るか、別途判断が必要。個別の unsupported field ごとに Gate 充足を判断する。 |
| `blocked by unclassified differences` | いずれの分類にも入らない差分が残っている。 | `docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` §7.3 に従い、Stage 4b を開始しない。調査を継続する。 |
| `blocked by src_next bug` | `bug/src_next` に分類された差分が残っており、修正が未完了。 | 修正 PR が merge されるまで Stage 4b を開始しない。 |

---

## 7. Additional Notes

comparison 実施中に記録すべき補足事項があればここに記入する。

```text
（例:
- fixture 比較ではすべて match したが、production data では unsupported fields が多数ある。
- current engine 側の export-report-numbers.bqn で field X の出力形式が想定と異なったため、手動で値を抽出した。
- as_of が 1 日ずれているため remaining_days が 1 日異なる。これは expected/current-engine-difference に分類。
- plan totals (4a): cycle_end_exclusive 上の plan rows が src_next では除外されており、strict cycle-bounded comparison では一致。境界日差分は expected/current-engine-difference に分類。
- plan totals (4b): export-report-numbers.bqn は将来分のみ、src_next はサイクル全体を出力するため export semantics で mismatch。expected/current-engine-difference に分類。
- budget totals: src_next に budget layer がないため unsupported。
- actual_comparison: src_next では not_implemented のため unsupported。
）
```

---

## 8. Explicit Non-Goals

この文書では以下を行わないことを明記する。

| # | Non-goal | 理由 |
|:---|:---|:---|
| 1 | 実 comparison を実施しない | この文書は template であり、comparison 実施手順ではない |
| 2 | Stage 4b daily-use trial を開始しない | 開始宣言は readiness gate 充足後の別の文書で行う |
| 3 | production replacement しない | Stage 5 の作業 |
| 4 | production default switch しない | `src_next` を `main.bqn` の既定ルートにしない |
| 5 | production TSV data を編集しない | `data/*.tsv` は不変 |
| 6 | `main.bqn` を変更しない | 本番 default は不変 |
| 7 | BQN 実装を変更しない | この PR は docs-only |
| 8 | fixtures を変更しない | この PR は docs-only |
| 9 | check script の挙動を変更しない | この PR は docs-only |
| 10 | 実金額を public repo に commit しない | 実金額を含む記録は private log に置く |
| 11 | 新しい command を追加しない | 既存 command の範囲で比較を実施する |

---

## 9. Related Documents

- [SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md](SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md) — 手動比較手順の正本（Comparison Workflow §4、Comparison Record Format §5、Required Comparison Areas §6、Difference Handling §7）
- [SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md](SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md) — production-equivalent Snapshot criteria 定義（Comparison Scope §4、Field-Level Criteria §5、Difference Classification §6）
- [SRC_NEXT_REPLACEMENT_READINESS.md](SRC_NEXT_REPLACEMENT_READINESS.md) — 置き換え準備チェックリスト（差分分類体系 §5）
- [SRC_NEXT_STAGE4B_READINESS_GATE.md](SRC_NEXT_STAGE4B_READINESS_GATE.md) — Stage 4b daily-use trial readiness gate 定義（Gate A / Gate B / Trial Start Criteria §4 / Stop Criteria §7）
- [SRC_NEXT_STAGE4_TRIAL_LOG.md](SRC_NEXT_STAGE4_TRIAL_LOG.md) — Stage 4 観察ログ template（divergence log format §12）
- [SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md](SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md) — Stage 4a 観測面棚卸し
- [SRC_NEXT_STATUS_JA.md](SRC_NEXT_STATUS_JA.md) — src_next 全体状況
- [CURRENT_STATE_REFERENCE.md](CURRENT_STATE_REFERENCE.md) — 現行エンジン比較基準
