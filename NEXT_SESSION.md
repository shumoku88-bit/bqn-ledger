# Next session

Status: selected prerequisite; parent converter blocked
Owner: journal source migration / profile and test-only IR
Canonical: yes; canonical plan is `docs/JOURNAL_LEGACY_METADATA_PROFILE_EXTENSION_PLAN.md`
Exit: complete the public synthetic profile/Stage 2A/Stage 2B evidence, archive this prerequisite, and keep the canonical converter selected but not started
Date: 2026-07-22

## Current selection

The **Canonical TSV-to-native Journal prefix converter** remains selected under `docs/JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_PLAN.md`, but it cannot begin until the selected test-only Minimal BQN Journal profile extension is complete.

This finite prerequisite must:

- retain nonempty `source_event_id` separately from optional business `txn_id`;
- preserve absence of `txn_id`, allow distinct transactions to share one `txn_id`, and keep posting IDs derived from source identity plus posting index;
- represent every admitted legacy `journal.tsv` metadata field through the public mapping table in `docs/JOURNAL_LEGACY_METADATA_PROFILE_EXTENSION_PLAN.md`;
- reject duplicate, unknown, ambiguous, empty, or malformed metadata fail closed;
- keep the existing 16-field Posting IR shape and production TSV routing unchanged;
- validate Stage 2B identity/provenance alignment;
- use public synthetic values only.

## Explicit non-goals

No converter, conversion, reconstruction, suffix replacement, production parser routing, production writer change, source-truth change, cutover, private-data access, dual write, reverse synchronization, or conflict resolution is selected. Completion of this prerequisite does not select the converter implementation automatically.

## Description boundary

Record but do not resolve inside this slice: TSV column 2 is source memo/description; the TSV editor preserves validated text; `tools/to-hledger` strips surrounding whitespace; the native writer requires trimmed text; and the Journal parser admits the transaction-header description. Any remaining exact-semantics ambiguity is a later converter gate.
