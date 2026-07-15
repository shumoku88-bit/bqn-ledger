# Actual Comparison projection normal fixture

Public synthetic fixture for characterizing the current source-parser implementation.

- Selected cycle: `[2026-03-01, 2026-04-01)`.
- The test supplies `ctx.as_of=2026-03-05`, while the current report independently derives `vm.as_of=2026-03-07` from the maximum journal date.
- `REJECTED_FROM` has an unknown source account. Checked Posting IR rejects both posting sides, but the current report's local parser still aggregates the known expense side.
- `BASE_END_EXCLUDED` is exactly at the derived baseline exclusive end and is excluded.

The fixture records current behavior; it does not endorse local source amount parsing or claim parity with checked Posting IR/TBDS.
