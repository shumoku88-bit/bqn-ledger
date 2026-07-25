# Israel 2026 Travel Funding and Settlement Lifecycle — 2026-07-25

Status: active plan / first finite characterization slice selected
Owner: currency / travel capture / settlement / balances
Canonical: yes for the Israel 2026 travel funding and settlement lifecycle; broader currency policy remains elsewhere
Exit: archive after physical cash, own-card, friend-paid, and Wise paths can be captured and settled without double counting, with synthetic end-to-end verification and a separate production-readiness checkpoint

## Purpose

Represent the complete Israel 2026 travel money lifecycle without collapsing different economic meanings into one ambiguous journal path.

The required user journeys are:

1. exchange JPY in Japan for physical ILS cash, spend part of it in Israel, exchange the remainder back to JPY after returning, and explain any retained or lost remainder;
2. record the user's ordinary card purchases once at the issuer-confirmed JPY amount;
3. retain a friend's ILS payments as pending source facts, finalize them after return at a human-confirmed JPY amount, create the JPY liability and expense once, and later record repayment;
4. record Wise balance exchanges while preserving both observed currency amounts and the accounts that held each currency;
5. record Wise card spending without counting the currency exchange and the purchase as two expenses.

The lifecycle is not one universal cross-currency journal. It is a composition of separately owned rails:

```text
asset exchange
  physical cash exchange or Wise balance exchange

ordinary spending
  physical ILS cash, Wise ILS balance, or confirmed-JPY own-card expense

pending source fact
  friend-paid purchase before JPY finalization

settlement
  friend JPY finalization and later repayment

read models
  per-currency asset positions and JPY obligations, never one mixed-currency total
```

## Whole-trip topology

```text
Japan before departure
  JPY cash/account
    -> observed JPY-to-ILS exchange
  physical ILS cash

  JPY bank/Wise balance
    -> observed JPY-to-ILS Wise exchange
  Wise ILS balance

During travel
  physical ILS cash
    -> ordinary ILS expenses

  Wise ILS balance
    -> ordinary ILS expenses paid by Wise card

  Japanese card
    -> ordinary JPY expense at issuer-confirmed JPY amount

  friend pays in ILS
    -> pending friend-travel source event

After return
  remaining physical ILS cash
    -> observed ILS-to-JPY exchange or explicit explained remainder

  remaining Wise ILS balance
    -> observed ILS-to-JPY Wise exchange, retained ILS asset, or another explicit later action

  pending friend events
    -> human-confirmed JPY expense and friend liability
    -> later ordinary JPY repayment
```

## Current verified foundation

The repository already has public-synthetic foundations for:

- ordinary ILS spending through the native Journal;
- ordinary JPY own-card spending through the native Journal;
- a pure friend-travel JPY finalization validator and one-row preview;
- a pure JPY-to-ILS exchange validator and structured preview;
- currency-aware account and exact-decimal validation;
- native Journal as the only production Actual source.

The current gaps are concrete:

1. the exchange validator is directionally fixed to JPY source and ILS target;
2. the exchange contract does not yet explicitly distinguish physical-cash accounts from Wise balance accounts while preserving the same asset-exchange meaning;
3. return-home ILS-to-JPY exchange is not admitted;
4. exchange events are not safely persisted or included in a selected balance consumer;
5. pending friend-event storage and atomic JPY finalization writing remain unselected;
6. Wise card behavior has not been characterized for pre-converted ILS spending versus purchase-time automatic conversion;
7. there is no narrow whole-trip view showing separate ILS holdings and JPY obligations with contributor provenance.

## Selected accounting meanings

### A. Physical cash exchange

An outbound cash exchange records two primary observations:

```text
source_account  = explicit JPY cash or JPY account
source_currency = JPY
source_amount   = actual JPY handed over

target_account  = explicit physical ILS cash account
target_currency = ILS
target_amount   = actual ILS received
```

A return exchange records the opposite observed asset movement:

```text
source_account  = explicit physical ILS cash account
source_currency = ILS
source_amount   = actual ILS handed over

target_account  = explicit JPY cash or JPY account
target_currency = JPY
target_amount   = actual JPY received
```

Neither direction is an expense, income, market valuation, or one-amount Journal row. Both observed amounts remain primary facts. A derived rate must never replace them.

### B. Physical ILS cash spending

Ordinary spending from physical ILS cash remains owned by the native Journal:

```text
assets:<physical ILS cash> -> expenses:<category>-ILS
currency=ILS
trip_id=israel-2026
payment=cash
```

The expense is counted exactly once in ILS. The preceding exchange is not another expense.

### C. User's ordinary Japanese card

A purchase charged by the user's ordinary Japanese card is recorded once through the native JPY Journal at the issuer-confirmed JPY amount:

```text
liabilities:<card-JPY> -> expenses:<category>-JPY
currency=JPY
trip_id=israel-2026
payment=card
```

The merchant's displayed ILS amount may remain receipt or memo evidence, but it is not a second canonical expense and does not create a second ILS posting lifecycle in this selected operating path.

### D. Friend-paid local purchase

At purchase time, the friend's payment remains a pending source event:

```text
date
party
item_or_category
original_amount
original_currency=ILS
payer=friend
trip_id=israel-2026
source_event_id
status=pending
```

After return, the user and friend confirm one final JPY amount. The existing pure finalization contract previews exactly one canonical JPY expense/liability row:

```text
liabilities:<friend-JPY> -> expenses:<travel category>-JPY
currency=JPY
source_event_id=<source event>
trip_id=israel-2026
```

Later repayment uses the ordinary Journal:

```text
assets:<JPY account> -> liabilities:<friend-JPY>
currency=JPY
trip_id=israel-2026
payment=friend-settlement
```

The pending ILS amount is preserved as source evidence. It must not also enter expense totals. Finalization creates the sole canonical expense for this path, and repayment clears the liability without creating another expense.

### E. Wise balance exchange

A Wise exchange has the same asset-exchange meaning as a cash exchange, but the account location is different and must remain explicit:

```text
source_account  = assets:<Wise JPY balance>
source_currency = JPY
source_amount   = actual JPY debited by Wise

target_account  = assets:<Wise ILS balance>
target_currency = ILS
target_amount   = actual ILS credited by Wise
```

The reverse direction uses the actual ILS debited and JPY credited. Fees, when separately observed, require an explicit later decision; they must not be silently invented from the difference between a market rate and the observed amounts.

### F. Wise card spending from an existing ILS balance

When Wise spends from an already-held ILS balance, the purchase is an ordinary single-currency ILS Journal transaction:

```text
assets:<Wise ILS balance> -> expenses:<category>-ILS
currency=ILS
trip_id=israel-2026
payment=wise-card
```

The earlier JPY-to-ILS Wise exchange is an asset exchange, not another expense.

### G. Wise purchase-time automatic conversion

Wise may convert currency at purchase time instead of spending an already-held ILS balance. The repository does not yet have enough observed statement evidence to select one source contract for this case.

A later characterization must determine whether Wise exposes enough evidence to represent:

```text
one observed JPY-to-ILS exchange
linked to
one ordinary ILS purchase
```

or whether the safest operating choice is a single confirmed funding-currency expense with the foreign amount retained only as source evidence.

The design must never count both representations as independent expenses. It must use actual Wise evidence rather than infer a conversion from market rates.

## Account-location boundary

Currency and location are independent facts. These balances must not collapse merely because they use ILS:

```text
physical ILS cash
Wise ILS balance
```

Likewise, JPY cash, a Japanese bank account, a Wise JPY balance, a card liability, and a friend liability have different operational meanings.

The selected account for every exchange, spending, finalization, and repayment action must be explicit and already existing. No account may be inferred from prefixes, currency alone, payment method, or trip identifier.

## Required read models

The first useful trip consumer is a narrow read-only position and obligation result, not a universal mixed-currency travel total:

```text
Israel 2026

ILS assets
  Physical cash acquired       +₪...
  Physical cash spending       -₪...
  Physical cash exchanged back -₪...
  Physical cash explained      -₪...
  Physical cash remaining       ₪...

  Wise ILS acquired            +₪...
  Wise ILS card spending       -₪...
  Wise ILS exchanged back      -₪...
  Wise ILS remaining            ₪...

JPY obligations and settlement
  Friend expenses finalized    +¥...
  Friend repayments            -¥...
  Friend liability remaining    ¥...

  Confirmed own-card spending   ¥...
```

This output must not add ILS and JPY. Each subtotal must retain contributor provenance to admitted exchange events, pending/finalized friend events, or native Journal transactions/postings. Dense totals must not become the only evidence surface.

## Source ownership boundary

| User action | Semantic owner | Canonical expense timing |
|---|---|---|
| Exchange JPY for physical ILS cash | exchange-event source | no expense |
| Exchange balances inside Wise | exchange-event source | no expense |
| Spend physical ILS cash | native Journal | once in ILS |
| Spend an existing Wise ILS balance | native Journal | once in ILS |
| Use ordinary Japanese card | native Journal | once at confirmed JPY amount |
| Friend pays in ILS | pending friend-event source | no expense yet |
| Finalize friend amount in JPY | friend finalization plus native Journal append | once in JPY |
| Repay friend | native Journal | no new expense |
| Explain retained/lost ILS | separately selected explicit event or operating rule | only according to its selected meaning |

No generic unified event log, Currency axis, valuation layer, or automatic source projection is selected by this plan.

## Ordered finite slices

Each slice requires a separate PR, exact scope review, checks, and merge. Completion of one does not authorize the next.

1. **Integrated travel-rail ownership characterization**
   - inventory the current exchange validator, writer proposal, storage assumptions, and directional constraints;
   - inventory the existing friend pending/finalization ownership and the ordinary Journal paths used for own-card, ILS cash, Wise ILS spending, and friend repayment;
   - characterize the minimum metadata and account-location facts needed to distinguish physical cash, Wise balances, ordinary card, and friend settlement;
   - identify every possible double-counting boundary;
   - characterize the available public-synthetic Wise evidence and leave purchase-time automatic conversion unresolved if evidence is insufficient;
   - use public synthetic facts only;
   - perform no runtime write, source mutation, report output, or private-data access.

2. **Bidirectional account-explicit exchange pure contract**
   - admit JPY-to-ILS and ILS-to-JPY directions;
   - support explicitly supplied physical-cash or Wise balance accounts without inferring account type from names;
   - preserve both observed amount texts and exact precision rules;
   - expose structured preview and diagnostics only;
   - perform no storage or balance mutation.

3. **Exchange-event safe append**
   - select one storage contract;
   - add duplicate identity, stale-write, backup or equivalent recovery, post-check, and rollback boundaries;
   - do not automatically project exchange legs into the native Journal.

4. **Friend-paid pending source-event safe append**
   - select storage for the already-defined pending friend-event contract;
   - preserve immutable source identity, original ILS facts, and pending status;
   - perform no JPY finalization in the same slice.

5. **Return-home atomic friend finalization writer**
   - atomically finalize one pending event, persist duplicate-prevention evidence, and append exactly one JPY expense/liability transaction;
   - preserve the existing pure validation contract;
   - leave later repayment on the ordinary Journal path.

6. **Wise card evidence characterization**
   - distinguish spending from an existing ILS balance from purchase-time automatic conversion;
   - inspect only public synthetic statement shapes or user-supplied redacted examples;
   - select no general card subsystem, market-rate logic, or automatic conversion without evidence.

7. **Narrow per-account position and obligation read models**
   - calculate physical ILS cash, Wise ILS balance, and friend JPY liability separately;
   - retain contributor provenance and fail closed on malformed or mismatched evidence;
   - expose confirmed own-card JPY spending without converting ILS expenses.

8. **Synthetic whole-trip rehearsal**
   - acquire physical ILS cash;
   - acquire Wise ILS balance;
   - make physical-cash and Wise-card ILS purchases;
   - record confirmed-JPY ordinary-card purchases;
   - capture friend-paid pending events, finalize them in JPY, and repay the liability;
   - exchange remaining physical and Wise ILS back to JPY or explicitly retain/explain the remainder;
   - prove no expense is duplicated and all balances are zero or explicitly explained.

9. **Production readiness checkpoint**
   - provide commands and a human-run checklist for the actual private ledger;
   - do not read, copy, print, or modify private `LEDGER_DATA_DIR` inside an implementation PR;
   - any real account creation or data edit requires explicit user-controlled operation and backup.

## Invariants

- Never add JPY and ILS.
- Never classify either exchange direction as expense or income.
- Preserve both observed amounts for every physical-cash or Wise exchange.
- Do not save only a derived rate.
- Do not fetch market rates or perform valuation.
- Keep physical cash and Wise balances separate even when both are ILS.
- Count physical-cash spending exactly once in ILS.
- Count Wise card spending exactly once under the selected evidence contract.
- Count ordinary Japanese-card spending exactly once at the issuer-confirmed JPY amount.
- Never count a friend's pending ILS source fact and finalized JPY expense as two expenses.
- Never count friend finalization and repayment as two expenses.
- Do not retroactively rewrite foreign-currency facts after JPY settlement.
- Do not auto-create accounts.
- Do not infer trip, currency, account location, payer, or payment method from account names or prefixes.
- Do not use private paths or values to select policy.
- Do not combine this work with strict-source Steps 2–5, M4, generic projection extraction, a Currency axis, valuation, or document-governance implementation.

## Current selected slice

Only Slice 1, the docs/test-boundary integrated travel-rail ownership characterization, is selected by the routing PR that introduces this plan. Runtime implementation remains unselected until that characterization is reviewed and merged.

The characterization must end with explicit answers to these finite questions:

1. Can the existing exchange source contract safely become bidirectional and account-explicit for both physical cash and Wise balances?
2. Which existing module owns each validation, preview, write, and read responsibility?
3. Which metadata is already preserved by the native Journal for `trip_id` and payment-path evidence?
4. What durable source is still missing for pending friend events and exchange events?
5. What Wise statement evidence is needed before purchase-time automatic conversion can be represented without double counting?
6. Which smallest next implementation slice is supported by the evidence?

## Relation to existing plans

- `ISRAEL_PREDEPARTURE_EDITOR_CAPTURE_COMPLETION-2026-07-13.md` remains the completed evidence for existing synthetic capture paths.
- `ISRAEL_TRAVEL_DAILY_CAPTURE_PLAN-2026-07-13.md` remains the completed semantic decision record for physical cash, confirmed-JPY own-card, friend-paid pending events, and ordinary ILS spending; this plan extends it with return exchange, Wise balances, and whole-trip settlement integration.
- `FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md` remains canonical for the friend pending-event and one-row JPY finalization meaning.
- `FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md` remains a parked implementation proposal until Slice 5 is separately selected.
- `TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md` remains broader background evidence, especially for separating exchange, spending, settlement, and valuation.
- `CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md` remains the broader mixed-ledger foundation.
- strict-source Steps 2–5 remain independently unselected.
- PR #354 remains paused and does not supply implementation authority for this lifecycle.
