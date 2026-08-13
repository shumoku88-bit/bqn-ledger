# Phase 6 Actual-file and Budget editor observation — 2026-08-13

## Scope

This review advances the normal Phase 6 cursor through four adjacent production owners:

- `src_edit/actual_journal_file_cmd.bqn`;
- `src_edit/budget_add_cmd.bqn`;
- `src_edit/budget_movement_candidate.bqn`;
- `src_edit/budget_validate_cmd.bqn`.

The review asks the same question used throughout the BQN-native pass: where does mutation hide a regular data shape, and where does sequential staging instead protect source authority, evaluation order, exact round-trip evidence, or safe publication?

## Actual Journal File

`actual_journal_file_cmd.bqn` is intentionally tiny and remains production-unchanged.

It accepts the editor base argument only to fit the command boundary and emits `canonical.actual`. It does not inspect `config.tsv`, `ACTUAL_JOURNAL_FILE`, environment overrides, or the contents of the Household root.

That apparent lack of work is the capability law: the shell may ask for the canonical Actual writer target, but it does not own the basename and local legacy configuration cannot redirect it.

Existing ownership checks already prove that a legacy `ACTUAL_JOURNAL_FILE=legacy.journal` entry cannot change the result from `actual.journal`. Removing the leaf merely because its base argument is unused would move canonical routing knowledge back into shell.

## Budget Add

The Budget Add command already has several appropriate semantic boundaries:

- canonical Accounts are admitted once before account selection;
- from/to Accounts must resolve exactly once and must have role `budget`;
- the two Accounts must differ;
- Commodity is inferred only when selected Budget Accounts imply exactly one known Commodity, otherwise explicit currency is required;
- selected Account Commodity and chosen currency must agree;
- date, text, exact decimal, metadata, and currency-metadata contracts are admitted before candidate construction;
- complete canonical Budget publication is delegated to the pure candidate owner.

The local role/currency vectors, masks, reductions, and exact checks are already direct BQN. `Unique` is a small first-occurrence array operation and does not justify replacement merely for novelty.

### Regular metadata collection

One mutable accumulator was incidental:

```text
meta token -> parse key/value -> metadata ∾↩ one record
```

After generic metadata admission, Budget Add deliberately applies a stricter local law: each `--meta` token must contain exactly one equals sign. The existing implementation already mapped a function over `metaTokens`; mutation was used only to accumulate the mapped records.

The natural relation is simply:

```text
metadata = MetadataRecord¨metaTokens
```

The refactor keeps the same per-token exactly-one-`=` gate, source order, key/value split, evaluation path, and rendered bytes while removing the accumulator.

## Budget Movement Candidate

`budget_movement_candidate.bqn` remains production-unchanged.

Its mutation is not ordinary domain state. `Reject` records the first failure and guards later candidate construction. The stages depend on each other:

1. canonical Budget root admission establishes the physical publication base;
2. intent date/amount/account/Commodity validation establishes typed movement meaning;
3. metadata safety is checked before rendering;
4. the candidate source is assembled;
5. the complete candidate is re-admitted against the same AccountRegistry;
6. the new transaction is checked for exact date, description, posting count/order, accounts, signed exact amounts, Commodity, and metadata round trip;
7. only then is a payload published.

Flattening this into eager whole-array evaluation merely to remove `failed↩1` would weaken or obscure fail-closed staging. The owner is also reused by Plan Budget sync, so its exact candidate law is a useful shared semantic boundary rather than Budget Add shell machinery.

## Budget Validate

`budget_validate_cmd.bqn` also remains production-unchanged.

It is the mandatory post-write validation leaf for canonical `budget.journal`:

- canonical Accounts are re-admitted;
- the Budget root is checked as a canonical journal root;
- Budget semantic admission runs with the canonical currency registry;
- failure remains diagnostic/fail-closed;
- success publishes only the small `OK\tBUDGET_JOURNAL...` protocol.

The shell owns physical append, stale-observation fencing, backup, and rollback. This BQN command owns semantic re-observation after publication. A generic validator abstraction would make that writer-safety boundary less visible, not more native.

## Cross-cutting effect-lifetime observation

The review found a real repeated inefficiency but does not patch it locally.

`validate.bqn` currently loads the editor currency registry at module import time. `budget_add_cmd.bqn` also loads `editorCurrency` directly because it needs the registry and policy for candidate preparation. Plan Add/Edit/Finish show the same pattern.

Therefore some editor commands can observe `config/currencies.tsv` twice in one process.

This is not a Budget semantic defect, and fixing it by copying date/text/metadata validation into Budget Add would create worse duplication. There are now multiple real consumers demonstrating the pressure, so the later `validate.bqn` owner review should consider a narrower pure currency/policy validation boundary or another way to avoid eager registry setup while preserving existing diagnostic/evaluation laws.

Until then, retain the known double observation rather than introduce a Budget-only workaround.

## Evidence

The existing `check-edit-bqn-budget-add.sh` already protects:

- dry-run non-publication;
- canonical Budget block shape;
- apply + mandatory validation;
- exact-decimal USD movement;
- unknown/non-Budget/same-account failures;
- invalid date/amount/zero/negative failures;
- canonical-only operation;
- invalid-Household refusal;
- exact rollback after forced post-admission failure;
- stale AccountRegistry fencing;
- absence of legacy Budget/Account/config routing.

This review extends the same check with metadata evidence:

1. two admitted metadata records render in source order;
2. a token with more than one equals sign retains the existing local failure contract;
3. metadata dry-run/failure leaves canonical Budget bytes unchanged.

Existing configuration-ownership checks continue to protect the Actual Journal basename capability.

## Decision

All four owners in this observation are reviewed.

- `actual_journal_file_cmd.bqn`: law review; production unchanged.
- `budget_add_cmd.bqn`: regular metadata accumulation becomes a direct map; other boundaries retained.
- `budget_movement_candidate.bqn`: law review; fail-closed staging retained unchanged.
- `budget_validate_cmd.bqn`: law review; mandatory post-write leaf retained unchanged.

The normal Phase 6 cursor can advance to:

`src_edit/issue_add_cmd.bqn`
