# Journal Event Identity Inventory 002 Plan (2026-07-24)

## Objective

Classify and inventory all transaction identities (`event-id` metadata) in Canonical `actual.journal` across multiple orthogonal axes:
- Presence
- Lexical Family
- Incoming References
- Outgoing Functional Links
- Provenance
- Reconstructibility
- Deletion Disposition

---

## Deliverables Completed

1. **BQN Core Module**: `src_edit/journal_identity_inventory.bqn`
   - Multi-axis classification engine (`IsLegacyEntryId`, `ClassifyLexicalFamily`, `BuildReferenceIndex`, `ClassifyProvenance`, `ClassifyReconstructibility`, `ClassifyDisposition`, `BuildInventory`).
   - Summary and privacy-redacted TSV formatting (`Summarize`, `FormatSummary`, `FormatTsv`).

2. **CLI Commands**:
   - `src_edit/journal_identity_inventory_cmd.bqn`
   - Subcommand routing in `tools/edit-bqn` and wrapper `tools/edit` (`journal identity-inventory`).

3. **Unit & Integration Tests**:
   - Unit test: `tests/test_journal_event_identity_inventory.bqn`
   - Check script: `checks/check-edit-bqn-journal-event-identity-inventory.sh`
   - Baseline update: `tools/repo-index --baseline`

4. **Documentation**:
   - `docs/JOURNAL_EVENT_IDENTITY_INVENTORY_002.md`
   - Completed plan record: `docs/archive/completed-plans/JOURNAL_EVENT_IDENTITY_INVENTORY_002_PLAN-2026-07-24.md`

---

## Production Verification

Run against private production data:
```bash
tools/edit --base ~/Projects/moko/ledger-data/data journal identity-inventory --format summary
```
Result: Total=410, Identity-free=6, Explicit=404 (0 legacy entry 24hex, 401 semantic text, 3 prefixed other). No files altered in `ledger-data`.
