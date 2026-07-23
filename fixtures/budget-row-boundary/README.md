# Fixture: budget-row-boundary

Invalid fixture used by `tools/check-budget-row-lint.sh`.

`actual.journal` and `plan.tsv` intentionally contain `budget:*` rows. They must fail lint/strict validation because manual budget allocation belongs in `budget_alloc.tsv`.

`budget_alloc.tsv` contains the same kind of budget movement and is valid there.
