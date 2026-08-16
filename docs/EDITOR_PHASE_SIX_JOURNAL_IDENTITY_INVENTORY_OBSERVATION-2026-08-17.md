# Editor Phase 6 Journal Identity Inventory observation — 2026-08-17

## Status

The Journal Identity Inventory pair has been reviewed under the BQN-native re-baseline:

- `src_edit/journal_identity_inventory.bqn`
- `src_edit/journal_identity_inventory_cmd.bqn`

The review keeps the established identity vocabulary, privacy boundary, output protocol, and conservative deletion semantics. It changes only places where regular relations or precedence laws were obscured by mutation or nested control flow.

## Identity inventory is observation, not authority to delete

The inventory remains a read-only observer over an admitted historical Journal profile.

Its axes remain distinct:

```text
presence
lexical family
incoming references
outgoing functional links
provenance + confidence
reconstructibility
deletion disposition
```

No axis is promoted into canonical transaction identity meaning by this review. Lexical shape does not prove provenance. Reconstructibility does not authorize deletion. Disposition still has no `DELETE` value.

The later `journal_reconstructible_identity_cleanup` owner remains a separate transformation with its own selection and parity laws.

## Incoming reference relation

`BuildReferenceIndex` previously accumulated reference records by mutating an initially empty `refs` list while traversing every transaction and metadata item.

The reviewed implementation exposes the existing shape directly:

```text
transactions
  -> metadata rows per transaction
  -> recognized non-empty reference mask
  -> reference records
  -> Join
```

Each record retains the same coordinates:

```text
target_id
ref_key
source_ordinal
source_layer
```

The recognized key vocabulary is unchanged:

```text
actual-event-id
source-event-id
original-event-id
reversal-of
parent-event-id
related-event-id
```

This is a regular relation. No history-dependent accumulator is required to express it.

## Durable identity projection and duplicate law

Durable identities are now projected directly from the transaction relation with a durable mask.

The inventory's `duplicate_identity_definitions` value means the number of **distinct identity values with at least two definitions**, not the number of duplicate rows beyond the first.

BQN Occurrence Count exposes that law directly:

```text
+´ 0 ∾ 1 = ⊒ durableIds
```

For one identity appearing three times, Occurrence Count is `0 1 2`; only the second occurrence contributes to the count, so that identity contributes exactly one duplicate definition.

A regression fixture now fixes this meaning with three occurrences of the same identity.

## Ordered classification axes

Four classifiers previously expressed precedence through deeply nested `◶` trees:

- lexical family;
- provenance;
- reconstructibility;
- deletion disposition.

These are not unordered sets. Their first matching case is the domain law.

The reviewed form publishes each precedence as an aligned boolean case vector with a final true fallback, then selects the first satisfied coordinate.

### Lexical family precedence

```text
NONE
LEGACY_ENTRY_24HEX
PREFIXED_HEX
PREFIXED_OTHER
OPAQUE_HEX
TEXTUAL_OTHER
OTHER
```

### Provenance precedence

```text
IDENTITY_FREE
TSV_MIGRATION_CANDIDATE
NATIVE_EDITOR_CANDIDATE
TRAVEL_EDITOR_CANDIDATE
REVERSE_COMMAND_CANDIDATE
PLAN_COMPLETION_CANDIDATE
UNKNOWN
```

The established ordering matters. For example, a durable `tx-...` identity that also carries a `plan_id` remains `NATIVE_EDITOR_CANDIDATE`; the Plan link does not override the earlier native-editor witness. A regression now records that precedence explicitly.

### Reconstructibility precedence

```text
IDENTITY_FREE
REVERSE_COMMAND_CANDIDATE -> NOT_RECONSTRUCTIBLE
LEGACY_ENTRY_24HEX -> NOT_RECONSTRUCTIBLE
PLAN/NATIVE/TRAVEL candidate -> LIKELY_RECONSTRUCTIBLE
otherwise -> UNKNOWN
```

`PROVEN_RECONSTRUCTIBLE` remains part of the public vocabulary but this classifier still does not manufacture proof. No new proof source is introduced.

### Disposition precedence

```text
IDENTITY_FREE
KEEP_REFERENCED
KEEP_FUNCTIONAL
KEEP_NONRECONSTRUCTIBLE
REVIEW_RECONSTRUCTIBLE
REVIEW_UNKNOWN
```

Incoming reference protection therefore still outranks functional-link and reconstructibility considerations.

## Empty relation behavior

The mapped reference relation and durable identity projection are valid for an empty transaction relation.

A regression now requires an empty inventory to produce:

```text
rows = empty
duplicate_identity_definitions = 0
dangling_references = 0
self_references = 0
```

This makes empty input a property of the relation itself rather than a caller-side special case.

## Privacy and presentation

The supported output contracts remain unchanged:

- aggregate summary;
- redacted TSV row inventory.

They still omit event-id values, descriptions, account names, amounts, Plan IDs, Txn IDs, and other private link values.

The existing privacy canaries remain in the test portfolio. The command still rejects unsupported unredacted formats.

`FormatSummary` and `FormatTsv` already map from the inventory relation and require no structural rewrite in this pass.

## Command adapter

`src_edit/journal_identity_inventory_cmd.bqn` is deliberately production-unchanged.

Its effect boundary is already narrow:

```text
base directory + format
  -> canonical Actual source path
  -> raw read
  -> historical_external_plan admission
  -> BuildInventory
  -> privacy-safe rendering
```

It performs no Journal write, candidate publication, backup, or cleanup action. Existing checks verify source SHA stability and absence of backup/candidate artifacts.

## Removed residue

The inventory module no longer imports `src/text/parse.bqn`, which it did not use, and removes the unused `GetMetaVal` helper.

No new generic classification framework is introduced. The small local first-true coordinate helper exists only to make this owner's ordered axes visible.

## Stale production aggregate

`docs/JOURNAL_EVENT_IDENTITY_INVENTORY_002.md` still described its original production aggregate as current even though the later completed cleanup removed 390 approved migration-derived event-id metadata lines.

The old aggregate remains useful evidence, so it is not deleted. The document now labels it explicitly as the historical pre-cleanup Inventory 002 snapshot and points to `JOURNAL_RECONSTRUCTIBLE_IDENTITY_CLEANUP_001.md` for the later recorded transition.

The review does not infer a new private Household aggregate from public source or current configuration.

## Decision

The Journal Identity Inventory now exposes the intended BQN shape more directly:

```text
admitted transactions
  -> reference relation + durable identity projection
  -> ordered classification axes
  -> privacy-safe row inventory
  -> aggregate / redacted presentation
```

The command boundary is already appropriate and remains unchanged.

The next normal Phase 6 cursor is:

```text
src_edit/journal_list_cmd.bqn
```
