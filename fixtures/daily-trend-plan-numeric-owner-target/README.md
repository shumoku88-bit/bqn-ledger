# Daily Trend Plan Numeric-Owner Target Fixture

Public synthetic fixture for the Daily Trend checked plan-money path.

```text
C = [2026-02-01, 2026-02-11)
row coordinates D = 2026-02-01, 2026-02-03, 2026-02-06, 2026-02-09
header observation = 2026-02-09
```

Expected fixed reserves by row are `201`, `171`, `70`, and `70`. The fixture includes plan inflow/outflow, two plans on one date, same-day completion, completion before due date, the cycle start, and `end_exclusive`.

Amounts are fictional integers. The focused BQN test also supplies deliberately different source evidence and admitted Posting IR for one stable `source_row` (`999` versus `10`). That synthetic seam must return `10`; the mismatch is intentionally not encoded in this source fixture because a normal context builds both views from one source snapshot.
