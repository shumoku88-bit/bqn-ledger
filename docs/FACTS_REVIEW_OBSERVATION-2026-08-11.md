# Canonical Facts review observation — 2026-08-11

## Baseline and ownership

- repository: `shumoku88-bit/bqn-ledger`
- review base: `cdae0c7c1c4400c46a8e15a2c357808dc06bdbe5`
- active owner: `src/ledger/facts.bqn`
- focused review PR: #664

`facts.Project` is the live pure boundary that converts one successful canonical Journal admission plus one admitted Account table into aligned readonly Transaction/Posting Facts and side-table coordinates.

Current production callers include canonical Actual snapshot composition and canonical Plan/Budget application adapters. Those callers first run the appropriate Journal/Account admissions and pass the same admitted Account table to Facts.

## Why projection validation remains

Complete Journal admission already owns substantial accounting meaning: source syntax, strict dates, exact decimal admission, Account resolution, transaction-domain admission, exact normalization/balance, source coordinates, and identity construction. Plan/Budget admission add their source-specific identity/layer semantics.

It would therefore be tempting to delete many checks from `facts.Project` as duplicates.

That is not the selected change. The current Fact-schema contract explicitly defines `facts.Project` as a fail-closed projection-invariant boundary. It checks that the supplied successful admission and Account table can actually be represented as bounded aligned Fact axes before publishing any numeric Facts.

The retained projection guards include:

- successful admission;
- nonempty source identity;
- required Domain/Layer axes;
- unique Layer and Transaction identities;
- aligned and unique Account columns;
- valid Transaction date/domain/layer/identity coordinates;
- Posting Account membership and Account default-Commodity compatibility;
- nonempty Posting evidence and zero normalized Transaction balance;
- all-or-nothing Fact publication.

The review therefore separates **validation ownership** from **repeated relation discovery**.

## Historical native-search work was already complete

PR #446 had already replaced manual match-mask search and mutable uniqueness helpers with BQN-native Index Of / Deduplicate relations (`⊐` / `⍷`). Repeating that refactor would not address the current structural debt.

The remaining duplication was that the same semantic joins were discovered once during validation and then discovered again during publication:

```text
Transaction Domain -> Domain axis
Transaction Layer  -> Layer axis
Posting Account    -> Account axis
```

In addition, successful Posting publication built a temporary namespace row for every Posting and immediately decomposed those namespaces back into aligned columns.

## Characterization before production change

A dedicated two-Domain/four-Account characterization deliberately gives each axis a different order:

```text
Domain axis: JPY, USD
Account axis: USD Asset, JPY Expense, JPY Asset, USD Expense
Posting axis: transaction-major source order
```

It pins:

- Transaction Domain coordinates;
- Posting Domain coordinates;
- Posting Account coordinates in admitted Account order;
- transaction-major Posting order;
- transaction-local Posting order;
- Layer coordinates.

Characterization-only CI #2673 was SUCCESS.

## Retained coordinate pipeline

The new successful/validation path names the semantic axes once.

Transaction cells first become aligned source columns and coordinates:

```text
Transactions
  -> Date / Domain / Layer / identity columns
  -> Posting cells per Transaction
  -> Posting counts
  -> Domain coordinates via `⊐`
  -> Layer coordinates via `⊐`
```

Posting cells are then flattened exactly once in transaction-major source order:

```text
Transaction Posting cells
  -> flat Posting axis
  -> Posting -> Transaction coordinate
  -> Posting Account key column
  -> Account coordinates via `⊐`
```

Those same Domain/Layer/Account coordinates now drive both projection-invariant diagnostics and final Fact publication.

No second Index Of pass exists in the success block.

## Diagnostic order remains an explicit public boundary

Preclassifying all joins must not reorder diagnostics.

The retained publication order remains transaction-major:

```text
Transaction date
Transaction domain
Transaction layer missing
Transaction layer undeclared
Transaction identity
Posting account diagnostics in source order
Transaction posting-count
Transaction balance
```

Posting account relations are classified globally, while `postingCounts` plus a prefix Scan produce each Transaction's contiguous Posting slice for ordered diagnostic publication.

A forged projection input now pins the exact mixed-invalid diagnostic code order:

```text
transaction_date_invalid
transaction_domain_undeclared
transaction_layer_missing
transaction_layer_undeclared
transaction_identity_missing
posting_account_unknown
transaction_unbalanced
```

The fail-closed result still publishes zero Transaction/Posting Facts.

Production coordinate refactor CI #2674 and diagnostic-order CI #2675 were SUCCESS.

## Row reconstruction removed

The previous success path constructed one `postingRows` namespace per Posting containing source, transaction, date, Account, Layer, Domain, amount, side, and provenance fields. `postingFacts` then immediately mapped over those namespaces field by field to recover columns.

That detour is removed.

The retained Fact publication now uses:

- the already flattened Posting cells for Posting-owned source fields;
- the already classified Account coordinates;
- Posting -> Transaction coordinates to Select Transaction date/layer/domain/scale columns;
- direct constant source coordinate vectors.

This is not a generic table abstraction. It is the concrete canonical Fact column owner publishing the axes it already owns.

## Exact arithmetic deliberately unchanged

This review does not replace the existing local zero-balance check or change exact-normalization ownership. The reason-to-change is relation classification and column publication, not arithmetic semantics.

`Sum0` therefore remains unchanged in this owner. Any stronger decision about exact checked balance at Journal/Facts boundaries belongs to the later review of the Journal exact-admission owners and must be evaluated with their existing exactness laws rather than smuggled into this coordinate refactor.

## Review conclusion

The useful transformation is:

```text
repeated lookup + row reconstruction
  -> named semantic axes
  -> classify each join once
  -> preserve ordered fail-closed diagnostics
  -> publish columns directly from the same coordinates
```

The result is slightly more explicit source code, not glyph compression. The gain is that Domain, Layer, Transaction, Posting, and Account axes are now visible as the actual shape of the canonical Fact projection.