# Single-domain Journal Posting relation review observation — 2026-08-12

## Owner and production reachability

`src/ledger/journal_single_domain_admission.bqn` is the semantic owner for one supported-currency transaction partition.

Production reaches it through `journal_complete_admission`, which has already partitioned the complete Journal into individual transactions. The downstream `journal_transaction_structure` owner likewise admits exactly one transaction in a normalized partition.

This matters because the helper's mutable transaction counters initially looked like a general multi-transaction traversal problem. They are not evidence that this owner should become a second complete-Journal container.

## Characterization correction

The first characterization attempt incorrectly expected direct multi-transaction input to succeed.

Evidence sequence:

- CI #2726 failed before execution because the test defined `Raw` and `raw`, a BQN identifier redefinition. This provided no production evidence.
- CI #2727 reached the production owner and showed that direct multi-transaction input is rejected by structural admission.
- the contract was reread from the current production consumer and structure owner rather than weakening production to fit the test;
- CI #2728 succeeded with the corrected single-partition characterization;
- the test was then narrowed again to final semantic publication rather than intermediate helper tables;
- CI #2729 succeeded before production changed.

The retained laws are now:

- one successful partition publishes one final Transaction;
- metadata and blank rows do not consume final Posting coordinates;
- final Posting source lines remain physical source coordinates;
- direct multi-transaction use remains rejected with no partial Transaction publication;
- a Posting before the first dated transaction owns `posting_outside_transaction` at its physical source row.

## Source and Posting relations

The previous `Collect` maintained file-wide mutable state:

```text
transactionIndex
postingIndex
transactionStarts
postings
diagnostics
```

while walking physical source lines.

The reviewed form exposes the axes first:

```text
physical source rows
  -> date-header mask
  -> prefix transaction coordinates

physical source rows
  -> Posting-candidate mask
  -> candidate source coordinates
  -> parsed Posting cells
  -> shape-valid mask

candidate transaction coordinates
  -> Group candidate positions by transaction
  -> shape-valid prefix count inside each Group
  -> Posting coordinates

candidate cells
  -> row-local {diagnostics,item}
  -> source-order diagnostic flatten
  -> admitted Posting items
```

Transaction coordinates are nondecreasing in physical source order. Therefore the Group cells occur in the same transaction order as the source, and joining their local prefix-rank cells preserves candidate source order.

The local Posting rank is expressed as:

```bqn
valid ← group ⊏ shapeValid
(+`valid) - valid
```

The inclusive prefix count minus the current shape-valid bit is exactly the count of earlier shape-valid Posting candidates in that transaction.

## Local state retained

Exact amount parsing and semantic validation remain row-local inside `AdmitCandidate`.

This local staging is meaningful:

- explicit versus elided Posting text changes which amount evidence exists;
- exact decimal parsing must succeed before coefficient and source scale exist;
- registry precision policy depends on the parsed scale;
- Account resolution supplies the Account currency evidence used by the domain check;
- diagnostics remain ordered within one physical Posting row.

The review therefore removes traversal state without pretending dependent row admission is a whole-array reduction.

## Publication subtraction

Two helper result fields were also reviewed:

- `normalized_postings`;
- `transaction_starts`.

Repository search found no production consumer outside `journal_single_domain_admission` itself. The complete-Journal caller consumes the helper state, diagnostics, and final Transactions.

The new characterization deliberately does not promote these intermediate values into public laws. They are removed from the helper result, leaving:

```text
state
domain
calculation_scale
transactions
diagnostics
```

This keeps the semantic publication boundary at durable admitted Transactions rather than exposing internal normalization and traversal coordinates.

## Evidence

- CI #2728 SUCCESS: corrected single-partition characterization;
- CI #2729 SUCCESS: final Transaction/publication characterization on old production;
- CI #2730 SUCCESS: source relation + publication implementation with full `tools/check.sh` and coverage.

## Review boundary

This change deliberately does not refactor:

- `CompleteElided`;
- `Normalize`;
- `BalanceDiagnostics`;
- structural-JPY adapter construction;
- final structural/semantic Transaction joining.

Those functions belong to the exact completion/balance and structural evidence halves of the same owner and require their own diagnostic/frontier observation.

No exact arithmetic, currency policy, Account proof, identity, provenance, diagnostic ownership, complete-Journal partitioning, or writer/source authority changed.