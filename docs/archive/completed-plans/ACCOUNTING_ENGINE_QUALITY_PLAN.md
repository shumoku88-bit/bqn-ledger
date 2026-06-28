# Accounting Engine Quality Plan

Status: **active plan / accounting-grade redesign gate**
Date: 2026-06-26

## 1. 背景

`bqn-ledger` は、`bqn-kakeibo` の日常レポート表示を単に置き換えるための実験ではなく、会計ソフトとして筋の通った ledger engine を作るための場所として扱う。

現状の `src_next` には、家計レポートの一部数値が current engine と一致する箇所がある一方で、会計エンジンとして重要な境界が混ざっている。

特に重大な問題:

```text
cycle / period を ledger の読み込み境界にしている。
```

その結果、period 開始前の actual postings が `skipped day_before_start` として落ち、残高表示で period movement を balance のように扱ってしまう。

これは表示差ではなく、会計ソフトとしての構造問題である。

## 2. 目標

`bqn-ledger` の `src_next` を、次の性質を持つ accounting-grade engine candidate に育てる。

```text
source TSV
  -> Posting IR
  -> validation
  -> Ledger / Posting set
  -> TBDS(period, as_of)
  -> accounting reports
  -> household policy layer
  -> household views
```

Household policy layer の詳細は `docs/HOUSEHOLD_POLICY_LAYER_PLAN.md` に置く。Accounting core は年金・月給・封筒派などの生活スタイルを知らない。

### 必須品質

- 全履歴の postings を ledger として保持する。
- period / cycle は ledger 読み込み境界ではなく、view / report の選択条件とする。
- TBDS は `opening / movement / closing` を正しく持つ。
- 残高系 report は `closing` を使う。
- 期間損益・サイクル集計は `movement` を使う。
- 不正入力は fail closed し、成功値として `0` にしない。
- source TSV を自動修正しない。
- household advice は accounting core に混ぜない。
- 年金・月給・不定期収入・封筒派などの生活スタイルは policy layer で扱う。

## 3. 非目標

当面は次を目標にしない。

- `bqn-kakeibo` の human report と byte-for-byte で一致させること。
- 見た目の改善を先に進めること。
- household daily advice / envelope advice を accounting core に入れること。
- source TSV format を ledger/beancount 風に置き換えること。
- UI / editor / TUI を accounting engine の一部にすること。

## 4. Core invariant

### 4.1 Ledger loading invariant

Posting IR は、source TSV の有効な全履歴から作る。

```text
journal.tsv      -> actual postings for all valid dates
plan.tsv         -> plan postings for all valid dates
budget_alloc.tsv -> budget postings for all valid dates
```

`cycle_start` より前という理由だけで actual postings を捨ててはいけない。

### 4.2 Period selection invariant

Period は report query の条件である。

```text
before period_start          -> opening
period_start <= date < end   -> movement
as_of / end boundary         -> closing / observation
```

### 4.3 TBDS invariant

For every account/layer/period:

```text
movement = debit_movement + credit_movement
closing  = opening + movement
```

`opening = 0` をデフォルトとして残高を作ってはいけない。履歴不足や未実装なら `UNAVAILABLE` / `ERROR` とする。

### 4.4 Report usage invariant

| Report kind | value to use |
|---|---|
| Trial Balance | opening / debit_movement / credit_movement / movement / closing |
| Balance Sheet / Snapshot / Balances | closing |
| Income Statement / Cycle Summary | movement |
| Household outlook | accounting closing + separately documented household policy |

### 4.5 Naming invariant

`movement` を `balance` と呼んではいけない。

`balance` と表示する値は、明示的な `opening + movement` または as-of cumulative closing でなければならない。

## 5. Target architecture

### 5.1 Ledger context

`BuildContext` は cycle-bounded cube を作る入口ではなく、ledger-wide context を作る入口へ寄せる。

Target:

```text
BuildLedgerContext(base)
  -> account space
  -> all source rows
  -> Posting IR for all valid dates
  -> validation partition
  -> ledger-wide posting set
```

### 5.2 Period context

Period-specific report は ledger context から作る。

```text
BuildPeriod(ctx, period_start, period_end_exclusive, as_of)
  -> TBDS rows with opening / movement / closing
```

Cycle is one period resolver, not the ledger boundary.

## 6. First accounting-grade gate

最初の gate は human report parity ではなく Trial Balance parity とする。

### Fixture: opening before cycle

Example:

```text
cycle: 2026-06-15 .. 2026-08-15

2026-06-01 opening equity:opening-balances -> assets:bank 100000
2026-06-20 food    assets:bank -> expenses:food 1000
```

Expected TBDS actual layer:

| account | opening | movement | closing |
|---|---:|---:|---:|
| assets:bank | 100000 | -1000 | 99000 |
| expenses:food | 0 | 1000 | 1000 |
| equity:opening-balances | -100000 | 0 | -100000 |

Expected report usage:

```text
Cycle expense = 1000      # movement
Bank balance  = 99000     # closing
```

If this gate fails, `src_next` must not be treated as an accounting replacement.

## 7. Work phases

### Phase A — Contract and fixture gate

- [x] Update docs to state that period/cycle is not ledger loading boundary.
- [x] Add public fixture for opening-before-cycle (`fixtures/src-next-opening-before-cycle`).
- [x] Add TBDS field-level check for opening / movement / closing (`tests/test_src_next_tbds_opening_before_cycle.bqn`).
- [x] Add regression check proving Balances uses closing, not movement.
- [x] Move Snapshot to TBDS closing.
- [x] Separate invalid vs out-of-period diagnostics.

### Phase B — Ledger-wide Posting IR

- [x] Split current `BuildContext` responsibilities into `BuildAllRows` (ledger-wide source loading) and `BuildPeriodView` (period view construction).
- [x] `BuildContext` kept as backward-compatible convenience wrapper.
- [x] Keep all valid postings in Posting IR regardless of cycle position.
- [x] Reclassify out-of-period rows as outside selected period (`out_of_period_count`), not skipped ledger rows.
- [x] Preserve fail-closed behavior for invalid date / amount / unknown account.

### Phase C — TBDS real implementation

- [x] Implement `opening` from postings before `period_start`.
- [x] Implement `debit_movement` / `credit_movement` / `movement` inside period.
- [x] Implement `closing = opening + movement`.
- [x] Add invariant checks for every TBDS row.

### Phase D — Accounting reports first

- [x] Add machine-readable Trial Balance exporter for `src_next`.
- [x] Balance Sheet / Snapshot from TBDS closing (covered by `snapshot.bqn`).
- [x] Income Statement / Cycle Summary from TBDS movement (covered by `cycle_summary.bqn`).
- [x] Trial Balance wired into `summary.bqn` and `report.bqn`.

### Phase E — Replacement readiness

- [ ] Compare current engine and `src_next` on accounting fields.
- [ ] Classify differences as bug / expected policy difference / unsupported.
- [ ] Do not use `src_next` for household decisions until accounting gates pass.

## 8. Immediate next task

Phase A–D complete. Next: household policy layer Phase D or Phase E replacement readiness comparison.

Concrete next work unit:

```text
1. Household policy assumption audit (from HOUSEHOLD_POLICY_LAYER_PLAN.md Phase 1).
2. Or: current engine vs src_next accounting field comparison (Phase E).
```
