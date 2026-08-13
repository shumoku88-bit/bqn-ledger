# `src_edit/account_list_cmd.bqn` Phase 6 observation — 2026-08-13

## Scope

Owner under review:

- `src_edit/account_list_cmd.bqn`

The review follows Account Add in the same canonical Account editor closeout because both touch the boundary between a narrow Account command and broader historical editor helpers.

Relevant boundaries read:

- `src/application/account_source_adapter.bqn` for admitted canonical Accounts;
- `src/application/editor_currency.bqn` and `src/ledger/currency_registry.bqn` for supported-currency policy;
- `config/currencies.tsv` for current registry data;
- `src_edit/validate.bqn::ValidateCurrency` for the existing shared validation path;
- `tools/edit-bqn` Account List routing;
- existing Account List and multi-currency editor witnesses.

## BQN-native result

The list/filter kernel is already a compact array relation and should remain so.

From admitted canonical Accounts it projects aligned axes:

```text
account key
role
currency
```

Role and currency filters become boolean masks over those axes. Their conjunction selects the result. `preferred-role` is implemented as a stable partition: selected rows matching the preferred role are emitted first and the remaining selected rows retain source order.

That is direct BQN data shaping. Replacing it with shell filtering, a generic selector abstraction, or row-by-row mutable accumulation would be a regression.

## Effect-lifetime pressure found

`ValidateCurrency` is not semantically stale: current `src_edit/validate.bqn` already delegates supported-currency policy to `editor_currency.bqn`, so USD is correctly registry-supported there too.

The problem is narrower. `validate.bqn` performs:

```bqn
setup ← editorCurrency.Load @
```

at module import time. Account List needs currency admission only when the caller supplies a nonempty currency filter. Importing the broad validator surface at command startup therefore opens the canonical currency registry even for the common unfiltered list path, where the result is never used.

This is an effect-lifetime issue rather than a competing currency policy owner.

## Change

Account List now depends directly on the narrower `editor_currency.bqn` capability and calls `Load` only inside the nonempty explicit-currency branch.

An empty currency argument remains semantically different from a default currency: it means **no currency filter**. Account List does not call `ResolveDefault` and does not silently narrow the result to the configured editor default.

When an explicit currency exists, supported/unsupported meaning still comes from the same canonical registry. The existing `unsupported currency: <key>` diagnostic text is preserved.

## Preserved behavior

No change is made to:

- canonical Account loading;
- supported-currency policy;
- USD support;
- unsupported-currency rejection text;
- role filtering;
- combined role + currency filtering;
- source order;
- preferred-role stable partitioning;
- the existing contract that an unknown role filter simply selects no Accounts;
- UI selector policy or physical ordering beyond the already-owned preferred-role relation.

## Evidence

`checks/check-edit-bqn-account-list-registry.sh` adds a synthetic USD Asset and USD Expense to a canonical fixture and proves:

1. explicit USD filtering still follows canonical registry support;
2. JPY rows do not leak into the USD result;
3. role + currency masks compose exactly;
4. unsupported EUR retains the existing error contract;
5. Account List no longer imports the broad `validate.bqn` surface solely for optional currency admission.

The existing Account List check continues to protect role masks, all-account output, preferred-role stable partitioning, shell argument routing, and Account writer safe-publication behavior.

## Decision

`src_edit/account_list_cmd.bqn` is reviewed.

Its array filtering/stable-partition kernel and registry-owned currency semantics are retained. Production changes only to narrow the dependency/effect lifetime: the currency registry is observed only when an explicit currency filter actually requires it.

The normal Phase 6 cursor can advance to:

`src_edit/account_validate_cmd.bqn`
