# JOURNAL_READ_PATH_TRIAL_BALANCE_REHEARSAL_PLAN-2026-07-21

Status: active plan (read-only rehearsal)
Owner: repository routing
Canonical: yes
Exit: complete trial balance rehearsal verification using public synthetic fixture only

## Purpose

既存の public synthetic Journal fixture (`fixtures/journal-native-three-posting-parity/profile.journal`) から生成した Posting IR を、
現在の production TSV source loader (`context.BuildContext` 等) の挙動を変更することなく、
エンジン内の context assembly 境界 (`BuildPeriodView`) に流し込み、試算表 (`trial_balance.bqn`) を生成する最小 of read-only rehearsal を設計・実装する。

## Responsibility Boundary

- **Source Input**: `fixtures/journal-native-three-posting-parity/profile.journal`
- **Stage 1 (Parser)**: `src_next/journal_profile_stage1.bqn` (Text -> Transaction IR)
- **Stage 2A (Adapter)**: `src_next/journal_posting_ir_stage2a.bqn` (Transaction IR -> Posting IR rows)
- **Context Assembly (Seam)**: `src_next/context.bqn` の `BuildPeriodView` (Posting IR rows -> Cube / TBDS)
- **Report Consumer**: `src_next/trial_balance.bqn` (TBDS -> Trial Balance report)
- **Production Boundary**: `BuildContext` と `LoadPostingSourceSnapshot` 等の production code は改変しない。

## Rehearsal Pipeline Design

```text
[profile.journal]
       │ (•FChars)
       ▼
[raw text]
       │
       ├─► [src_next/journal_profile_stage1.bqn] ─► [Transaction IR]
       │
       ├─► [src_next/journal_posting_ir_stage2a.bqn] ─► [Posting IR rows]
       │
       ├─► [src_next/context.bqn] (BuildPeriodView) ─► [Rehearsal Cube/TBDS]
       │
       └─► [src_next/trial_balance.bqn] (Build) ─► [Trial Balance Report]
```

## Focused Test Specification

`tests/test_journal_read_path_trial_balance_rehearsal.bqn` を新規作成する。
テスト内容：
1. `profile.journal`, `accounts.tsv` をロードする。
2. アカウント定義から `account_key.Resolve` を呼び出す。
3. `journal_profile_stage1.Parse` で `profile.journal` をパース。
4. `journal_posting_ir_stage2a.Build` で 3-posting Posting IR を構築。
5. `cycle.ReadCycle` またはモックした cycle 構造を用いて `context.BuildPeriodView` を呼び出し、rehearsal cube と tbds を得る。
6. `trial_balance.Build` を呼び出し、Trial Balance レポートオブジェクトを得る。
7. レポートオブジェクトおよび human-readable table format が legacy TSV から構築したものとセマンティックに同一であることを検証する。
8. ゼロサムチェック (debits + credits = 0) 等がパスすることを確認。

## Safety Profile
- 実運用 `LEDGER_DATA_DIR` は一切触らない。
- production source tsv / loader には一切影響を与えない。
- I/O は読み取りのみ。
