# Israel Travel Editor Usage

Status: current operational guide / partial readiness only
Owner: editor / travel capture
Canonical: yes
Exit: revise after native Journal ILS admission, travel metadata admission, return exchange, or friend finalization writing changes the usable paths

This guide records what the current public editor can actually do. All examples use synthetic names and amounts. The editor never creates accounts, and no command here authorizes private-data inspection.

## Current readiness summary

| Path | Current status |
|---|---|
| JPY↔ILS exchange event | available bidirectionally through the account-explicit dedicated source-event editor |
| Friend-paid ILS pending event | available through dedicated source-event editor |
| Ordinary confirmed-JPY card/debit expense | available through native Journal |
| Ordinary physical ILS cash expense | available through supported-currency native Journal append when explicit ILS accounts exist |
| Ordinary Wise ILS balance expense | available through the same ILS path when spending an already-held ILS balance |
| `trip_id` / `payment` Journal metadata | admitted as native `trip-id` and `payment=cash|card|debit` |
| Friend JPY finalization write | pure preview exists; writer is not implemented |
| ILS/Wise remaining-balance view | not implemented |
| Wise purchase-time automatic conversion | unresolved pending statement evidence |

The dedicated exchange and friend sources do not affect the configured native Journal, Posting IR, Cube, TBDS, balances, or reports.

## Bidirectional JPY / ILS exchange event

An exchange preserves both explicitly observed source and target amounts. It is not an expense or income and is not written to the configured native Journal.

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

The same command supports return exchange by explicitly reversing the account/currency legs:

```bash
tools/edit --base "$BASE" travel exchange add \
  --date 2026-07-30 \
  --memo "synthetic return exchange" \
  --source-account "assets:cash-ils" \
  --source-amount "125.50" \
  --source-currency ILS \
  --target-account "assets:bank-jpy" \
  --target-amount "4800" \
  --target-currency JPY \
  --exchange-id israel-2026-exchange-return-0001 \
  --trip-id israel-2026 \
  --dry-run
```

Both directions use the same ten-column source contract. Precision follows each explicit leg: JPY has zero fractional digits and ILS permits at most two. The validator accepts only JPY→ILS or ILS→JPY, requires existing accounts whose currencies match the explicit legs, and never infers physical cash or Wise from account names.

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

The stable `journal add` surface accepts one explicit registry-supported currency and matching existing accounts. A confirmed JPY card/debit expense can be recorded with explicit JPY accounts and travel metadata:

```bash
tools/edit --base "$BASE" journal add \
  --date 2026-07-20 \
  --memo "synthetic transit paid by Japanese debit card" \
  --from "assets:bank-jpy" \
  --to "expenses:trip-jpy" \
  --amount "1800" \
  --currency JPY \
  --meta trip_id=israel-2026 \
  --meta payment=debit \
  --yes \
  --post-check lint
```

Record the bank/card issuer's confirmed JPY amount exactly once. The merchant-displayed ILS amount may remain in receipt evidence or memo, but it must not be entered as another expense.

`trip_id` is rendered as native `; trip-id: ...`; `payment` is restricted to `cash|card|debit`. Both remain generic Transaction IR metadata. They do not select accounts, infer currency, identify Wise semantics, create exchange events, or change report aggregation.

## Physical ILS cash and Wise ILS spending

Ordinary ILS spending uses the same native Journal path with explicit matching ILS accounts. For example, physical cash spending may use `--meta payment=cash`; spending from an already-held Wise ILS balance may use `--meta payment=card`. Account identity—not the payment metadata—distinguishes those assets.

```text
assets:<physical ILS cash> -> expenses:<category>-ILS
assets:<Wise ILS balance>  -> expenses:<category>-ILS
```

Do not convert an ILS purchase to an invented JPY amount, place it in the exchange source, or use the friend source as a substitute.

## Wise exchanges and Wise card behavior

A JPY↔ILS conversion inside Wise may be recorded by the exchange command using explicit Wise JPY and Wise ILS accounts, provided both accounts exist and both observed amounts satisfy their explicit currency precision. This still does not update Journal balances or reports.

Spending from an already-held Wise ILS balance can use an ordinary ILS Journal expense with explicit Wise ILS and expense accounts. This does not define purchase-time automatic conversion semantics.

Purchase-time automatic conversion remains unresolved. Do not create both a conversion and an expense unless actual Wise evidence supports one linked lifecycle without double counting.

## Current operational boundary

Before real use:

- verify every selected account exists with the expected currency;
- dry-run each dedicated source-event command first;
- keep exchange and friend-event sources backed up with the rest of the ledger data;
- use ordinary Journal append only with one explicit supported currency and matching existing accounts;
- treat `trip-id` and `payment` as evidence, not account/currency/FX inference;
- do not assume dedicated travel sources affect balances;
- use explicit source/target accounts and observed amounts for return exchange; do not infer direction or Wise semantics from names;
- do not improvise friend finalization, correction/reversal, or Wise automatic-conversion semantics.

The current ownership characterization is recorded in `docs/archive/audits/ISRAEL_TRAVEL_RAIL_OWNERSHIP_CHARACTERIZATION-2026-07-25.md`.
