# Journal Posting IR adapter parity Stage 2A plan

Status: completed test-only implementation
Owner: journal source migration
Canonical: no; canonical routing remains TODO.md
Exit: completed; identity/provenance, rejection, native multi-posting, production routing, and cutover require separately selected slices
Date: 2026-07-18

## Purpose

Select only the first successful conversion path from the Minimal BQN Journal Stage 1 Transaction IR to the current normalized Posting IR shape. Stage 2A is a bounded, test-only semantic parity slice:

```text
Minimal Journal text
  -> existing src_next/journal_profile_stage1.bqn
  -> admitted Transaction IR
  -> new test-only Journal Posting IR adapter
  -> semantic comparison with existing checked TSV Posting IR path
```

This completed slice implements only the success path below. It does not select Stage 2 as a whole.

## Existing boundaries

- Journal parser: `src_next/journal_profile_stage1.bqn`.
- Current checked TSV Posting IR boundary: `src_next/context.bqn`, `BuildCheckedPostingProjectionFromSnapshot`.
- Posting IR contract: `docs/POSTING_IR_CONTRACT.md`.
- Current source truth remains `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, and `accounts.tsv` in the selected base directory.

The Stage 1 parser and current TSV adapter are comparison inputs. Stage 2A must not change either one.

## Selected success-path fixture

The implementation uses only public synthetic data in exactly one dedicated fixture directory: `fixtures/journal-posting-ir-stage2a/`.

The fixture contains exactly:

- one actual transaction;
- one plan transaction;
- one positive and one negative posting in each transaction;
- transaction shapes that are each representable by one TSV source row;
- the same account declarations and integer JPY amounts on the Journal and TSV sides;
- no budget-layer transaction.

A small example equivalent to the Stage 0 rent plan and rent paid events is suitable, but this fixture must be independent from the Stage 0 fixture. Transaction order and posting order must be explicit and deterministic.

Native Journal transactions with three or more postings are deliberately absent. Stage 2A must not flatten such a transaction into a one-row TSV shape.

## Journal adapter Posting IR row

For each admitted Journal posting, the Stage 2A adapter emits the current normalized Posting IR shape with these fields:

1. `source_file`
2. `source_row`
3. `source_id`
4. `tx_id`
5. `posting_id`
6. `date`
7. `day_index`
8. `account_key`
9. `account_key_index`
10. `layer_name`
11. `layer_index`
12. `side`
13. `delta`
14. `kind`
15. `status`
16. `message`

The adapter is test-only. Emitting the complete row shape does not make every field a Stage 2A parity assertion.

## Selected parity assertions

The focused test compares only these semantic properties between the admitted Journal adapter result and the existing checked TSV Posting IR result:

- transaction order;
- posting order within each transaction;
- `date`;
- `account_key`;
- `delta`;
- `side`;
- `layer_name`;
- the sum of `delta` is zero for each transaction;
- the TSV checked path has `status = ok`;
- the Journal adapter path has `status = ok`.

This is semantic parity for the first common success path, not byte-for-byte row identity.

## Explicitly excluded parity

Stage 2A does not compare:

- the `source_file` string;
- physical `source_row`;
- `source_id`, `tx_id`, or `posting_id` strings;
- `identity_kind`;
- provenance;
- `receipt-id`, `plan-id`, `execution-envelope`, `allocation-id`, or `agreement-id`;
- numeric `account_key_index`;
- numeric `day_index`;
- `kind`;
- message details;
- rejected-transaction diagnostics;
- red-path coverage.

Identity/provenance parity, rejection parity, and native multi-posting parity remain independently unselected.

## Implementation

The completed Stage 2A slice adds:

- adapter: `src_next/journal_posting_ir_stage2a.bqn`;
- unit test: `tests/test_journal_posting_ir_adapter_stage2a.bqn`;
- public fixture: `fixtures/journal-posting-ir-stage2a/`.

The pure adapter accepts admitted Stage 1 transactions, resolved account evidence, and an explicit cycle start. It performs no I/O and has no production consumer. The focused test supplies the same public accounts and integer JPY movements to the Journal and checked TSV paths.

## Non-goals and safety boundaries

Stage 2A must not:

- change the Stage 1 Journal parser;
- change the current TSV adapter or `BuildCheckedPostingProjectionFromSnapshot`;
- flatten native multi-posting Journal transactions into one TSV row;
- include a Stage 0 transaction with three or more postings in the fixture;
- enable production Journal reads or private-data shadow reads;
- read private data;
- change source truth;
- create a Journal or TSV writer;
- begin conversion, synchronization, or cutover;
- connect the adapter to Cube, TBDS, reports, or the editor;
- add a CLI or human-facing parity report;
- select identity/provenance parity, rejection parity, native multi-posting parity, or production routing;
- auto-select Stage 2B or any later stage;
- restore the withdrawn deadline-bound submission work.

## Completion evidence

1. The one public synthetic fixture directory contains exactly the selected actual and plan success cases.
2. The Journal path uses the existing Stage 1 parser and admits both transactions.
3. The TSV path uses `BuildCheckedPostingProjectionFromSnapshot` and is `ok`.
4. The Journal adapter emits the full 16-field Posting IR row shape and is `ok`.
5. The selected semantic parity assertions pass, including transaction balance.
6. No excluded parity area or production connection was added.
7. The focused unit test and repository normal checks pass.

Completion does not automatically select a follow-up.
