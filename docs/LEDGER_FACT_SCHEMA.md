# Canonical ledger fact schema

Status: Phase 1B canonical admission and facts
Owner: `src/ledger/snapshot.bqn` / `src/ledger/facts.bqn`
Public evidence: `fixtures/ledger-facts-phase1-proof/`

## Boundary

`facts.Project ⟨completeAdmission, admittedAccounts⟩` accepts only:

- a successful complete Actual admission result;
- a strict aligned admitted Account table.

It does not accept a report context, source path, raw Journal text, historical transaction carrier, Plan/Budget rows, Cube, TBDS, or section ViewModel. It performs no I/O and reads no clock.

Destination code does not import `src_next`. Phase 1B moved transaction grammar, exact decimal, currency registry, strict Account admission, single-domain admission, complete multi-domain admission, and fact projection into `src/ledger`. Runtime/editor/tool/test callers now import the canonical admission owners directly; old module paths were physically deleted without wrappers. Compatibility callers may still construct the minimal Account key/currency carrier from their existing resolver, while the canonical snapshot proof uses strict Account admission.

`src/ledger/snapshot.bqn` is the pure composition boundary:

```text
already-read accounts.tsv lines + raw Journal + currency registry
  -> strict Account admission
  -> complete Journal admission
  -> canonical Transaction/Posting facts
```

It returns no partial facts after account, Journal, or projection failure and performs no source I/O.

## Canonical transaction structure boundary

`journal_transaction_structure.Parse(normalizedPartition)` is pure and admits exactly one already domain-normalized transaction partition. It owns:

- strict header/status/description grammar;
- supported, nonempty, unique transaction metadata;
- declared-account membership;
- normalized structural posting shape and zero sum;
- debit/credit side;
- durable or physical transaction identity and posting IDs;
- source transaction/posting lines;
- all-or-nothing transaction output.

It does not own source paths, account currency lookup, decimal normalization, domain partitioning, or cross-source Plan resolution. In particular, an Actual `plan-id` may refer to separately admitted `plan.tsv`; accepting that reference is canonical cross-source behavior, not the old historical parser profile.

## Result

```text
{
  state,
  transactions,
  postings,
  domains,
  accounts,
  layers,
  diagnostics
}
```

On any projection invariant failure, `state` is `error`, diagnostics are nonempty, and Transaction/Posting fact columns are empty. No partial numeric facts are returned.

## Transaction Facts

All columns have length `transactions.count`.

| column | meaning |
|---|---|
| `index` | dense snapshot-local transaction index |
| `transaction_id` | admitted durable event ID or admitted physical snapshot identity |
| `identity_kind` | provenance of that identity |
| `source_start_line`, `source_end_line` | original Journal transaction range |
| `date_text` | admitted strict ISO date |
| `date_ordinal` | proleptic Gregorian arithmetic coordinate |
| `description` | admitted transaction description |
| `layer_index` | index into Layer table |
| `domain_index` | index into Domain table |
| `calculation_scale` | exact normalized coefficient scale for that transaction domain |
| `txn_id` | admitted optional transaction metadata |
| `plan_id` | admitted optional durable Plan relationship |
| `allocation_id` | admitted optional allocation relationship |
| `execution_envelope` | admitted optional execution-envelope relationship |
| `actual_event_id` | admitted optional external Actual relationship |

`transaction_id` values are unique within the admitted snapshot. Snapshot-local `index` is a join coordinate, not a durable external identity.

## Posting Facts

All columns have length `postings.count`.

| column | meaning |
|---|---|
| `index` | dense snapshot-local posting index and contributor coordinate |
| `posting_id` | admitted transaction identity plus transaction-local posting index |
| `transaction_index` | join to Transaction Facts |
| `transaction_posting_index` | position inside the source transaction |
| `date_ordinal` | duplicated arithmetic date coordinate for selection without object traversal |
| `account_index` | join to Account table |
| `layer_index` | join to Layer table |
| `domain_index` | join to Domain table |
| `coefficient` | exact signed normalized integer coefficient |
| `scale` | decimal scale for `coefficient` |
| `side` | admitted debit/credit side |
| `source_line` | original posting line |
| `source_coefficient`, `source_scale`, `amount_text` | exact source amount provenance before normalization |

A numeric amount is the pair `(coefficient, scale)`. Consumers never combine rows with different domains or scales without an explicit exact normalization/partition rule.

## Side tables

### Domain table

`index`, `code`; order follows complete source declarations. A valid empty Journal still has at least one explicit domain.

### Account table

`src/ledger/account_admission.bqn` admits account evidence before fact projection. Currency is explicit and registry-supported; account keys and metadata keys are unique; malformed or unsupported metadata fails without partial accounts. Missing role remains an `account_role_unclassified` warning with an empty role, never prefix inference.

The table exposes aligned `index`, `key`, `currency`, `role`, `type`, `budget`, `budget_group`, `spend_class`, `kind`, `envelope_role`, metadata, and source-row columns in source order, including accounts with no postings. Posting Facts join by Account index and require account currency to match transaction domain.

### Layer table

`index`, `name`; order is first admitted transaction occurrence. Empty Actual has an empty Layer table.

## Required invariants

- every fact family is column-aligned;
- every transaction has at least one posting;
- normalized posting coefficients sum to zero per transaction;
- dates are strict valid Gregorian text before ordinal conversion;
- transaction IDs are nonempty and unique;
- domains are explicit and declared;
- account keys are unique and account columns align;
- every posting account exists and its currency equals the transaction domain;
- posting/transaction/account/domain/layer joins use bounded dense indices;
- invalid admission never becomes partial facts;
- declaration-only Actual is valid when domain/account evidence is explicit.

## Phase 1A proof

The public fixture proves:

```text
3 transactions
7 Actual postings
1 three-posting split transaction
8 admitted accounts (including zero-posting Budget accounts)
1 JPY domain
1 actual layer
exact transaction zero sums
stable event/posting IDs
source transaction and posting lines
durable completed-Plan metadata retained on Transaction Facts
```

Trial Balance and Recent remain current-engine outputs in this slice. Their observable fixture assertions establish the values and transaction structure that later narrow capabilities must derive from these facts.

## Not in this schema

- no all-report context or section fields;
- no Plan/Budget fact admission yet;
- no Cube/TBDS materialization;
- no Select/Join/Group/Pivot API yet;
- no human/compact/JSON formatting;
- no path/config/default/fallback behavior;
- no private source evidence.
