# Fixture: envelope-plan

Future variable `plan.tsv` spending should reduce envelope exhaustion prediction through `accounts.tsv` `budget=...` mapping.

As of `2026-01-04`:

- `budget:daily` balance is 600 after three 100 actual food spends.
- rolling average spend is 100/day.
- future planned food spend on `2026-01-05` is 500 and maps to `budget:daily`.
- expected `env_days_until_empty` for `daily` is `(600 - 500) / 100 = 1`.

Without the plan-to-envelope projection, the prediction would be 6 days.
