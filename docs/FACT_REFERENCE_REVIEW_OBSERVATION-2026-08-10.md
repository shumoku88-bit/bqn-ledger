# Fact reference review observation — 2026-08-10

## Baseline

The review began on `main` `0f33d6044f186acbf9185f97690872b76d376b1f` after the Envelope Backing review closed in PR #603. PR #604 recorded the first observation on `main` `f0636998aac10c63eefa3be80e52f281b3df21d2` before production ownership changed.

The owner was then located at `src/accounting/fact_reference.bqn`. The relocation slice following #604 moves the unchanged three-function module to `src/ledger/fact_reference.bqn`, updates every direct production importer and active owner-path document, and leaves no compatibility shim at the retired accounting path.

The active review cursor follows the owner to `src/ledger/fact_reference.bqn`. The owner is not review-complete yet because the separate `SourceIs` subtraction candidate still requires a focused law.

## Owner shape

`src/ledger/fact_reference.bqn` is a 13-line, dependency-free module with three public functions:

```text
SourceIs    Facts × source name -> boolean
Transaction Facts × snapshot-local Transaction index -> {source, transaction_id}
Posting     Facts × snapshot-local Posting index     -> {source, posting_id}
```

It performs no accounting arithmetic, period selection, grouping, report policy, rendering, I/O, or source parsing. Its responsibility is source qualification plus publication of durable source-qualified identity from canonical Facts.

`Transaction` and `Posting` deliberately translate snapshot-local numeric coordinates into stable public evidence. The record shapes remain centralized here rather than reconstructed by consumers.

## Facts source-axis contract

`src/ledger/facts.bqn` owns the source axis. `Project` starts with an empty source name, admits one nonempty canonical `source_name`, and publishes either an empty source-name vector or exactly one source-name cell.

Successful Facts therefore have exactly one source name. An error Facts value may still retain that singleton source axis if a later Facts diagnostic was raised after source admission.

This distinction matters: source-name equality alone is not enough to accept an error Facts value; `SourceIs` must retain the `facts.state == "ok"` requirement.

## Direct consumer graph

Repository search found ten direct production importers spanning three architectural layers.

Accounting:

- `src/accounting/account_balance.bqn`
- `src/accounting/cycle_account_period.bqn`
- `src/accounting/cycle_income_anchor_resolution.bqn`
- `src/accounting/envelope_backing.bqn`
- `src/accounting/month_account_movement.bqn`
- `src/accounting/plan_completion_join.bqn`
- `src/accounting/profit_and_loss.bqn`
- `src/accounting/recent_transactions.bqn`

Section:

- `src/sections/planned_payments.bqn`

Application:

- `src/application/household_daily_scope.bqn`

The relocation updates all ten to import `src/ledger/fact_reference.bqn` through their appropriate relative path. No consumer API changes.

`SourceIs` remains the source-qualified Facts admission predicate. `Transaction` remains the durable Transaction reference constructor used by Plan completion, recent Transactions, and income-anchor provenance. `Posting` remains the durable Posting reference constructor used by Account/cycle/month/P&L/Envelope/recent/Plan evidence publication.

The consumers use the reference constructors only after selecting canonical Facts indices; none asks this owner to perform selection, bounds checking, accounting validation, or diagnostic policy.

## Ownership decision: MOVE

`TODO.md` defines Phase 2 `src/ledger/` as owning admission, Facts, exact values, identity, and provenance. Fact reference operates only on generic Facts structure and is consumed directly by Section and Application code as well as Accounting.

Keeping it under `src/accounting/` therefore made higher layers depend on the accounting directory for a generic Facts identity/provenance concern. Repository dependency search also found higher layers importing Accounting while no `src/ledger/` consumer imported `../accounting/`.

The retained ownership is therefore:

```text
src/ledger/fact_reference.bqn
```

The relocation is behavior-preserving:

1. the file content and exported `SourceIs`, `Transaction`, and `Posting` contracts are unchanged;
2. all ten direct production imports point to the ledger owner;
3. active path documentation points to the ledger owner;
4. the production inventory lists the file exactly once under Phase 2;
5. `src/accounting/fact_reference.bqn` is removed rather than retained as a compatibility shim.

Classification: **MOVE applied**.

## `Transaction` / `Posting` decision: KEEP

The two reference constructors are small but carry real domain meaning:

```text
snapshot-local coordinate -> source-qualified durable identity
```

Their scalar shape composes naturally with consumer-owned Group/Each cells that determine provenance ordering. Adding plural `Transactions` / `Postings` APIs would enlarge the public surface without removing a semantic owner. Replacing both with a kind-parameterized generic `Reference` helper would weaken the Transaction/Posting vocabulary.

No duplicate production definition of the `{source, transaction_id}` or `{source, posting_id}` reference shapes was found in the current search.

Classification: **KEEP**.

## `SourceIs` subtraction candidate

The current implementation intentionally remains unchanged by the ownership relocation:

```text
ok <- 0
if facts.state == "ok" and facts.sources.count == 1:
  ok <- first(facts.sources.name) == sourceName
```

Given the canonical Facts source-axis contract, exact vector equality appears able to express singleton shape and name relation simultaneously:

```text
(facts.state == "ok") and (facts.sources.name == <sourceName>)
```

In BQN terms, the candidate is equivalent in intent to:

```text
(facts.state≡"ok") ∧ (facts.sources.name≡⟨sourceName⟩)
```

This would remove the mutable `ok`, conditional execution, and separate count topology while still rejecting error Facts that happen to carry the expected singleton source name.

Classification: **SUBTRACT candidate**, not applied by the ownership relocation.

## Evidence required before `SourceIs` subtraction

There is no focused direct Fact reference law yet. Current behavior is exercised transitively through accounting, section, and application tests, but a local relation simplification deserves a local proof.

The focused law should cover at least:

1. `ok` Facts + expected singleton source -> true;
2. `ok` Facts + different singleton source -> false;
3. `ok` Facts + empty source axis -> false;
4. `ok` Facts + multiple source names -> false;
5. `error` Facts + expected singleton source -> false;
6. `Transaction` publishes the supplied Facts source plus durable `transaction_id`, not the numeric coordinate;
7. `Posting` publishes the supplied Facts source plus durable `posting_id`, not the numeric coordinate.

The last two laws protect why the owner exists while the first five establish the proposed source-axis relation.

## Current classification and continuation

`src/ledger/fact_reference.bqn` is now the retained **ledger identity/provenance owner**. The ownership question is closed; the owner itself remains unchecked until the `SourceIs` law/subtraction decision is completed and the final form is reread on merged `main`.

The current cursor stays on `src/ledger/fact_reference.bqn` for that focused follow-up. After Fact reference closes, normal Phase 1 review resumes at `src/accounting/matrix_result.bqn`.
