# `src_edit/account_list_cmd.bqn` Phase 6 observation — 2026-08-13

## Scope

Owner under review:

- `src_edit/account_list_cmd.bqn`

The review follows Account Add in the same canonical Account editor closeout because both exposed pressure from the same retired validator topology.

Relevant boundaries read:

- `src/application/account_source_adapter.bqn` for admitted canonical Accounts;
- `src/application/editor_currency.bqn` and `src/ledger/currency_registry.bqn` for supported-currency policy;
- `config/currencies.tsv` for current registry data;
- `tools/edit-bqn` Account List routing;
- `checks/check-edit-bqn-account-list.sh` and multi-currency editor witnesses;
- historical `src_edit/validate.bqn::ValidateCurrency`.

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

## Concrete defect found

Currency filter admission was delegated to `src_edit/validate.bqn::ValidateCurrency`.

That helper is an older editor validation surface with a hard-coded JPY/ILS set, while the canonical registry currently owns JPY / ILS / USD and is already exposed to editor code by `src/application/editor_currency.bqn`.

The result was an ownership split:

```text
canonical registry says USD is supported
Account List legacy helper says USD is invalid
```

A read-only Account selector therefore could reject a valid canonical Commodity before it even inspected admitted Accounts.

## Change

Account List now admits a nonempty explicit currency filter through the canonical registry owner exposed by `editor_currency.bqn`.

An empty currency argument remains semantically different from a default currency: it means **no currency filter**. Therefore Account List does not call `ResolveDefault` or silently narrow the result to the configured editor default.

The registry observation is also lazy: an ordinary Account List with no currency filter does not open an additional currency-registry observation merely because that capability exists. The registry is loaded only when a caller supplies a nonempty explicit currency filter.

Unsupported explicit values still fail closed with a direct diagnostic.

## Preserved behavior

No change is made to:

- canonical Account loading;
- role filtering;
- combined role + currency filtering;
- source order;
- preferred-role stable partitioning;
- the existing contract that an unknown role filter simply selects no Accounts;
- UI selector policy or physical ordering beyond the already-owned preferred-role relation.

## Evidence

`checks/check-edit-bqn-account-list-registry.sh` adds a synthetic USD Asset and USD Expense to a canonical fixture and proves:

1. `--currency USD` is admitted because USD is registry-supported;
2. JPY rows do not leak into the USD result;
3. role + currency masks compose exactly;
4. unsupported EUR remains an error;
5. Account List no longer depends on `validate.bqn` for currency admission.

The existing Account List check continues to protect role masks, all-account output, preferred-role stable partitioning, shell argument routing, and Account writer safe-publication behavior.

## Decision

`src_edit/account_list_cmd.bqn` is reviewed.

Its array filtering/stable-partition kernel is retained. The only production change is replacing the stale hard-coded currency helper with the canonical registry owner while preserving the no-filter effect lifetime.

The normal Phase 6 cursor can advance to:

`src_edit/account_validate_cmd.bqn`
