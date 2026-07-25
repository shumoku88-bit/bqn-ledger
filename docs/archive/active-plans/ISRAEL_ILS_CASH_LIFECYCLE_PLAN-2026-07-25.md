# Israel 2026 Travel Funding and Settlement Lifecycle — 2026-07-25

Status: active lifecycle plan / usable ILS slice and travel metadata admission complete / no next continuation slice selected
Owner: currency / travel capture / settlement / editor / balances
Canonical: yes for the Israel 2026 travel funding and settlement lifecycle
Exit: archive after the required travel paths are implemented, synthetically rehearsed without double counting, and separately approved for human-controlled production use

## Purpose

Represent the complete Israel 2026 travel money lifecycle without collapsing asset exchange, ordinary spending, friend-paid source facts, JPY settlement, Wise balances, or reporting conversion into one ambiguous path.

Required user journeys:

1. exchange JPY in Japan for physical ILS cash, spend it, and later exchange or explicitly retain/explain the remainder;
2. record ordinary Japanese-card or debit spending once at the confirmed JPY amount;
3. capture friend-paid ILS purchases as pending source facts, finalize them once in JPY after return, and later repay the liability;
4. record JPY↔ILS exchanges between explicit Wise balance accounts;
5. record Wise-card spending without counting both exchange and purchase as independent expenses;
6. view physical ILS cash, Wise ILS balance, JPY card spending, and friend JPY obligations without adding JPY and ILS.

## Current authority

The current repository ownership and readiness snapshot is:

- `docs/archive/audits/ISRAEL_TRAVEL_RAIL_OWNERSHIP_CHARACTERIZATION-2026-07-25.md`

The executable operating guide is:

- `docs/ISRAEL_TRAVEL_EDITOR_USAGE.md`

This plan records lifecycle meaning and candidate order. It does not override observed runtime boundaries in the characterization or select a continuation automatically.

## Whole-trip topology

```text
Japan before departure
  JPY cash/account
    -> observed JPY-to-ILS exchange event
  physical ILS cash

  Wise JPY balance
    -> observed JPY-to-ILS exchange event
  Wise ILS balance

During travel
  physical ILS cash
    -> ordinary ILS expense

  Wise ILS balance
    -> ordinary ILS expense paid by Wise card

  Japanese card/debit
    -> one confirmed JPY expense

  friend pays in ILS
    -> pending friend source event

After return
  remaining physical or Wise ILS
    -> observed ILS-to-JPY exchange, retained ILS asset, or explicit explanation

  pending friend event
    -> one human-confirmed JPY expense and friend liability
    -> later JPY repayment clears liability
```

This is a composition of separate rails, not a universal cross-currency Journal.

## Current verified reality

### Implemented

- JPY→ILS exchange pure validation and structured preview;
- durable `travel_exchange_events.tsv` creation/append through the public editor;
- duplicate, malformed-source, stale-write, post-check, rollback, and interrupted-first-write protection for exchange events;
- friend-paid ILS pending-event pure validation and preview;
- durable `friend_travel_events.tsv` creation/append through the public editor with equivalent safety boundaries;
- pure one-row JPY friend-finalization validation/preview;
- ordinary native Journal writing for one explicit registry-supported currency;
- exact ILS and USD ordinary append through the same admission/carrier boundary;
- selected-domain JPY/ILS/USD balances without cross-currency totals;
- native Journal `trip-id` and `payment=cash|card|debit` metadata admission and exact generic Transaction IR preservation;
- native Journal as the only production Actual source.

### Not implemented or not admitted

- ILS→JPY return exchange;
- atomic friend finalization/status/index/Journal writing;
- exchange/friend source consumption by Posting IR, Cube, TBDS, balances, or a travel read model;
- ILS selected balances;
- Wise purchase-time automatic-conversion semantics;
- a complete synthetic whole-trip rehearsal.

## Accounting meanings

### Asset exchange

Every physical-cash or Wise balance exchange preserves:

```text
source_account
source_amount
source_currency
target_account
target_amount
target_currency
exchange_id
trip_id
```

Both observed amounts are primary facts. A derived rate must not replace them. Exchange is neither expense nor income.

Physical cash and Wise balances remain distinct accounts even when both use ILS.

### Physical ILS cash spending

Intended meaning:

```text
assets:<physical ILS cash> -> expenses:<category>-ILS
```

This is one ILS expense. The preceding exchange is not another expense.

Current status: available through ordinary supported-currency Journal append with explicit matching ILS accounts. Optional `payment=cash` and `trip-id` remain evidence only.

### Wise ILS balance spending

Intended meaning:

```text
assets:<Wise ILS balance> -> expenses:<category>-ILS
```

This is one ILS expense when Wise spends from an already-held ILS balance.

Current status: available when spending an already-held explicit Wise ILS asset account. This does not define purchase-time automatic conversion.

### Ordinary Japanese card or debit

Record one transaction at the issuer/bank-confirmed JPY amount. Merchant-displayed ILS may remain receipt or memo evidence but must not become a second expense.

Current status: ordinary supported-currency transactions are available. Optional `trip_id=<id>` and `payment=cash|card|debit` CLI metadata render as native `trip-id` / `payment` and remain generic evidence without report interpretation.

### Friend-paid purchase

At purchase time, preserve one pending ILS source fact. After return, a human confirms one JPY amount and explicit JPY liability/expense accounts.

The finalized JPY transaction is the sole canonical expense for this rail. The pending ILS amount remains evidence. Later repayment clears the liability and is not another expense.

Current status: pending capture is durable; finalization is pure preview only.

### Wise purchase-time automatic conversion

No representation is selected. A later characterization must use actual redacted or synthetic Wise statement evidence and must prevent one conversion plus one purchase from becoming two expenses.

## Current source ownership

| Source | Owner | Meaning | Journal effect |
|---|---|---|---|
| configured native Journal | complete-source admission, Stage 1 partition parser, Stage 2A carrier, editor | production Actual transactions | yes, one supported currency per ordinary transaction |
| `travel_exchange_events.tsv` | exchange pure owner plus dedicated editor | two-currency asset-exchange observations | none currently |
| `friend_travel_events.tsv` | friend pending pure owner plus dedicated editor | pending friend-paid source facts | none currently |
| supplied friend finalization request | pure finalization owner | proposed one-row JPY expense/liability | preview only |

No generic unified event log is selected.

## Read-model requirement

A future narrow consumer should show separate domains:

```text
ILS assets
  physical cash acquired / spent / returned / remaining
  Wise ILS acquired / spent / returned / remaining

JPY obligations and spending
  friend finalized / repaid / remaining liability
  confirmed own-card or debit spending
```

It must preserve contributor provenance and must never add ILS and JPY.

## Completed characterization result

The ownership characterization originally established the pre-vertical-slice facts below. Items 4 and 5 are now completed; the remaining findings still route future work:

1. exchange and friend pending safe append already exist;
2. the current exchange contract is fixed to JPY→ILS but its explicit ten-column shape can support a single bidirectional contract in principle;
3. no evidence requires a separate return-exchange event kind;
4. ordinary ILS spending was the first practical blocker — resolved by the supported-currency Journal vertical slice;
5. `trip-id` and `payment` were absent — resolved by the travel metadata admission slice;
6. exchange/friend sources have no selected accounting consumer;
7. Wise automatic conversion lacks sufficient source evidence.

## Continuation slices and completion status

No incomplete candidate below is currently selected.

1. **Native Journal ILS single-currency admission characterization — completed**
   - public synthetic and test-only;
   - trace the minimum commodity, exact-decimal, account-currency, Stage 1, Stage 2A, source-validation, and downstream boundaries for one balanced ILS transaction;
   - no runtime write or report change.

2. **Native Journal ILS ordinary-add implementation — completed**
   - followed candidate 1's finite contract;
   - one explicit single-currency ILS transaction path;
   - no exchange projection, mixed totals, metadata expansion, or reports.

3. **Travel metadata admission — completed**
   - canonical native spelling is `trip-id` and `payment`;
   - CLI compatibility spelling is `trip_id` and `payment`;
   - `trip-id` is a nonempty safe opaque ID; `payment` is `cash|card|debit`;
   - parser/writer round-trip is checked; no consumer, inference, FX, or report grouping was added.

4. **Bidirectional account-explicit exchange**
   - admit JPY→ILS and ILS→JPY;
   - choose precision from explicit currencies;
   - preserve current source safety and no-Journal-projection boundary;
   - never infer cash versus Wise from names.

5. **Friend atomic JPY finalization writer**
   - durable status/finalization index plus exactly one native Journal append;
   - all-or-nothing recovery and retry;
   - repayment remains ordinary Journal work.

6. **Wise card evidence characterization**
   - use public synthetic or user-supplied redacted statement shapes;
   - distinguish existing-ILS-balance spending from purchase-time conversion.

7. **Narrow per-account position and obligation read models**
   - physical cash, Wise balance, and friend liability separately;
   - confirmed JPY card spending visible without converting ILS expenses.

8. **Synthetic whole-trip rehearsal**
   - acquire physical and Wise ILS;
   - spend through both paths;
   - record confirmed JPY card/debit spending;
   - capture, finalize, and repay friend events;
   - return or explain remaining ILS;
   - prove no duplicate expenses and zero-or-explained positions.

9. **Human-controlled production readiness checkpoint**
   - commands, backup, dry-run, account checks, and rollback checklist;
   - no private-data read or write inside implementation PRs.

## Invariants

- Never add JPY and ILS.
- Never classify exchange as expense or income.
- Preserve both observed amounts for every exchange.
- Do not save only a derived rate.
- Do not fetch market rates or perform valuation.
- Keep physical ILS cash and Wise ILS balances separate.
- Count each purchase exactly once under its selected rail.
- Never count a friend pending ILS fact and finalized JPY expense as two expenses.
- Never count friend finalization and repayment as two expenses.
- Do not retroactively rewrite foreign-currency evidence after JPY settlement.
- Do not auto-create accounts.
- Do not infer account location, payer, trip, payment path, or currency from account names.
- Do not use private paths or values to select policy.
- Do not combine this lifecycle with strict-source Steps 2–5, M4, generic projection extraction, a Currency axis, valuation, or document-governance runtime work.

## Relation to existing records

- `ISRAEL_TRAVEL_DAILY_CAPTURE_PLAN-2026-07-13.md` remains the historical semantic decision record, but its claims about current ILS Journal readiness are superseded by the current characterization.
- `FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md` remains canonical for one-row JPY finalization meaning.
- `FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md` remains a parked implementation proposal.
- `TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md` remains broader background on separating exchange, spending, settlement, and valuation.
- `CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md` remains historical mixed-ledger evidence; current ordinary Journal append and selected-domain balances use the supported-currency boundary.
- PR #354 remains paused and supplies no implementation authority for this lifecycle.
