# Fixture: envelope-bootstrap

Covers empty-journal bootstrap with future-only cube data.

As of `2026-01-05`:

- `actual.journal` is empty.
- `plan.tsv` contains only future rows; the former legacy Budget allocation source is retired.
- `main.bqn --section envelopes` must not crash.
- Envelope health values should be zero-safe: balance 0, avg spend 0, days until empty 999, not critical.

This fixes the case where `BuildCube` has days, but no cube date is `<= as_of`.
