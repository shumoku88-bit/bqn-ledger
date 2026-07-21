# Journal read-path report-context rehearsal — test-only

Status: completed test-only implementation
Owner: journal source migration
Canonical: no; current routing remains TODO.md and NEXT_SESSION.md
Exit: completed; later Journal work requires a separately selected finite slice
Date: 2026-07-21

## Purpose

すでに完了した `JOURNAL_READ_PATH_TRIAL_BALANCE_REHEARSAL_PLAN-2026-07-21.md` を拡張し、
Journal 由来の Posting IR からアセンブルした Rehearsal Context が、
残高レポート (`balances.bqn`) にも正常に接続できることを検証する最小の read-only rehearsal を実証・実装した。

## Responsibility Boundary

- **Source Input**: `fixtures/journal-native-three-posting-parity/profile.journal`
- **Stage 1 & 2A**: `src_next/journal_profile_stage1.bqn` / `src_next/journal_posting_ir_stage2a.bqn`
- **Context Assembly**: `context.BuildPeriodView` からの Rehearsal Context `{ cy, resolved, tbds }`
- **Report Consumer**: `src_next/balances.bqn` (context -> Balances entries -> Format)
- **Production Boundary**: `BuildContext` 等の production code は改変しない。

## Rehearsal Pipeline Design

```text
[profile.journal] -> [Transaction IR] -> [Posting IR rows]
                                              │
                                              ▼ (BuildPeriodView)
                                       [Rehearsal Context]
                                              │
                                        (balances.Build)
                                              ▼
                                      [Balances Report]
```

## Implemented Rehearsal Specification

`tests/test_journal_read_path_trial_balance_rehearsal.bqn` において、以下の検証を実装し成功した。
1. `balances.Build` に `rehearsalCtx` (with `resolved` and `tbds`) を渡して、残高データを構築。
2. 得られた `balanceEntries` が legacy TSV から構築した残高データと完全に一致することを確認。
3. `balances.FormatHuman` と `balances.Format` に通して例外が発生せず、かつ出力が空でない（非ゼロ要素）であることをアサートして検証。

## Safety Profile
- 実運用 `LEDGER_DATA_DIR` は一切触らない。
- production source tsv / loader には一切影響を与えない。
- I/O は読み取りのみ。
