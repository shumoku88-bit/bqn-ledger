# Single-domain Journal structural evidence review observation — 2026-08-12

## Scope

This is the final local review of `src/ledger/journal_single_domain_admission.bqn` after:

- PR #674 exposed the physical source / Posting relation and narrowed publication to final Transactions;
- PR #675 exposed exact completion, normalization, and balance as transaction-local cells.

This review covers:

- `BuildStructuralRaw`;
- the final structural/semantic Posting join;
- structural Transaction identity/metadata evidence;
- transaction currency metadata reconciliation;
- structural trace guards.

## Characterization

The focused structural-evidence law protects the final result rather than the temporary JPY adapter.

For a durable transaction it verifies:

- `source_event_id`;
- `identity_kind`;
- `txn_id`;
- date and description;
- physical transaction start/end lines;
- semantic domain and calculation scale;
- structural metadata retention;
- Posting ids and Posting indices;
- structural side;
- physical Posting source lines;
- original source amount text;
- original exact source coefficient and canonical source scale;
- normalized coefficient.

A second case protects physical fallback identity:

```text
no durable event-id
-> source_event_id = stage0-line-<physical transaction start>
-> identity_kind = physical_fallback
-> Posting ids derive from that source identity
```

A third case protects currency metadata reconciliation:

```text
semantic domain JPY
+ transaction metadata currency ILS
-> transaction_currency_mismatch at transaction start
-> no partial Transaction publication
```

Characterization-only CI #2739 was SUCCESS.

## Structural source projection

The temporary JPY source exists only to reuse `journal_transaction_structure` for grammar, metadata, identity, side, and source-shape admission. It is not monetary evidence returned to callers.

The previous implementation scanned every semantic Posting for every physical line:

```text
for physical line:
  compare line number with every Posting source_line
  select matches
```

The reviewed form classifies the relation once:

```text
semantic Posting source_line axis
  -> Index Of physical line axis
  -> one Posting coordinate or absent bound per physical line
  -> structural source transformation
```

In BQN:

```bqn
postingLines ← {𝕩.source_line}¨postings
postingCoordinates ← postingLines ⊐ 1 + ↕≠lines
postingBound ← ≠postings
```

Each source line then reads its already-classified Posting coordinate. This removes repeated whole-Posting scans while preserving physical source order and first-match behavior.

## One-partition contract

The production caller, `journal_complete_admission`, constructs one transaction partition before invoking the single-domain owner. The downstream `journal_transaction_structure` owner also admits exactly one transaction on success.

The previous `BuildTransactions` nevertheless looped an arbitrary parsed Transaction axis and repeatedly selected semantic Postings by `transaction_index`.

The reviewed owner now reflects the actual successful contract:

```text
one parsed structural Transaction
+ one aligned semantic Posting axis
-> one final Transaction
```

`BuildTransaction` therefore zips structural and semantic Postings by their shared Posting coordinate and constructs exactly one Transaction.

## Trace diagnostics

### `transaction_trace_count_mismatch` removed

This diagnostic is not independently reachable on the path where it was evaluated.

Control flow proves:

- zero semantic transaction starts produces `transaction_missing` before structural admission;
- multiple dated transaction headers make the structural one-partition owner fail with `transaction_count_invalid`;
- the trace block was entered only when `structural.state = "ok"`;
- structural success already guarantees exactly one parsed Transaction.

Therefore re-comparing structural Transaction count with semantic transaction starts after structural success duplicated the one-partition admission boundary.

### `posting_trace_count_mismatch` retained

Posting count remains an adapter consistency law.

The temporary structural source is synthesized from semantic exact Posting evidence and then independently parsed by the structural grammar owner. Before zipping the two Posting axes, equal cardinality remains a useful fail-closed assertion against adapter drift.

The guard is now expressed directly against the one parsed structural Transaction:

```bqn
postingCountOk ← (≠parsed.postings) = ≠normalizedPostings
```

## Currency metadata reconciliation

The previous code mapped currency reconciliation across `structural.transactions`. With the successful one-partition contract explicit, the owner now checks the one parsed Transaction directly.

This does not move currency authority into the structural parser. The semantic transaction domain remains authoritative; structural metadata is checked against it before final publication.

## Evidence

- CI #2739 SUCCESS: characterization-only durable/fallback identity, Posting provenance, side, and currency-mismatch laws;
- CI #2740 SUCCESS: structural source relation + one-Transaction join with full `tools/check.sh` and coverage.

## Review conclusion

The final retained path is:

```text
physical source
  -> semantic Posting relation
  -> exact completion and normalization
  -> temporary structural-JPY projection
  -> structural grammar / identity evidence
  -> one aligned structural + semantic Posting axis
  -> final Transaction
```

The structural JPY adapter remains intentionally transient. It does not replace original amount text, source coefficient/scale, semantic domain, or physical provenance.

No exact arithmetic, registry policy, Account proof, durable identity meaning, Posting identity meaning, diagnostic line ownership, complete-Journal partitioning, or writer/source authority changed.
