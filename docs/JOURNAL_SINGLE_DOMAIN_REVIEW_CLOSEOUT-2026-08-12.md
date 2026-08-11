# Single-domain Journal admission review closeout — 2026-08-12

## Final state

`src/ledger/journal_single_domain_admission.bqn` is the retained semantic admission owner for one supported-currency transaction partition.

Production reaches it through `journal_complete_admission`, which already partitions the complete Journal by transaction. Its successful contract is therefore:

```text
one complete-Journal transaction partition
  -> one supported semantic currency domain
  -> one final admitted Transaction
```

The owner was reviewed in three coherent changes:

- PR #674 exposed the physical source / Posting relation and narrowed publication to durable final semantic results;
- PR #675 exposed exact completion, normalization, and balance as transaction-local cells;
- PR #676 aligned the transient structural-JPY projection with physical Posting coordinates and the actual one-Transaction successful contract.

Final runtime main: `3f7131cf0649d0e2f492356f35e2632a87b2a957`.
Merged-main CI #2742: SUCCESS.

Detailed observations:

- `docs/JOURNAL_SINGLE_DOMAIN_POSTING_RELATION_REVIEW_OBSERVATION-2026-08-12.md`;
- `docs/JOURNAL_SINGLE_DOMAIN_EXACT_COMPLETION_REVIEW_OBSERVATION-2026-08-12.md`;
- `docs/JOURNAL_SINGLE_DOMAIN_STRUCTURAL_EVIDENCE_REVIEW_OBSERVATION-2026-08-12.md`.

## Final transformation

```text
physical partition source
  -> date-header / Posting-candidate source relations
  -> row-local Posting semantic admission
  -> transaction-local elided completion
  -> exact calculation-scale normalization
  -> transaction-local exact balance
  -> transient structural-JPY grammar projection
  -> structural grammar / metadata / identity / side evidence
  -> aligned structural + semantic Posting join
  -> one final Transaction
```

The temporary JPY source is an internal grammar adapter only. It never replaces original amount text, source coefficient/scale, semantic currency domain, or physical provenance.

## Subtracted machinery

The completed review removed or narrowed several forms of incidental machinery:

- file-wide mutable `transactionIndex` / `postingIndex` traversal in `Collect`;
- shared file-wide Posting/diagnostic accumulation during source admission;
- public intermediate `normalized_postings` and `transaction_starts` result fields with no production consumer;
- guarded mutation for empty-safe normalization scale selection;
- shared transaction-axis accumulation in elided completion and balance diagnostics;
- repeated whole-Posting rescans for every physical line in the structural source adapter;
- generic multi-Transaction final joining inside an owner whose successful contract is one partition / one Transaction;
- unreachable `transaction_trace_count_mismatch` revalidation after the structural one-Transaction boundary had already succeeded.

## Retained complexity

Not all conditionals or local state were removed.

The following remain because they carry semantic dependency or safety meaning:

- exact decimal parsing before coefficient/scale evidence exists;
- registry precision checks after exact source scale is known;
- Account resolution before Account-currency/domain reconciliation;
- exactly-one-elision -> explicit evidence -> exact normalization -> nonzero inferred coefficient dependency;
- structural parser diagnostics and metadata laws;
- `posting_trace_count_mismatch` as a fail-closed assertion before independently parsed structural Postings are zipped with semantic Posting evidence;
- final publication only when all admission and reconciliation diagnostics are empty.

This is the intended distinction between traversal state and domain state.

## Identity and provenance

The final owner continues to preserve:

- durable `event-id` identity when present;
- physical fallback `stage0-line-<transaction-start>` identity when durable identity is absent;
- Posting ids derived from structural event identity and Posting coordinate;
- physical Transaction and Posting source lines;
- original source amount text;
- canonical exact source coefficient and scale;
- normalized exact coefficient;
- structural side and metadata evidence.

The complete-Journal owner remains responsible for mapping synthetic partition coordinates back to the original complete source and for cross-transaction durable identity uniqueness.

## Characterization lessons

Several failed characterization runs were useful because they corrected the review model before production was changed:

- #2726 exposed a test identifier-role mistake;
- #2727 showed that direct multi-Transaction success was not part of the single-partition contract;
- #2733 exposed another BQN binding-role mistake in test code;
- #2734 corrected the assumption that textual trailing decimal zeros survive in the canonical exact coefficient/scale carrier.

They are evidence about the review process, not production regressions.

## Final BQN shape

The strongest array-language result is not code compression. It is that the owner now exposes the meaningful axes separately:

```text
physical source-row axis
Posting-candidate axis
transaction-local Posting cell
exact scale relation
structural source-row -> Posting coordinate relation
aligned structural / semantic Posting axis
```

Local dependent admission remains local; whole-source traversal machinery became masks, coordinates, Group/Scan relations, reductions, and result cells.

## Next cursor

Resume Phase 2 at:

`src/ledger/journal_transaction_structure.bqn`
