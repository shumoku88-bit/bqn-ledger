# Journal Event Identity Inventory 002

Status: current classification contract; historical production snapshot retained
Owner: journal-identity
Canonical: yes

## Overview

This inventory presents a multi-axis breakdown of transaction identities (`event-id` metadata) in an admitted Canonical Journal observation.

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

The inventory owner is read-only and does not delete Journal identities. A later, separately specified cleanup used this classification evidence to remove exactly 390 approved migration-derived `event-id` metadata lines. See `JOURNAL_RECONSTRUCTIBLE_IDENTITY_CLEANUP_001.md` for that completed transformation and its verification boundary.

---

## Historical Production Inventory Aggregate

The following aggregate is the **pre-cleanup observation recorded by Inventory 002**. It is retained as historical evidence and must not be interpreted as the current private Household state after the later cleanup.

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

The cleanup completion record documents the later transition from 404 explicit identities / 6 identity-free transactions to 14 explicit identities / 396 identity-free transactions while preserving all 410 transactions. This document intentionally does not invent a newer private-data aggregate beyond that recorded evidence.

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

- Inventory execution does not modify the Journal.
- No private event ID, description, account, amount, or link value is emitted by the supported summary/TSV formats.
- Summary output is aggregate-only.
- TSV output is redacted (no event-id, description, account, amount, plan-id, or txn-id values).
- Unredacted stdout output is not provided (`private-tsv` format removed).

---

## Historical Findings From the Pre-cleanup Observation

These findings describe the pre-cleanup Inventory 002 snapshot above. They are not assertions about the current private Household Journal after the later cleanup.

1. **Zero Removable Legacy 24-Hex Entry IDs**: All 404 durable event IDs in that observation were non-legacy. 401 IDs fell into the textual lexical family; 3 into prefixed-other.
2. **Zero Incoming Reference Dependencies**: No actual layer transactions were targeted by incoming reference metadata in that observation.
3. **Zero Duplicate or Dangling References**: No duplicate identity definitions or dangling references were observed.
4. **12 Functional Link Transactions**: 12 transactions carried functional links (`plan-id`, `txn-id`, `series`, `recur`, `income-budget`) requiring conservative retention (`KEEP_FUNCTIONAL`).
5. **392 Review Unknown Transactions**: 392 transactions had text-shaped event IDs with no incoming references or outgoing functional links and therefore required further evidence before any deletion decision.
6. **All Provenance Was Inferred or Unknown**: No provenance had been verified against actual generator implementation or migration manifests. 7 transactions had inferred provenance (plan completion candidate); 397 had unknown provenance.
