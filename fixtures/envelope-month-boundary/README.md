# Fixture: envelope-month-boundary

Regression fixture for envelope average spend across a month boundary.

The cycle starts on 2026-01-31 and `--as-of` is 2026-02-02. Elapsed days should be ordinal/inclusive days (`3`), not `YYYYMMDD` numeric subtraction (`72`).

Expected envelope `avg_day` for `daily` is `900 / 3 = 300`.
