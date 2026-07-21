# Journal read-path report-context rehearsal — test-only

Status: active plan (read-only rehearsal extension)
Owner: journal source migration
Canonical: yes
Exit: complete balances report rehearsal verification using public synthetic fixture only

## Purpose

すでに完了した `JOURNAL_READ_PATH_TRIAL_BALANCE_REHEARSAL_PLAN-2026-07-21.md` を拡張し、
Journal 由来の Posting IR からアセンブルした Rehearsal Context が、
残高レポート (`balances.bqn`) にも接続できることを実証・検証する最小の read-only rehearsal を設計・実装する。

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

## Focused Test Specification

`tests/test_journal_read_path_trial_balance_rehearsal.bqn` を編集し、以下の検証を追加する。
1. `balances.Build` に `rehearsalCtx` (with `resolved` and `tbds`) を渡す。
2. 得られた `balanceEntries` が legacy TSV から構築したものと一致することを確認。
3. `balances.FormatHuman` と `balances.Format` に通して例外が出ないことを確認。

## Safety Profile
- 実運用 `LEDGER_DATA_DIR` は一切触らない。
- production source tsv / loader には一切影響を与えない。
- I/O は読み取りのみ。
