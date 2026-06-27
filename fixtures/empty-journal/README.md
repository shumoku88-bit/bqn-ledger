# Fixture: empty-journal

Tests the behavior of the system when `journal.tsv` is completely empty but `accounts.tsv`, `budget_alloc.tsv`, and `plan.tsv` exist. This simulates a "fresh start" scenario.

The system should not crash and should render zero values or appropriate defaults for metrics requiring history.
