# Journal read-only source carrier rehearsal — test-only

Status: completed test-only implementation
Owner: journal source migration
Canonical: no; current routing remains TODO.md and NEXT_SESSION.md
Exit: completed; production routing or later Journal work requires a separately selected finite slice
Date: 2026-07-21

## Purpose

This completed slice isolates and groups the construction of Transaction IR and Posting IR rows from public synthetic Journal text into a single, explicit read-only source carrier module (`src_next/journal_read_only_source_carrier.bqn`). It migrates the existing public synthetic Journal rehearsal test (`tests/test_journal_read_path_trial_balance_rehearsal.bqn`) to route through this carrier boundary while preserving all Trial Balance and Balances report assertions, maintaining legacy TSV parity evidence.

This work remains test-only and does not modify production routing, file parsing, or editor operations.

## Finite question

> 明示的なpublic synthetic Journal source carrierを受け取り、既存のStage 1 parserとStage 2A adapterを通して、Transaction IR、Posting IR rows、diagnosticsを一つの結果として返す純粋なread-only境界を追加できるか。また、既存のJournal read-path rehearsalをその境界へ寄せても、Trial Balance、Balances、legacy TSV parityの証拠を維持できるか。

### Answer

Yes. The explicit read-only carrier module `src_next/journal_read_only_source_carrier.bqn` was added and verified. Migrating `tests/test_journal_read_path_trial_balance_rehearsal.bqn` to use this carrier successfully preserves all downstream Trial Balance, Balances, and legacy TSV parity assertions.

## Implemented Carrier Boundary

The implemented carrier takes:
- `carrier` namespace containing `{ source_file, lines }`
- `resolved` account axis
- `cycleStart` date string

It performs Stage 1 Parse on the concatenated lines and, if successful, runs the Stage 2A Build adapter to construct Posting IR rows. The return structure is a namespace of:
```text
{
  state,
  source_file,
  transactions,
  posting_rows,
  diagnostics
}
```
All details of the parser and Stage 2A adapter execution status and error diagnostics are preserved and not hidden. If the parser detects errors, it aborts adaptation and returns `state: "error"`, empty `posting_rows`, and the accumulated diagnostics.

> [!NOTE]
> Arbitrary row-level Journal source identity injection remains unselected because Stage 2A currently owns the fixed test-only `profile.journal` value. Generalizing it requires a separately selected Stage 2A/source-provenance contract decision.

## Focused Verification Evidence

A focused test (`tests/test_journal_read_only_source_carrier.bqn`) verifies that:
- Explicit source identity is correctly retained in the result-level `source_file` field.
- Unchanged Stage 2A Posting IR rows are preserved, meaning their row-level `source_file` values remain `profile.journal`.
- Success path parsing/adapting builds 3 posting rows with a zero-sum delta sum, 1 transaction, and 3 postings.
- Parser failure (e.g., `event_unbalanced`) aborts adaptation and leaves the carrier result's `posting_rows` empty.
- Parser diagnostics (like `event_unbalanced`) are successfully propagated without hiding parser/adapter error details.

## Validation Results

- Focused unit test: `tests/test_journal_read_only_source_carrier.bqn` succeeded.
- Rehearsal integration test: `tests/test_journal_read_path_trial_balance_rehearsal.bqn` succeeded.
- All checks in `tools/check.sh` passed.
