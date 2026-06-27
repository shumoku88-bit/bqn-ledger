# Cycle-end Envelope Consultation Task

Status: manual consultation task packet / no implementation approved
Date: 2026-06-22

This packet is for asking an AI consultant to help review the end of a cycle and draft the next cycle's envelope allocation.

It follows:

- `docs/EXTERNAL_REASONING_BOUNDARY.md`
- `docs/EXTERNAL_REASONING_NEUTRAL_LANGUAGE_POLICY.md`
- `docs/AI_TASK_PACKET_TEMPLATE.md`

## Task packet

```text
bqn-ledger の cycle-end envelope consultation をしてください。

目的:
- 次サイクルの Daily / flex / reserve 配賦案を、人間が判断するための draft として出す。
- 支出見直し材料として、金額だけでなく plan外 actual のペース・タイミング・余白を観察する。
- 相談結果を canonical output や budget_alloc.tsv の更新として扱わない。

読む文書:
- AGENTS.md
- TODO.md
- docs/EXTERNAL_REASONING_BOUNDARY.md
- docs/EXTERNAL_REASONING_NEUTRAL_LANGUAGE_POLICY.md
- docs/SAFETY_PROFILE.md
- docs/PLAN.md
- docs/CYCLE.md
- docs/ACTUAL_COMPARISON_REPORT_PLAN.md

読むデータ/出力:
- BQN report / BQN export output supplied by the human
- current cycle date range and next cycle date range supplied by the human
- current envelope summary supplied by the human
- seed可能額 / 配賦上限 supplied by the human
- actual-comparison output if supplied
- section status / WARN / UNAVAILABLE status if supplied
- plan外 actual 日別表 if supplied
- actual 全体の日別表 if supplied

触ってよいファイル:
- なし。これは相談タスクです。

触らないファイル:
- data/journal.tsv
- data/plan.tsv
- data/budget_alloc.tsv
- data/accounts.tsv
- data/*.tsv
- src/**
- editor/**
- tools/**

非目標:
- source TSV を編集しない。
- budget_alloc.tsv を更新しない。
- BQNの数字を再計算して正本扱いしない。
- plan外支出を悪い支出として扱わない。
- 相談結果を自動適用しない。

言葉の方針:
- `docs/EXTERNAL_REASONING_NEUTRAL_LANGUAGE_POLICY.md` に従う。
- 中立的な観察語を使う。
- 例: ペース, リズム, タイミング, 余白, 確認候補, 見直し候補, 変化。
- BQN の `WARN` / `UNAVAILABLE` は status として引用してよいが、生活判断へ変換しない。

観察するもの:
- amount_review: 金額として大きい項目。
- unplanned_pace_review: plan.tsv にない actual 支出のペース。
  - plan外 actual 日別表が supplied されていない場合は推測しない。
  - その場合、unplanned_pace_review は `data_notes` に不足として書くか、相談全体を `blocked_by_unavailable_data` にする。
- timing_pattern_review: 週末, 収入直後, サイクル終盤, 特定日周辺の変化。
- margin_review: 残日数と封筒残額の余白。

特に見るもの:
- plan外 actual 食費の日別ペース（plan外 actual 日別表が supplied されている場合のみ）。
- plan外 actual タバコの日別ペース（plan外 actual 日別表が supplied されている場合のみ）。
- actual 全体の食費 / タバコの日別表が supplied されている場合は、amount_review や補助観察として使ってよい。ただし plan外 pace signal と混ぜない。
- 週末周辺の食費の変化。
- 収入直後の変動費の前寄り。
- サイクル終盤の残り余白。
- 単発支出が短期間にまとまった箇所。

出力形式:
consultation_type: cycle_end_envelope_consultation
status: draft | needs_human_decision | blocked_by_unavailable_data
uses:
  - bqn_export_or_report_name
  - as_of
  - cycle_id_or_period
observations:
  amount_review:
    - <BQN由来の数字と短い観察>
  unplanned_pace_review:
    - <plan外actualのペース観察>
  timing_pattern_review:
    - <週末/収入直後/終盤/特定日周辺の観察>
  margin_review:
    - <残日数と残額の余白観察>
proposal:
  Daily: <draft amount or range, or unavailable if seed/limit/envelope input is missing>
  flex: <draft amount or range, or unavailable if seed/limit/envelope input is missing>
  reserve: <draft amount or range, or unavailable if seed/limit/envelope input is missing>
rationale:
  numbers_from_bqn:
    - <数字>
  assumptions:
    - <前提>
  interpretation:
    - <中立的な読み取り>
data_notes:
  - <不足・古さ・対応関係の不明点>
do_not_apply_automatically: true

確認:
- budget_alloc.tsv は変更していない、と明記する。
- source TSV は変更していない、と明記する。
- 提案は人間判断用の draft だと明記する。
```

## Human preparation checklist

Before using this packet, prepare a small set of BQN-derived material.

Keep inputs compact. Prefer `tools/query` (over `tools/report-next-summary`) or selected report sections over full decorative output when possible.

### Required inputs for an allocation draft

These are required if the consultant should propose Daily / flex / reserve amounts.

```text
- current cycle date range
- next cycle date range
- current envelope summary or envelope report
- seed可能額 or next-cycle allocation upper limit
- current Daily / flex / reserve framing
```

If seed可能額 / 配賦上限 or envelope summary is missing, the consultant must not invent allocation amounts. It should set proposal amounts to `unavailable`, explain the missing input in `data_notes`, or use `status: blocked_by_unavailable_data` when allocation is the main request.

### Required inputs for unplanned pace review

These are required if the consultant should observe plan外 actual pace.

```text
- plan外 actual 食費 daily table for the cycle
- plan外 actual タバコ daily table for the cycle
- the BQN export/report name and as_of used to produce those tables
```

If the plan外 actual daily tables are not supplied, `unplanned_pace_review` must not be inferred from actual totals or raw intuition. The consultant should write the missing table in `data_notes`, and either leave `unplanned_pace_review` unavailable or set `status: blocked_by_unavailable_data` when pace review is the main request.

### Optional inputs

These can improve the consultation but should not be treated as required source truth.

```text
- actual 全体の食費 daily table for the cycle
- actual 全体のタバコ daily table for the cycle
- actual-comparison summary if available
- section status summary if available
- notes about known one-off events supplied by the human
```

Actual 全体の日別表 can support amount/timing observations, but it must be kept separate from plan外 actual pace signals.

### If unavailable

```text
- missing next cycle date range: note it in data_notes; avoid date-specific allocation rationale
- missing seed可能額 / 配賦上限: do not propose concrete allocation amounts
- missing envelope summary: do not claim current remaining room
- missing plan外 actual daily tables: do not perform unplanned_pace_review
- unavailable / WARN section status: quote as BQN status only; do not turn it into lifestyle judgment
```

## Expected style

The consultant should sound like an observation assistant, not a judge.

Good:

```text
食費はサイクル前半に寄っています。
週末周辺で食費が増えています。
終盤のDaily余白が小さくなっています。
タバコのペースはこの日付周辺で変化しています。
```

Avoid meaning-heavy wording. See `docs/EXTERNAL_REASONING_NEUTRAL_LANGUAGE_POLICY.md` for the wording policy.

## Retrospective / replay test mode

A retrospective / replay test may be used before a real cycle-end decision.

Purpose:

```text
- confirm that this consultation packet is usable
- confirm that missing input is handled as unavailable
- confirm that no allocation is invented without BQN-derived material
```

Replay test is not a production budget decision. It must not be applied to `budget_alloc.tsv` or any source TSV.

If no BQN material is supplied, the minimum output should be blocked rather than inferred:

```yaml
consultation_type: cycle_end_envelope_consultation
status: blocked_by_unavailable_data
uses:
  - no BQN export/report supplied in this replay
  - as_of: unavailable
  - cycle_id_or_period: unavailable
observations:
  amount_review:
    - unavailable: BQN-derived amount summary was not supplied.
  unplanned_pace_review:
    - unavailable: plan外 actual daily table was not supplied. No pace inference was made.
  timing_pattern_review:
    - unavailable: daily actual table and cycle dates were not supplied.
  margin_review:
    - unavailable: envelope summary and remaining-room data were not supplied.
proposal:
  Daily: unavailable
  flex: unavailable
  reserve: unavailable
rationale:
  numbers_from_bqn:
    - none supplied
  assumptions:
    - This is a retrospective replay test, not a budget decision.
  interpretation:
    - Required inputs were missing, so no concrete allocation was proposed.
data_notes:
  - missing BQN envelope summary
  - missing seed可能額 / 配賦上限
  - missing plan外 actual daily tables
  - missing cycle dates or as_of
do_not_apply_automatically: true
confirmation:
  - budget_alloc.tsv was not changed.
  - source TSV was not changed.
  - This is a human-review replay test only.
```

Do not implement these before a later explicit decision:

```text
- unplanned actual daily spending export
- planned-vs-unplanned 判定ロジック
- compact consultation input bundle
- consultant automation
- budget_alloc.tsv 自動更新
- actual 全体から plan外 pace を推測する heuristic
```

## Next possible step

After trying this manually, decide whether the next work should be:

```text
A. improve this consultation packet
B. design a BQN export for unplanned actual daily spending
C. create a compact consultation input bundle
D. keep the consultation manual for now
```
