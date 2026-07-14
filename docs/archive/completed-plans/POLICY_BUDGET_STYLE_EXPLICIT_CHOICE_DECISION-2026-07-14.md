# POLICY_BUDGET_STYLE explicit-choice decision — 2026-07-14

Status: completed docs-only policy decision
Owner: ledger policy / configuration
Canonical runtime: current behavior remains in `src_next/config.bqn` until a separately selected migration slice
Supersedes: only the `POLICY_BUDGET_STYLE` classification in `../active-plans/CONFIG_KEY_CLASSIFICATION_DECISION-2026-07-05.md`

## Decision

`POLICY_BUDGET_STYLE` is a ledger-owner choice, not a universal repository default.

The supported choices remain:

```text
POLICY_BUDGET_STYLE=envelope
POLICY_BUDGET_STYLE=none
```

- `envelope` means the ledger uses envelope-oriented household policy, reports, and diagnostics.
- `none` means the ledger does not use envelope policy.
- Neither value is the morally correct or universally simpler household method.
- A person may start with `none`, try `envelope`, or later return to `none`.

The target classification is `required-explicit`:

```text
missing -> CONFIG ERROR
empty   -> CONFIG ERROR
unknown -> CONFIG ERROR
```

A repository fallback would be misleading because it would silently choose a household-management method on behalf of the ledger owner.

## Compatibility transition

This decision does not change runtime behavior today.

Current compatibility behavior remains temporarily:

```text
missing -> warning + envelope fallback
```

That fallback exists only to preserve older ledgers and fixtures that may rely on the previous application default. It is not the recommended setup for a new ledger.

From this decision onward:

1. every new first-class ledger, profile, fixture, onboarding example, and generated configuration must state either `envelope` or `none` explicitly;
2. missing-key behavior must not be presented as a valid new-ledger configuration;
3. changing the runtime to fail on missing remains a separate finite migration slice;
4. no private or live configuration is automatically edited.

## Switching policy

Switching between `envelope` and `none` changes selected policy consumers, reports, and diagnostics. It must not silently rewrite or delete source truth.

In particular, switching to `none` must not automatically:

- delete `budget_alloc.tsv` rows;
- delete budget account metadata;
- rewrite journal or plan rows;
- erase historical envelope evidence;
- reinterpret past source events as though envelope policy never existed.

A later return to `envelope` may reuse compatible source data only through existing validated contracts. Any migration or cleanup remains an explicit human decision through the safe editor boundary.

## Why `none` is not the repository default

`none` looks neutral, but a missing key and an intentional choice of no envelope policy are different facts.

If missing silently resolved to `none`, a damaged or incomplete configuration could make envelope views disappear without a visible failure. That would replace one hidden worldview with another hidden behavior.

Therefore:

```text
missing != none
missing != envelope
```

The ledger owner must eventually choose.

## Existing evidence

The repository already proves both choices as concrete consumers:

- `fixtures/household-moko/config.tsv` explicitly uses `envelope`;
- `fixtures/household-monthly-salary/config.tsv` explicitly uses `none`;
- `fixtures/envelopes-disabled-policy/config.tsv` explicitly uses `none` while retaining envelope-related configuration evidence;
- current config tests distinguish missing, explicit empty, and explicit values.

This is enough to decide ownership. It does not by itself authorize the runtime migration.

## Migration gates before fail-closed activation

A future implementation may remove the compatibility fallback only after a separately reviewed slice proves all of the following:

1. first-class public ledgers, fixtures, and onboarding examples explicitly declare the key;
2. envelope and non-envelope paths remain covered independently;
3. missing, empty, duplicate, and unknown values have focused negative tests;
4. the warning-to-error change is documented as a compatibility change;
5. no source TSV is rewritten as part of configuration migration;
6. existing local users have a simple manual instruction for adding one explicit line;
7. full repository checks and daily-use verification pass.

No date or release is chosen here.

## Module boundary

This decision does not create a plugin system.

For now, `POLICY_BUDGET_STYLE` selects a closed built-in policy vocabulary:

```text
envelope
none
```

Unknown values fail closed. Arbitrary module paths, dynamic code loading, and user-authored accounting programs remain out of scope.

A future policy-module interface requires at least two implementations sharing the same typed input and result contracts. The current enum is a small explicit composition seam, not a general extension framework.

## Non-goals

- no runtime, report, JSON, ViewModel, or source TSV change;
- no automatic edit of private or production configuration;
- no removal of envelope support;
- no claim that `none` is simpler or better for every household;
- no cleanup of household group keys, budget prefixes, or budget account IDs;
- no plugin manager, module-path setting, or arbitrary policy DSL;
- no selection of the later missing-key error implementation.

## Result

Envelope budgeting is optional and reversible as a user policy choice.

The engine supports the choice; it does not make the choice for the user.

The long-term contract is explicit selection. The current `envelope` fallback remains a temporary compatibility bridge until a separate migration slice closes it safely.
