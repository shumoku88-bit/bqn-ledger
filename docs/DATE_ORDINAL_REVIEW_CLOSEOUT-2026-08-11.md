# Date ordinal review closeout — 2026-08-11

## Final state

- focused review: PR #657
- squash-merged main: `76ed65e021c2daaec9966d05bdf5d617efafc0ab`
- final owner: `src/ledger/date_ordinal.bqn`
- detailed review evidence: `docs/DATE_ORDINAL_REVIEW_OBSERVATION-2026-08-11.md`

The merged owner was reread on `main` after the squash merge.

## Retained change

The review found one local relation worth changing. Parsed month is now classified once onto the canonical 1..12 month axis:

```bqn
monthDays ← ⟨31,28+IsLeap y,31,30,31,30,31,31,30,31,30,31⟩
monthIndex ← ⊑((1+↕12)⊐⟨m⟩)
maxDay ← monthIndex⊑(monthDays∾0)
valid ↩ (monthIndex<≠monthDays) ∧ (1 ≤ d) ∧ d ≤ maxDay
```

An invalid month uses Index Of's absent coordinate and the appended zero-day fill cell instead of entering a separately guarded Pick path.

## Kept unchanged

The following were already direct and remain unchanged:

- strict shape and digit admission before numeric conversion;
- Gregorian leap-year calculation;
- `Parts` / `FromParts`;
- `Ordinal` / `FromOrdinal`;
- `AddDays`.

The review did not introduce abstraction or glyph density merely to make those formulas look more array-oriented.

## Protected laws

Focused tests now include century leap rules, invalid month/day boundaries, strict date text shape, month length, year rollover, leap-day movement, non-leap 1900 movement, and existing round-trip/ordinal-distance laws.

Characterization CI #2655, production CI #2656, and final documentation-head CI #2657 were all SUCCESS before merge. Merged-main qualification is tracked by the main workflow on the squash commit.

## Review lesson

The useful transformation was not “rewrite date arithmetic in clever BQN.” It was narrower:

```text
guarded month lookup
  -> semantic month axis
  -> Index Of coordinate
  -> absent-coordinate fill
```

This preserves a readable mathematical kernel while using a BQN relation exactly where the problem contains one.
