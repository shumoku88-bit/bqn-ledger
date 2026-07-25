# Israel Travel Editor Usage

Status: current operational guide / partial readiness only
Owner: editor / travel capture
Canonical: yes
Exit: revise after native Journal ILS admission, travel metadata admission, return exchange, or friend finalization writing changes the usable paths

This guide records what the current public editor can actually do. All examples use synthetic names and amounts. The editor never creates accounts, and no command here authorizes private-data inspection.

## Current readiness summary

| Path | Current status |
|---|---|
| JPY→ILS exchange event | available through dedicated source-event editor |
| Friend-paid ILS pending event | available through dedicated source-event editor |
| Ordinary confirmed-JPY card/debit expense | available through native Journal, JPY only |
| Ordinary physical ILS cash expense | blocked by JPY-only native Journal writer/parser |
| Ordinary Wise ILS balance expense | blocked by JPY-only native Journal writer/parser |
| `trip_id` / `payment` Journal metadata | not admitted by current native Journal profile |
| ILS→JPY return exchange | not admitted by current exchange validator |
| Friend JPY finalization write | pure preview exists; writer is not implemented |
| ILS/Wise remaining-balance view | not implemented |
| Wise purchase-time automatic conversion | unresolved pending statement evidence |

The dedicated exchange and friend sources do not affect the configured native Journal, Posting IR, Cube, TBDS, balances, or reports.

## JPY to ILS exchange event

An exchange preserves the JPY handed over and ILS received as two observations. It is not an expense or income and is not written to the configured native Journal.

```bash
tools/edit --base "$BASE" travel exchange add \
  --date 2026-07-20 \
  --memo "synthetic airport exchange" \
  --source-account "assets:bank-jpy" \
  --source-amount "10000" \
  --source-currency JPY \
  --target-account "assets:cash-ils" \
  --target-amount "250.00" \
  --target-currency ILS \
  --exchange-id israel-2026-exchange-0001 \
  --trip-id israel-2026 \
  --dry-run
```

Review both amounts and account names, then replace `--dry-run` with `--yes`. Both accounts must already exist with the selected currency. JPY source amounts use zero fractional digits; ILS target amounts permit at most two.

The headerless `<base>/travel_exchange_events.tsv` source uses ten fixed columns:

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

Every data row and exchange ID is validated before append. Duplicate IDs, malformed existing data, stale writes, and post-check failure fail closed. The writer preserves backups or removes a failed first creation as appropriate.

Current limitation: the pure validator and public check intentionally reject ILS→JPY. Do not reverse the fields and assume that return exchange works.

## Friend-paid pending event

When a friend pays in ILS, record a pending source event rather than an ordinary Journal expense:

```bash
tools/edit --base "$BASE" travel friend add \
  --date 2026-07-20 \
  --party "synthetic friend" \
  --item "meal" \
  --amount "42.50" \
  --currency ILS \
  --payer friend \
  --trip-id israel-2026 \
  --source-event-id israel-2026-friend-0001 \
  --dry-run
```

After reviewing the exact preview, replace `--dry-run` with `--yes`. This writes only `<base>/friend_travel_events.tsv`; it does not write the configured native Journal, create a liability or expense, convert the ILS amount, or finalize a JPY amount.

The source has no header and exactly nine columns:

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

For this command, `original_currency=ILS`, `payer=friend`, `trip_id=israel-2026`, and `status=pending` are fixed contracts. IDs must be file-wide unique. Existing malformed or duplicate data causes the whole append to fail closed.

The pure return-home JPY preview exists, but the atomic writer, durable finalization index/status transition, and Journal append integration are not implemented. Do not manually reinterpret a pending event as already finalized.

## Ordinary confirmed-JPY card or debit expense

The current stable `journal add` surface supports the configured native Journal only in JPY. A confirmed JPY card/debit expense can be recorded with explicit existing JPY accounts:

```bash
tools/edit --base "$BASE" journal add \
  --date 2026-07-20 \
  --memo "synthetic transit paid by Japanese debit card" \
  --from "assets:bank-jpy" \
  --to "expenses:trip-jpy" \
  --amount "1800" \
  --currency JPY \
  --yes \
  --post-check lint
```

Record the bank/card issuer's confirmed JPY amount exactly once. The merchant-displayed ILS amount may remain in receipt evidence or memo, but it must not be entered as another expense.

Current native Journal metadata does not admit `trip_id`, `trip-id`, or `payment`. Do not add those options until a separate metadata contract is implemented and verified.

## Physical ILS cash and Wise ILS spending

These paths are required by the travel lifecycle but are not currently available through `tools/edit journal add`.

The public command rejects non-JPY currency, while the native Journal writer/parser require JPY commodity declarations and exact-integer postings. Commands such as the following are therefore illustrative intent only and must not be run as operating instructions:

```text
assets:<physical ILS cash> -> expenses:<category>-ILS
assets:<Wise ILS balance>  -> expenses:<category>-ILS
```

Do not convert an ILS purchase to an invented JPY amount, place it in the exchange source, or use the friend source as a substitute. Native Journal ILS admission requires a separately selected implementation.

## Wise exchanges and Wise card behavior

A pre-purchase JPY→ILS conversion inside Wise may be recorded by the existing exchange command using explicit Wise JPY and Wise ILS accounts, provided both accounts exist and the observed amounts satisfy the current JPY→ILS contract. This still does not update Journal balances or reports.

Spending from an already-held Wise ILS balance is currently blocked by the native Journal ILS limitation.

Purchase-time automatic conversion remains unresolved. Do not create both a conversion and an expense unless actual Wise evidence supports one linked lifecycle without double counting.

## Current operational boundary

Before real use:

- verify every selected account exists with the expected currency;
- dry-run each dedicated source-event command first;
- keep exchange and friend-event sources backed up with the rest of the ledger data;
- record only confirmed JPY ordinary transactions in the native Journal;
- do not assume dedicated travel sources affect balances;
- do not improvise ILS Journal blocks, return exchange, friend finalization, correction/reversal, or Wise automatic-conversion semantics.

The current ownership characterization is recorded in `docs/archive/audits/ISRAEL_TRAVEL_RAIL_OWNERSHIP_CHARACTERIZATION-2026-07-25.md`.
