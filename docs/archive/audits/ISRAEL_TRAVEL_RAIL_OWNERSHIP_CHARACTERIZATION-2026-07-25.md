# Israel 2026 Travel Rail Ownership Characterization — 2026-07-25

Status: completed ownership characterization / no next implementation slice selected
Owner: currency / travel capture / settlement / editor / read models
Canonical: yes for the current repository ownership snapshot
Exit: supersede when one selected implementation changes the observed ownership or operational readiness

## Finite question

What currently owns each Israel 2026 travel funding and settlement path, which paths are actually writable through the public editor, where can double counting occur, and what is the smallest separately selectable next slice supported by current public-synthetic evidence?

## Scope and evidence boundary

This characterization used only public repository code, checks, and documentation. It did not read or modify private `LEDGER_DATA_DIR`, create accounts, change runtime, alter source data, or infer Wise behavior from market knowledge.

Observed owners include:

- `src_next/travel_exchange_event.bqn`;
- `src_edit/travel_exchange_add_cmd.bqn`;
- `tools/lib/edit-bqn-travel.sh`;
- `src_next/friend_travel_source_event.bqn`;
- `src_edit/travel_friend_add_cmd.bqn`;
- `src_next/friend_travel_jpy_finalization.bqn`;
- `tools/edit-bqn` and `src_edit/journal_block_add_cmd.bqn`;
- `src_next/journal_profile_stage1.bqn` and `src_next/journal_posting_ir_stage2a.bqn`;
- `src_next/balances.bqn`;
- current travel documentation and public checks.

## Executive result

The repository is not at the originally assumed predeparture boundary.

Already implemented and publicly checked:

1. JPY-to-ILS exchange-event validation, storage, safe append, stale-write rejection, post-check, and rollback;
2. friend-paid ILS pending-event validation, storage, safe append, stale-write rejection, post-check, and rollback;
3. a pure one-row JPY friend-finalization preview;
4. ordinary native Journal writing for JPY integer transactions.

Not currently implemented or admitted:

1. ordinary ILS native Journal transactions;
2. ILS exact-decimal native Journal postings;
3. `trip_id` and `payment` metadata in the native Journal profile/writer;
4. ILS-to-JPY return exchange;
5. atomic friend finalization writing and durable finalization/status mutation;
6. exchange-event or friend-event read-model consumption;
7. ILS balance reporting;
8. Wise purchase-time automatic-conversion semantics.

The first practical blocker is therefore not exchange persistence or friend pending storage. It is the inability to record ordinary ILS spending in the only production Actual source.

## Ownership inventory

| User action | Semantic owner | Write owner | Durable source | Current consumer | Current state |
|---|---|---|---|---|---|
| JPY to physical ILS cash | `travel_exchange_event.bqn` | `travel_exchange_add_cmd.bqn` plus safe-write shell | `travel_exchange_events.tsv` | none | implemented, outbound only |
| JPY to Wise ILS balance | same exchange owner, with explicit Wise accounts | same exchange writer | `travel_exchange_events.tsv` | none | structurally possible for outbound JPY→ILS if accounts exist |
| ILS to JPY return exchange | no admitted direction | none | none | none | explicitly rejected by current validator/check |
| Friend pays in ILS | `friend_travel_source_event.bqn` | `travel_friend_add_cmd.bqn` plus safe-write shell | `friend_travel_events.tsv` | pure finalization only when supplied manually | implemented pending capture |
| Finalize friend amount in JPY | `friend_travel_jpy_finalization.bqn` | none | no durable finalization index/status transition | none | pure preview only |
| Repay friend in JPY | native Journal ordinary transaction | native Journal writer | configured native Journal | JPY context/report path | possible as ordinary JPY transaction |
| Ordinary Japanese card/debit spending | native Journal ordinary transaction | native Journal writer | configured native Journal | JPY context/report path | possible in JPY, travel metadata blocked |
| Spend physical ILS cash | intended native Journal transaction | current writer/parser reject it | none through public editor | no ILS balance/report consumer | blocked |
| Spend existing Wise ILS balance | intended native Journal transaction | current writer/parser reject it | none through public editor | no ILS balance/report consumer | blocked |
| Wise purchase-time automatic conversion | no selected source contract | none | none | none | unresolved; evidence absent |

## Exchange rail

### Implemented ownership

`travel_exchange_event.bqn` owns the pure ten-field contract, account existence/currency checks, exact positive amounts, precision, trip identity, exchange identity uniqueness, full existing-source validation, and structured preview.

`travel_exchange_add_cmd.bqn` reads `accounts.tsv` and `travel_exchange_events.tsv`, delegates semantics to the pure owner, and emits an `APPEND` protocol.

`tools/lib/edit-bqn-travel.sh` owns checked file creation/append, snapshots, stale-write rejection, recoverable backup, post-write validation, and rollback.

The public check proves dry-run, exclusive first creation, checked append, duplicate rejection, malformed-source rejection, stale-write rejection, rollback, and no Journal mutation.

### Directional boundary

The current contract is not bidirectional:

- source account/currency must be JPY;
- target account/currency must be ILS;
- JPY source precision is zero fractional digits;
- ILS target precision is at most two;
- the public check explicitly expects a reversed ILS→JPY request to fail unchanged.

The ten-column storage shape itself is directional only through its values. No separate event-kind column exists. Current evidence supports widening one account-explicit exchange contract to the admitted pairs `JPY→ILS` and `ILS→JPY`; it does not require a distinct return-exchange event kind.

Such widening must still update pure validation, existing-row validation, CLI usage, precision selection by currency, public checks, and any later consumer. It must not infer physical cash versus Wise from account names.

## Friend-paid rail

### Pending capture is already durable

The pending source contract is fixed to nine columns, `original_currency=ILS`, `payer=friend`, `trip_id=israel-2026`, and `status=pending`.

The public editor already safely creates and appends `friend_travel_events.tsv`. The check covers duplicate IDs, exact-decimal/precision failures, malformed existing rows, stale writes, rollback, concurrent first creation, and interrupted creation.

Therefore pending friend-event storage and safe append are not missing future slices. Earlier plans that describe them as unselected are stale relative to current code.

### Finalization remains incomplete

`friend_travel_jpy_finalization.bqn` validates one supplied pending event, explicit finalization date, positive JPY integer, explicit existing JPY liability/expense accounts, and a supplied finalization-ID set. It returns exactly one JPY preview row or zero rows with diagnostics.

Missing ownership remains:

- loading a pending source event by immutable identity;
- durable finalized/pending state transition;
- durable duplicate-prevention index;
- native Journal append integration;
- atomicity, recovery, and retry across source status/index/Journal;
- a current read model for remaining friend liability.

The original ILS amount remains evidence and must not become a second expense. Finalization is the sole expense for this rail; later repayment clears the liability.

## Native Journal travel-spending rail

### Current writer is JPY-only

The public `journal add` command resolves the configured native Journal and rejects any explicit currency other than JPY.

`journal_block_add_cmd.bqn` additionally requires:

- canonical signed exact integers;
- every posting commodity to be JPY;
- every resolved posting account to use JPY.

The Stage 1 parser also requires a JPY commodity declaration, accepts only exact-integer postings, and validates `currency` metadata only when its value is JPY.

Consequently, current native Journal production routing cannot admit an ordinary `42.50 ILS` cash or Wise purchase.

### Travel metadata is not admitted

The current Journal writer metadata whitelist and Stage 1 supported metadata do not include `trip_id`/`trip-id` or `payment`.

`config/meta_schema.tsv` also does not define those keys.

Therefore commands shown in the current travel guide with:

```text
trip_id=israel-2026
payment=cash|card|debit
```

are not valid through the current native Journal append path. Generic TSV metadata validation from the pre-cutover editor does not establish native Journal metadata admission.

### Operational-document drift

`docs/ISRAEL_TRAVEL_EDITOR_USAGE.md` currently labels the travel paths predeparture ready and shows ordinary ILS cash/Wise commands. Those commands conflict with the current JPY-only native Journal writer/parser.

The same guide states that `trip_id` and `payment` are preserved, but the native writer/parser reject those keys.

`docs/AI_CODEMAP.md` also names `checks/check-israel-travel-four-path-rehearsal.sh`, but that check file is absent from current main.

These are documentation-governance findings, not runtime evidence.

## Read-model ownership

`travel_exchange_events.tsv` and `friend_travel_events.tsv` are not admitted into Posting IR, Cube, TBDS, balances, or another selected travel consumer.

`balances.BuildSelected` explicitly fails closed for a selected currency other than JPY. It therefore cannot show:

- physical ILS cash acquired/spent/remaining;
- Wise ILS balance acquired/spent/remaining;
- return-exchanged ILS;
- any combined trip position.

A future read model must keep physical cash and Wise balances as separate explicit accounts and must not add ILS and JPY.

## Double-counting boundaries

### Exchange versus expense

Exchange events currently never enter the Journal, so they cannot currently duplicate an expense. They also do not affect any selected asset balance, leaving acquisition and remaining-cash reporting incomplete.

Future consumption must treat exchange ILS legs as asset inflow/outflow only.

### Friend source fact versus final JPY expense

The pending ILS amount is source evidence only. One later finalized JPY Journal transaction is the sole expense. Repayment is a liability-clearing transfer.

### Ordinary Japanese card

The issuer-confirmed JPY amount is the sole canonical expense. Merchant-displayed ILS may be memo/receipt evidence but not another expense.

### Wise pre-converted balance

One JPY→ILS asset exchange followed by one ILS expense is valid. The exchange must not be counted as spending.

### Wise purchase-time automatic conversion

No representation is selected. Required evidence before selection includes actual transaction identifiers, debited and credited amounts/currencies, fee evidence, balance movement, and linkage between conversion and purchase. A market-rate reconstruction is insufficient.

## Answers to the finite plan questions

### 1. Can the exchange contract become bidirectional and account-explicit?

Yes, the existing ten-field shape and explicit account descriptors support a single bidirectional contract in principle. Current validation and tests are direction-specific and must be widened deliberately. No evidence requires a separate return-exchange event kind.

### 2. Which modules own validation, preview, write, and read responsibilities?

- exchange validation/preview: `src_next/travel_exchange_event.bqn`;
- exchange source adapter: `src_edit/travel_exchange_add_cmd.bqn`;
- exchange write safety: `tools/lib/edit-bqn-travel.sh` plus safe-write helpers;
- friend pending validation/preview: `src_next/friend_travel_source_event.bqn`;
- friend pending adapter/write safety: `src_edit/travel_friend_add_cmd.bqn` and the same shell boundary;
- friend JPY finalization semantics: `src_next/friend_travel_jpy_finalization.bqn`;
- ordinary Actual write: `tools/edit-bqn` → `src_edit/journal_block_add_cmd.bqn`;
- native Journal admission: `src_next/journal_profile_stage1.bqn`;
- Posting IR adaptation: `src_next/journal_posting_ir_stage2a.bqn`;
- current balances consumer: `src_next/balances.bqn`;
- no current owner consumes exchange or friend-event sources into a travel read model.

### 3. Which travel metadata is currently preserved?

Neither `trip_id`/`trip-id` nor `payment` is admitted by the current native Journal writer/parser. Account identity and memo are the only presently usable path distinctions for ordinary JPY transactions without another selected metadata extension.

### 4. What durable source is still missing?

Exchange and pending friend sources already exist. Missing durable state is friend finalization/status/index ownership. Missing accounting integration is ordinary ILS Journal admission and later travel read-model consumption.

### 5. What Wise evidence is needed?

A redacted or synthetic statement shape must expose, where available:

- transaction identity;
- purchase identity and original amount/currency;
- balance debit amount/currency;
- conversion credit amount/currency;
- fee amount/currency;
- timestamps/order;
- pre/post balance or another linkage signal.

Without this, purchase-time automatic conversion remains unresolved.

### 6. What is the smallest supported next slice?

The leading candidate is a separate public-synthetic, test-only **native Journal ILS single-currency admission characterization**.

It should answer only whether one balanced two-posting ILS transaction with an exact decimal amount can pass, and what exact changes are required across:

- commodity declarations;
- posting amount representation;
- account-currency matching;
- Stage 1 Transaction IR;
- Stage 2A Posting IR numeric representation;
- complete-Journal validation;
- ordinary editor preview;
- downstream fail-closed boundaries.

It must not yet add runtime writing, mixed-currency totals, exchange projection, travel metadata, Wise semantics, or reports.

This candidate comes before bidirectional return exchange because outbound exchange and friend pending capture already work, while ordinary ILS spending is currently impossible in the production Actual source.

## Routing result

This characterization is complete. It selects no implementation automatically.

Recommended candidate order, each independently selectable:

1. native Journal ILS single-currency admission characterization;
2. native Journal ILS ordinary-add implementation, only if candidate 1 supports it;
3. travel metadata admission for `trip-id` and `payment` as a separate contract;
4. bidirectional account-explicit exchange validation and safe append;
5. friend atomic JPY finalization writer;
6. Wise statement evidence characterization;
7. narrow per-account position and obligation read models;
8. synthetic whole-trip rehearsal;
9. human-controlled production readiness.

## Non-actions

- no runtime, tests, fixtures, parser, writer, source, report, or account changes;
- no private-data access;
- no assumption that current documentation proves executable behavior;
- no selection of ILS admission, metadata, reverse exchange, friend finalization writing, Wise integration, or a travel report.
