# Account Balances Mock Notes

Status: **adopted**
Review state: `adopted`
Date: 2026-06-26
Adopted: 2026-06-26

## Question answered

各 account key の現在残高はいくらか。

## View type

```text
point-in-time balance / stock view
```

This is not a YTD summary.

- `Account Balances`: ある時点で account にいくら残っているか
- `YTD Summary`: 年初から今までにいくら動いたか

## Intended source when implemented

Implementation is not part of this mock.

Likely future basis:

```text
TBDS actual layer closing balances
```

## Include

- report date / as-of date
- basis line
- asset accounts
- liability accounts
- budget / envelope accounts, if these remain account-backed
- totals that help verify the view

## Exclude for now

- YTD movement
- cycle income / expense summary
- planned future payments
- daily amount / outlook
- advice text
- automatic interpretation such as "you should spend less"

## Review decisions (2026-06-26)

1. Budget / Envelope accounts → appear here AND in Envelope / Budget (両方に表示)
2. Liabilities → negative numbers
3. Totals → appear here (not moved to Balance Summary)
4. Zero-balance accounts → hidden by default
5. Accounts → grouped by role/type (as in mock)
6. This screen → adopted as independent screen

## Decision log

```text
review_state: adopted
human_decision: adopted as-is
notes: mock approved 2026-06-26. Budget/Envelope shown here too, liabilities negative, totals included, zero-balance hidden, grouped by role/type.
```
