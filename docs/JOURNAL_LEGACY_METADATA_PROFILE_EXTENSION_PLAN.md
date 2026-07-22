# Journal Legacy Metadata and Business-Link Profile Extension Plan

Status: active plan
Owner: journal source migration / profile and test-only IR
Canonical: yes; canonical path: docs/JOURNAL_LEGACY_METADATA_PROFILE_EXTENSION_PLAN.md
Exit: archive under `docs/archive/completed-plans/` after the public synthetic profile, Stage 2A, and Stage 2B evidence is complete; return Journal routing to the still-blocked converter with no production cutover selected
Date: 2026-07-22

## Finite prerequisite question

> Can the test-only Minimal BQN Journal profile, Transaction IR, and Stage 2A adapter retain canonical source event identity separately from optional business `txn_id` linkage, while representing the supported legacy `journal.tsv` metadata vocabulary explicitly and fail-closed, without changing the current 16-field Posting IR schema, production routing, source truth, writers, private files, or converter output?

## Selection and boundary

The selected parent remains the **Canonical TSV-to-native Journal prefix converter**, whose canonical plan is `docs/JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_PLAN.md`. That parent is selected but blocked: its canonical prefix cannot be implemented until the profile can retain distinct source identity, business linkage, and the supported legacy metadata vocabulary.

This document selects only that finite prerequisite. It is not converter implementation, conversion, reconstruction, suffix replacement, production routing, writer work, cutover, dual writes, reverse synchronization, or conflict resolution. Completion of this prerequisite does not perform conversion or reconstruction and does not select the later converter or production cutover automatically.

The first PR is docs-only on `docs/journal-legacy-metadata-profile-extension`. Implementation must be a separate Draft PR on `feat/journal-legacy-metadata-profile-extension` after the docs-only selection is reviewed and merged.

## Identity contract

The admitted Transaction IR retains these concepts independently and in this order of responsibility:

```text
source_event_id
identity_kind
source_start_line
source_end_line
txn_id
metadata
ordered postings
```

- `source_event_id` is nonempty canonical source identity. It remains durable or an explicitly labelled physical fallback.
- `txn_id` is optional business linkage. Absence remains absence; it never replaces or generates `source_event_id`.
- Two physical transactions may share one `txn_id` and remain two transaction blocks and two distinct source identities.
- Posting IDs remain `source_event_id + posting_index`.
- Metadata order is presentation evidence only and must not affect semantic comparison.
- Duplicate metadata keys, unknown metadata keys, unsupported values, and ambiguous mappings fail closed.

## Public legacy metadata mapping table

The table is the public spelling contract for this prerequisite. The TSV key and Journal key are not treated as equivalent merely because they look similar. `txn_id` is not `event-id`; `receipt` is not `receipt-id`; and `plan_id` is mapped to the already-established `plan-id` semantic field because the repository documents plan completion by `plan_id=` and the profile already admits `plan-id`.

| TSV spelling | Classification | Canonical Journal spelling | Transaction IR field or metadata representation | Absence vs empty | Duplicate-key behavior | Stage 2A projection |
|---|---|---|---|---|---|---|
| `tax` | direct Journal metadata mapping | `tax` | `metadata` item `{key: "tax", value}` | absent = no item; empty = reject | reject duplicate `tax` | no Posting IR field; retained in transaction metadata |
| `biz` | direct Journal metadata mapping | `biz` | `metadata` item `{key: "biz", value}` | absent = no item; empty/malformed = reject | reject duplicate `biz` | no Posting IR field; retained in transaction metadata |
| `invoice` | direct Journal metadata mapping | `invoice` | `metadata` item `{key: "invoice", value}` | absent = no item; empty = reject | reject duplicate `invoice` | no Posting IR field; retained in transaction metadata |
| `note` | direct Journal metadata mapping | `note` | `metadata` item `{key: "note", value}` | absent = no item; empty = reject under Journal metadata shape | reject duplicate `note` | no Posting IR field; retained in transaction metadata |
| `due_on` | direct Journal metadata mapping | `due-on` | `metadata` item `{key: "due-on", value}` | absent = no item; empty/invalid date = reject | reject duplicate `due-on` | no Posting IR field; retained in transaction metadata |
| `receipt` | direct Journal metadata mapping | `receipt` | `metadata` item `{key: "receipt", value}` | absent = no item; empty = reject | reject duplicate `receipt` | no Posting IR field; retained in transaction metadata |
| `txn_id` | direct Journal metadata mapping | `txn-id` | transaction `txn_id`, plus the ordered metadata item `{key: "txn-id", value}` | absent = `txn_id` absent; empty = reject | reject duplicate `txn-id` | `tx_id = txn_id` when present; `source_id = source_event_id`; never merged |
| `party` | direct Journal metadata mapping | `party` | `metadata` item `{key: "party", value}` | absent = no item; empty = reject | reject duplicate `party` | no Posting IR field; retained in transaction metadata |
| `plan_id` | existing Journal-profile semantic field | `plan-id` | transaction `plan_id`, plus the ordered metadata item `{key: "plan-id", value}` | absent = empty/absent semantic field; empty = reject | reject duplicate `plan-id` | no Posting IR field; existing plan semantics remain unchanged |
| `cashflow` | direct Journal metadata mapping | `cashflow` | `metadata` item `{key: "cashflow", value}` | absent = no item; empty/unknown value = reject | reject duplicate `cashflow` | no Posting IR field; retained in transaction metadata |
| `currency` | rendered accounting field | `currency` source metadata is admitted only when its value is valid; the posting commodity is rendered and parsed as the accounting representation | transaction metadata retains the explicit source marker when present; every posting retains its commodity | absent remains absent source metadata and follows the established default only where the profile proves it; empty/unsupported = reject | reject duplicate `currency` | unchanged 16 fields; commodity is not added to Posting IR and no currency meaning is inferred into a new field |
| `income_budget` | direct Journal metadata mapping | `income-budget` | `metadata` item `{key: "income-budget", value}` | absent = no item; empty/unknown value = reject | reject duplicate `income-budget` | no Posting IR field; retained in transaction metadata |

The admitted value vocabulary is derived from `config/meta_schema.tsv`, `docs/JOURNAL_META.md`, and `docs/CONVENTIONS.md`, not from name similarity. The implementation must publish focused tests for every admitted mapping, explicit absence, malformed/empty mapped values, duplicate keys, and unknown keys. If a value cannot be represented without changing commodity, account, layer, status, amount, or parser grammar semantics, it is unsupported and must fail closed rather than be silently dropped.

## Stage 2A contract

The current 16-field Posting IR row shape remains unchanged in field count and order. For each Journal transaction:

```text
source_id = transaction.source_event_id

tx_id = transaction.txn_id, when present
       = transaction.source_event_id, when txn_id is absent
```

All postings from one transaction must retain the same `source_id` and resulting `tx_id`, deterministic posting IDs, transaction order, and posting order. Shared `txn_id` values do not merge transactions. Stage 2B must verify identity/provenance alignment after this projection without adding fields to Posting IR.

## Required public synthetic evidence

Use only invented accounts, dates, descriptions, amounts, IDs, Unicode values, and metadata. The implementation evidence must include:

1. two separate actual transactions with distinct source event IDs and the same `txn_id`;
2. two transaction blocks, four ordered Posting IR rows, shared business `tx_id`, and distinct source IDs;
3. a transaction without `txn_id`, proving source-ID fallback;
4. Unicode description and metadata values;
5. every admitted legacy metadata mapping;
6. presence versus absence;
7. duplicate metadata rejection;
8. unknown metadata rejection;
9. empty or malformed mapped-value rejection;
10. Stage 2B posting identity and provenance alignment;
11. no private values in fixtures, diagnostics, or committed documentation.

## Description boundary and explicit converter gate

This prerequisite records but does not implement the complete converter description transformation:

- `journal.tsv` column 2 is the source memo/description;
- the TSV editor preserves validated input text;
- compatibility `tools/to-hledger` strips surrounding whitespace;
- the native Journal writer requires a trimmed description;
- the Journal parser admits the transaction-header description.

No lossy converter normalization is selected here. If exact established semantics remain ambiguous, the converter remains an explicit implementation gate and this prerequisite stops without choosing a normalization.

## Explicit stop conditions

Stop and report rather than simplify if implementation would require changing Posting IR field count/order; collapsing `txn_id` into `source_event_id`; treating physical line numbers as durable identity; dropping supported metadata; accepting arbitrary unknown metadata; changing parser grammar beyond metadata support; changing account, commodity, layer, status, or amount semantics; changing production routing or writers; implementing conversion/reconstruction; accessing private data; or performing cutover, dual writes, reverse synchronization, or conflict resolution.

## Validation and completion routing

The implementation Draft PR must run focused parser, Stage 2A, Stage 2B, and metadata tests, `git diff --check`, `checks/check-docs-lifecycle.sh`, `checks/check-absolute-links.sh`, `checks/check-repo-index.sh`, and `rtk bash ./tools/check.sh`. It must verify public-only synthetic changes, privacy-safe paths, selected-surface filenames, and a clean worktree.

On successful implementation, archive this plan under `docs/archive/completed-plans/` and route the repository to:

```text
legacy metadata/profile prerequisite: complete
canonical TSV-to-native Journal prefix converter: still selected, implementation not yet started
production cutover: blocked
```

Explicit owner review is required before a converter implementation branch begins.
