# Israel ILS Cash Lifecycle Plan — 2026-07-25

Status: active plan / first finite design slice selected
Owner: currency / travel capture / balances
Canonical: yes for the Israel 2026 ILS cash lifecycle; broader currency policy remains elsewhere
Exit: archive after outbound exchange, ILS cash spending, return exchange, zero-or-explained remainder, and a synthetic round-trip verification are implemented and separately verified

## Purpose

Treat the user's physical ILS cash as one continuously traceable asset from acquisition through travel spending and return-home reconversion.

The required lifecycle is:

```text
JPY cash or JPY account
  -> observed JPY-to-ILS exchange
ILS physical cash
  -> ordinary ILS cash spending
remaining ILS physical cash
  -> observed ILS-to-JPY return exchange
JPY cash or JPY account
```

This is an asset-lifecycle requirement, not an FX valuation feature. The ledger must preserve the actually handed-over and actually received amounts for each exchange. It must not infer market value, fetch rates, or add JPY and ILS.

## Current verified foundation

The repository already has synthetic-only public capture paths for:

- ordinary ILS cash spending through the native Journal;
- confirmed-JPY card spending through the native Journal;
- friend-paid pending travel events;
- JPY-to-ILS exchange events retaining both observed amounts.

The missing operational connection is narrower:

1. the current exchange contract is shaped around JPY source and ILS target;
2. return-home ILS-to-JPY exchange is not yet an admitted event direction;
3. exchange events do not currently contribute to an ILS cash-position read model;
4. no selected read-only view proves the remaining physical ILS balance across acquisition, spending, reconversion, and explained remainder.

## Selected accounting meaning

### Outbound exchange

An outbound exchange records two primary observations:

```text
source_currency = JPY
source_amount   = actual JPY handed over
target_currency = ILS
target_amount   = actual ILS received
```

It is not an expense, income, valuation, or one-amount Journal row.

### ILS cash spending

Ordinary spending from physical ILS cash remains owned by the native Journal:

```text
assets:現金-ILS -> expenses:<category>-ILS
currency=ILS
trip_id=israel-2026
payment=cash
```

The expense is counted exactly once in ILS.

### Return exchange

A return exchange records the opposite observed asset exchange:

```text
source_currency = ILS
source_amount   = actual ILS handed over
target_currency = JPY
target_amount   = actual JPY received
```

It is not a negative travel expense and does not retroactively revalue earlier ILS spending.

### Explained remainder

Any ILS not spent or exchanged back must remain visible until explicitly explained. Examples include retained notes or coins, donation, loss, or an exchange desk refusing small denominations. The first implementation must not invent a generic adjustment mechanism. A later finite slice must select the narrowest explicit representation supported by observed travel use.

## ILS cash-position equation

For one selected trip and one selected physical ILS account:

```text
ILS received in admitted exchange events
+ other explicitly admitted ILS cash inflows
- ordinary Journal outflows from the ILS cash account
- ILS handed over in admitted return-exchange events
- separately admitted explained remainder events
= remaining physical ILS cash
```

JPY legs remain available as exchange provenance but do not enter the ILS balance arithmetic.

## Required read model

The first useful consumer is a narrow read-only travel cash-position result, not a broad travel report:

```text
Israel 2026 — ILS cash position

Acquired by exchange       +₪...
Cash spending              -₪...
Exchanged back             -₪...
Explained remainder        -₪...
--------------------------------
Cash remaining              ₪...
```

The checked result must retain enough provenance to trace every subtotal to either:

- an admitted exchange-event identity and ILS leg; or
- an admitted native Journal transaction/posting affecting the selected ILS cash account.

Dense totals must not become the only evidence surface.

## Ordered finite slices

Each slice requires a separate PR, exact scope review, checks, and merge. Completion of one does not authorize the next.

1. **Round-trip exchange contract characterization**
   - inventory the current exchange validator, writer, storage shape, and directional assumptions;
   - decide whether the existing contract can safely admit both directions or whether a distinct return-exchange event kind is required;
   - use synthetic public facts only;
   - no writes, Journal projection, report output, or production data.

2. **Return-exchange pure contract**
   - admit an explicit ILS source account and JPY target account;
   - retain both observed amount texts;
   - preserve exact currency precision rules;
   - expose structured preview and diagnostics only;
   - no storage or balance mutation.

3. **Return-exchange safe append**
   - add checked persistence using the existing safe-write, duplicate identity, stale-write, post-check, and rollback boundaries;
   - do not project either exchange leg into the Journal automatically.

4. **ILS cash-position pure read model**
   - consume one supplied native Journal snapshot plus supplied exchange-event rows;
   - select one trip and one explicit ILS cash account;
   - calculate only ILS quantities;
   - preserve contributor provenance and fail closed on malformed or mismatched evidence.

5. **Narrow human output and public read entry**
   - expose the cash-position result without adding FX, valuation, mixed-currency totals, or a Currency axis;
   - keep the selected trip and account visible in output.

6. **Synthetic outbound-to-return rehearsal**
   - acquire ILS, make multiple ILS cash purchases, return-exchange the remainder, and prove zero or explicitly explained remaining cash;
   - exercise duplicate, malformed, stale-write, and rollback evidence where applicable.

7. **Production readiness checkpoint**
   - provide commands and a human-run checklist for the actual private ledger;
   - do not read, copy, print, or modify private `LEDGER_DATA_DIR` inside an implementation PR;
   - any real account creation or data edit requires explicit user-controlled operation and backup.

## Invariants

- Never add JPY and ILS.
- Never classify either exchange direction as expense or income.
- Preserve both observed amounts for every exchange.
- Do not save only a derived rate.
- Do not fetch market rates or perform valuation.
- Do not retroactively rewrite ILS expenses when JPY is received on return.
- Do not auto-create accounts.
- Do not infer the trip or physical cash account from name prefixes.
- Do not use private paths or values to select policy.
- Do not combine this work with strict-source Steps 2–5, M4, generic projection extraction, or document-governance implementation.

## Current selected slice

Only Slice 1, the docs/test-boundary characterization of the existing round-trip exchange ownership, is selected by the routing PR that introduces this plan. Runtime implementation remains unselected until that characterization is reviewed and merged.

## Relation to existing plans

- `ISRAEL_PREDEPARTURE_EDITOR_CAPTURE_COMPLETION-2026-07-13.md` remains the completed evidence for four synthetic capture paths.
- `ISRAEL_TRAVEL_DAILY_CAPTURE_PLAN-2026-07-13.md` remains the historical semantic decision record.
- `CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md` remains the broader mixed-ledger foundation.
- strict-source Steps 2–5 remain independently unselected.
- PR #354 remains paused and does not supply implementation authority for this lifecycle.
