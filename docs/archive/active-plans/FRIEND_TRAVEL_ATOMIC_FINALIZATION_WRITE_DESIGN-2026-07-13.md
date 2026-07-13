# Friend travel atomic finalization write design

Status: selected docs-only design; implementation not yet complete
Owner: currency / editor / source safety
Canonical: yes; canonical path: `docs/archive/active-plans/FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md`
Exit: close only after the selected synthetic transaction implementation is merged, independently verified, and its production-use follow-up is separately selected or declined.

## Purpose

Define one recoverable write operation that turns one validated pending friend-paid travel source event into exactly one canonical JPY journal expense while preserving duplicate protection and source recovery evidence.

This design follows the already-verified pure preview in `src_next/friend_travel_jpy_finalization.bqn`. It does not change the accounting result: one existing JPY friend-liability account points to one existing JPY travel-expense account for the human-confirmed integer JPY amount.

## Selected storage boundary

The selected source file is:

```text
<ledger>/friend_travel_events.tsv
```

It is a source-fact file and is not a journal-like posting source. Its rows do not enter Posting IR, Cube, TBDS, envelope consumption, report totals, or valuation merely because they exist.

The fixed columns are:

```tsv
date	party	item_or_category	original_amount	original_currency	payer	trip_id	source_event_id	status	finalization_date	final_jpy_amount	journal_row_sha256
```

Pending rows require:

- the first nine fields to satisfy the existing pending source-event contract;
- `status=pending`;
- the final three fields to be empty.

Finalized rows require:

- the original observed fields to remain byte-for-byte unchanged;
- `status=finalized`;
- a valid explicit `finalization_date`;
- a positive integer `final_jpy_amount`;
- `journal_row_sha256` equal to the digest of the exact appended journal row.

`source_event_id` is unique across all non-comment source rows. Duplicate, empty, malformed, or unknown status rows fail closed.

## Durable finalization index

No second index file is introduced.

The durable finalization index is the set of valid `source_event_id` values from finalized rows in `friend_travel_events.tsv`. The index is derived only after the complete file validates. Any malformed finalized row, duplicate identifier, pending row with finalization fields, or finalized row with missing finalization fields rejects the entire index with no partial admission.

The exact journal scan remains a second independent duplicate check. A normal finalization requires:

- no finalized event row for the identifier;
- no journal row carrying the same `source_event_id`;
- exactly one pending event row for the identifier.

A retry after a successful commit may return `already_committed` only when the finalized event row and the exact journal row agree on identifier, finalization date, amount, trip, account direction, and journal-row digest. It performs no write and creates no new backup.

Any one-sided or conflicting state fails as `incomplete_or_conflicting_finalization`; it must not append a repair or replacement row automatically.

## Selected write set

One accepted operation changes exactly two source files:

1. `friend_travel_events.tsv`: replace exactly one pending row with its finalized form;
2. `journal.tsv`: append exactly the one row returned by the verified pure preview.

All other bytes, rows, comments, blanks, ordering, line endings, and unrelated metadata remain unchanged.

`accounts.tsv` is read-only evidence for the operation. The selected liability and expense descriptors must still exist with the required JPY currencies and roles immediately before replacement.

## Atomicity claim

This is an application-level recoverable two-file transaction. It is not described as a filesystem-wide atomic transaction because ordinary file replacement cannot make two independent files change in one indivisible kernel operation.

The selected protocol is:

1. acquire one exclusive finalization lock for the ledger base;
2. reject any unfinished earlier finalization transaction;
3. snapshot `friend_travel_events.tsv`, `journal.tsv`, and read-only `accounts.tsv` identities;
4. parse the complete event file and derive the complete finalization index;
5. rerun `ValidateAndPreview` from current supplied evidence;
6. construct complete staged replacement candidates for events and journal;
7. create a private recovery transaction directory with original copies, staged copies, hashes, operation identity, and a `prepared` manifest;
8. repeat stale checks for events, journal, and accounts;
9. replace journal first, then events;
10. run exact post-write checks;
11. mark the recovery manifest `committed` only after all post-write checks pass;
12. release the lock.

The journal-first order does not make a partial state valid. A process interruption after either replacement leaves a non-committed manifest, and every ordinary finalization attempt must refuse until recovery is completed.

## Recovery ownership

The writer owns rollback for every detected error while its process remains alive.

If replacement or a post-write check fails, the writer restores both original source files from the prepared recovery directory and verifies the restored hashes before reporting failure.

For process, device, or power interruption:

- a later normal finalization command must not guess, continue, or append;
- a dedicated recovery operation owns inspection and rollback;
- an uncommitted transaction defaults to restoring the original pair;
- automatic rollback is allowed only when the current files match one of the exact manifest-recognized states;
- any unrecognized bytes fail closed for manual inspection and are never overwritten automatically.

A committed manifest is durable acknowledgement evidence. If the client loses the response after commit, the next invocation recognizes the exact committed state and returns `already_committed` rather than writing again.

Recovery must never delete or edit a source row by semantic guess. It restores exact captured bytes only.

## Stale-check contract

The operation rejects before replacement if any of these changed after preview/snapshot:

- complete `friend_travel_events.tsv` bytes;
- complete `journal.tsv` bytes;
- complete `accounts.tsv` bytes;
- selected pending event row bytes;
- selected account descriptors or their role/currency evidence;
- derived finalization index.

The lock does not replace stale checks. It limits cooperating writers; hashes and exact bytes protect against external edits and stale previews.

No backup or replacement is created when validation or the first stale check fails. The recovery directory is created only after a complete accepted staged candidate exists.

## Confirmation boundary

A commit requires explicit human confirmation of the exact preview row and the selected source-event identifier.

The implementation may support a non-interactive confirmation flag for automated tests, but that flag does not authorize production use by itself. No AI, MCP, report, or UI consumer may infer approval from an accepted preview.

## Post-write evidence

A successful `committed` result requires all of:

- `journal.tsv` equals its original bytes plus exactly one newline-normalized accepted row;
- the accepted row appears exactly once;
- the row contains the selected `source_event_id` and `trip_id` exactly once each;
- `friend_travel_events.tsv` differs only at the selected row;
- the selected row is finalized with the exact date, integer JPY amount, and row digest;
- the derived finalization index contains the identifier exactly once;
- no pending row remains for the identifier;
- the selected JPY liability and expense account evidence still validates;
- journal/source lint and the focused friend-travel semantic check pass;
- the committed manifest records pre/post hashes and semantic status without private field values.

Process exit 0 alone is not proof of commit. The command must return an explicit semantic result such as `committed` or `already_committed` with privacy-safe evidence.

## Diagnostics and privacy

Diagnostics may include:

- operation identifier;
- stage;
- status/error code;
- source kind;
- zero-based row index when safe;
- pre/post hashes;
- whether rollback was attempted and verified.

Diagnostics must not echo private party, item, memo, account, original amount, final amount, or full source rows by default.

## Selected first implementation slice

After this design merges, the only selected implementation slice is a synthetic-fixture transaction core that:

- parses and renders the fixed `friend_travel_events.tsv` schema;
- derives the all-or-nothing finalized index;
- reuses the existing pure `ValidateAndPreview` result;
- stages and commits the exact two-file replacement under an explicit base directory;
- creates the prepared/committed recovery manifest and exact backups;
- implements fail-closed stale detection and rollback;
- implements exact `already_committed` retry recognition;
- provides a dedicated exact-byte recovery operation;
- adds focused synthetic fixtures and executable checks.

Required focused cases include:

- one accepted pending event commits exactly one journal row and one finalized event row;
- duplicate event identifiers reject;
- malformed pending/finalized rows reject with no partial index;
- pre-existing journal provenance rejects before write;
- stale events, journal, or accounts reject before replacement;
- injected failure after journal replacement restores both originals;
- injected failure after both replacements but before post-check completion restores both originals;
- uncommitted recognized manifest recovery restores originals;
- unrecognized recovery state refuses without overwrite;
- successful retry returns `already_committed` without new row or backup;
- post-write evidence proves exact two-file effect.

## Explicit exclusions from the first implementation

- actual `LEDGER_DATA_DIR` reads or writes;
- production source migration or production trial;
- MCP, editor UI, gum/fzf, report section, JSON API, or Ledger Observatory integration;
- automatic event creation or account selection;
- arbitrary source-event types or a generic event-sourcing framework;
- batch finalization, partial allocation, refunds, reversals, or repair rows;
- FX conversion, foreign-currency canonical postings, clearing, or two-row settlement;
- strict-source Steps 2–5 or M4;
- changing Canonical Daily Cube axes.

Production use remains a later separately selected checkpoint after implementation and independent post-implementation verification.

## Dependencies and routing

- Consumer semantics and preview row: `FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md`.
- Verified pure implementation: `src_next/friend_travel_jpy_finalization.bqn` and its focused tests.
- Existing safety precedents: the editor snapshot-token/backup/stale-check/atomic-append path, the MCP prepare/commit path, and the complete-set staging/rollback pattern from Currency M2.5 migration tooling.
- Current selection owner: `TODO.md`.

This design does not authorize Ledger Observatory runtime work, strict-source Steps 2–5, M4, or any production write.