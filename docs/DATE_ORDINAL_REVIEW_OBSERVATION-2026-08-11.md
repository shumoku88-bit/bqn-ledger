# Date ordinal review observation — 2026-08-11

## Baseline and ownership

- repository: `shumoku88-bit/bqn-ledger`
- review base: `a68a3a541d68f2316f7b9ff11860fdfabf3f1cc4`
- active owner: `src/ledger/date_ordinal.bqn`
- focused review PR: #657

`date_ordinal.bqn` is a live pure kernel rather than a legacy source seam. Current Cycle, temporal-status, report-profile, editor, and validation paths consume its strict Gregorian coordinates or date operations.

Its retained public surface is intentionally small:

```text
strict YYYY-MM-DD text
  <-> year / month / day parts
  <-> integer ordinal
  -> AddDays
```

No clock, source I/O, report formatting policy, or compatibility date representation belongs to this owner.

## Most of the kernel was already direct

The review did not find a reason to rewrite the Gregorian ordinal or inverse formulas. `Ordinal`, `FromOrdinal`, `Parts`, `FromParts`, and `AddDays` are already compact numeric transformations with no incidental row model, generic framework, or repeated source observation.

That matters for this review policy: BQN-native work is not a requirement to change every owner. A mathematically direct scalar/array formula does not become better merely by adding more glyphs, trains, or intermediate axes.

## Characterization strengthened first

Before production changed, `tests/test_ledger_date_ordinal.bqn` was expanded to protect:

- leap-day validity for 1900, 2000, and 2024;
- invalid month coordinates 0 and 13;
- month-length rejection such as April 31;
- invalid day coordinates 0 and 32;
- strict `YYYY-MM-DD` width and separator shape;
- AddDays continuity across ordinary year rollover;
- leap-day progression;
- the non-leap 1900 century boundary;
- existing ordinal/inverse round trips and coordinate distances.

Characterization-only CI #2655 was SUCCESS.

## Month admission was the one useful array relation

The old `IsValid` month logic used an explicit scalar guard before month-day lookup:

```bqn
monthOk ← (1 ≤ m) ∧ m ≤ 12
maxDay ← 0
{𝕊: maxDay ↩ (m-1)⊑monthDays}⍟monthOk @
valid ↩ monthOk ∧ (1 ≤ d) ∧ d ≤ maxDay
```

That guard existed only to make the Pick coordinate safe. The semantic question is simpler: where does parsed month `m` occur on the canonical month axis, and is the resulting coordinate the absent bound?

The retained code states that relation directly:

```bqn
monthDays ← ⟨31,28+IsLeap y,31,30,31,30,31,31,30,31,30,31⟩
monthIndex ← ⊑((1+↕12)⊐⟨m⟩)
maxDay ← monthIndex⊑(monthDays∾0)
valid ↩ (monthIndex<≠monthDays) ∧ (1 ≤ d) ∧ d ≤ maxDay
```

`⊐` classifies one parsed month onto the 1..12 axis. An invalid month becomes the absent coordinate, which selects the appended zero-day fill item. Month validity is then the ordinary in-axis coordinate relation rather than a separate guarded indexing regime.

Production CI #2656 was SUCCESS with the strengthened boundary laws.

## Why the review stops here

The remaining guarded structure in `IsValid` is not the same kind of problem:

- shape admission protects parsing from malformed text;
- digit admission protects numeric conversion;
- those are genuine staged validity boundaries rather than a hidden array relation.

Likewise, the Gregorian forward/inverse formulas are already the bounded mathematical kernel. Rewriting them for density would increase proof burden without exposing a clearer semantic axis.

## Review conclusion

The retained change is deliberately narrow:

```text
strict text admission remains staged
Gregorian arithmetic remains direct
month validity becomes month-axis classification
```

This is a useful BQN teaching case because the language contribution is specific: Index Of turns a guarded scalar lookup into an explicit coordinate relation, while unrelated control and arithmetic remain untouched.
