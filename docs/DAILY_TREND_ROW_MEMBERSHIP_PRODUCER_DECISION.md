# Daily Trend Row Membership Producer Decision

Status: current decision / pre-runtime product contract
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Selected product: `docs/DAILY_TREND_CURRENT_SOURCE_COORDINATE_REPLAY_DECISION.md`
Current dependency observation: `docs/DAILY_TREND_TEMPORAL_DEPENDENCY_MAP.md`
Exit: revise after a runtime slice changes Daily Trend row-set construction or after a stronger row-membership product is selected

## 0. Purpose

PR #103 exposed that Daily Trend row membership currently mixes more than one row-coordinate producer.

Current runtime combines:

```text
valid actual projection coordinates
raw-journal-derived frontier L
```

This document decides which evidence grants ordinary existence to a Daily Trend row coordinate.

Decision questions:

```text
Who owns Daily Trend row membership?
Are ordinary row membership and empty-state anchoring separate responsibilities?
Does L semantically produce row coordinates, or is it frontier/freshness context only?
```

This is docs-only. It does not change runtime behavior.

## 1. Vocabulary

```text
S = source snapshot supplied to this run
D = Daily Trend row coordinate
O_row = Daily Trend row observation rule, currently D
C = cycle / period boundary
R = final Daily Trend row coordinate set / ordering
R_actual = coordinates produced by accepted actual projection evidence
A_empty = explicit empty-state anchor policy / producer
L = local last-recorded coordinate frontier from LatestActualDateInCycle
K = historical knowledge boundary; unavailable / not claimed
```

Important distinctions remain unchanged:

```text
O_row = D
L != O_row
L != K
O_row != K
historical coordinate != historical knowledge state
```

## 2. Current behavior

The current implementation should always be verified against `src_next/daily_trend.bqn` before changing runtime behavior. At the time of this decision, its row-set construction is approximately:

```text
valid_rows = ctx.cube.valid_rows
j_projs = valid_rows where layer_index = 0
j_dates = j_projs.date

L = LatestActualDateInCycle(base, cy)
trend_dates_all = j_dates + <L>

R_current = cycle_filter(dedupe(sort(trend_dates_all)))
```

Conceptually:

```text
R_current = cycle_filter(dedupe(sort(R_actual ∪ {L})))
```

`R_actual` is produced through the projection / cube acceptance boundary.

`L` is produced separately by `LatestActualDateInCycle`, which reads `journal.tsv` dates directly and falls back to `cy.start` when no in-cycle journal date is found.

Therefore current runtime row membership mixes:

```text
valid actual evidence
frontier evidence
empty-state fallback behavior
```

This document decides the product ownership model. It does not claim the runtime has already been repaired.

## 3. Evidence from PR #103

PR #103 characterized the row-set effects without changing runtime behavior.

### 3.1 Scenario A: ordinary valid journal

Fixture shape:

```text
valid actual coordinates:
  2026-01-02
  2026-01-03

L:
  2026-01-03

final row set:
  2026-01-02
  2026-01-03
```

Observation:

```text
appended L is redundant in this ordinary case
```

Narrow conclusion:

```text
When L is already an accepted actual coordinate,
appending L does not independently add row membership.
```

This does not prove that L is always redundant.

### 3.2 Scenario B: empty / fallback

Fixture shape:

```text
valid actual coordinates:
  none

fallback L:
  cycle.start = 2026-06-15

final row set:
  2026-06-15
```

Observation:

```text
cycle.start fallback contributes a synthetic row coordinate
```

Narrow conclusion:

```text
Empty-state display / anchoring exists as a distinct product question.
```

This does not prove that L should own ordinary row membership.

### 3.3 Scenario C: producer disagreement

Fixture:

```text
fixtures/src-next-unknown-account
```

Evidence:

```text
raw journal dates:
  2026-06-15
  2026-06-16

valid actual coordinates:
  2026-06-15

2026-06-16:
  rejected as unknown_account

L:
  2026-06-16

final row set:
  2026-06-15
  2026-06-16
```

Observation:

```text
When frontier producer and valid-row producer disagree,
appended L independently contributes a row coordinate.
```

A date rejected by valid actual projection can re-enter Daily Trend row membership through L.

This must not be framed merely as an `unknown_account` bug. The deeper question is:

```text
What evidence grants existence to a Daily Trend row coordinate?
```

PR #103 C shows that raw frontier evidence and valid actual evidence can disagree.

## 4. Decision

Separate row-membership responsibilities conceptually:

```text
R_actual
  = accepted actual projection coordinates

A_empty
  = explicit empty-state anchor policy / producer

L
  = local record-frontier / freshness context
```

Selected product direction:

```text
ordinary row membership is owned by valid coordinate producers
empty-state anchoring is owned by an explicit separate policy
L does not generally own row membership
L remains available as frontier/freshness context
```

A raw journal coordinate rejected by valid projection must not gain ordinary Daily Trend row-membership authority merely because it becomes L.

## 5. Selected conceptual row-set shape

The selected conceptual shape for a later runtime slice is approximately:

```text
if R_actual is non-empty:
  R = R_actual
else:
  R = A_empty(S, C)
```

This is not currently implemented.

This document intentionally does not fully specify the exact runtime representation of `A_empty`. Existing evidence shows that current fallback behavior creates a `cycle.start` row in the empty fixture, but choosing the final runtime representation of empty-state anchoring belongs to the later implementation slice.

The important ownership decision is narrower:

```text
empty-state anchoring is not ordinary L row-membership authority
```

## 6. Position of cycle.start

PR #103 B shows current behavior:

```text
empty valid actual coordinates
LatestActualDateInCycle fallback L = cycle.start
append L
-> final row cycle.start
```

This decision distinguishes:

```text
cycle.start as an explicit empty-state anchor candidate
```

from:

```text
cycle.start appearing accidentally because fallback L is appended
```

A later runtime slice may preserve `cycle.start` as the desired empty-state coordinate while changing who semantically owns that coordinate:

```text
owner should be A_empty, not L
```

## 7. Position of L

`L` remains meaningful as:

```text
local record-frontier context
possible freshness context
possible header/current-state context
compatibility evidence for existing VM as_of
```

`L` is not:

```text
O_row
a historical knowledge boundary K
automatic Daily Trend row-membership authority
```

This decision does not require deleting `L` from Daily Trend. It only rejects using `L` as the general producer of row coordinates.

## 8. Rejected projection coordinates

A coordinate rejected by valid actual projection must not automatically regain ordinary Daily Trend row-membership authority through raw frontier production.

This is scoped specifically to Daily Trend row membership authority.

It does not claim:

```text
rejected source evidence is globally meaningless
raw source diagnostics should disappear
frontier/freshness displays may not mention rejected or skipped evidence
```

It claims only:

```text
ordinary Daily Trend row coordinates need valid row-membership evidence,
and raw L alone is not that evidence.
```

## 9. Knowledge boundary

This decision does not introduce `K`.

It does not claim historical immutability.

It does not claim:

```text
row D shows what was known at D
accepted coordinate D reconstructs historical source state at D
removing L row-membership authority creates historical-knowledge replay
```

Current-source replay remains the selected product:

```text
Using source snapshot S supplied to this run,
render coordinate D when an accepted row-membership producer selects D under C.
```

PR #99 remains valid: a backdated source change can change a historical row under fixed D, fixed L, fixed C, and fixed row set.

PR #101 remains valid: planned future income is row-local `f(S, D, C)`.

## 10. Non-goals

Do not bundle this decision with:

```text
runtime change
row-set rewrite
reserve rewrite
VM as_of change
header change
Outlook change
K implementation
shared temporal-kernel redesign
TemporalFrame
broad projection-policy redesign
source TSV schema change
fixture change
historical-knowledge replay
materializing every cycle day
```

## 11. Runtime consequence deferred

A later slice must separately decide and implement the smallest runtime change that aligns code with this ownership model.

That later slice should start from the current code and explicitly state:

```text
current runtime behavior being changed
chosen A_empty representation
expected effect on PR #103 A/B/C fixtures
unchanged VM as_of / header / reserve / Outlook / K behavior
```

This PR does not implement that runtime slice.

## 12. Decision summary

```text
Question:
  Who owns Daily Trend row membership?

Answer:
  ordinary membership: valid coordinate producers (R_actual)
  empty membership: explicit empty-state anchor policy (A_empty)
  frontier L: freshness/frontier context only

Rejected:
  raw journal coordinate rejected by valid projection regaining ordinary
  row-membership authority merely because it becomes L

Runtime impact:
  none in this docs-only decision
```
