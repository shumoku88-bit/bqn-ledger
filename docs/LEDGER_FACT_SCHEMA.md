# Canonical ledger fact schema

Status: current canonical Actual/Plan Facts with explicit Domain/Layer semantics
Owner: canonical Journal admissions / `src/ledger/facts.bqn`
Public evidence: `fixtures/ledger-facts-phase1-proof/`

## Boundary

`facts.Project ⟨canonicalAdmission, admittedAccounts⟩` accepts only:

- a successful canonical Journal admission result;
- a strict aligned admitted Account table.

It does not accept a report context, source path, raw Journal/TSV text, historical transaction carrier, Cube, TBDS, or section ViewModel. It performs no I/O and reads no clock.

Production Account identity, accounting type, optional default Commodity, declaration order, metadata, and source rows come from canonical `accounts.journal` through `src/ledger/account_journal_admission.bqn`. Household classification does not travel through the Account Fact carrier; it is admitted independently from `household.toml`. Retained legacy/test helpers may still construct the same narrow Account coordinates from `account_admission.bqn`, but canonical read authority is `accounts.journal`.

`src/ledger/snapshot.bqn` exposes `BuildFromAccounts` as the pure composition boundary for an already-admitted Account table:

```text
admitted Account table + raw Journal + currency registry
  -> complete Journal admission
  -> canonical Transaction/Posting Facts
```

The retained `snapshot.Build` convenience entry still performs legacy `accounts.tsv` admission for older proof surfaces; production canonical application adapters use `account_journal_admission.bqn` and pass its Account table to the same Fact projection. Neither path returns partial Facts after admission or projection failure, and the snapshot owner performs no source I/O.

`transaction_rows.bqn` provides the narrow source-ordered Transaction→Posting join for editor/recent consumers; `amount_text.bqn` formats exact coefficient/scale pairs without currency or report policy. Strict legacy config/cycle definitions remain separate non-Fact admission results documented in `CONFIG_CYCLE_ADMISSION.md`.

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

It does not own source paths, account currency lookup, decimal normalization, domain partitioning, or cross-source Plan resolution. In particular, an Actual `plan-id` may refer to separately admitted canonical `plan.journal`; accepting that relation is cross-source behavior, not Account policy or report behavior.

## Result

```text
{
  state,
  transactions,
  postings,
  sources,
  domains,
  accounts,
  layers,
  diagnostics
}
```

On any projection invariant failure, `state` is `error`, diagnostics are nonempty, and Transaction/Posting fact columns are empty. No partial numeric Facts are returned.

## Transaction Facts

All columns have length `transactions.count`.

| column | meaning |
|---|---|
| `index` | dense snapshot-local transaction index |
| `source_index` | join to the Source table |
| `transaction_id` | admitted durable event ID or admitted physical snapshot identity |
| `identity_kind` | provenance of that identity |
| `source_start_line`, `source_end_line` | original Journal transaction range |
| `date_text` | admitted strict ISO date |
| `date_ordinal` | proleptic Gregorian arithmetic coordinate |
| `description` | admitted transaction description/memo |
| `status_marker` | admitted source status marker |
| `metadata` | closed admitted source metadata retained as key/value evidence |
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
| `source_index` | join to the Source table |
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

### Source table

`index`, `name`; one independently admitted Transaction/Posting Fact result has one explicit physical source even when it is empty: `actual.journal` or `plan.journal`. Transaction and Posting Facts carry `source_index=0`. Native `entitlement.journal` is a separate StockOrigin/Transfer relation and is not projected into accounting Postings. Cross-source consumers retain source-qualified durable references rather than treating snapshot-local indices from different Fact results as interchangeable.

### Domain table

`index`, `code`; order follows complete source declarations. A valid empty canonical Journal retains its admitted source/domain contract rather than fabricating Transaction or Posting evidence.

### Account table

Canonical `src/ledger/account_journal_admission.bqn` admits Account identity, accounting type/role, optional default Commodity, declaration metadata, and source order before Fact projection. Account keys are unique and the projected Account columns are aligned.

The Fact table exposes aligned `index`, `key`, `currency`, `role`, `type`, `metadata`, and `source_row` columns in admitted Account order, including Accounts with no Postings. Posting Facts join by Account index and require a declared Account Commodity, when present, to match the Transaction domain.

Household-only classifications such as Asset selection, stable Envelope identity, historical Expense/Fulfillment routing, Cycle, and Daily Target policy are not Account Fact columns. They are independently admitted from `household.toml` / `envelope.toml` by their named policy owners and remain explicit cross-source evidence where required. The Account Fact axis has only Asset, Liability, Equity, Income, and Expense roles.

### Layer table

`index`, `name`; order follows canonical admission's explicit `declared_layers`. Transaction layers must occur in that table. A valid empty source still retains its source-layer contract without fabricating a Transaction or Posting.

## Retained legacy Plan proof boundary

`plan_snapshot.Build ⟨planLines,admittedAccounts,registry⟩` remains a legacy/test Plan-only proof surface, and the retained companion admission family can still prove historical TSV compatibility. Those helpers are not the production Household source authority.

Production canonical Plan admission reads `plan.journal`, reuses the accounting Account axis, and projects Transaction/Posting evidence through `facts.Project`. Entitlement admission instead publishes native StockOrigin and Transfer arrays against stable Envelope identities; it never receives Account coordinates.

## Required invariants

- every Fact family is column-aligned;
- every Transaction has at least one Posting;
- normalized Posting coefficients sum to zero per Transaction;
- dates are strict valid Gregorian text before ordinal conversion;
- Transaction IDs are nonempty and unique;
- every Transaction and Posting joins one explicit admitted Source; cross-source local indices are never silently combined;
- every Transaction domain and layer is explicit and declared; source-specific empty Domain/Layer requirements stay in source admission;
- Account keys are unique and Account columns align;
- every Posting Account exists and its declared Commodity matches the Transaction domain when present;
- Posting/Transaction/Account/Domain/Layer joins use bounded dense indices;
- invalid admission never becomes partial Facts;
- declaration-only Actual remains valid when its source/domain/account evidence satisfies canonical admission.

## Public proof

The retained public fixture proves:

```text
3 Actual transactions / 7 postings
3 Plan transactions / 6 postings
1 native Entitlement StockOrigin / 1 Transfer (outside the Fact schema)
1 three-posting split transaction
4 admitted accounting Accounts
1 JPY domain
1 actual layer
exact transaction zero sums
stable event/posting IDs
source transaction and posting lines
durable completed-Plan metadata retained on Transaction Facts
```

Trial Balance and Recent remain observable consumers of these Facts. Their fixture assertions establish values and transaction structure independently of the removed Household-policy carrier columns.

## Not in this schema

- no Household classification or Envelope policy columns on Account Facts;
- no all-report context or section fields;
- no Cube/TBDS materialization;
- no generic Select/Join/Group/Pivot API;
- no human/compact/JSON formatting;
- no path/config/default/fallback behavior;
- no private source evidence.
