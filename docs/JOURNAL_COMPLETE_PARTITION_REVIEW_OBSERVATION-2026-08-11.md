# Complete Journal partition review observation — 2026-08-11

## Context

This review follows the source-line relation work merged in PR #670. `journal_complete_admission.bqn` already exposes declarations and Posting-domain discovery as independent source cells. The remaining question is how complete-Journal transaction boundaries, synthetic single-domain partitions, physical provenance remapping, and whole-source identity admission fit together.

## Characterization before production change

A focused law protects the synthetic-to-physical provenance bridge.

For a transaction without a durable event-id, the single-domain partition may place the transaction on a synthetic row internally, but complete-source publication must reconstruct identity from the physical Journal start:

```text
physical transaction line 3
  -> mapped start 3
  -> physical_fallback
  -> source_event_id = stage0-line-3
```

The same law protects Posting source lines and Posting ids after remapping.

A second case protects transaction-major diagnostic behavior across multiple transaction blocks:

- an invalid first transaction emits its local Posting-shape diagnostic;
- later clean transactions are still observed once declaration admission is clean;
- duplicate durable event ids across those later transactions produce the whole-source aggregate diagnostic last at line 0;
- final transaction publication remains fail closed.

CI #2716 was SUCCESS on the characterization-only head.

## Transaction axis

The previous implementation discovered transaction starts and then looped while mutating:

- a per-iteration `end` coordinate;
- the complete-source `transactions` array;
- the complete-source `diagnostics` array.

The retained form makes the partition axis explicit:

```text
starts
ends = next start, with source length as final boundary
  -> ParseTransaction¨ transaction index axis
  -> { diagnostics, optional transaction } cells
  -> transaction-major diagnostic flatten
  -> admitted transaction cells
  -> whole-source durable identity diagnostic
  -> fail-closed publication
```

The declaration/inline-Account diagnostic frontier remains intact: transaction semantic admission is not run when source declarations have already failed.

Once that frontier is clean, every transaction cell is evaluated independently. An earlier transaction-local failure does not suppress later transaction observation, preserving established behavior and allowing the final durable identity relation to see every individually admitted transaction.

## Structural partition construction

`BuildPartition` is a real provenance transformation, not disposable parser plumbing. It builds a temporary single-domain source plus an aligned map back to the complete Journal.

The old implementation mutated both arrays while iterating Account keys. The retained form exposes their aligned construction:

```text
commodity header rows
+ synthetic Account declaration/blank rows
+ original transaction block rows

paired with

domain source line / 0
+ zeroes for synthetic Account rows
+ physical transaction block lines
```

Synthetic Account rows therefore remain deliberately unmapped (`0`), while the domain declaration and original transaction block preserve physical ownership.

## Provenance remapping

`MapTransaction` now derives fallback identity directly from the mapped physical start rather than staging a mutable source-event id.

`MapLine` itself remains guarded local state. A `0` line-map entry means a synthetic row has no physical source owner, and out-of-range/zero diagnostic coordinates must retain their original coordinate. That fallback is semantic provenance behavior rather than incidental mutation.

`MapDiagnostic` and `MapPosting` continue to use the same line-map owner.

## Whole-source durable identity

`CrossTransactionDiagnostics` is reduced to its relation:

```text
durable admitted transactions
  -> durable source-event-id cells
  -> duplicate relation
  -> event_id_duplicate line 0 or empty
```

No separate mutable diagnostic staging remains.

## Deliberate retained state

Not every remaining local guard was removed.

- terminal-LF handling keeps the empty-source safety fixed during the canonical Plan read cutover;
- `DomainSourceLine` explicitly distinguishes exactly-one physical declaration from the fallback coordinate `0`;
- `MapLine` preserves synthetic-row fallback semantics;
- each `ParseTransaction` retains local diagnostic sequencing because domain count, declaration membership, single-domain admission, and provenance mapping are dependent stages inside one transaction cell.

These are bounded semantic guards, not file-wide traversal state.

## Evidence

- CI #2716 SUCCESS: characterization-only fallback/provenance/diagnostic laws;
- CI #2717 SUCCESS: aligned transaction axis, structural partition construction, and aggregate identity publication with full `tools/check.sh` and coverage.

Existing Facts evidence also continues to protect exact physical Transaction and Posting source-line coordinates on the proof Journal.

## Review conclusion

Together with PR #670, the complete Journal owner now reads as:

```text
complete source rows
  -> declaration / Posting-domain relations
  -> transaction boundary axis
  -> independent transaction partition cells
  -> single-domain admission capability
  -> physical provenance remap
  -> complete-source durable identity law
  -> fail-closed complete Journal result
```

The owner remains intentionally responsible for orchestration between complete-source topology and the separate single-domain semantic owner. It does not absorb exact money, Account, or transaction-structure semantics from downstream owners.
