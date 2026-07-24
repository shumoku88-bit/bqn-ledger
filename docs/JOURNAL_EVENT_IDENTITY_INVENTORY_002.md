# Journal Event Identity Inventory 002

Status: current identity inventory and classification contract
Owner: journal-identity
Canonical: yes

## Overview

This inventory presents a multi-axis breakdown of all transaction identities (`event-id` metadata) in the Canonical production Journal (`actual.journal`).

Rather than forcing event IDs into a single binary deletion classification, this tool evaluates identities along seven orthogonal axes:
1. **Presence**: `IDENTITY_FREE` vs `EXPLICIT_EVENT_ID`
2. **Lexical Family**: `NONE`, `LEGACY_ENTRY_24HEX`, `PREFIXED_HEX`, `PREFIXED_OTHER`, `OPAQUE_HEX`, `SEMANTIC_TEXT`, `OTHER`
3. **Incoming References**: Counts incoming metadata links targeting the event ID (`actual-event-id`, `source-event-id`, `original-event-id`, `reversal-of`, `parent-event-id`, `related-event-id`).
4. **Outgoing Functional Links**: Presences of functional link metadata (`plan-id`, `txn-id`, `allocation-id`, `actual-event-id`, `execution-envelope`, `series`, `recur`, `income-budget`).
5. **Provenance**: Migration origin or generator pipeline (`IDENTITY_FREE`, `TSV-to-Journal migration`, `native durable editor`, `travel editor`, `reverse command`, `plan completion`, `manual or unknown`).
6. **Reconstructibility**: Deterministic regenerability (`IDENTITY_FREE`, `PROVEN_RECONSTRUCTIBLE`, `LIKELY_RECONSTRUCTIBLE`, `NOT_RECONSTRUCTIBLE`, `UNKNOWN`).
7. **Deletion Disposition**: Recommended disposition (`IDENTITY_FREE`, `KEEP_REFERENCED`, `KEEP_FUNCTIONAL`, `KEEP_NONRECONSTRUCTIBLE`, `REVIEW_RECONSTRUCTIBLE`, `REVIEW_UNKNOWN`). **Note**: Deletion disposition NEVER outputs `DELETE`.

---

## Production Inventory Aggregate (Data SHA: 2cae9e1dfb07bc0f1b071abb2ae59e5117dc64af)

```text
Journal Event Identity Inventory 002 Summary
total_transactions=410
identity_free=6
explicit_event_id=404

[Lexical Families]
family_none=6
family_legacy_entry_24hex=0
family_prefixed_hex=0
family_prefixed_other=3
family_opaque_hex=0
family_semantic_text=401
family_other=0

[Incoming References]
total_incoming_references=0
transactions_with_references=0

[Outgoing Functional Links]
has_plan_id=7
has_txn_id=5
has_allocation_id=0
has_actual_event_id=0
has_execution_envelope=0
has_series=7
has_recur=4
has_income_budget=5

[Provenance]
prov_identity_free=6
prov_tsv_migration=0
prov_native_editor=0
prov_travel_editor=0
prov_reverse_cmd=0
prov_plan_completion=7
prov_manual_unknown=397

[Reconstructibility]
recon_identity_free=6
recon_proven=0
recon_likely=7
recon_not=0
recon_unknown=397

[Deletion Disposition]
disp_identity_free=6
disp_keep_referenced=0
disp_keep_functional=12
disp_keep_nonreconstructible=0
disp_review_reconstructible=0
disp_review_unknown=392
```

---

## Command Usage

```bash
# Printed aggregate summary (privacy-safe, no private IDs or details)
tools/edit [--base DIR] journal identity-inventory --format summary

# Redacted TSV row inventory (privacy-safe, redacts event-ids, descriptions, amounts)
tools/edit [--base DIR] journal identity-inventory --format tsv

# Local unredacted debug TSV (prints warning to stderr)
tools/edit [--base DIR] journal identity-inventory --format private-tsv
```

---

## Key Findings

1. **Zero Removable Legacy 24-Hex Entry IDs**: All 404 durable event IDs in production are non-legacy or semantic event IDs (401 semantic text, 3 prefixed other).
2. **Zero Incoming Reference Dependencies**: No actual layer transactions are targeted by incoming reference metadata.
3. **12 Functional Link Transactions**: 12 transactions carry functional links (`plan-id`, `txn-id`, `series`, `recur`, `income-budget`) requiring retention (`KEEP_FUNCTIONAL`).
4. **392 Review Unknown Transactions**: 392 transactions have semantic event IDs with no incoming references or outgoing functional links; their reconstructibility requires further pipeline tracing before any future decision (`REVIEW_UNKNOWN`).
