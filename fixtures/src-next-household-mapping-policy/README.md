# src-next-household-mapping-policy

Minimal fixture for `src_next` household mapping metadata visibility.

It covers explicit `role=expense`, `budget=...`, config-backed `budget_group` policy labels, direct `spend_class=...`, missing group metadata, and a non-expense transfer.

The expected output covers only `src_next` diagnostic household policy summary fields. It does not define food remaining or daily remaining report output.

The intended configurable household report policy contract is documented in `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md`.
