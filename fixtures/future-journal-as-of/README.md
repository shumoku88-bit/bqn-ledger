# Fixture: future-journal-as-of

Characterization fixture for `--as-of` behavior when `journal.tsv` contains rows after the observation date.

Run golden checks with:

```sh
bash checks/golden_check.sh fixtures/future-journal-as-of 2026-01-03
```

Important current behavior captured here:

- Snapshot/balances use the cube snapshot at `as_of`.
- YTD and cycle summary use matching journal rows only up to `as_of`.
- Recent journal is file-order based and does not filter by `as_of`.
- Cycle consultation has its own `as_of`-bounded recorded-actual subtotal.
- Residual is `as_of`-bounded: future actual expense rows after `as_of` and `future_open` plans are excluded.

This fixture is a characterization test, not a statement that all behavior is final.
