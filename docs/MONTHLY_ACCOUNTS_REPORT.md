# Retained Monthly Accounts report

Status: Portfolio P5 destination proof

Owners:

- `src/accounting/month_account_movement.bqn` — dense exact Month × Account movement;
- `src/sections/monthly_accounts.bqn` — retained human-only Matrix.

Input is canonical Actual Facts, one explicit domain, and strict half-open calendar-month coordinates `[first_month,last_month_exclusive)`. The capability enumerates every month and every admitted Account before selecting Postings, so empty months, empty Actual, and zero-posting Accounts remain explicit zero cells.

```text
rows    = YYYY-MM ascending
columns = Accounts in admitted selected-domain order
cell    = signed exact sum of Actual Postings for month and Account
```

Each nonzero cell retains source-qualified Posting references; zero cells have no contributors. All selected coefficients normalize to one exact scale. Month totals, Account totals, and a grand total are checked independently and must reconcile. Because all Accounts in one domain are included, each valid month remains zero-sum.

Portfolio P1 renders human output only. The displayed `Total` column and `Range total` row are reconciliation evidence, not extra Matrix measures. No compact/JSON surface exists.

Monthly closing, debit/credit submatrices, role summaries, and YTD Cards are intentionally absent.

Failure is closed: wrong source, unknown domain, invalid/nonascending month coordinates, normalization/sum overflow, or reconciliation failure returns no Matrix. Valid empty Actual returns the full requested month and Account axes with exact zero cells.

Public proof covers JPY January movement plus explicit empty February, ILS mixed-scale March plus empty April, USD empty Actual, source-qualified contributors, strict invalid ranges/domains, deterministic axes, and a human golden.

Production routing remains unchanged until atomic cutover.
