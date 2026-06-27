# report-mocks

Status: **mock review workspace**

This directory stores terminal report screen mocks for one-screen-at-a-time review.

## Rule

Do not create a full 13-screen mock at once.

Create one screen mock, review it, then decide:

```text
adopt / revise / reject / merge into another screen / defer
```

## File pair convention

Each mock screen should have two files.

```text
SCREEN_NAME.mock.txt
SCREEN_NAME.notes.md
```

| File | Role |
|---|---|
| `*.mock.txt` | static terminal output mock |
| `*.notes.md` | question, scope, non-goals, review state |

## Current first mock

```text
ACCOUNT_BALANCES.mock.txt
ACCOUNT_BALANCES.notes.md
```

`Account Balances` is a point-in-time balance view. It is not a YTD summary.

## Safety

Mocks are static examples.

They must not:

- read `data/*.tsv`
- write `data/*.tsv`
- change `src_next` behavior
- become production output without a separate implementation decision
