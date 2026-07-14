# Israel Travel Editor Usage

Status: current operational guide / predeparture ready
Owner: editor / travel capture
Canonical: yes
Exit: keep current while these travel capture commands are in use.

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

## Ordinary cash, Wise, and debit capture

ILS cash and Wise balance expenses each use the ordinary journal once. They may share one ILS expense account; the `from` account and `payment` metadata distinguish the payment path:

```bash
# ILS cash
tools/edit --base "$BASE" journal add \
  --date 2026-07-20 --memo "synthetic meal paid in cash" \
  --from "assets:wallet-ils" --to "expenses:trip-ils" \
  --amount "42.50" --currency ILS \
  --meta trip_id=israel-2026 --meta payment=cash \
  --yes --post-check lint

# Wise ILS balance
tools/edit --base "$BASE" journal add \
  --date 2026-07-20 --memo "synthetic meal paid by Wise" \
  --from "assets:prepaid-ils" --to "expenses:trip-ils" \
  --amount "42.50" --currency ILS \
  --meta trip_id=israel-2026 --meta payment=card \
  --yes --post-check lint
```

SMBC is a debit path, not a credit-card liability. Record only the JPY amount confirmed by the bank, from an existing JPY asset to a JPY expense. Do not also record the displayed ILS amount. A trip-specific JPY expense may keep food or transit detail in the memo until `trip_id` reporting is sufficient to return to ordinary expense accounts:

```bash
tools/edit --base "$BASE" journal add \
  --date 2026-07-20 --memo "synthetic transit paid by debit" \
  --from "assets:bank-jpy" --to "expenses:trip-jpy" \
  --amount "1800" --currency JPY \
  --meta trip_id=israel-2026 --meta payment=debit \
  --yes --post-check lint
```

These paths preserve `trip_id=israel-2026` and `payment=cash|card|debit` through the existing generic metadata path. Journal `lint` is a mixed-currency-safe source-integrity check; it does not add currencies or broaden the full report. If it fails, the editor restores exact pre-append bytes only when no later writer changed the target. `--post-check none` is not the standard travel solution.

Before real use, confirm that every account shown in the command exists with the expected role and currency. All account names above are synthetic examples; do not copy private account names into public documentation. Accounts are never created automatically by travel capture. Friend pending events are not projected into the ordinary journal. Return-home friend finalization is not implemented. Correction/reversal for friend and exchange source events remains unselected and must not be improvised through the ordinary journal.
