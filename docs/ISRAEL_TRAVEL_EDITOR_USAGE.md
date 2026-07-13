# Israel Travel Editor Usage

Status: current operational guide / predeparture implementation in progress
Owner: editor / travel capture
Canonical: yes
Exit: revise after the integrated four-path rehearsal; keep current while these travel capture commands are in use.

This guide currently documents the completed capture paths. All examples use synthetic names and amounts; verify that required real accounts already exist before travel use. The editor does not create accounts.

## JPY to ILS exchange event

An exchange preserves the JPY handed over and ILS received as two observations. It is not an expense or income and is not written to `journal.tsv`.

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

Review both amounts and account names, then replace `--dry-run` with `--yes`. Both accounts must already exist with the selected currency. JPY source amounts use zero fractional digits; ILS target amounts permit at most two. The editor does not calculate or save a rate, call a market API, value one amount in the other currency, change balances, or create accounts.

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

Blank/comment lines follow the existing loader convention. Every data row and exchange ID is validated before append. Duplicate IDs and malformed existing data fail closed.

## Friend-paid pending event

When a friend pays in ILS, record a pending source event rather than an ordinary journal expense:

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

After reviewing the exact preview, replace `--dry-run` with `--yes` to append. This writes only `<base>/friend_travel_events.tsv`; it does not write `journal.tsv`, create a liability or expense, convert the ILS amount, or finalize a JPY amount.

The source has no header. Blank and comment lines follow the existing loader convention and are ignored. Every data row has exactly nine columns:

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

The return-home JPY finalization writer is not implemented. Correction/reversal is also not yet selected; do not edit or reinterpret an event through the ordinary journal.

## Ordinary cash and card capture

ILS cash expenses and the user's confirmed-JPY card expenses continue to use `tools/edit journal add`. They preserve `trip_id=israel-2026` and `payment=cash|card` through the existing generic metadata path. The default journal `--post-check lint` is a mixed-currency-safe source-integrity check; it does not add currencies or broaden the full report. If that check fails, the editor restores exact pre-append bytes only when no later writer changed the target. `--post-check none` is not the standard travel solution. Full four-path examples will be finalized at integrated rehearsal closure.
