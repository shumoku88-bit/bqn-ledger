# Recent Transactions review observation — 2026-08-11

## Baseline

Observed against `main` `08dc953d86b9dc751261a63831efdc18f805da50` after PR #636 closed the Profit and Loss review and advanced the Phase 1 cursor to `src/accounting/recent_transactions.bqn`.

The separate canonical Household recovery closeout Draft #550 does not overlap this accounting owner.

This document is observation-only. It does not change production BQN, tests, public result shape, ordering, exact arithmetic, provenance, source authority, writer behavior, or the TODO cursor.

## Owner boundary

`src/accounting/recent_transactions.bqn` owns a bounded Recent Actual Transaction projection from canonical `actual.journal` Facts.

Public entry points:

```text
Build        Facts + positive limit
BuildThrough Facts + positive limit + explicit through ordinal
```

The retained contract is deliberately **physical-source recent**, not date-sorted recent:

```text
Build:
  final N Transaction Facts in physical source order
  → reverse selected Transactions

BuildThrough:
  Transaction Facts whose date_ordinal <= through ordinal
  → final N of that filtered physical-source sequence
  → reverse selected Transactions
```

For each selected Transaction the owner publishes date, description, currency, exact debit amount, debit/credit Account arrays, durable Transaction reference, and separate debit/credit Posting contributors.

It reads no source file, chooses no report limit, resolves no wall clock, renders no table, and fabricates no singular from/to Account from multi-posting evidence.

## Current consumer graph

Current production composition is:

```text
src/report/compose.bqn
  → recentTransactions.BuildThrough
  → src/sections/recent_journal.bqn
  → human / compact renderer
```

The section intentionally republishes semantic evidence but not the accounting owner's snapshot-local `transaction_index` field.

Focused accounting characterization is `tests/test_accounting_recent_transactions.bqn`; section characterization is `tests/test_section_recent_journal.bqn`.

## Protected ordering semantics

The active `docs/RECENT_JOURNAL_REPORT.md` contract explicitly says:

```text
selection = final N Transaction Facts in physical source order
result    = selected Transactions reversed to newest first
```

Therefore “newest” means latest physical journal position inside the eligible sequence, **not maximum transaction date**.

This distinction matters because canonical Journal source order can carry semantic history that is not equivalent to sorting by date. Do not add a date sort merely because the current proof fixture happens to be date-ordered.

`BuildThrough` adds date eligibility, not date ordering. After filtering by the explicit through ordinal, physical source order still owns the tail selection.

## Existing array relation is already strong

After bounded Transaction selection, the owner classifies selected Postings onto the selected Transaction axis once:

```text
selected Transaction indices
posting.transaction_index
→ selected Transaction coordinate per Posting with ⊐
→ matched selected Posting mask
→ ⊔ one Posting cell per selected Transaction
```

The same selected coordinate relation is reused to build aligned:

- Posting scale cells;
- debit Account cells;
- credit Account cells;
- debit contributor cells;
- credit contributor cells.

There is no Transaction-by-Transaction rescan of the full Posting axis and no candidate-row namespace append followed by field reprojection.

Classification: **KEEP the current coordinate classification / Group structure.** Forcing a different Rank/Cells/Table form would not reveal a missing semantic axis.

## KEEP multi-posting lane arrays

Debit and credit Account lanes remain arrays in posting order. This is a core retained Recent Journal difference from old one-from/one-to views.

The semantic owner must not collapse a split transaction into one selected Account or infer a synthetic direction pair.

## KEEP checked debit amount

The published Recent amount is the exact debit total for each selected Transaction. The owner must actually derive that measure from the selected debit Posting cell, so checked `scale.Sum` remains operation-local accounting work.

Corresponding credit Account and Posting evidence remains separately published for zero-sum/provenance inspection rather than being discarded after deriving the debit amount.

## KEEP fail-closed lane alignment

The owner rejects selected Transactions when:

- the Facts are not canonical `actual.journal` Facts;
- limit is not a positive integer;
- selected evidence contains a non-Actual layer;
- debit or credit lane is missing;
- Posting scales disagree within a selected Transaction;
- exact debit summation fails.

Rows are published only after every selected Transaction cell passes.

## Strong subtraction candidate: public `transaction_index`

Accounting rows currently publish both:

```text
transaction_index
transaction_reference
```

Repository search finds `rows.transaction_index` only in `tests/test_accounting_recent_transactions.bqn`. The production Recent Journal section does not forward it, and the active Recent Journal contract specifies durable Transaction reference rather than snapshot-local numeric identity.

The owner already needs snapshot-local Transaction indices internally to classify Postings, but that does not justify publishing them after durable source-qualified identity has been constructed.

Classification: **SUBTRACT candidate, strong evidence.** Remove public `rows.transaction_index` after ordering laws are strengthened, while retaining the private selected Transaction coordinate used by the kernel.

## Focused-law gaps

The current focused accounting test proves:

- newest-first result for the existing fixture;
- limit truncation;
- split debit Account arrays;
- exact amounts and provenance;
- empty Actual;
- wrong source and invalid limit failure.

The fixture's physical source order and date order currently agree, so it does not directly distinguish the documented physical-order contract from a date-sort implementation.

`BuildThrough` is a live production API used by `src/report/compose.bqn`, but repository search finds no direct focused test invocation of `BuildThrough`.

Before changing the public result shape, add a characterization with deliberately non-monotonic transaction dates that proves:

1. `Build` selects the physical tail and reverses it, regardless of date order;
2. ordering is asserted through durable Transaction references, not numeric transaction indices;
3. `BuildThrough` first filters by date eligibility and then takes/reverses the physical tail of the eligible sequence;
4. Posting lane arrays and contributor cells remain aligned to those durable references after the selection.

This law should make it impossible to “fix” Recent into a date-sorted report accidentally.

## Public-section shape

`src/sections/recent_journal.bqn` already declares and publishes a result without `transaction_index`:

```text
index
date
description
currency
coefficient / scale
credit_accounts / debit_accounts
transaction_reference
debit_contributors / credit_contributors
```

Unlike the cross-statement `account_index` question recorded during Profit and Loss review, removing `transaction_index` here would make the accounting result converge on the already-retained Section/public contract rather than diverge from a sibling capability.

## Current review direction

A coherent continuation is:

1. merge this observation;
2. add focused physical-order + `BuildThrough` ordering laws using durable Transaction references;
3. remove public `transaction_index` from Recent accounting rows and update the old focused assertions accordingly;
4. run full qualification and reread owner + Section on merged `main`;
5. close the Recent Transactions review and advance to `src/accounting/sparse_group.bqn` if no new evidence appears.

No broader Recent algorithm rewrite is currently justified.
