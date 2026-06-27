# expected/

## Status

- `incomeAnchor` cycle mode is now implemented in `src_next/cycle.bqn`.
- Compact golden output (`src_next_summary.txt`) is fixed in this directory.
- This fixture is connected to `tools/check.sh` via `check-src-next-golden.sh`.

## Golden output

The compact golden contains the grep-filtered minimal report summary surface
used by `checks/check-src-next-golden.sh` for diff-based regression checks.
