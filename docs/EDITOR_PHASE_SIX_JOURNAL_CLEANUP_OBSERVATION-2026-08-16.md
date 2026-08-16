# Editor Phase 6 Journal Cleanup observation — 2026-08-16

## Status

The conservative legacy Journal event-id Cleanup family has been reviewed as one Phase 6 unit under the 2026-08-16 BQN-native re-baseline:

- `src_edit/journal_cleanup_apply_cmd.bqn`
- `src_edit/journal_cleanup_plan.bqn`
- `src_edit/journal_cleanup_plan_cmd.bqn`
- `src_edit/journal_cleanup_rewrite.bqn`
- `src_edit/journal_cleanup_verify_cmd.bqn`

The review preserves the existing Cleanup eligibility law and writer protocol. It changes only places where procedural staging obscured a regular classification or source-ordered collection.

## Classification law

Cleanup classification has an intentional priority:

```text
IDENTITY_FREE
NOT_LEGACY
REFERENCED
PLAN_LINKED
OTHER_LINKED
REMOVABLE
```

`OTHER_LINKED` has its own reason priority:

```text
non-actual-layer
non-durable-identity
txn-id
allocation-id
actual-event-id
execution-envelope
```

The previous implementation encoded both priorities by mutating empty string sentinels through guarded `Set` functions. The reviewed implementation publishes each priority as an aligned predicate vector with a trailing true case, then selects the first satisfied coordinate.

This does not flatten priority into an unordered set. The vector order is the domain law. It makes precedence visible as data rather than as mutation history.

## Removal line relation

`journal_cleanup_rewrite.bqn` previously grew `removeLines` as each REMOVABLE plan row passed validation.

The plan relation already owns one `event_id_line` coordinate per removal. The rewrite now derives the complete ordered `removalLines` relation directly from those rows.

Per-row safety validation remains explicit and ordered:

1. event-id source line is in raw Journal range;
2. transaction ordinal is valid;
3. exactly one matching event-id metadata record exists on the intended transaction and owns that line;
4. the raw physical line is exactly the expected `; event-id: ...` metadata after indentation normalization;
5. the same raw line was not selected by an earlier cleanup row;
6. the event-id has the exact legacy `entry-` + 24 lowercase hex shape.

Duplicate detection now asks whether the current line coordinate occurs in the earlier prefix of the already-observed line vector. It preserves the old first-duplicate diagnostic order without using a mutable accumulator.

Only after all diagnostics are empty does the keep mask filter the source line relation.

## Whole-source Join

The final source text is a pure source-ordered Join of the retained boxed lines. Cleanup removes complete metadata lines and does not synthesize new line content, so unlike Canonical Surface there is no separate Posting reconstruction axis.

The candidate is still reparsed after construction. Array-based construction is not treated as proof of a valid Journal.

## Presentation

`journal_cleanup_plan_cmd.bqn` keeps the exact ten-field TSV contract and exact text summary while building rows/summary from field vectors rather than mutable strings.

The existing portfolio protects:

- transaction order;
- classification and reason;
- exact event-id/source-start line coordinates;
- incoming reference count;
- Plan linkage;
- no fallback/internal identity leakage;
- exact text summary;
- read-only behavior.

## Complexity deliberately retained

### Optional event-id source line

`Build` still conditionally assigns `eventIdLine` from admitted metadata. This is a partial physical-source coordinate, not a regular collection. Keeping the guarded assignment makes the absence/default `0` case explicit.

### Ordered diagnostics

Rewrite diagnostics remain an ordered fail-closed sequence. Invalid raw coordinates, metadata/source mismatch, exact physical-line mismatch, duplicate selection, legacy identity mismatch, candidate parse failure, classification transition failure, and semantic equivalence failure must not be collapsed into an opaque boolean.

### Candidate re-admission and classification transition

After line removal, Cleanup reparses the entire candidate Journal, rebuilds its Cleanup plan, and proves the classification transition:

```text
before REMOVABLE -> after IDENTITY_FREE
before REFERENCED / PLAN_LINKED / OTHER_LINKED / NOT_LEGACY -> unchanged counts
candidate REMOVABLE -> 0
transaction count -> unchanged
```

This remains separate from semantic equivalence because both are useful laws: one protects the cleanup classification effect, the other protects transaction/accounting meaning.

### Semantic equivalence

`VerifyEquivalent` remains production-unchanged. It compares every transaction in order and allows only the exact intended transition for a REMOVABLE row:

```text
durable identity + one exact event-id metadata
  -> physical fallback identity + no event-id metadata
```

All accounting-bearing transaction fields, Posting order/semantics, and non-target identity/metadata remain exact.

### Apply artifact and Verify leaves

`journal_cleanup_apply_cmd.bqn` and `journal_cleanup_verify_cmd.bqn` require no production change.

Apply already has the right narrow effect boundary:

```text
admitted source
  -> plan
  -> verified candidate
  -> caller-owned candidate artifact
  -> read-back byte equality
  -> machine protocol
```

It does not own final canonical source publication.

Verify is already a small read-only leaf:

```text
before raw + canonical after raw
  -> same historical parser
  -> before Cleanup plan
  -> VerifyEquivalent
```

Rewriting either merely to remove all effects or reduce lines would make the ownership boundary less clear.

## No generic rewrite framework

Canonical Surface and Cleanup share architectural laws: whole-source candidate construction, semantic verification, caller-owned candidate artifacts, and shell safe publication. This review does not merge them into a generic rewrite framework.

Their transformation semantics are different enough that shared abstraction would currently replace domain vocabulary with machinery rather than remove accidental complexity.

## Decision

The Cleanup family now exposes the intended shape:

```text
admitted transaction relation
  -> ordered Cleanup classification axis
  -> removal coordinate relation
  -> validated source-line filter
  -> candidate re-admission
  -> classification transition law
  -> semantic equivalence
  -> caller-owned candidate artifact
```

No further Cleanup rewrite is justified in this pass.

The next normal Phase 6 cursor is:

```text
src_edit/journal_identity_inventory.bqn
```

## Qualification

PR #787 code head `c90d4f4f49ebfc89613d93b9c5b282e258766b64` passed GitHub Actions #3382 through full `tools/check.sh` and coverage before this closeout note was added. Final PR qualification must remain green after documentation/TODO updates.
