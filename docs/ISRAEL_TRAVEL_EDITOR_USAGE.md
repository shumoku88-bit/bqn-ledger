# Israel Travel Editor Usage

Status: current operational guide / predeparture implementation in progress
Owner: editor / travel capture
Canonical: yes
Exit: revise after the integrated four-path rehearsal; keep current while these travel capture commands are in use.

This guide currently documents the completed capture paths. All examples use synthetic names and amounts; verify that required real accounts already exist before travel use. The editor does not create accounts.

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

ILS cash expenses and the user's confirmed-JPY card expenses continue to use `tools/edit journal add`. They preserve `trip_id=israel-2026` and `payment=cash|card` through the existing generic metadata path. Full four-path examples will be added at integrated rehearsal closure.
