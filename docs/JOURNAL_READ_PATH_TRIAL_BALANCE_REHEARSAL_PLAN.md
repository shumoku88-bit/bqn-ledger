# Journal read-path trial-balance rehearsal — test-only

Status: current contract / selected test-only implementation plan
Owner: journal source migration
Canonical: yes
Exit: archive as completed after the focused public-synthetic test lands, or replace with a new decision if the selected path requires production routing or a contract change
Date: 2026-07-21

## Purpose

Prove one bounded downstream read path for the native Journal work already present in `bqn-ledger`:

```text
public synthetic Journal text
  -> Minimal BQN Journal Profile Stage 1 Parse
  -> Journal Posting IR Stage 2A Build
  -> context.BuildPeriodView
  -> trial_balance.Build
```

This slice moves beyond direct Cube parity by exercising the existing Cube plus TBDS period-view boundary and one existing accounting report builder. It remains test-only and does not activate Journal as a production source.

## Finite question

> Can the existing public native three-posting Journal fixture be parsed and adapted into successful current Posting IR rows, passed through the existing `BuildPeriodView` boundary, and consumed by the existing Trial Balance builder with the expected balanced account movements, without changing production loading or report code?

## Existing fixture boundary

Reuse only the existing public synthetic fixture:

```text
fixtures/journal-native-three-posting-parity/
  accounts.tsv
  profile.journal
```

Do not add private data or copy production account names or amounts.

The fixture contains exactly one actual transaction dated `2026-08-03` with three ordered postings:

- `expenses:anonymous-first`: `+800 JPY`;
- `expenses:anonymous-second`: `+300 JPY`;
- `assets:anonymous`: `-1100 JPY`.

The focused test will be:

```text
tests/test_journal_read_path_trial_balance_rehearsal.bqn
```

No new fixture is required unless the existing fixture cannot express the selected test without alteration. If alteration is required, stop and request a separate decision rather than broadening this slice.

## Selected path

The implementation must use the existing modules and boundaries directly:

1. read `profile.journal` as test input;
2. call `journal_profile_stage1.Parse`;
3. call `journal_posting_ir_stage2a.Build` with the parsed transactions, resolved account axis, and fixed cycle start;
4. pass the resulting successful Posting IR rows to `context.BuildPeriodView` with a test-local cycle carrier covering `2026-08-03`;
5. construct only the minimal test-local context carrier required by `trial_balance.Build`;
6. call `trial_balance.Build` for the actual layer;
7. assert the expected Trial Balance values and zero-sum invariant.

The focused test may import existing production modules, but it must not change their runtime routing.

## Expected observations

### Parser and Posting IR

- parser state is `ok`;
- exactly one transaction is admitted;
- exactly three ordered postings are retained;
- Stage 2A state is `ok`;
- exactly three Posting IR rows are emitted;
- all three rows have `status = ok`;
- the Posting IR delta sum is zero.

### Period view

- `context.BuildPeriodView` accepts the three Journal-derived rows;
- Cube valid-row count is three;
- Cube skipped-row count is zero;
- TBDS contains one row for each of the three resolved accounts in the actual layer;
- no legacy TSV projection participates in this path.

### Trial Balance

For the actual layer and the fixed period containing `2026-08-03`:

- all openings are zero;
- `expenses:anonymous-first` debit movement is `800` and closing is `800`;
- `expenses:anonymous-second` debit movement is `300` and closing is `300`;
- `assets:anonymous` credit movement is `-1100` and closing is `-1100`;
- total debit movement equals the magnitude of total credit movement;
- total closing balance is zero;
- formatted output is not the primary contract and need not be snapshot-tested in this slice.

## Allowed implementation surface

The implementation may add only:

- `tests/test_journal_read_path_trial_balance_rehearsal.bqn`;
- the minimum test registration or check wiring required by current repository conventions;
- completion-routing documentation after the test passes.

Prefer no changes under `src_next/`. If a new `src_next` helper, export, loader seam, or production carrier appears necessary, stop and request a separate design decision.

## Explicit non-goals

This slice does not implement or select:

- changes to `context.BuildContext`;
- production Journal loading or routing;
- replacement of `LoadPostingSourceSnapshot`;
- Journal and TSV source mixing in one production context;
- shadow read against generated or private Journal data;
- private-data comparison;
- writer or editor work;
- TSV-to-Journal conversion;
- source-of-truth cutover;
- `source_row` consumer migration;
- changes to Posting IR, Cube, TBDS, Trial Balance, or report contracts;
- full `summary.bqn` or human report execution from Journal;
- plan or budget Journal families;
- broader parser red-path or rejection parity;
- Ledger or hledger full syntax compatibility;
- bidirectional sync, reverse sync, or conflict resolution;
- TSV cleanup or production source changes;
- automatic selection of shadow read or any later Journal stage.

## Stop conditions

Stop without adding a workaround if any of the following is required:

- production source access;
- private data;
- modification of `BuildContext`, `LoadPostingSourceSnapshot`, report modules, Cube, TBDS, Posting IR, or parser/Stage 2A contracts;
- a new production normalizer or Journal loader;
- flattening the native three-posting transaction into legacy two-account rows;
- cross-source identity unification;
- changing the fixture's accounting meaning;
- broadening the supported Journal syntax.

Record the mismatch and request a separate design decision.

## Completion conditions

This slice is complete only when:

- the existing public fixture is read directly;
- the selected Parse -> Stage 2A -> BuildPeriodView -> Trial Balance path passes;
- all expected numeric assertions pass;
- the test proves the Journal-derived path contains three Posting IR rows and does not use legacy TSV projection;
- production runtime and production source files remain unchanged;
- focused checks and `tools/check.sh` pass;
- this plan is archived as completed;
- repository routing returns to no selected finite Journal slice;
- no later Journal stage is selected automatically.
