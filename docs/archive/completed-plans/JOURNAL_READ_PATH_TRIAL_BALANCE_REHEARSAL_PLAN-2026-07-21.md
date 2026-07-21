# Journal read-path trial-balance rehearsal — test-only

Status: completed test-only implementation
Owner: journal source migration
Canonical: no; current routing remains `TODO.md` and `NEXT_SESSION.md`
Exit: completed; any later Journal or production work requires a separately selected finite slice
Date: 2026-07-21

## Purpose

This completed slice proves one bounded downstream read path for the native Journal work already present in `bqn-ledger`:

```text
public synthetic Journal text
  -> Minimal BQN Journal Profile Stage 1 Parse
  -> Journal Posting IR Stage 2A Build
  -> context.BuildPeriodView
  -> trial_balance.Build
```

It moves beyond direct Cube parity by exercising the existing Cube plus TBDS period-view boundary and one existing accounting report builder. It remains test-only and does not activate Journal as a production source.

## Finite question

> Can the existing public native three-posting Journal fixture be parsed and adapted into successful current Posting IR rows, passed through the existing `BuildPeriodView` boundary, and consumed by the existing Trial Balance builder with the expected balanced account movements, without changing production loading or report code?

## Implemented fixture boundary

The completed test reuses only the existing public synthetic fixture:

```text
fixtures/journal-native-three-posting-parity/
  accounts.tsv
  profile.journal
```

The fixture contains one actual transaction dated `2026-08-03` with three ordered postings:

- `expenses:anonymous-first`: `+800 JPY`;
- `expenses:anonymous-second`: `+300 JPY`;
- `assets:anonymous`: `-1100 JPY`.

The focused test is:

```text
tests/test_journal_read_path_trial_balance_rehearsal.bqn
```

No new fixture, private data, production account name, or production amount was added.

## Implemented path

The focused test:

1. reads `profile.journal` directly;
2. calls `journal_profile_stage1.Parse`;
3. calls `journal_posting_ir_stage2a.Build` with the parsed transaction, resolved account axis, and fixed cycle start;
4. passes the three successful Posting IR rows to `context.BuildPeriodView` with a test-local cycle covering `2026-08-03`;
5. constructs only the minimal test-local context carrier required by `trial_balance.Build`;
6. calls `trial_balance.Build` for the actual layer;
7. asserts the expected account movements and zero-sum invariant.

The test imports existing modules without changing runtime routing or their contracts.

## Completion evidence

### Parser and Posting IR

- parser state is `ok`;
- exactly one transaction is admitted;
- exactly three ordered postings are retained;
- Stage 2A state is `ok`;
- exactly three Posting IR rows are emitted;
- all three rows have `status = ok` and `source_file = profile.journal`;
- Posting IR deltas are `⟨800, 300, -1100⟩` and sum to zero.

### Period view

- `context.BuildPeriodView` accepts the three Journal-derived rows;
- Cube valid-row count is three;
- Cube skipped-row count is zero;
- actual account totals are `⟨-1100, 800, 300⟩` on the resolved account axis;
- TBDS contains one actual-layer row for each resolved account;
- all openings are zero;
- no legacy TSV projection participates in the selected path.

### Trial Balance

For the actual layer and period `2026-08-01` through `2026-09-01` exclusive:

- account order is `assets:anonymous/JPY`, `expenses:anonymous-first/JPY`, `expenses:anonymous-second/JPY`;
- openings are `⟨0, 0, 0⟩`;
- debit movements are `⟨0, 800, 300⟩`;
- credit movements are `⟨-1100, 0, 0⟩`;
- closings are `⟨-1100, 800, 300⟩`;
- total debit movement is `1100`;
- total credit movement is `-1100`;
- total closing balance is zero.

## Validation

- focused test: `tests/test_journal_read_path_trial_balance_rehearsal.bqn`;
- repository check: GitHub Actions `check` run #1092 succeeded;
- Coverage step succeeded in the same run;
- implementation merged by PR #298 as squash commit `9da4fec2408affd1fa248f81602798b1e247fa74`.

## Preserved boundaries

The completed slice adds no:

- `context.BuildContext` or `LoadPostingSourceSnapshot` change;
- production Journal loader or routing;
- Journal and TSV mixing in a production context;
- new `src_next` helper, export, normalizer, or production carrier;
- Posting IR, Cube, TBDS, Trial Balance, report, parser, or Stage 2A contract change;
- fixture or production source-data change;
- full summary or human-report execution from Journal;
- shadow read, private-data comparison, writer/editor work, conversion, cutover, or source-of-truth change;
- `source_row` consumer migration;
- broader parser red-path/rejection parity;
- Ledger or hledger full syntax compatibility;
- bidirectional sync, reverse sync, or conflict resolution;
- automatically selected later Journal stage.

Repository routing returns to no next finite Journal slice selected. No follow-up work is selected automatically.
