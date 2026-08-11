# Complete Journal admission review closeout — 2026-08-11

## Final state

`src/ledger/journal_complete_admission.bqn` was reviewed as the live complete-source orchestration owner for canonical multi-currency Journals.

The review completed in two coherent changes:

- PR #670 exposed Declaration and Posting-domain source relations;
- PR #671 exposed the transaction partition axis, structural synthetic partition construction, physical provenance remapping, and whole-source durable identity relation.

Final merged main: `19fc9e017f167635b47c938542457f739b8573bc`.
Merged-main CI #2719: SUCCESS.

Detailed observations:

- `docs/JOURNAL_COMPLETE_SOURCE_RELATION_REVIEW_OBSERVATION-2026-08-11.md`;
- `docs/JOURNAL_COMPLETE_PARTITION_REVIEW_OBSERVATION-2026-08-11.md`.

## Retained architecture

```text
complete Journal source
  -> Declaration cells
  -> Posting-domain source relations
  -> transaction start/end axis
  -> independent transaction partition cells
  -> single-domain semantic admission
  -> synthetic-to-physical provenance remap
  -> complete-source durable identity law
  -> fail-closed complete Journal result
```

The owner no longer uses file-wide mutable append state for Declaration classification, Posting-domain discovery, synthetic Account partition construction, or complete-source transaction accumulation.

## Protected ownership

The review deliberately keeps this owner as orchestration rather than collapsing neighboring responsibilities into it.

- exact amount and balance semantics remain in single-domain Journal admission;
- Account identity/currency admission remains in the Account owner;
- transaction structure semantics remain downstream;
- synthetic source rows remain explicitly mapped to physical Journal coordinates;
- fallback event identity is reconstructed from the mapped physical transaction start;
- declaration errors remain a frontier before transaction semantic admission;
- transaction-local failures do not suppress later transaction observation once declarations are clean;
- whole-source durable event-id uniqueness remains aggregate-last;
- final transaction publication remains fail closed.

## Retained local guards

Some local guarded state remains intentionally:

- terminal-LF handling protects the empty-source boundary;
- `DomainSourceLine` distinguishes exactly-one physical declaration from a fallback coordinate;
- `MapLine` distinguishes physical from synthetic/unmapped coordinates;
- transaction-local staging preserves dependent domain/declaration/single-domain admission order.

These guards encode bounded semantic fallback behavior, not traversal machinery.

## BQN lesson

The completed owner distinguishes three kinds of axes explicitly:

```text
source row axis
transaction partition axis
synthetic source ↔ physical provenance map
```

Array-native structure does not require removing every local conditional. The useful subtraction was to replace repeated file-wide discovery and append state with stable coordinates and local result cells while leaving genuine admission frontiers visible.

## Next cursor

Resume Phase 2 at:

`src/ledger/journal_posting_text.bqn`
