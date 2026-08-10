# Fact reference review observation — 2026-08-10

## Baseline

Observed on `main` `0f33d6044f186acbf9185f97690872b76d376b1f` after the Envelope Backing review closed in PR #603.

The active review cursor is `src/accounting/fact_reference.bqn`. This is observation-only: no production file, import path, public result, source authority, identity, provenance, accounting meaning, or review checkbox is changed here.

## Current owner shape

`src/accounting/fact_reference.bqn` is a 13-line, dependency-free module with three public functions:

```text
SourceIs    Facts × source name -> boolean
Transaction Facts × snapshot-local Transaction index -> {source, transaction_id}
Posting     Facts × snapshot-local Posting index     -> {source, posting_id}
```

It performs no accounting arithmetic, period selection, grouping, report policy, rendering, I/O, or source parsing. Its responsibility is source qualification plus publication of durable source-qualified identity from canonical Facts.

`Transaction` and `Posting` deliberately translate snapshot-local numeric coordinates into stable public evidence. The record shapes are centralized here rather than reconstructed by consumers.

## Facts source-axis contract

`src/ledger/facts.bqn` owns the source axis. `Project` starts with an empty source name, admits one nonempty canonical `source_name`, and publishes:

```text
sources.name = empty
```

or exactly:

```text
sources.name = <sourceName>
```

as a one-cell vector. Successful Facts therefore have exactly one source name. An error Facts value may still retain that singleton source axis if a later Facts diagnostic was raised after source admission.

This distinction matters: source-name equality alone is not enough to accept an error Facts value; `SourceIs` must retain the `facts.state == "ok"` requirement.

## Direct consumer graph

Repository search finds ten direct production importers spanning three architectural layers.

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

`SourceIs` is used as a source-qualified Facts admission predicate across those consumers. `Transaction` is used by Plan completion, recent Transactions, and income-anchor provenance. `Posting` is used by Account/cycle/month/P&L/Envelope/recent/Plan evidence publication.

The consumers use the reference constructors after selecting canonical Facts indices; none of the observed consumers asks this module to own selection, bounds checking, accounting validation, or diagnostic policy.

## Ownership observation

The current path is suspicious.

`TODO.md` describes Phase 2 `src/ledger/` as owning "admission, Facts, exact values, identity, and provenance". `fact_reference.bqn` describes itself as source validation plus durable source-qualified references, operates only on generic Facts structure, and is imported directly by Section and Application code as well as Accounting.

That makes the module look more like a ledger identity/provenance capability than an accounting kernel.

Keeping it under `src/accounting/` causes higher layers to depend on the accounting directory for a generic Facts/provenance concern. Moving the owner downward to `src/ledger/fact_reference.bqn` would align dependency direction and repository vocabulary without changing the public three-function contract.

Classification: **MOVE candidate**, strong evidence but not applied in this observation.

If accepted, prefer one coherent ownership relocation:

1. move the file to `src/ledger/fact_reference.bqn`;
2. update all direct production imports to the new owner;
3. update active documentation that names the current owner path, including `docs/PLAN_COMPLETION_JOIN.md` and `docs/ACTUAL_FACT_SUFFICIENCY.md`, and re-check other current review records for path references;
4. update the production BQN inventory / review cursor bookkeeping so the file is listed exactly once in its new phase;
5. do not leave an `src/accounting/fact_reference.bqn` compatibility shim;
6. do not change `SourceIs`, `Transaction`, or `Posting` semantics in the relocation PR.

The move is an ownership refactor, not an algorithm refactor. A complete move must update both dependency edges and current explanatory ownership references rather than leaving documentation pointing at the retired path.

## `Transaction` / `Posting` judgment

The two reference constructors are small but carry real domain meaning:

```text
snapshot-local coordinate -> source-qualified durable identity
```

Their current scalar shape composes naturally with the consumer-owned Group/Each cells that determine provenance ordering. Adding plural `Transactions` / `Postings` APIs would enlarge the public surface without removing a semantic owner; replacing both with a generic kind-parameterized `Reference` helper would weaken the Transaction/Posting vocabulary.

Classification: **KEEP**.

No duplicate production definition of the `{source, transaction_id}` or `{source, posting_id}` reference shapes was found in the current search. Central ownership is useful.

## `SourceIs` subtraction candidate

The current implementation uses a mutable local plus conditional execution to avoid taking the first source name when the source axis is not singleton:

```text
ok <- 0
if facts.state == "ok" and facts.sources.count == 1:
  ok <- first(facts.sources.name) == sourceName
```

Given the canonical Facts source-axis contract, exact vector equality can express the singleton shape and name relation simultaneously:

```text
(facts.state == "ok") and (facts.sources.name == <sourceName>)
```

In BQN terms, this suggests a direct expression equivalent to:

```text
(facts.state≡"ok") ∧ (facts.sources.name≡⟨sourceName⟩)
```

This would remove the mutable `ok`, the conditional, and the separate count topology while preserving the important rejection of error Facts even when an error value still carries the expected singleton source name.

Classification: **SUBTRACT candidate**, secondary to the ownership decision.

Do not combine this simplification with the file relocation. If the owner moves first, prove and apply this relation against the retained ledger owner in a separate algorithm slice.

## Evidence gap before `SourceIs` subtraction

No focused `test_accounting_fact_reference.bqn` (or equivalent direct owner test) was found. Current behavior is exercised transitively through many accounting/section/application tests, but a local relation simplification deserves a small direct law before production change.

A focused law should cover at least:

1. `ok` Facts + expected singleton source -> true;
2. `ok` Facts + different singleton source -> false;
3. `ok` Facts + empty source axis -> false;
4. `ok` Facts + multiple source names -> false;
5. `error` Facts + expected singleton source -> false;
6. `Transaction` publishes the supplied Facts source plus durable `transaction_id` rather than the numeric index;
7. `Posting` publishes the supplied Facts source plus durable `posting_id` rather than the numeric index.

The last two laws protect the reason this owner exists while the first five establish the proposed shape relation.

## Current classification

`src/accounting/fact_reference.bqn` is **OBSERVE / MOVE candidate**, with a later local `SourceIs` subtraction candidate.

The next decision should be whether to relocate this generic Facts identity/provenance owner to `src/ledger/` without semantic changes. Only after ownership is settled should the `SourceIs` implementation be simplified.
