# Journal Event Identity Inventory 002

Status: current identity inventory and classification contract
Owner: journal-identity
Canonical: yes

## Overview

This inventory presents a multi-axis breakdown of all transaction identities (`event-id` metadata) in the Canonical production Journal (`actual.journal`).

Rather than forcing event IDs into a single binary deletion classification, this tool evaluates identities along seven orthogonal axes:
1. **Presence**: `IDENTITY_FREE` vs `EXPLICIT_EVENT_ID`
2. **Lexical Family**: `NONE`, `LEGACY_ENTRY_24HEX`, `PREFIXED_HEX`, `PREFIXED_OTHER`, `OPAQUE_HEX`, `TEXTUAL_OTHER`, `OTHER`. Lexical family is a syntax observation. It does not prove semantic meaning, provenance, reconstructibility, or deletion safety.
3. **Incoming References**: Counts incoming metadata links targeting the event ID (`actual-event-id`, `source-event-id`, `original-event-id`, `reversal-of`, `parent-event-id`, `related-event-id`). Also tracks `duplicate_identity_definitions`, `dangling_references`, and `self_references`.
4. **Outgoing Functional Links**: Presences of functional link metadata (`plan-id`, `txn-id`, `allocation-id`, `actual-event-id`, `execution-envelope`, `series`, `recur`, `income-budget`).
5. **Provenance**: Classification plus confidence level. Provenance may be verified, inferred, or unknown. ID prefix alone does not prove generation pipeline origin.
   - `provenance_class`: `IDENTITY_FREE`, `TSV_MIGRATION_CANDIDATE`, `NATIVE_EDITOR_CANDIDATE`, `TRAVEL_EDITOR_CANDIDATE`, `REVERSE_COMMAND_CANDIDATE`, `PLAN_COMPLETION_CANDIDATE`, `UNKNOWN`
   - `provenance_confidence`: `not_applicable`, `not_verified`, `inferred_from_prefix`, `inferred_from_plan_link`
6. **Reconstructibility**: Deterministic regenerability (`IDENTITY_FREE`, `PROVEN_RECONSTRUCTIBLE`, `LIKELY_RECONSTRUCTIBLE`, `NOT_RECONSTRUCTIBLE`, `UNKNOWN`). This classification does not authorize deletion. `LIKELY_RECONSTRUCTIBLE` means only that a possible reconstruction path has been identified; exact deterministic regeneration has not been verified. `PROVEN_RECONSTRUCTIBLE` requires: same inputs produce the same ID, the generating algorithm is identified, and all required inputs remain available.
7. **Deletion Disposition**: Recommended disposition (`IDENTITY_FREE`, `KEEP_REFERENCED`, `KEEP_FUNCTIONAL`, `KEEP_NONRECONSTRUCTIBLE`, `REVIEW_RECONSTRUCTIBLE`, `REVIEW_UNKNOWN`). Deletion disposition NEVER outputs `DELETE`. `REVIEW_UNKNOWN` does not mean removable. `KEEP_FUNCTIONAL` is conservative retention.

No production event-id was deleted.

---

## Production Inventory Aggregate

```text
transactions: 410
identity-free: 6
explicit event-id: 404
legacy entry 24hex: 0
IDs in the textual lexical family: 401
IDs in the prefixed-other lexical family: 3
incoming references observed: 0
duplicate identity definitions: 0
dangling references: 0
self-references: 0
transactions with functional links: 12
provenance verified: 0
provenance inferred: 7
provenance unknown: 397
PROVEN_RECONSTRUCTIBLE: 0
REVIEW_UNKNOWN: 392
KEEP_FUNCTIONAL: 12
```

---

## Command Usage

```bash
# Printed aggregate summary (privacy-safe, no private IDs or details)
tools/edit [--base DIR] journal identity-inventory --format summary

# Redacted TSV row inventory (privacy-safe, redacts event-ids, descriptions, amounts)
tools/edit [--base DIR] journal identity-inventory --format tsv
```

---

## Privacy Boundary

- No production Journal modification.
- No private event ID, description, account, amount, or link value committed.
- Summary output is aggregate-only.
- TSV output is redacted (no event-id, description, account, amount, plan-id, or txn-id values).
- Unredacted stdout output is not provided (`private-tsv` format removed).

---

## Key Findings

1. **Zero Removable Legacy 24-Hex Entry IDs**: All 404 durable event IDs in production are non-legacy. 401 IDs fall into the textual lexical family; 3 into prefixed-other.
2. **Zero Incoming Reference Dependencies**: No actual layer transactions are targeted by incoming reference metadata.
3. **Zero Duplicate or Dangling References**: No duplicate identity definitions or dangling references exist in production.
4. **12 Functional Link Transactions**: 12 transactions carry functional links (`plan-id`, `txn-id`, `series`, `recur`, `income-budget`) requiring retention (`KEEP_FUNCTIONAL`).
5. **392 Review Unknown Transactions**: 392 transactions have text-shaped event IDs with no incoming references or outgoing functional links; their reconstructibility requires further pipeline tracing before any future decision (`REVIEW_UNKNOWN`).
6. **All Provenance is Inferred or Unknown**: No provenance has been verified against actual generator implementation or migration manifests. 7 transactions have inferred provenance (plan completion candidate); 397 have unknown provenance.
