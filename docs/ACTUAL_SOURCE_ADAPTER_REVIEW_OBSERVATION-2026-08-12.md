# Actual Source Adapter review observation — 2026-08-12

## Owner

`src/application/actual_source_adapter.bqn`

## Decision

Retain the production adapter unchanged.

Its apparent nested guards are not incidental control-flow residue. They define a short effect/admission lifetime:

```text
canonical Accounts admission
  -> read canonical actual.journal
  -> canonical Journal-root topology admission
  -> Snapshot.BuildFromAccounts
```

Each later capability is evaluated only after the earlier one succeeds.

In particular, invalid canonical Accounts must fail before the Actual file read. This matters at the application boundary because eager evaluation would turn an Account admission failure into an unrelated file-I/O failure when `actual.journal` is absent or unreadable.

The focused test now proves this boundary with a fixture that contains an invalid `accounts.journal` and deliberately contains no `actual.journal`. `Load` must return the Account admission error rather than attempt the Actual read.

The existing successful-path law continues to protect canonical Actual Facts shape, source coordinates, Account alignment, domain/layer identity, and Posting amount text.

## Protected ownership

- `canonical_household_sources.bqn` owns the physical `actual.journal` and `accounts.journal` basenames.
- `account_source_adapter.bqn` owns Account read/admission at the application boundary.
- `canonical_journal_root_admission.bqn` owns root include-topology admission.
- `snapshot.BuildFromAccounts` owns complete Actual Journal admission and Fact projection from already-admitted Accounts.
- `actual_source_adapter.bqn` owns only the ordered capability lifetime connecting those owners.

No generic source-loader abstraction is introduced. The current short-circuit structure is retained because it is the clearest expression of fail-closed effect sequencing.
