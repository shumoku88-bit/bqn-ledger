# Sanitized report mock contract

This document defines how public report mocks may be created from real-shaped BQN Ledger output without publishing real household data.

The goal is to preserve the report surface, column widths, section order, density, and accounting shape while removing facts that can identify a person, place, routine, income timing, or private account state.

## Scope

This contract applies to public mock reports committed under `mocks/reports/`.

Public mock reports may be based on the shape of real output, but they must not contain real source data. They are design specimens, not household records.

## Required statement

Every public mock report generated from real-shaped output must include a visible note near the top:

```text
This is sanitized public mock output. It is not real household data.
```

## Sanitization rules

Before committing a report mock, replace or transform the following data.

| Data kind | Public mock handling |
|---|---|
| Personal names | Replace with role labels such as `person:friend_1` or remove entirely. |
| Store names | Replace with category labels such as `store:grocery_1`. |
| Hospital, clinic, pharmacy, or care names | Replace with `clinic:medical_1`, `store:pharmacy_1`, or similar generic labels. |
| Station names, addresses, regions, and local landmarks | Replace with `place:local_1`, `place:station_1`, or remove. |
| Bank, wallet, or account labels | Replace with `assets:bank_main`, `assets:wallet`, `liabilities:card_1`, and similar stable mock names. |
| Memo text | Rewrite as generic purpose labels. Do not keep distinctive wording. |
| IDs, phone numbers, URLs, emails, and account numbers | Remove completely or replace with obvious placeholders. |
| Exact income dates | Shift into a demo cycle or replace with `cycle_day_001` style labels. |
| Exact balances | Replace with synthetic balances that preserve sign, scale, and flow only when useful. |
| Distinctive amounts | Round, scale, or substitute synthetic values. Do not keep rare or identifying amounts. |
| Daily rhythm | Use cycle day labels, shifted dates, or sparse samples to avoid exposing real routines. |

## Allowed transformations

A public mock may preserve:

- section names
- report ordering
- column names
- alignment and approximate width
- sign conventions
- account role structure
- relative flow direction
- sample accounting invariants

A public mock must not preserve:

- exact source TSV rows
- exact real dates
- exact real balances
- exact real recurring payment timing
- distinctive personal memo wording
- real place or counterparty names

## Suggested public labels

```text
assets:bank_main
assets:wallet
liabilities:card_1
income:main
expenses:food
expenses:daily
expenses:medical
budget:daily
budget:flex
budget:reserve
store:grocery_1
store:daily_1
clinic:medical_1
place:local_1
person:friend_1
cycle_day_001
```

## Date handling

Prefer cycle-relative labels for public mocks:

```text
cycle_day_001
cycle_day_002
cycle_day_003
```

If calendar dates are needed for layout testing, use a fully synthetic demo period such as `2026-01-01..2026-01-14`. Do not use the real household cycle dates.

## Amount handling

Use one of these approaches:

1. `rounded`: keep approximate scale only, such as `1327` -> `1300`.
2. `scaled`: multiply all amounts by a fixed factor and round.
3. `synthetic`: replace with hand-written values that preserve the visual shape.
4. `ratio-only`: show `1.0x`, `0.7x`, or percentages instead of yen amounts.

For public GitHub mocks, `synthetic` is the safest default.

## Mock generation boundary

The recommended flow is:

```text
real report outside repo
  -> manual or scripted sanitization outside repo
  -> public mock text under mocks/reports/
  -> review before commit
```

Do not commit the real input report, intermediate unsanitized report, or raw source TSV to this repository.

## Review checklist

Before merging a public report mock, confirm:

- [ ] The file says it is sanitized mock output.
- [ ] No real person, place, institution, or store names remain.
- [ ] No real account names or account numbers remain.
- [ ] No exact real income dates or real cycle dates remain.
- [ ] No exact real balances remain.
- [ ] Memo text has been generalized.
- [ ] The mock still preserves the intended report surface.

## Relationship to sandbox data

The public `data/` directory and fixtures are sandbox data. Sanitized report mocks are different: they are allowed to preserve the shape of real output, but only after removing the real facts. They are a window into the report design, not into the household.
