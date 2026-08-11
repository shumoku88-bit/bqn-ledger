# Transaction rows review observation — 2026-08-12

## Owner and scope

`src/ledger/transaction_rows.bqn` is a narrow source-ordered typed join over already admitted canonical Facts.

It is used by editor-facing consumers that need Transaction records with their Posting evidence attached. It is not a source loader, accounting kernel, report ViewModel, or editor-specific binary-transaction validator.

The reviewed input relations are already present in canonical Facts:

```text
Transaction axis
Posting axis
Posting.transaction_index -> Transaction coordinate
Posting.account_index     -> Account coordinate
Transaction.layer_index   -> Layer coordinate
Transaction.domain_index  -> Domain coordinate
```

## Consumer boundary

`src/application/editor_actual.bqn` consumes the typed Posting cells to distinguish debit/credit evidence and build completion-oriented editor data.

`src/application/editor_plan_rows.bqn` consumes the same Transaction rows but owns a later, narrower binary-editor restriction.

Therefore `transaction_rows.bqn` must retain arbitrary admitted multi-Posting Transactions. It must not manufacture a two-Posting assumption merely because one editor surface is narrower.

## Characterization first

Focused characterization protects:

- Transaction rows in canonical Facts Transaction order;
- multi-Posting Transactions remaining intact;
- canonical global Posting index order within each Transaction cell;
- transaction-local Posting index order;
- Account coordinate to Account key alignment;
- Posting coefficient and durable Posting-id alignment;
- rejected Facts remaining fail-closed with zero rows and diagnostics preserved.

The first characterization run failed only because the test used the lower-case name `raw` beside the function-role name `Raw`, producing a BQN redefinition/role collision. Renaming the noun to `journalRaw` corrected the fixture.

Corrected characterization-only CI #2800: SUCCESS.

## Previous traversal

The previous implementation iterated the Transaction axis and, for every Transaction, rescanned the complete Posting axis:

```bqn
postingIndices ← (ti=factSet.postings.transaction_index)/factSet.postings.index
```

It then appended each newly constructed row through shared:

```bqn
rows∾↩⟨...⟩
```

The relation was therefore present in Facts but rediscovered one Transaction at a time.

## Grouped Posting relation

The reviewed implementation classifies Posting coordinates once:

```bqn
postingGroups ← factSet.postings.transaction_index⊔factSet.postings.index
```

`postingGroups` is now a Transaction-aligned cell axis. Each cell contains the canonical Posting indices belonging to that Transaction, in canonical Posting order.

Typed Posting publication becomes a local map over one cell:

```text
Posting index cell
  -> MakePosting¨
  -> typed Posting cell
```

The Account key remains an aligned lookup through the already admitted Account coordinate. No Account matching or source parsing is reintroduced here.

## Direct Transaction-row map

The mutable row append is also removed.

```text
Transaction index
  -> its Posting-index cell
  -> typed Posting cell
  -> layer/domain coordinates
  -> typed Transaction row
```

is mapped directly across the canonical Transaction axis:

```bqn
rows↩MakeRow¨factSet.transactions.index
```

Transaction order therefore remains the Facts order by construction rather than by append side effect.

## Production qualification

Production CI #2801: SUCCESS with full `tools/check.sh` and coverage.

The focused laws confirm that the Group transformation preserves:

- source Transaction order;
- Posting order and local Posting coordinates;
- multi-Posting shape;
- Account identity;
- coefficient/scale/source amount evidence;
- durable Posting identity;
- rejected-Facts fail-closed behavior.

## Retained state and boundaries

The outer success guard remains intentionally:

```text
Facts state ok -> construct typed rows
Facts state error -> zero rows, preserve diagnostics
```

That is a publication boundary, not traversal machinery.

No generic relation/join abstraction is introduced. `MakePosting` and `MakeRow` remain domain-named because their record shapes are the useful contract.

## Review conclusion

The useful subtraction is:

```text
per-Transaction whole-Posting rescans
+ mutable Transaction-row append
```

becoming:

```text
Posting transaction coordinate
-> one Group
-> Transaction-aligned Posting cells
-> direct typed Transaction-row map
```

`src/ledger/transaction_rows.bqn` is reviewed under the dense-array-kernel policy with editor-specific narrowing deliberately left to its owning consumer.
