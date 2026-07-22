# Next session

Status: selected finite canonical TSV-to-native Journal prefix converter; profile prerequisite complete
Owner: journal source migration / conversion
Canonical: yes; canonical plan is `docs/JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_PLAN.md`
Exit: converter implementation, synthetic validation, private read-only verification, independent review, completion archive, and explicit return to no selected Journal slice
Date: 2026-07-22

## Current routing

The legacy metadata/profile prerequisite is complete and archived at `docs/archive/completed-plans/JOURNAL_LEGACY_METADATA_PROFILE_EXTENSION_PLAN-2026-07-22.md`.

The **Canonical TSV-to-native Journal prefix converter** remains selected, but its implementation has not started. It must preserve canonical `source_event_id`, distinct optional business `txn_id`, the complete mapped legacy metadata vocabulary, transaction/posting order, and fail-closed diagnostics while keeping the current 16-field Posting IR and production TSV route unchanged.

## Explicit gates

- The implementation branch must be preceded by explicit owner review of the completed prerequisite and the canonical converter plan.
- The converter must not read or modify private data in this phase; only public synthetic evidence is authorized until a separately gated read-only verification.
- No conversion, reconstruction, suffix replacement, production parser routing, production writer change, source-truth change, cutover, dual write, reverse synchronization, or conflict resolution is included in the completed prerequisite.
- Description semantics remain an explicit converter gate: TSV column 2 is source memo/description; the TSV editor preserves validated text; `tools/to-hledger` strips surrounding whitespace; the native writer requires trimmed text; and the Journal parser admits the transaction-header description.
- Production cutover remains blocked and is not selected automatically.
