# src-next-golden

Small public fixture for `src_next` compact golden checks and current-engine comparison analysis.

Purpose:
- Baseline case where cycle range, actual expense total, and plan expense total are intended to match the current engine comparison helper.
- Also demonstrates that ledger-like signed totals can be `0` while household expense totals are nonzero.
- Includes an out-of-cycle plan row that is visible as skipped projection evidence in `src_next`.

Classification note:
- A mismatch in `actual_expense_total` or `plan_expense_total` here is an **unknown / needs investigation** item first, then possibly a **regression candidate** if no design or fixture reason explains it.
