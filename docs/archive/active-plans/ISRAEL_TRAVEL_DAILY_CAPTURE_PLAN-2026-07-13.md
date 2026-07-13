# Israel Travel Daily Capture Plan — 2026-07-13

Status: active plan / docs-only finite design
Owner: currency / travel capture / editor routing
Canonical: yes; canonical path: `docs/archive/active-plans/ISRAEL_TRAVEL_DAILY_CAPTURE_PLAN-2026-07-13.md`
Exit: archive as completed after this docs-only design is reviewed and each implementation candidate remains explicitly selected, declined, or unselected through separate routing; this plan does not authorize implementation.

## Purpose and selected operating choice

This plan fixes the daily-capture meanings for the Israel trip without changing runtime or source data. The trip has exactly three payment paths plus the asset-exchange path needed to obtain local cash:

1. cash obtained by exchanging JPY for ILS;
2. the user's own card, recorded once at the card issuer's confirmed JPY amount;
3. a friend's ILS payment, retained as a pending friend-travel source event; and
4. ordinary spending from the acquired ILS cash asset.

For this trip, the stable grouping token is:

```text
trip_id = israel-2026
```

This document selects semantic rails only. It does **not** select or implement a source file, writer, fixture, account, report, UI, projection, or production-data change.

## Rail A — ILS cash acquisition is an exchange event

Exchanging JPY for ILS is an asset exchange, not an expense. The JPY handed over and ILS received are two observed primary facts. An effective rate may later be derived from them, but saving only a rate and losing either observed amount is forbidden.

Minimum candidate fields:

```text
date
memo
source_account
source_amount
source_currency
target_account
target_amount
target_currency
exchange_id
trip_id
```

For this trip, the intended fixed values are:

```text
source_currency = JPY
target_currency = ILS
target_account = assets:現金-ILS
trip_id = israel-2026
```

`source_account`, `source_amount`, and `target_amount` remain explicit observations. This docs plan does not resolve an actual source account or private amounts, and it does not create or verify the named target account.

An exchange event must not be represented as any of the following:

- travel expense or income;
- ordinary one-amount journal row;
- card usage or card settlement;
- friend liability or friend-paid event; or
- market valuation or FX-rate lookup.

### Candidate contract versus unresolved decisions

The field list above is a **candidate event contract**, not a storage schema. A later independently selected contract slice must decide validation details, including exact-decimal rules for each amount, admitted currencies, account descriptor checks, uniqueness and syntax of `exchange_id`, and privacy-safe rejection diagnostics.

The following are deliberately unresolved and must not be inferred or implemented by this PR:

- exchange source-file name or whether a dedicated file is used;
- header presence and exact serialized column order;
- `exchange_id` generation and durable uniqueness ownership;
- append writer, safe-write protocol, recovery, stale checks, and post-write evidence;
- whether and how accepted exchange events project into the journal or another checked ledger input;
- fees, reverse exchange, refunds, corrections, and gain/loss treatment.

Any future projection must preserve both observed amounts and must not disguise the exchange as one ordinary amount or as travel spending.

## Rail B — ILS cash spending uses the ordinary journal

ILS cash spending reuses the existing currency-aware ordinary journal rail:

```text
assets:現金-ILS
  -> expenses:<category>-ILS
```

Every such row must explicitly carry:

```text
currency=ILS
trip_id=israel-2026
payment=cash
```

This path reuses the existing currency-aware editor, exact-decimal validation, and same-currency account validation. It must fail closed on a currency/account mismatch. It does not introduce a separate cash-spending source log, a second foreign-expense record, or cross-currency arithmetic.

This plan does not create `assets:現金-ILS`, any expense account, or metadata admission. The displayed account shapes state intended meaning only; a future operation may use only already-existing, explicitly validated accounts.

## Rail C — the user's card uses the ordinary JPY journal once

The user's card purchase uses the existing ordinary JPY journal rail. The user records the card issuer's actually confirmed JPY amount exactly once, using existing JPY accounts/categories and the current ordinary daily-entry policy.

Candidate metadata:

```text
currency=JPY
trip_id=israel-2026
payment=card
```

For this selected operating choice, the original ILS display amount is not another canonical expense. The following are explicitly not created:

- a local-ILS card-usage source event;
- a pending card lifecycle;
- a card-settlement index;
- an ILS-to-JPY conversion;
- both an original ILS expense and a JPY expense for one purchase; or
- a new card subsystem.

This rail does not reinterpret the card issuer's confirmed JPY amount as FX valuation. It simply uses the already-existing JPY journal behavior. The plan does not resolve actual card accounts, category names, dates, private amounts, or production data.

### Metadata readiness boundary

`trip_id` and `payment` are not currently listed in `config/meta_schema.tsv`. This does not by itself prove that the current editor cannot preserve them: journal extension fields permit `key=value` tokens, and the current `ValidateMeta` boundary checks token structure rather than schema membership.

Before travel use, a separate synthetic-fixture readiness check should verify that:

```text
trip_id=israel-2026
payment=cash|card
```

passes journal add, safe append, lint, and reload without metadata loss or reinterpretation. That readiness check is unselected and is not implemented in this docs-only PR. This plan does not change `config/meta_schema.tsv`, editor behavior, fixtures, or source data.

## Rail D — friend-paid ILS purchases remain pending source events

When a friend pays in ILS, the purchase does not enter the ordinary journal at capture time. It follows the existing friend-travel contract as a pending source event with fields matching the existing pure validator:

```text
date
party
item_or_category
original_amount
original_currency
payer
trip_id
source_event_id
status
```

For this trip:

```text
original_currency = ILS
payer = friend
trip_id = israel-2026
status = pending
```

The detailed validation and final JPY one-row preview contract remains canonical in [FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md](FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md). In particular, the pending ILS amount is an observed source fact, not a canonical foreign expense, Posting IR row, JPY valuation, or ordinary journal row. The already-implemented return-home pure preview can produce the sole canonical JPY expense only from explicit human-confirmed finalization input.

This plan does not choose pending-event storage, append format, status mutation, finalization-index persistence, journal writer, or an atomic status/index/journal protocol. The friend atomic writer remains an independently unselected later candidate.

## Daily capture decision table

| User action | Semantic owner / destination | Canonical expense timing | Must not become |
|---|---|---|---|
| Obtain ILS cash with JPY | future exchange event | no expense at exchange | ordinary one-amount row or FX valuation |
| Spend acquired ILS cash | existing ordinary ILS journal | once, in ILS | separate cash log or JPY conversion |
| Pay with own card | existing ordinary JPY journal | once, at confirmed JPY amount | ILS usage lifecycle plus JPY duplicate |
| Friend pays in ILS | future pending friend-event append path | no expense until explicit JPY finalization | ordinary ILS journal expense |

## Candidate travel input surface and ownership boundary

A future small travel input surface may route intents as follows:

```text
travel cash
  -> existing journal add --currency ILS

travel card
  -> existing journal add --currency JPY

travel friend
  -> future pending friend-event append path

travel exchange
  -> future exchange-event append path
```

The router is presentation, selection, and dispatch only. Shell/UI must not independently interpret or duplicate:

- account roles or account existence;
- account/row currency matching;
- exact-decimal or minor-unit rules;
- source-event field validation, identity uniqueness, or status semantics;
- exchange semantics or friend-finalization semantics; or
- canonical expense timing.

Those meanings stay with the existing BQN editor or the future BQN-owned pure contract for each new source-event rail. The router may pass explicit user choices and display structured results; it must not parse human output or directly assemble semantic TSV rows.

## Independent finite implementation candidates

The following order is a routing backlog, not authorization. Each item requires a separate selection, design/recheck, scoped implementation, and review. Completing any candidate does not automatically select the next candidate or any other candidate.

1. **Friend-paid pending source-event storage and safe append**
   - choose storage only in that slice;
   - preserve the existing pure validator's field contract;
   - define safe append, duplicate identity rejection, recovery, and write evidence without selecting finalization.
2. **Exchange-event source contract, pure validation, and preview**
   - decide the unresolved contract details;
   - retain both observed amounts as primary facts;
   - perform no write and no journal projection.
3. **Exchange-event safe append and recovery boundary**
   - select storage/write ownership separately from pure validation;
   - define stale/duplicate checks, backup or equivalent recovery, and unambiguous post-write evidence.
4. **Travel input router over existing and new semantic owners**
   - route only after the relevant owners expose checked interfaces;
   - keep shell/UI free of accounting and source-event meaning.
5. **Narrow read-only travel cash-remaining view, conditionally**
   - consider only if ordinary selected-currency ILS balances cannot safely represent exchange acquisition and remaining cash;
   - first document concrete evidence of that insufficiency;
   - do not create a broad travel report, valuation, cross-currency total, or M4 by default.
6. **Return-home atomic friend finalization writer**
   - only after separate selection under the friend-finalization plan;
   - define one atomic pending-status transition, durable finalization-index update, and one JPY journal append with recovery ownership and write evidence.

This ordering does not bundle the candidates. Candidate 1 does not select 2 or 6; candidate 2 does not select 3; candidate 3 does not select 4 or 5; and no completion selects strict-source Steps 2–5, M4, or another currency campaign.

## Safety invariants

All future work derived from this plan must preserve these boundaries:

- Never add JPY and ILS.
- Never classify exchange as expense or income.
- Never count a card's ILS display amount and confirmed JPY amount as two expenses.
- Never treat a friend-paid ILS source event as a canonical foreign expense.
- Preserve both observed exchange amounts; do not replace them with only a rate.
- Do not create or modify source TSV in this docs-only PR.
- Do not read production `LEDGER_DATA_DIR` in this PR.
- Do not resolve or record actual account names beyond the explicitly selected generic target shape, private amounts, or private paths.
- Do not auto-create accounts.
- Do not perform FX arithmetic, valuation, or market-rate fetches.
- Do not add a Currency axis.
- Do not select M4.
- Do not select strict-source Steps 2–5.
- Do not select the friend atomic writer.
- Do not mix Ledger Observatory PR #211 changes into this plan or its PR.

## Scope of this docs-only PR

Allowed changes:

- this canonical plan;
- the finite `TODO.md` routing entry;
- minimal active-plan inventory and docs-router links.

Forbidden changes:

- runtime, BQN modules, shell writers, editor commands, source TSV, fixtures, account definitions, reports, UI, or production data;
- metadata schema or journal contract implementation;
- any read or discovery of production `LEDGER_DATA_DIR`;
- implementation of any candidate above.

## Dependencies and routing

- [FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md](FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md) owns the existing friend pending-event validation and return-home one-row JPY pure-preview/finalization boundary.
- [TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md](TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md) retains broader travel multi-currency background. This Israel plan supersedes that intake only for the selected Israel daily-capture choices, especially the decision not to use a card usage/settlement lifecycle.
- [CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md](CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md) records the existing ordinary currency-aware daily-use foundation and its independently unselected residual candidates.
- `TODO.md` is the sole current finite-work selector. Implementation remains unselected after this docs design.

## Validation for this PR

Run without resolving or reading production data:

```bash
env -u LEDGER_DATA_DIR rtk bash ./tools/check.sh
rtk tools/coverage
git diff --check
```
