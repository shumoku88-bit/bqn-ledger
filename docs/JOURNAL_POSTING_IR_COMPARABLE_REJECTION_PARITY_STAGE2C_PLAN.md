# Journal Posting IR comparable rejection parity Stage 2C plan

Status: current contract / selected test-only implementation plan
Owner: journal source migration
Canonical: yes
Exit: archive as completed after the focused fixture and test land, or replace with a new decision if the observed result shapes cannot support this contract without production normalization
Date: 2026-07-19

## Purpose

Stage 2C selects one finite rejection-parity slice after the completed Stage 2A success parity and Stage 2B identity/provenance parity. It compares only three input errors that can describe the same intended one-row accounting movement in both the Minimal Journal profile and legacy TSV:

1. invalid date;
2. invalid exact-integer amount;
3. unknown account.

Parity here is structural rejection parity, not equality of source-specific diagnostics, line identity, row identity, or IDs. The focused test will prove that neither source path admits the invalid movement as successful Posting IR, that rejection evidence remains observable, and that no normal numeric result reaches a Cube materialization boundary.

This document selects the later test-only implementation. This docs-only change adds no BQN, fixture, test, runtime connection, or production-data change.

## Exact input boundary

One dedicated public synthetic fixture directory will contain three isolated cases. Every case represents one intended movement from an asset account to an expense account, with exactly two explicit Journal postings and one legacy `date / memo / from / to / amount` row.

| case | shared intended movement evidence | exact invalid evidence |
|---|---|---|
| invalid date | declared asset -> declared expense, amount `100` JPY | date text `2026-02-30` on both sides |
| invalid exact-integer amount | declared asset -> declared expense on a valid date | TSV amount `12x`; Journal postings `12x JPY` and `-12x JPY` |
| unknown account | undeclared asset -> declared expense, amount `100` JPY on a valid date | the same undeclared asset key on both sides |

`12x` is deliberate. A fractional exact decimal such as `10.5` is not a comparable rejection case today: Stage 1 requires explicit integer JPY postings, while the checked TSV arithmetic path admits supported exact decimals and normalizes them. Stage 2C must not disguise that grammar difference as parity.

Each case is parsed and projected independently. This slice therefore proves no partial success for the selected invalid movement; it does not introduce a new snapshot-wide policy for a file containing unrelated valid and invalid movements.

## Current-behavior audit

The following behavior was observed on current `main` through public synthetic in-memory/file-local evidence. Diagnostic spellings are recorded as source evidence, not selected equality assertions.

### Journal: `journal_profile_stage1.Parse`

| case | parse state | admitted transactions | diagnostics | possible successful Stage 2A Posting IR for invalid movement |
|---|---:|---:|---|---:|
| invalid date | `error` | 0 | one `unsupported_group` diagnostic; the invalid date prevents the header from being classified as a transaction group | 0 rows because no transaction is admitted |
| invalid exact-integer amount | `error` | 0 | two `posting_amount_invalid`, two `posting_amount_zero`, and one `posting_missing` diagnostics for the selected two-posting `12x` block | 0 rows because no transaction is admitted |
| unknown account | `error` | 0 | `posting_account_unknown` plus `event_unbalanced`; the undeclared posting is withheld before the remaining raw posting is balanced | 0 rows because no transaction is admitted |

The extra Journal diagnostics are current parser behavior. Stage 2C preserves and observes them; it does not clean them up, rename them, or require them to equal TSV diagnostics.

### Legacy TSV: `BuildCheckedPostingProjectionFromSnapshot`

| case | checked-result state | posting rows | row status / top-level diagnostics | Cube admission boundary |
|---|---:|---:|---|---:|
| invalid date | `ok` | 2 rejected-evidence rows | both rows have `status = invalid_date`; top-level diagnostics are empty | `cube.Materialize` admits 0 valid rows and retains 2 skipped rows |
| invalid exact-integer amount | `error` | 0 | one top-level authorization diagnostic with code `arithmetic_currency_proof_rejected`; no row status exists because arithmetic authorization fails before posting construction | empty input reaches no Cube value; 0 valid rows |
| unknown account | `ok` | 2 rejected-evidence rows | both rows have `status = unknown_account`; top-level diagnostics are empty | `cube.Materialize` admits 0 valid rows and retains 2 skipped rows |

For invalid date and unknown account, `state = ok` means that the checked projection operation returned structured rejected rows; it does **not** mean those posting rows are successful. `cube.Materialize` requires `row.status = ok`, so these rows cannot enter Cube arithmetic. For invalid amount, rejection is aggregate and earlier: `posting_rows` is empty, so the malformed amount cannot become a zero-valued successful posting.

The two APIs therefore have intentionally different rejection shapes, but the selected structural facts are comparable without changing either production result shape.

## Existing functions and observation points

The focused test will call only existing functions:

### Journal side

1. `journal_profile_stage1.Parse raw`;
2. observe `state`, `transactions`, and each diagnostic's current `code`;
3. call `journal_posting_ir_stage2a.Build ⟨parsed.transactions, resolved, cycleStart⟩` only to prove that the withheld invalid transaction produces zero successful Posting IR rows.

Stage 2A is not changed. Its `state = ok` on an empty admitted-transaction input is not treated as movement success; the successful-row count must be zero.

### Legacy TSV side

1. build a test-local supplied snapshot from the matching synthetic TSV line;
2. call `context.BuildCheckedPostingProjectionFromSnapshot ⟨snapshot, resolved, cycleStart⟩`;
3. observe checked-result `state`, `posting_rows`, row `status`/`message`, and top-level diagnostics;
4. call `cube.Materialize` on the returned rows as a terminal test observation and assert zero `valid_rows`. Rejected date/account rows must remain in `skipped_rows`; invalid amount has no posting rows to materialize.

No report is invoked. Existing Cube behavior is observed, not modified or promoted into a Journal runtime route.

## Planned fixture

Add exactly one public directory:

```text
fixtures/journal-posting-ir-stage2c/
  accounts.tsv
  invalid-date.journal
  invalid-date.tsv
  invalid-exact-integer-amount.journal
  invalid-exact-integer-amount.tsv
  unknown-account.journal
  unknown-account.tsv
```

`accounts.tsv` declares only anonymous asset and expense accounts with the roles needed by the existing resolvers. Each `.journal` contains the minimal JPY declaration, matching account declarations, and exactly one invalid transaction block. Each `.tsv` contains exactly one journal-like data row, without a private path, real account, amount, memo, or identifier.

The planned focused test is:

```text
tests/test_journal_posting_ir_comparable_rejection_stage2c.bqn
```

The fixture and test are not added by this docs-only slice.

## Helper and test-local comparison carrier decision

No new `src_next` helper is needed. The existing Journal parser, Stage 2A adapter, checked TSV adapter, and Cube acceptance boundary already expose all selected evidence. Adding a production/runtime normalizer would prematurely turn asymmetric source diagnostics into a shared API.

The focused test may define a test-local `ObserveCase`/carrier projection with exactly these fields:

1. `case_key` — `invalid_date`, `invalid_exact_integer_amount`, or `unknown_account`;
2. `source_kind` — `journal` or `legacy_tsv`;
3. `source_state` — the unmodified source API state;
4. `admitted_transaction_count` — Journal admitted count, and `0` for the one-row legacy rejection case because no successful transaction carrier exists;
5. `posting_row_count` — rows returned by Stage 2A or the checked TSV result, including rejected TSV rows;
6. `ok_posting_count` — returned Posting IR rows whose status is `ok`;
7. `rejected_posting_count` — returned Posting IR rows whose status is non-`ok`;
8. `diagnostic_count` — top-level/parser diagnostic count;
9. `has_rejection_evidence` — parser/top-level diagnostics exist or rejected posting rows exist;
10. `downstream_admitted_count` — Journal successful Stage 2A row count or legacy Cube `valid_rows` count;
11. `source_codes` — unmodified Journal diagnostic codes, legacy top-level diagnostic codes, and/or rejected legacy row statuses as source-specific evidence.

This carrier is test-local normalization only. `source_state`, counts, and `source_codes` are observed rather than forced equal. It is not a production type, an optional Posting IR extension, or a new diagnostic vocabulary.

## Per-case observation requirements

### Invalid date

- Journal: parser `state = error`, zero admitted transactions, `unsupported_group` evidence, zero Stage 2A rows.
- Legacy: checked result `state = ok`, exactly two posting rows, both non-`ok` with `invalid_date`, no top-level diagnostic, zero Cube-valid rows, and both rows retained as skipped evidence.

### Invalid exact-integer amount

- Journal: parser `state = error`, zero admitted transactions, the current amount/missing-posting diagnostics remain observable, and Stage 2A emits zero rows.
- Legacy: checked result `state = error`, zero posting rows, at least one top-level authorization diagnostic, and zero Cube-valid rows.
- Neither side may expose an `ok` posting with delta `0`; no source token is normalized into a successful zero-value movement.

### Unknown account

- Journal: parser `state = error`, zero admitted transactions, current account/unbalanced diagnostics remain observable, and Stage 2A emits zero rows.
- Legacy: checked result `state = ok`, exactly two posting rows, both non-`ok` with `unknown_account`, no top-level diagnostic, zero Cube-valid rows, and both rows retained as skipped evidence.

## Structural parity assertions

For each of the three cases, the focused test must assert:

1. the Journal and TSV fixture sides encode the same intended source movement except for source syntax;
2. `ok_posting_count = 0` on both sides;
3. `has_rejection_evidence = 1` on both sides;
4. `downstream_admitted_count = 0` on both sides;
5. no invalid movement appears as successful Posting IR;
6. no successful delta, account total, Cube value, or other normal numeric partial result is derived from the invalid movement;
7. invalid exact-integer evidence produces no successful zero-delta posting;
8. rejected legacy rows, when present, retain their non-`ok` status and message;
9. Journal diagnostics and legacy diagnostics/statuses remain independently observable;
10. exact diagnostic strings/codes, line numbers, source rows, source states, row counts, and identity strings are not cross-source equality assertions.

The test may assert the audited current source-specific codes/statuses to detect local drift. Such assertions remain side-specific and do not redefine parity as code equality.

## Fail-closed and no-partial-success meaning

For Stage 2C, **fail closed** means the selected invalid source movement contributes zero successful Posting IR rows and zero Cube-valid rows. Rejection may occur either by withholding the Journal transaction, by failing the legacy checked result before posting construction, or by returning legacy posting evidence with a non-`ok` status that Cube skips.

**No partial success** means that one side of the movement, a default amount, a zero substitute, or another normal numeric fragment must not be admitted when the paired movement is invalid. It does not require the Journal parser and TSV adapter to share an aggregate state or diagnostic representation, and it does not define behavior for a larger source containing unrelated valid events.

## Completion conditions

Stage 2C implementation is complete only when:

1. the one dedicated public fixture directory contains exactly the three selected paired cases and shared anonymous accounts;
2. the focused test directly observes the existing Journal parser, Stage 2A adapter, checked TSV adapter, and legacy Cube acceptance boundary;
3. all carrier fields and structural assertions above are implemented test-locally;
4. all three invalid movements have zero successful Posting IR and zero downstream admission;
5. source-specific rejection evidence is preserved and asserted without cross-source code equality;
6. the malformed amount cannot become an `ok` zero-valued posting;
7. no `src_next` helper, production result-shape change, runtime route, report change, or source-data change is added;
8. focused and repository checks pass;
9. routing records completion without automatically selecting Stage 2D or any later work.

If implementation discovers that these exact existing shapes cannot support the carrier and assertions without changing production code, it must stop. The implementation must document the mismatch and request a separate design decision rather than adding normalization or changing result shapes.

## Production non-connection boundary

Stage 2C remains public-synthetic and test-only. It must not connect Journal parsing or rejection evidence to `LoadPostingSourceSnapshot`, `BuildContext`, production Cube/TBDS/report routing, the editor, a CLI, shadow reads, or private data. The legacy checked adapter and Cube are invoked only with the dedicated public fixture snapshot from the focused test. Current source truth remains the legacy TSV files in the selected base directory.

## Explicit non-goals

Stage 2C does not implement or select:

- unbalanced explicit Journal postings;
- missing plan event-id;
- duplicate Journal metadata;
- unsupported Journal syntax;
- the parser red path as a whole;
- native parity for three or more postings;
- Stage 1 parser changes;
- Stage 2A or Stage 2B changes;
- production Journal routing or loader work;
- shadow read or private-data comparison;
- a Journal or TSV writer/editor;
- conversion, synchronization, cutover, or source-of-truth changes;
- `source_row` consumer migration;
- report, Cube, or TBDS changes;
- automatic selection of Stage 2D or any later stage;
- TSV cleanup, deletion, or production source TSV changes.

Unbalanced postings and the other excluded parser failures are Journal-specific or lack an equivalent one-row TSV movement shape. They are not comparable rejection parity evidence for this slice.

## Unresolved decisions intentionally left open

- whether a future production Journal adapter should expose rejected transaction carriers;
- whether shared diagnostics should ever gain a cross-source taxonomy;
- whether production Posting IR should represent aggregate rejection separately from rejected rows;
- broader mixed-valid/invalid source admission policy;
- the next Journal stage after Stage 2C.

None is selected by this contract.
