# Fixture: future-journal-hard-error

Invalid fixture for the actual-only journal contract.

`journal.tsv` intentionally contains `2999-01-01`, which should always be after `system_today`. This must fail lint and report loading because future declarations belong in `plan.tsv`, not `journal.tsv`.

The same future date in `plan.tsv` is valid.
