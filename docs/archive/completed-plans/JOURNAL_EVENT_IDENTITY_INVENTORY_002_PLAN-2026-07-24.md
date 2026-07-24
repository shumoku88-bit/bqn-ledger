# Journal Event Identity Inventory 002 Plan (2026-07-24)

## Objective

Classify and inventory all transaction identities (`event-id` metadata) in Canonical `actual.journal` across multiple orthogonal axes:
- Presence
- Lexical Family (syntax observation, not semantic proof)
- Incoming References (including duplicate, dangling, and self-reference tracking)
- Outgoing Functional Links
- Provenance (class + confidence; may be verified, inferred, or unknown)
- Reconstructibility (not deletion authorization)
- Deletion Disposition (never outputs DELETE)

---

## Deliverables Completed

1. **BQN Core Module**: `src_edit/journal_identity_inventory.bqn`
   - Multi-axis classification engine (`IsLegacyEntryId`, `ClassifyLexicalFamily`, `BuildReferenceIndex`, `ClassifyProvenance`, `ClassifyReconstructibility`, `ClassifyDisposition`, `BuildInventory`).
   - Provenance returns class + confidence pair.
   - Summary and privacy-redacted TSV formatting (`Summarize`, `FormatSummary`, `FormatTsv`).
   - Duplicate identity, dangling reference, and self-reference tracking.

2. **CLI Commands**:
   - `src_edit/journal_identity_inventory_cmd.bqn`
   - Subcommand routing in `tools/edit-bqn` and wrapper `tools/edit` (`journal identity-inventory`).
   - Formats: `summary` and `tsv` only. No unredacted stdout output.

3. **Unit & Integration Tests**:
   - Unit test: `tests/test_journal_event_identity_inventory.bqn`
   - Check script: `checks/check-edit-bqn-journal-event-identity-inventory.sh`
   - Privacy canary tests (summary and TSV)
   - Reference independence tests
   - Duplicate and dangling reference tests

4. **Documentation**:
   - `docs/JOURNAL_EVENT_IDENTITY_INVENTORY_002.md`
   - Completed plan record: `docs/archive/completed-plans/JOURNAL_EVENT_IDENTITY_INVENTORY_002_PLAN-2026-07-24.md`

---

## Production Verification

Run against private production data:
```bash
tools/edit --base "$LEDGER_DATA_DIR" journal identity-inventory --format summary
```
Result: Total=410, Identity-free=6, Explicit=404 (0 legacy entry 24hex, 401 text-shaped event IDs, 3 prefixed other). No files altered in production data.
