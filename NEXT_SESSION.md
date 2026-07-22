# Next session

Status: selected finite canonical TSV-to-native Journal prefix converter
Owner: journal source migration / conversion
Canonical: yes; canonical plan is docs/JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_PLAN.md
Exit: implementation, synthetic validation, private read-only verification, independent review, completion archive, and explicit return to no selected Journal slice
Date: 2026-07-22

## Canonical finite question

> Can the repository define a deterministic one-way converter contract that transforms an immutable legacy `journal.tsv` snapshot into a canonical native Journal historical prefix while preserving accounting movements, established description semantics, legacy physical source identity, distinct business `txn_id` linkage, supported metadata, transaction order, posting order, layer, status, and diagnostics, and can it define a fail-closed reconstruction procedure that combines that verified prefix with an existing byte-preserved Journal-only suffix without modifying production code or private data in this docs-only slice?

## Owner decision and current diagnosis

Native Journal is the owner-selected future durable actual source truth. The current candidate has accounting-equivalent signed movements, posting order, layer/status, transaction grouping, and an established prefix boundary. Description, source identity, distinct business `txn_id`, and supported-metadata semantics are not yet equivalent.

The candidate remains preserved evidence. Its Journal-only suffix must remain byte-for-byte unchanged and must be combined with a verified replacement prefix only through the separately gated reconstruction procedure.

## Selected one-way flow

```text
immutable journal.tsv snapshot
  -> legacy TSV source adapter semantics
  -> canonical Journal transaction renderer
  -> verified native Journal historical prefix
```

A later reconstruction may combine that verified prefix with the exact preserved suffix into a new candidate. It must not modify the current candidate in place.

## Scope and routing boundaries

- This selection is docs-only. It performs no conversion, reconstruction, private-data change, production route change, or writer change.
- Production source truth and reports remain on the TSV route.
- Production cutover remains blocked until every converter, identity, metadata, reconstruction, and suffix-preservation gate passes.
- Dual writes, reverse synchronization, and automatic conflict resolution remain prohibited.
- Completion must explicitly return routing to no selected Journal slice.
- Converter completion must not select cutover or any later Journal slice automatically.
