# Issue admission review closeout — 2026-08-11

## Final state

`src/ledger/issue_admission.bqn` was reviewed as a live canonical `issues.tsv` admission owner and completed in PR #668.

- squash-merged main: `fe2108f82e2f188be388a98713e02784633dcf7d`;
- merged-main CI #2709: SUCCESS;
- detailed reasoning: `docs/ISSUE_ADMISSION_REVIEW_OBSERVATION-2026-08-11.md`.

## Retained architecture

```text
supplied Issue lines + one-based source rows
  -> scalar ignored-row mask
  -> aligned source/data coordinates
  -> structural header admission
  -> independent ParseRow cells
  -> source-major row diagnostics
  -> valid Issue cells
  -> whole-source duplicate identity law
  -> fail-closed column publication
```

The review removed file-wide filtering and diagnostic/row accumulation state while retaining genuine row-local sequencing for exact amount parsing, currency policy, precision admission, optional date ordinals, and diagnostic order.

The admitted Issue row remains a useful semantic cell. It is not replaced with a synthetic matrix or generic TSV abstraction merely to reduce local names.

## Protected laws

Focused evidence now protects:

- blank/comment rows at the pure `Admit` boundary;
- original supplied source-row coordinates and durable `issues.tsv:row:N` references;
- source-major row diagnostic order;
- aggregate duplicate identity diagnostics last with `source_row=0`;
- duplicate detection over individually admitted Issue rows only;
- existing exact/date/currency behavior and fail-closed publication.

## BQN lesson

Two shape lessons were especially useful:

1. whole-array evaluation requires total classifiers rather than boolean expressions that merely look guarded;
2. a mask cell must actually be scalar on the axis it selects. Compact membership syntax was rejected when it produced the wrong cell shape; explicit scalar equality made the file axis visible and correct.

## Next cursor

Resume Phase 2 at:

`src/ledger/journal_complete_admission.bqn`
