# Complete Journal source relation review observation — 2026-08-11

## Scope

`src/ledger/journal_complete_admission.bqn` is a live complete-source owner for canonical multi-currency Journals. It coordinates source declarations, transaction-domain discovery, single-domain partition admission, physical-source provenance remapping, and whole-source durable identity admission.

This review covers only the completed source-line relations owned by `Declarations` and `PostingDomains`. Synthetic partition construction and transaction admission remain separate review work because their line map carries real provenance meaning.

## Characterization first

A focused law was added before production changed.

It protects declaration diagnostics as source-major with the whole-source duplicate-domain diagnostic last:

```text
commodity_shape_invalid  line 1
commodity_unsupported    line 3
commodity_domain_duplicate line 0
```

It also protects Posting shape diagnostics in source order inside a transaction block and the existing frontier where Posting-shape failure suppresses later domain-count and single-domain semantic admission for that block.

CI #2712 was SUCCESS on the characterization-only head.

## Declarations

The previous implementation scanned all source lines while mutating four file-wide accumulators:

```text
diagnostics
domains
domainLines
accounts
```

The retained shape is now:

```text
trimmed source rows
  -> ParseDeclaration¨ source-row axis
  -> { diagnostics, optional domain, optional account } cells
  -> source-order diagnostic flatten
  -> admitted domain cells + aligned source lines
  -> admitted Account declaration cells
  -> whole-source duplicate-domain diagnostic
```

Only registry-supported, shape-valid Commodity declarations enter the duplicate-domain relation, preserving the previous contract. Account declarations preserve source order and one-based source-line ownership.

## Posting-domain discovery

The previous block scan similarly mutated diagnostics and domain arrays while deciding whether each physical block row was a Posting candidate.

The retained form separates classification from parsing:

```text
block rows
  -> scalar PostingCandidate mask
  -> candidate source offsets
  -> ParsePostingDomain¨ candidate axis
  -> source-order diagnostics
  -> explicit valid domain cells
  -> first-occurrence domain deduplication
```

The candidate predicate remains scalar and total for empty rows through appended fill cells. Metadata and nonindented rows remain outside the Posting candidate axis.

## Deliberate non-change

This slice does not change:

- complete-Journal transaction ordering;
- synthetic partition construction;
- `line_map` provenance semantics;
- physical fallback identity reconstruction;
- single-domain exact amount/balance semantics;
- Account resolution;
- transaction domain count/declaration rules;
- whole-source durable event-id ownership;
- fail-closed publication.

Those later structures are not incidental source scanning. In particular, `BuildPartition` creates a temporary source and an explicit map back to physical Journal lines, so it must be reviewed with provenance laws rather than rewritten merely because it contains append operations.

## Evidence

- CI #2712 SUCCESS: characterization-only source-order/frontier laws;
- CI #2713 SUCCESS: source relation implementation, full `tools/check.sh`, and coverage.

## Review conclusion

The useful change is not “remove loops.” It is:

```text
completed source rows
  -> independent semantic classification cells
```

instead of file-wide append state. The next review of this owner should start at partition construction and transaction-level admission, where source order and provenance are genuine semantics rather than simple line classification.
