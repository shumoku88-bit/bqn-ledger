# Fixture: cycle-end-exclusive

Tests the half-open interval boundary: `[start, end_exclusive)`.

- Cycle: `2026-06-01` to `2026-06-15` (exclusive).
- `actual.journal`:
  - `2026-06-14`: Shopping (Should be IN current cycle)
  - `2026-06-15`: Next cycle inc (Should be OUT of current cycle)
- `plan.tsv`:
  - `2026-06-15`: Planned bill (Should be OUT of current cycle/outlook)

As of `2026-06-14`:
- Cycle expense should be 500.
- Cycle income should be 0.
- Outlook should show 0 days left (since 15th is exclusive end).
