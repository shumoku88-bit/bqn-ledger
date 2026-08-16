# Journal Reconstructible Identity Cleanup 001

Status: historical completion record; runtime retired after completion
Owner: journal-identity
Canonical: historical evidence
Date: 2026-07-24

## 1. Scope

This document records the design, implementation, verification, and production application protocol for the completed cleanup of 390 reconstructible migration-derived event identities (`event-id` metadata lines) from the production Journal.

No additional provenance investigation was conducted. No non-migration, functional, purchase-shaped, or completion identity was removed.

The cleanup has already been applied. The dedicated executable cleanup runtime was later retired during the Phase 6 BQN-native re-baseline because it represented a completed one-shot migration rather than an ongoing Journal capability. This document is the durable record of that transformation.

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

## 3. Selection Rule Used by the Completed Migration

The migration reused the then-current `src_edit/journal_identity_inventory.bqn` semantic classification owner rather than implementing a completely separate inventory parser. A transaction was selected for removal if and only if all of the following held:
1. Transaction carried an explicit `event-id` metadata line.
2. `event-id` belonged to the admitted migration family (`TEXTUAL_OTHER` lexical family, `legacy:` prefix, or `TSV_MIGRATION_CANDIDATE`).
3. Transaction carried no functional links (`has_functional_link` false; disposition not `KEEP_FUNCTIONAL`).
4. `event-id` was not a purchase-shaped explicit input (`purchase-` prefix).
5. `event-id` was not a plan completion identity (`completion-` / `plan-` prefix).
6. `event-id` had no incoming reference links (`incoming_reference_count` 0).

The production application required the observed removable count to equal exactly 390. Any other count failed closed.

This rule is historical migration evidence. It is not a standing authorization to infer current identity meaning from prefixes or to delete future Journal metadata.

## 4. Byte-Preserving Transformation

The cleanup transformation did not re-render or re-format the Journal. Original bytes were preserved line-by-line, and only the 390 targeted `; event-id: ...` metadata lines were omitted.

Preserved byte-for-byte:
- Transaction and posting order
- All blank lines, indentation, comments, and descriptions (including Unicode characters)
- Header dates and status markers
- Account keys, amounts, commodities, layers, and non-event-id metadata
- Final trailing newline

Applied diff:
- Omitted lines: exactly 390
- Added lines: 0
- Modified non-event-id lines: 0

## 5. Allowed Identity and Provenance Delta

The transformation allowed only the following identity and provenance changes for the 390 cleaned transactions:
- `source_event_id` became absent and therefore fell back to the physical line identifier available at that time.
- `event-id` metadata line became absent.
- `posting_id` changed from durable identity-based form to physical fallback form.
- Provenance carriers derived from `source_event_id` reflected the identity-free status.

Accounting amounts, posting indices, transaction ordering, business links (`txn-id`, `plan-id`), and report calculations remained unchanged.

The exact names of historical fallback identifiers are implementation-history details, not current identity contracts.

## 6. Accounting and Report Parity

Semantic parity was verified between the baseline and candidate Journals across the pipeline then in production:
- Stage 1 Parser
- Account Resolver
- Stage 2A Posting IR
- Canonical Daily Cube
- TBDS (Trial Balance Data Set)
- Trial Balance
- Balances
- canonical production reports

Transaction counts, dates, descriptions, posting counts, account keys, signed amounts, currencies, balances, Cube values, TBDS values, and report section totals matched 1:1 for the migration evidence.

## 7. Historical Command Interface and Atomic Operations

The completed migration originally used:
- pure semantic owner: `src_edit/journal_reconstructible_identity_cleanup.bqn`
- command adapter: `src_edit/journal_reconstructible_identity_cleanup_cmd.bqn`
- CLI wrapper: `tools/journal-identity-cleanup`

Historical modes were:
- `inspect [INPUT]`: read-only privacy-safe aggregate analysis;
- `candidate INPUT OUTPUT [EXPECTED_REMOVAL_COUNT]`: byte-preserving candidate generation and validation before atomic candidate publication;
- `apply INPUT EXPECTED_SHA256 EXPECTED_REMOVAL_COUNT`: SHA-guarded candidate generation, pre-publish recheck, and atomic replacement.

These paths are intentionally no longer present on current `main`. Git history retains the executable implementation if the migration itself must ever be audited.

## 8. Verification Evidence

The migration was originally covered by:
- `tests/test_journal_reconstructible_identity_cleanup.bqn`
- `checks/check-journal-reconstructible-identity-cleanup.sh`

The evidence included:
- removable migration identity without a functional link;
- migration identity with a functional link preserved;
- completion identity with a functional link preserved;
- purchase-shaped explicit identities preserved;
- identity-free multi-posting transaction with Unicode/comments/metadata preserved;
- final newline preservation;
- removal count mismatch rejection;
- input SHA mismatch rejection;
- existing candidate output rejection;
- malformed Journal rejection;
- candidate/apply publication guards.

Those executable replay tests were retired together with the one-shot runtime. Ongoing Journal safety is now guarded by the active admission, writer, canonical-surface, cleanup-plan, list/reverse, and mandatory source-validation portfolios rather than by repeatedly replaying this historical production migration.

## 9. Production Application Record

The public implementation was merged before application to the private production data.

The application gate recorded:
- pre-apply production Journal SHA-256: `66e336fdbb95cf202420b701add7910b19205ffd8cd663e52268d9d5c594d80c`
- pre-apply production byte size: `59179`
- post-apply Journal diff limited to the 390 approved event-id removals
- 410 transactions preserved
- explicit event identities reduced from 404 to 14
- identity-free transactions increased from 6 to 396

These values are historical evidence only. They must not be treated as current private Household state.

## 10. Non-Authorization of Wider Metadata Cleanup

This completed cleanup authorized only the 390 observed non-functional migration event-id lines. It did NOT authorize:
- deletion of the 12 retained functional identities;
- deletion of the 2 retained purchase-shaped identities;
- removal of non-event-id metadata (`note`, `biz`, `tax`, `receipt-id`, etc.);
- re-rendering of Journal transactions;
- future deletion based on current configuration or lexical prefix alone;
- any wider metadata cleanup without a separate explicit specification.

## 11. Runtime Retirement

During the 2026-08-17 Phase 6 BQN-native review, repository reachability showed that the dedicated cleanup runtime was no longer part of the normal Journal dispatcher or Household surface. Its remaining live references were its own wrapper, replay tests/check, TODO inventory, and this completion record.

Because the production migration was complete, retaining that executable path created a second kind of authority: historical cleanup assumptions such as the 390-count gate and prefix exceptions remained runnable even though they no longer described an ongoing domain capability.

The re-baseline therefore retired:

```text
src_edit/journal_reconstructible_identity_cleanup.bqn
src_edit/journal_reconstructible_identity_cleanup_cmd.bqn
tools/journal-identity-cleanup
tests/test_journal_reconstructible_identity_cleanup.bqn
checks/check-journal-reconstructible-identity-cleanup.sh
```

The completed migration remains reconstructible from this document and Git history. Future Journal cleanup must start from current admitted semantics and current evidence rather than invoking this retired epoch-specific migration.
