# Journal resolved-account registry mismatch rejection — test-only plan

Status: selected finite implementation contract
Owner: journal source migration
Canonical: no; canonical routing remains `TODO.md`
Exit: focused implementation, review, completion record, and explicit return to no selected finite Journal slice
Date: 2026-07-21

## Purpose

Select one bounded red-path contract at the boundary between admitted Minimal BQN Journal Transaction IR and the resolved account axis derived from `accounts.tsv`.

Stage 1 owns Journal-internal syntax, declarations, metadata, posting shape, and transaction balance. Stage 2A owns mapping each admitted posting account onto the externally resolved account registry used by Posting IR, Cube, TBDS, and reports.

A Journal account can therefore be validly declared inside the Journal while still being absent from the supplied resolved account registry. This slice makes that cross-boundary mismatch explicit and fail-closed before any Posting IR row reaches downstream consumers.

## Finite question

> When Stage 1 successfully admits a balanced Journal transaction whose declared posting account is absent from the supplied resolved account registry, can the Stage 2A / read-only carrier boundary return a structured error with no partial Posting IR rows, while preserving all existing success-path contracts and remaining disconnected from production routing?

## Selected ownership

- Stage 1 remains responsible only for Journal-internal evidence. A posting account declared in the same Journal may pass Stage 1.
- Stage 2A owns resolution of admitted posting account names against `resolved.accounts` and construction of resolved AccountKey coordinates.
- The read-only source carrier propagates the Stage 2A state and diagnostics without changing their meaning.
- Downstream Cube, TBDS, Trial Balance, Balances, and formatters must receive no rows from the rejected source.

## Required rejection contract

For the selected mismatch case:

- Stage 1 result is `state = "ok"`;
- at least one admitted transaction and its ordered postings remain observable as Transaction IR evidence;
- Stage 2A result is `state = "error"`;
- Stage 2A returns zero `posting_rows`;
- Stage 2A returns at least one diagnostic identifying the unresolved posting account;
- the diagnostic stage is owned by `journal_posting_ir_stage2a`;
- the selected diagnostic code is `posting_account_unresolved`;
- the diagnostic retains enough source meaning to identify the account key and transaction/posting position without inventing legacy TSV row identity;
- the carrier result is also `state = "error"`, retains its result-level `source_file`, returns zero `posting_rows`, and propagates the Stage 2A diagnostic;
- no successful row for the valid counterpart posting is emitted;
- no numeric delta, account total, Cube value, Trial Balance movement, or Balances entry leaks from the rejected transaction.

The rejection is all-or-nothing for the complete adapter call. Partial success is not selected.

## Public synthetic evidence

Use one small hand-checkable Journal source and one resolved account registry:

- the Journal declares both posting accounts;
- the transaction is balanced and otherwise valid;
- one posting account exists in `resolved.accounts`;
- the other account is declared in the Journal but deliberately absent from `resolved.accounts`;
- no private or production source data is read.

The focused test should prove the boundary in this order:

```text
public synthetic Journal lines
  -> Stage 1 Parse succeeds
  -> Stage 2A account-axis resolution rejects
  -> read-only carrier propagates rejection
  -> zero downstream-admissible Posting IR rows
```

## Planned files

Expected implementation scope:

- `src_next/journal_posting_ir_stage2a.bqn`
- `tests/test_journal_resolved_account_registry_mismatch_rejection.bqn`
- optionally a dedicated public synthetic fixture directory if inline evidence would obscure the test
- routing and completion documentation required by the repository lifecycle

The implementation should prefer the smallest pure validation at the Stage 2A boundary. Do not broaden the carrier into a second adapter or duplicate Stage 2A account-resolution policy.

## Success-path preservation

The implementation must preserve:

- the current 16-field successful Posting IR row shape;
- successful transaction and posting order;
- existing `source_file`, `source_row`, identity, layer, side, delta, kind, status, and message behavior;
- existing read-only carrier success behavior;
- existing Trial Balance, Balances, legacy TSV parity, and Journal tests;
- zero production routing changes.

## Non-goals

This slice does not select:

- broader parser or adapter red-path coverage;
- diagnostic equality with legacy TSV;
- Journal declaration synchronization with `accounts.tsv`;
- automatic account creation or registry mutation;
- fuzzy matching, aliases, prefix inference, or role inference from account names;
- duplicate-account, duplicate-AccountKey, currency mismatch, missing-role, or malformed resolved-registry campaigns;
- row-level source identity injection or Stage 2B provenance redesign;
- `source_row` consumer migration;
- Cube, TBDS, report, formatter, or `BuildContext` production changes;
- production Journal loading or routing;
- writer/editor work;
- TSV-to-Journal conversion;
- shadow read or private-data comparison;
- source-of-truth cutover;
- reverse synchronization or conflict resolution;
- any later Journal stage.

## Validation gate

Before implementation completion:

- run the focused BQN test;
- run existing Stage 1, Stage 2A, carrier, Trial Balance, and report-context rehearsal tests affected by the boundary;
- run `bash checks/check-docs-lifecycle.sh`;
- run `bash checks/check-absolute-links.sh`;
- run `bash checks/check-repo-index.sh`;
- run `git diff --check`;
- run `bash tools/check.sh`;
- verify the branch is based on current `main` and contains only the selected finite slice;
- verify production source TSV and private data are unchanged.

## Completion routing

After focused implementation and checks pass:

- move this plan to `docs/archive/completed-plans/JOURNAL_RESOLVED_ACCOUNT_REGISTRY_MISMATCH_REJECTION_PLAN-2026-07-21.md`;
- record the exact observed rejection behavior and validation evidence;
- update `TODO.md`, `NEXT_SESSION.md`, and `docs/README.md`;
- return routing to no next finite Journal slice selected;
- do not automatically select broader registry validation, production routing, writer work, conversion, shadow read, or cutover.
