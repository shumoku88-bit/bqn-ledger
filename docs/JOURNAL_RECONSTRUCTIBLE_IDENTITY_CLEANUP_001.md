# Journal Reconstructible Identity Cleanup 001

Status: completion record
Owner: journal-identity
Canonical: yes
Date: 2026-07-24

## 1. Scope

This document records the design, implementation, verification, and production application protocol for the safe cleanup of 390 reconstructible migration-derived event identities (`event-id` metadata lines) from the production Journal.

No additional provenance investigation was conducted. No non-migration, functional, purchase-shaped, or completion identity was removed.

## 2. Inventory Aggregate Boundary (390 / 12 / 2 / 6)

Before cleanup:
- Total transactions: 410
- Explicit event identities: 404
- Identity-free transactions: 6
- Functional link identities (`KEEP_FUNCTIONAL`): 12
- Purchase-shaped explicit identities: 2
- Removable non-functional migration identities: 390

After cleanup:
- Total transactions: 410
- Explicit event identities: 14 (12 functional + 2 purchase-shaped)
- Identity-free transactions: 396 (6 original + 390 cleaned)
- Preserved functional identities: 12 (11 migration with functional link + 1 plan completion)
- Preserved purchase-shaped identities: 2 (explicit operator inputs)
- Removed event-id lines: 390

## 3. Selection Rule

Selection reuses the existing `src_edit/journal_identity_inventory.bqn` semantic classification owner rather than implementing a duplicate classifier. A transaction is selected for removal if and only if all of the following hold:
1. Transaction carries an explicit `event-id` metadata line.
2. `event-id` belongs to the verified canonical migration family (`TEXTUAL_OTHER` lexical family, `legacy:` prefix, or `TSV_MIGRATION_CANDIDATE`).
3. Transaction carries no functional links (`has_functional_link` is false; disposition is not `KEEP_FUNCTIONAL`).
4. `event-id` is not a purchase-shaped explicit input (`purchase-` prefix).
5. `event-id` is not a plan completion identity (`completion-` / `plan-` prefix).
6. `event-id` has no incoming reference links (`incoming_reference_count` is 0).

The target removal count must equal exactly 390. Any candidate generation with fewer than 389 or more than 391 removable transactions fails closed.

## 4. Byte-Preserving Transformation

The cleanup transformation does not re-render or re-format the Journal. Original bytes are preserved line-by-line, and only the 390 targeted `; event-id: ...` metadata lines are omitted.

Preserved byte-for-byte:
- Transaction and posting order
- All blank lines, indentation, comments, and descriptions (including Unicode characters)
- Header dates and status markers
- Account keys, amounts, commodities, layers, and non-event-id metadata
- Final trailing newline

Expected diff:
- Omitted lines: exactly 390
- Added lines: 0
- Modified non-event-id lines: 0

## 5. Allowed Identity and Provenance Delta

The transformation allows only the following identity and provenance changes for the 390 cleaned transactions:
- `source_event_id` becomes absent (falls back to Stage 1 physical line identifier).
- `event-id` metadata line becomes absent.
- `posting_id` changes from durable identity-based form (`legacy:...:N`) to physical fallback form (`stage0-line-L:N`).
- Provenance carriers derived from `source_event_id` reflect the identity-free status.

Accounting amounts, posting indices, transaction ordering, business links (`txn-id`, `plan-id`), and report calculations remain completely unchanged.

## 6. Accounting and Report Parity

Semantic parity was verified between the baseline and candidate Journals across all pipeline stages:
- Stage 1 Parser
- Account Resolver
- Stage 2A Posting IR
- Canonical Daily Cube
- TBDS (Trial Balance Data Set)
- Trial Balance
- Balances
- All canonical production reports

Transaction counts, dates, descriptions, posting counts, account keys, signed amounts, currencies, balances, Cube values, TBDS values, and report section totals match 1:1.

## 7. Command Interface and Atomic Operations

Surface:
- Pure semantic owner: `src_edit/journal_reconstructible_identity_cleanup.bqn`
- Command adapter: `src_edit/journal_reconstructible_identity_cleanup_cmd.bqn`
- CLI tool: `tools/journal-identity-cleanup`

Modes:
- `inspect [INPUT]`: Read-only analysis displaying privacy-safe aggregates only (no private IDs, descriptions, accounts, or amounts).
- `candidate INPUT OUTPUT [EXPECTED_REMOVAL_COUNT]`: Generates candidate raw text, completely validates semantic parity and line removal, writes to a temporary sibling file (`OUTPUT.tmp.PID.RAND`), and performs an atomic rename (`mv`) to publish `OUTPUT`. Fails if `OUTPUT` already exists or removal count mismatch.
- `apply INPUT EXPECTED_SHA256 EXPECTED_REMOVAL_COUNT`: Verifies `INPUT` current SHA-256 matches `EXPECTED_SHA256`, builds and validates candidate, re-verifies `INPUT` SHA-256 immediately before publish, writes to temporary sibling, and atomically renames (`mv`) to overwrite `INPUT`. Partial writes are prohibited.

## 8. Verification Evidence

Public synthetic test suite:
- `tests/test_journal_reconstructible_identity_cleanup.bqn`
- `checks/check-journal-reconstructible-identity-cleanup.sh`

Verified test cases:
- 1 removable migration identity without functional link
- 1 migration identity with functional link (preserved)
- 1 completion identity with functional link (preserved)
- 2 purchase-shaped explicit identities (preserved)
- 1 identity-free transaction (multi-posting, Unicode description, comment lines, metadata before/after `event-id`)
- Final newline preservation
- Failure paths: removal count mismatch, input SHA mismatch, existing candidate output file, malformed Journal

## 9. Production Application Gate

The public implementation must be merged into `shumoku88-bit/bqn-ledger` `main` before any application to private production data (`shumoku88-bit/ledger-data`).

Production application requirements:
- Private repository clean (except 2 pre-existing untracked backup files)
- Pre-apply production Journal SHA-256: `66e336fdbb95cf202420b701add7910b19205ffd8cd663e52268d9d5c594d80c`
- Pre-apply production byte size: `59179`
- Apply via `tools/journal-identity-cleanup apply`
- Post-apply Git diff: `data/actual.journal` modified only (-390 lines, +0 lines)
- Post-apply fast-forward merge into private `main` and remote push

## 10. Non-Authorization of Wider Metadata Cleanup

This cleanup is strictly limited to the 390 non-functional migration event-id lines. It does NOT authorize:
- Deletion of any of the 12 functional identities
- Deletion of any of the 2 purchase-shaped identities
- Removal of any non-event-id metadata (`note`, `biz`, `tax`, `receipt-id`, etc.)
- Re-rendering of Journal transactions
- Any wider metadata cleanup, which requires a separate explicit specification.
