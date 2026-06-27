# src-next-income-anchor-golden

Public fixture for `src_next` incomeAnchor cycle mode.

## Purpose

- Fabricated fixture for `incomeAnchor` cycle mode.
- Acts as a bridge between the contract doc (`docs/SRC_NEXT_INCOME_ANCHOR_CYCLE_CONTRACT.md`) and the implementation.
- All values are intentionally fictional. Do not copy production `data/cycle.tsv` values into this fixture.

## Cycle semantics

- Cycle start (resolved): **2026-01-10** (most recent `income:example` in `journal.tsv`).
- Cycle end_exclusive (resolved): **2026-03-10** (next `income:example` in `plan.tsv` after journal max date).
- Resolved day_count: **59**.
- The interval is half-open: `[start, end_exclusive)`.
- `INC2` in `plan.tsv` (2026-03-10) is the cycle end anchor and falls outside the half-open interval.
- `PLAN_AFTER` in `plan.tsv` (2026-03-11) is after end_exclusive and appears as skipped plan evidence.

## Status

- `src_next/cycle.bqn` supports `mode incomeAnchor`.
- This fixture is connected to `tools/check.sh` via `check-src-next-golden.sh`.
- `expected/src_next_summary.txt` is the compact golden check surface.
