# Recent Transactions review closeout — 2026-08-11

## Baseline

Final production reread is against `main` `1f5773beabad5a52a2cd0c511feb46ee261cf412` after PR #639.

The review sequence was:

- PR #637: recorded the physical-source ordering contract, consumer graph, existing selected-Posting relation, ordering-law gaps, and public `transaction_index` subtraction candidate;
- PR #638: fixed `Build` and `BuildThrough` ordering through durable Transaction references with deliberately non-monotonic transaction dates;
- PR #639: removed the public snapshot-local `transaction_index` while retaining the private Transaction coordinate required by the relation kernel.

## Final semantic owner

`src/accounting/recent_transactions.bqn` remains the pure bounded Recent Actual projection over canonical `actual.journal` Facts:

```text
Actual Facts + positive limit
  or
Actual Facts + explicit through ordinal + positive limit
→ eligible Transaction axis in physical source order
→ final N eligible Transactions
→ reverse selected physical tail
→ classify selected Postings onto selected Transaction coordinates
→ grouped scale / debit / credit / contributor cells
→ checked exact debit amount
→ semantic rows + durable Transaction/Posting provenance
```

The owner reads no files, chooses no wall clock, chooses no report limit, sorts no dates, renders no output, and fabricates no singular from/to Account from multi-posting evidence.

## KEEP

### Physical-source ordering

Recent means recent physical journal position inside the eligible Transaction sequence, not maximum transaction date.

PR #638 proves this with a source tail whose dates are intentionally out of order:

```text
A Jan20
B Feb01
C Jan14
D Jan05
```

`Build 3` returns durable identities `D,C,B`, proving final-three physical selection followed by reverse order rather than date sorting.

### `BuildThrough` eligibility boundary

Through-date policy filters Transaction eligibility first. The remaining eligible Transactions keep physical source order; only then does the owner take the final N and reverse them.

PR #638 directly characterizes the live `BuildThrough ⟨facts, throughOrdinal, limit⟩` API and proves the same durable-reference ordering after through-date filtering.

### BQN-native selected-Posting relation

The owner keeps one selected Transaction axis and classifies selected Postings onto it once with `⊐`. `⊔` then creates aligned Posting cells for scales, debit Accounts, credit Accounts, and durable contributor evidence.

There is no selected-Transaction-by-selected-Transaction full Posting rescan and no candidate-row append followed by field reprojection.

### Multi-posting lane arrays

Debit and credit Accounts remain arrays in Posting order. Split transactions remain visible without collapsing them into a synthetic singular from/to pair.

### Checked debit amount

The displayed Recent amount is a real semantic measure derived from the selected debit Posting cell. `scale.Sum` therefore remains operation-local exact accounting work.

### Durable provenance

Rows retain source-qualified Transaction references and separate debit/credit Posting contributor cells.

### Fail-closed selected evidence

Selected Transactions still require canonical Actual Facts, positive integer limit, Actual layer, nonempty debit and credit lanes, aligned scale evidence, and exact debit summation before any rows are published.

## SUBTRACTED

### Public `transaction_index`

The accounting result previously exposed both snapshot-local `transaction_index` and durable `transaction_reference`.

After #638 moved ordering laws to durable identity, PR #639 removed `transaction_index` from both empty and successful public row shapes. The old focused test now asserts durable Transaction IDs rather than numeric snapshot coordinates.

The private selected Transaction indices remain inside the kernel because they are legitimate Facts-local coordinates used to:

- select Transaction columns;
- classify Postings with `⊐`;
- build aligned grouped evidence.

The subtraction therefore removes a publication leak without erasing the coordinate system needed by the array relation itself.

## Public shape alignment

`src/sections/recent_journal.bqn` already published no numeric Transaction coordinate. After #639 the accounting and Section layers now agree on the durable semantic identity family:

```text
index                  — result-local presentation axis
transaction_reference  — durable source-qualified Transaction identity
```

This differs from the deferred cross-statement `account_index` question: here there was no sibling accounting contract or production consumer requiring the snapshot-local coordinate.

## Qualification

The final law set includes:

- ordinary Recent selection, limit behavior, multi-posting lanes, exact amounts, provenance, empty Actual, wrong source, and invalid limit in `tests/test_accounting_recent_transactions.bqn`;
- physical-source versus date ordering in `tests/test_accounting_recent_transactions_ordering.bqn`;
- direct `BuildThrough` date-eligibility plus physical-tail behavior;
- lane and contributor alignment through durable Transaction references;
- Section publication laws in `tests/test_section_recent_journal.bqn`.

PR #638 final head `f68d709db27743cf05468e3b73eae9696d8a3b27` passed full `tools/check.sh` and Coverage.

PR #639 final head `7409c277641f2113f71ef526eb6d4a596721efaf` passed full `tools/check.sh` and Coverage, including the #638 ordering law.

The merge-side main `check` run #2569 also passed full `tools/check.sh` and Coverage on `main` `1f5773beabad5a52a2cd0c511feb46ee261cf412`.

The accounting owner and `src/sections/recent_journal.bqn` were reread on that merged main.

## Final classification

The Recent Transactions accounting review is complete.

No further Recent-specific production subtraction is currently justified.

The next normal Phase 1 cursor is:

`src/accounting/sparse_group.bqn`
