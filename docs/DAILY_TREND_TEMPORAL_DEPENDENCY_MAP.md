# Daily Trend Temporal Dependency Map

Status: current observation / post-first-runtime dependency map
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Selected product: `docs/DAILY_TREND_CURRENT_SOURCE_COORDINATE_REPLAY_DECISION.md`
Knowledge boundary: `docs/DAILY_TREND_KNOWLEDGE_BOUNDARY_DECISION.md`
Exit: revise after later Daily Trend runtime slices materially change current dependencies

## Purpose

This map records the temporal and source-state dependencies currently present in `src_next/daily_trend.bqn` after the first runtime slice selected by the current-source coordinate replay decision.

The first protected property remains:

```text
observation consistency
```

The selected product direction is now:

```text
A1-like current-source coordinate replay
```

with initial reasoning shape:

```text
S = source snapshot supplied to this run
D = row coordinate
O_row = D
C = cycle / period boundary
L = current local last-recorded coordinate frontier
K = unavailable / not claimed
```

This map describes current implementation dependencies. It does not claim that all selected product work is complete.

## Revision history

### Revision A: reserve dependency correction

The first dependency map broadly classified ordinary reserve as:

```text
reserve = f(D, L, C)
```

That was too broad.

A dedicated characterization disproved the expected ordinary 5-field behavior:

```text
expected reserve:
  300 -> 0

observed reserve:
  300 -> 300
```

Inspection of `src_next/plan_journal_overlap.bqn` showed that ordinary 5-field rows receive a non-empty fallback identity. The current map therefore separates:

```text
ordinary fallback-identity reserve path
```

from:

```text
empty-identity reserve edge path
```

### Revision B: row-local future income

PR #101 implemented the first runtime slice selected by PR #100.

Before:

```text
planned_future_income = f(L, C)
```

One report-local scalar was computed outside the row loop using:

```text
plan.date > L
plan.date < C.end_exclusive
```

After:

```text
planned_future_income_for_row = f(S, D, C)
```

Each row computes its own future income using:

```text
plan.date > D
plan.date < C.end_exclusive
```

Existing plan admission and income classification remain unchanged.

This removes the previously characterized shared `L` cutoff from ordinary row fund / daily values.

## Symbols

```text
S = source snapshot supplied to the run
D = current trend-row coordinate date
P = predecessor rendered row coordinate used by delta
O = explicit observation / replay frame when one exists
O_row = selected Daily Trend row observation rule; currently D
C = cycle / period boundary
L = current report-local latest-journal coordinate from LatestActualDateInCycle
R = current trend-row coordinate set / ordering
M = plan/journal identity matching state visible at row D
E = empty-identity reserve edge path
K = historical knowledge boundary; unavailable / not claimed in current product
```

Important:

```text
O_row = D
```

is the selected product rule for row-local O-shaped calculations.

Current Daily Trend still does not expose a generic explicit `BuildAt(ctx, O)` boundary.

Also:

```text
L != O_row
L != K
O_row != K
```

## High-level result

The first runtime slice removed the strongest directly characterized ordinary-row frame mixture:

```text
historical D
+
shared planned_future_income(L, C)
```

Current ordinary row calculations are now approximately centered on:

```text
S
D
C
M
```

Residual `L` dependencies remain in separate places:

```text
trend row-set construction R
empty-identity reserve edge E
VM as_of
human header days_left
```

Therefore the temporal investigation is not complete.

## Current dependency table

| Term | Current dependency | Current mechanism | Observation |
|---|---|---|---|
| `trend row coordinate set` | `R + L + C` | actual posting dates plus local `as_of`, then sort/deduplicate and cycle filter | local frontier still participates in row-set construction |
| `date_str` | `D + R` | row `dn` resolved through current row set | presentation coordinate follows row set |
| `liquid` | `S + D + C` | cumulative actual cube slice at row day offset | current-source coordinate-local actual state |
| cumulative `sav` | `S + D + C` | same cumulative actual mechanism over savings accounts | current-source coordinate-local actual state |
| `planned_future_income` | `S + D + C` | plan date `> D` and `< C.end_exclusive`; existing income/liquid admission rules | row-local future-income contribution |
| ordinary 5-field `reserve` | `S + D + C + M` | plan window uses D; journal identities visible through D; ordinary rows receive fallback identity | no direct L dependence established for ordinary path |
| empty-identity reserve edge | `S + D + L + C + E` | empty identity branch compares plan date with `last_act_dn` containing local `as_of_dn` | residual local-L edge path |
| ordinary-path `fund` | `S + D + C + M` | `liquid + planned_future_income - reserve` | selected row-local future income removes direct L path |
| `days_left` | `D + C` | `C.end_exclusive - D` | coordinate-local denominator |
| ordinary-path `daily` | `S + D + C + M` | `fund / days_left` | no direct L path from ordinary future income |
| `day_var` | `S + D + C` | actual slice for row day | coordinate-local day actual |
| `day_sav` | `S + D + C` | actual slice for row day | coordinate-local day actual |
| `day_fixed` | `S + D + C` | actual slice for row day | coordinate-local day actual |
| `delta` | `S + D + P + C + R + M` | current daily minus predecessor daily | indirectly sensitive to any L effect on row set R |
| VM `as_of` | `L` | `LatestActualDateInCycle(base, cy)` | still local frontier, not row O |
| human header `days_left` | `L + C` | `C.end_exclusive - vm.as_of` | section-level frame remains separate from row D |

## Evidence by term

### 1. Trend coordinate set: `R + L + C`

Current row coordinates are built from valid actual posting dates plus local `as_of`:

```text
trend_dates_all = j_dates + <as_of>
```

Then sorted, deduplicated, and cycle-filtered.

So local `L` still participates in row-set construction.

This map does not yet decide whether that participation is semantically necessary.

Important nuance:

```text
when L is itself one of the actual posting dates,
appending L may deduplicate to an already-present coordinate
```

while fallback / empty-source cases may behave differently.

This deserves characterization before any row-set rewrite.

### 2. `liquid`: `S + D + C`

Current actual cube is cumulatively summed and indexed by row offset:

```text
d = D - C.start
cum = cumulative_actual[d]
liquid = sum liquid accounts from cum
```

PR #99 proves that changing source snapshot `S` with a backdated actual Event at `D` can change the row while `D`, `L`, and `C` stay fixed.

Therefore current-source state is a real dependency:

```text
liquid = f(S, D, C)
```

This is compatible with the selected A1-like product.

### 3. cumulative `sav`: `S + D + C`

Saving cumulative state is read from the same cumulative actual row as liquid, over savings accounts.

It therefore shares current-source coordinate-local shape.

### 4. `planned_future_income`: `S + D + C`

Current plan rows are admitted per row when:

```text
plan.date > D
plan.date < C.end_exclusive
```

plus unchanged existing conditions for:

```text
planned layer
liquid destination
income classification
```

The calculation now occurs inside the row loop.

Conceptual shape:

```text
planned_future_income_for_row = f(S, D, C)
```

This implements the first selected consequence of:

```text
O_row = D
L does not own historical row observation
```

### 5. Characterized removal of ordinary L-driven future-income drift

Existing fixture shape:

```text
historical row D = 2026-01-02
future income plan = 2026-01-05 amount 900

before local L = 2026-01-03
after local L  = 2026-01-06
```

Old behavior:

```text
future contribution:
  900 -> 0

fund:
  1000 -> 100

daily:
  111 -> 11
```

Current behavior after PR #101:

```text
future contribution:
  900 -> 900

fund:
  1000 -> 1000

daily:
  111 -> 111
```

The section-level VM `as_of` still moves:

```text
2026-01-03 -> 2026-01-06
```

so the slice specifically removes cutoff ownership from ordinary row future income rather than deleting local L entirely.

### 6. PR #99 backdated-source behavior remains valid

Fixture shape:

```text
D fixed
L fixed
C fixed
row set fixed

S changes by adding a backdated Event at D
```

Current row still changes:

```text
liquid:
  100 -> 90

fund:
  1000 -> 990

daily:
  111 -> 110
```

This distinction is intentional under current-source coordinate replay:

```text
later unrelated L movement
  -> no longer rewrites row through shared future-income cutoff

backdated source fact at/before D
  -> may change coordinate-local row state
```

This is not historical immutability.

### 7. ordinary 5-field reserve: `S + D + C + M`

Current reserve logic filters journal identity evidence through row D:

```text
journal.date <= D
```

Candidate plans are row-local and period-bound:

```text
plan.date >= D
plan.date < C.end_exclusive
```

Ordinary 5-field plans receive non-empty fallback identity from `PlanId`.

Therefore ordinary open/closed status depends on identity matching state visible at D:

```text
M
```

Current evidence does not establish direct L dependence for this ordinary path.

### 8. empty-identity reserve edge: `S + D + L + C + E`

The code still contains an empty-identity branch.

That branch uses:

```text
last_act_dn = last((journal dates <= D) + <as_of_dn>)
```

where `as_of_dn` is local L.

This remains a residual static L path.

Do not generalize it to ordinary 5-field reserve behavior.

Reachability and product meaning remain unresolved.

### 9. ordinary-path `fund`: `S + D + C + M`

Current formula:

```text
fund = liquid + planned_future_income - reserve
```

For ordinary identity path:

```text
liquid                = f(S, D, C)
planned_future_income = f(S, D, C)
reserve               = f(S, D, C, M)
```

Therefore approximately:

```text
fund = f(S, D, C, M)
```

The previously characterized ordinary direct L path through future income has been removed.

### 10. `days_left`: `D + C`

Current formula remains:

```text
days_left = max(0, C.end_exclusive - D)
```

### 11. ordinary-path `daily`: `S + D + C + M`

Current formula remains:

```text
daily = floor(fund / max(1, days_left))
```

With ordinary fund now row-local for future income, direct L dependence is no longer present through that path.

### 12. day actual terms: `S + D + C`

```text
day_var
day_sav
day_fixed
```

index actual state for row day D.

PR #99 demonstrates that current source snapshot changes can alter such terms under fixed L.

### 13. `delta`: second-order consumer

Current delta is:

```text
current row daily - predecessor rendered row daily
```

It therefore depends on:

```text
current D
predecessor P
row set R
row daily dependencies
```

Approximate ordinary shape:

```text
delta = f(S, D, P, C, R, M)
```

Because current R may depend on L, delta can still be indirectly L-sensitive through predecessor / row membership even after ordinary future income becomes row-local.

### 14. VM `as_of`: `L`

Current VM still returns:

```text
as_of = LatestActualDateInCycle(base, cy)
```

This remains local frontier evidence.

It is not proof that:

```text
historical row O = L
```

The current product rule is:

```text
O_row = D
```

for selected row-local O-shaped calculations.

### 15. Human header: `L + C`

Current human header computes section days remaining from:

```text
C.end_exclusive - vm.as_of
```

where VM `as_of` remains L.

So one section can still contain:

```text
historical row days_left = f(D, C)
header days_left         = f(L, C)
```

This may be intentional section presentation, but remains a separate unresolved semantic decision.

## Current relationship to explicit O

Daily Trend still has no generic consumer API shaped like:

```text
BuildAt(ctx, O)
```

The selected product does not require one for the first slice.

Instead, the row rule:

```text
O_row = D
```

is currently realized locally in the selected future-income cutoff and already-existing coordinate-local calculations.

Do not infer:

```text
ctx.as_of = Daily Trend O
```

or:

```text
Outlook O = Daily Trend O
```

## Findings

### Finding A: strongest characterized ordinary row-frame mixture was removed

The old directly characterized path:

```text
D-local actual / denominator
+
shared planned_future_income(L, C)
```

no longer exists for ordinary future-income contribution.

This is the main result of PR #101.

### Finding B: source snapshot S is an independent dependency

PR #99 proves:

```text
same D
same L
same C
same row set
different S
  -> row changes
```

Therefore L cannot stand in for source knowledge / snapshot identity.

### Finding C: residual L dependencies remain finite and named

Current residual L areas are:

```text
row-set construction R
empty-identity reserve edge E
VM as_of
human header
```

This is materially narrower than the pre-#101 dependency shape.

### Finding D: ordinary reserve remains identity-sensitive

Reserve is not merely a date-cutoff problem.

Ordinary path depends on plan/journal identity matching state M visible through D.

### Finding E: delta remains second-order

Even when row daily values are better aligned to D, delta depends on predecessor selection and row set.

### Finding F: current product is not historical-knowledge replay

Current-source coordinate replay uses S supplied to the run.

No K is implemented or claimed.

## What this map does not decide

This map does not decide:

- that historical rows are immutable,
- that K should be implemented,
- that all L usage is wrong,
- that row coordinates should exclude L,
- that the empty-identity edge path should be removed,
- that reserve should be rewritten,
- that header must use D,
- that Daily Trend needs a generic BuildAt API,
- that `ctx.as_of` should become row O,
- that all report consumers should share one date,
- that a shared temporal kernel is now justified.

## Recommended next finite slice

Do not perform another broad runtime rewrite immediately.

The strongest next question is:

```text
Does local L materially and independently change the Daily Trend row set,
or is the appended L normally redundant with an existing actual posting date?
```

Recommended test-only characterization:

```text
A. non-empty in-cycle journal
   compare actual posting coordinate set
   vs final trend row set contribution from appended L

B. empty / fallback journal case
   characterize whether cycle.start fallback creates a synthetic row
```

Why this next:

```text
row-set construction is the broadest remaining residual L path
and delta inherits row-set behavior
```

Keep that slice separate from:

```text
row-set redesign
header changes
reserve changes
K implementation
shared temporal kernel
```

## Current conclusion

Approximate current shape after PR #101:

```text
row coordinates             = f(R, L, C)
liquid                       = f(S, D, C)
ordinary reserve             = f(S, D, C, M)
empty-identity reserve edge  = f(S, D, L, C, E)
planned_future_income        = f(S, D, C)
ordinary-path fund           = f(S, D, C, M)
days_left                    = f(D, C)
ordinary-path daily          = f(S, D, C, M)
day actual terms             = f(S, D, C)
delta                        = f(S, D, P, C, R, M)
VM as_of                     = f(L)
header days_left             = f(L, C)
```

The first selected runtime slice has narrowed the ordinary row problem substantially.

The next work should characterize the remaining L paths one at a time rather than generalize from the old mixed-frame shape.
