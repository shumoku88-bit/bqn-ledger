# Daily Trend Current-Source Coordinate Replay Decision

Status: current decision / post-runtime product contract
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Protected property: `docs/DAILY_TREND_OBSERVATION_CONSISTENCY_DECISION.md`
Knowledge boundary: `docs/DAILY_TREND_KNOWLEDGE_BOUNDARY_DECISION.md`
Row membership producer decision: `docs/DAILY_TREND_ROW_MEMBERSHIP_PRODUCER_DECISION.md`
Current semantics note: `docs/DAILY_TREND_TEMPORAL_SEMANTICS.md`
Exit: revise or archive after the first runtime slice consumes this product contract and later review confirms the chosen direction

## 0. Purpose

Daily Trend temporal work has established:

```text
D = row coordinate
O = observation / replay frame
L = local last-recorded coordinate frontier
C = cycle boundary
K = possible historical knowledge boundary
S = source snapshot supplied to the run
```

Recent characterization also proves:

```text
same D
same L
same C
same row set
different source snapshot
  -> historical row may change
```

Current source data does not generally preserve a canonical historical `K` axis.

The next runtime step therefore requires a product question that is:

```text
useful
implementable from current source data
honest about source-history limits
compatible with observation consistency
```

This document selects that product direction.

## 1. Decision

Canonical Daily Trend direction for the next runtime work is:

```text
A1-like current-source coordinate replay
```

The household question is:

> Using the source snapshot supplied to this run, what did the household cycle state look like at each Daily Trend coordinate `D`, under an observation rule tied to that row coordinate?

Short form:

> From the source state used by this run, what does each day `D` in the cycle look like from `D`?

The initial temporal shape is:

```text
S = source snapshot supplied to this run
D = row coordinate
O_row = D
C = selected cycle boundary
L = record-frontier context, not owner of row observation
K = unavailable / not claimed
```

## 2. Meaning of `S`

`S` means the concrete source snapshot consumed by one execution.

For current architecture this includes the relevant current source files and configuration available to the run, such as:

```text
journal.tsv
plan.tsv
budget_alloc.tsv
accounts.tsv
cycle.tsv
config
```

This decision does not require a new runtime `SourceSnapshot` object.

`S` is a reasoning name for an input state that already exists operationally.

A result is reproducible relative to:

```text
same S
same code
same config
same explicit temporal inputs
```

This decision does not claim that current runtime assigns a stable global identifier to `S`.

## 3. Meaning of `D`

`D` is the Daily Trend row coordinate.

Examples:

```text
2026-01-02
2026-01-03
```

Coordinate-local terms may depend on `D` and `C`, for example:

```text
cumulative actual liquid at D
actual variable spending on D
days_left from D to C.end_exclusive
```

Current implementation already contains several such `D`-relative terms.

## 4. Initial observation rule: `O_row = D`

For the selected A1-like direction, the initial row observation rule is:

```text
O_row = D
```

This means O-shaped row calculations should be explained from the row coordinate rather than from a report-local `L`.

The rule is intentionally local to Daily Trend rows.

It does not imply:

```text
all report consumers use O = D
human Outlook uses O = D
ctx.as_of becomes D
cycle selection becomes D
```

## 5. What this product does not claim

The selected question does not claim:

```text
what the user knew at D
what the database knew at D
what source files physically contained at D
historical transaction-time replay
historical knowledge replay
```

Those stronger products require a historical `K` or another explicit source-history artifact.

Therefore a row rendered for:

```text
D = 2026-01-02
```

must not be labeled automatically as:

```text
what was known on 2026-01-02
```

The honest statement is closer to:

```text
what the source snapshot supplied to this run projects for coordinate 2026-01-02 under the selected row observation rule
```

## 6. Consequence of source changes

Because the product uses current run source snapshot `S`, a historical row may change when `S` changes.

The important distinction is not:

```text
historical rows never change
```

The important distinction is:

```text
why did the row change?
```

### 6.1 Backdated source fact at or before D

Example:

```text
before S:
  no 2026-01-02 spend

after S:
  add 2026-01-02 spend 10
```

For row:

```text
D = 2026-01-02
```

A change is compatible with this product.

The new source snapshot changes the coordinate-local actual state visible at `D`.

PR #99 characterizes this class:

```text
same D
same L
same C
same row set
S changes through backdated Event
  -> row changes
```

That behavior is not rejected by this decision.

### 6.2 Later unrelated Event after D

Example:

```text
D = 2026-01-02

later source change:
  add unrelated 2026-01-06 Event
```

The later Event may alter source snapshot `S`, but it should not silently redefine O-shaped row calculations merely because local max coordinate `L` advanced.

This is the first practical consequence of:

```text
O_row = D
L != row observation owner
```

A later Event can still affect the row if the selected product explicitly depends on it through another named mechanism.

The current shared future-income cutoff has no such selected justification.

## 7. Position of L

`L` remains a useful meaning:

```text
last recorded actual-coordinate frontier
```

But for this Daily Trend product:

```text
L does not own historical row observation
```

Therefore this product rejects the general rule:

```text
all historical rows use current local L as their as_of
```

This does not require deleting `L` from Daily Trend immediately.

Current uses must be reviewed term by term.

Possible legitimate future uses may include:

```text
section freshness display
record-frontier relation
current row selection policy
```

if explicitly chosen.

They are not automatically row-calculation cutoffs.

## 8. Position of K

Current source model does not generally provide canonical historical `K`.

Therefore:

```text
K = unavailable / not claimed
```

for the selected product.

Do not simulate K from:

```text
L
system_today
file mtime
row order
cycle boundary
Git commit timestamp without explicit source-snapshot contract
```

This decision does not block a future A2/B2 product when historical source knowledge is actually available.

## 9. First selected dependency change

The first runtime slice should change only:

```text
planned_future_income
```

Current dependency:

```text
planned_future_income = f(L, C)
```

Selected first target:

```text
planned_future_income_for_row = f(S, D, C)
```

Initial date-window direction:

```text
plan.date > D
plan.date < C.end_exclusive
```

subject to existing plan admission / income classification rules that remain otherwise unchanged.

This means each row receives its own future-income amount.

## 10. Why `planned_future_income` is first

The first runtime slice is chosen because existing evidence is unusually strong.

Current characterization already shows:

```text
historical row D fixed
local L advances
L crosses 2026-01-05 future-income plan date
shared planned_future_income 900 -> 0
historical fund / daily change
```

The current formula is also structurally isolated:

```text
planned_future_income
```

is computed once outside the row loop and reused across historical rows.

Moving this one cutoff to row `D` directly tests the selected product contract without requiring a broad Daily Trend rewrite.

## 11. Expected behavior for the existing stability fixture

Existing before/after shape:

```text
historical row D = 2026-01-02
future income plan = 2026-01-05 amount 900

before local L = 2026-01-03
after local L  = 2026-01-06
```

Current behavior:

```text
planned future contribution:
  900 -> 0

fund:
  1000 -> 100

daily:
  111 -> 11
```

Under the selected first slice:

```text
D remains 2026-01-02
plan.date 2026-01-05 > D
```

so the row-local future-income contribution should remain:

```text
900 -> 900
```

for both source snapshots, assuming no other row-local dependency intentionally changes.

Expected row values for that fixture become approximately:

```text
fund:
  1000 -> 1000

daily:
  111 -> 111
```

This is not a blanket historical-stability guarantee.

It is the expected consequence of removing one unjustified `L` dependency.

## 12. Expected behavior for PR #99 backdated-source fixture

Existing #99 shape:

```text
D = 2026-01-02
L = 2026-01-03 before and after
C fixed
row set fixed

S changes by adding 2026-01-02 spend 10
```

The selected product should continue to allow:

```text
liquid:
  100 -> 90

fund:
  1000 -> 990

daily:
  111 -> 110
```

because source snapshot `S` changed with a fact at the row coordinate.

The first runtime slice must preserve this distinction:

```text
later L movement after D
  -> must not rewrite row through shared future-income cutoff

backdated source fact at/before D
  -> may rewrite current-source coordinate replay
```

## 13. Reserve remains unresolved

This decision does not authorize a reserve rewrite.

Current reserve behavior includes:

```text
row D
cycle C
plan identity matching M
empty-identity edge path E
possible local L dependency in edge branch
```

Earlier dependency mapping required correction after ordinary 5-field plan identity behavior was characterized.

Therefore reserve remains outside the first runtime slice.

## 14. Row membership ownership

Current trend row set now comes from accepted actual projection coordinates restricted to `C`, with explicit `cycle.start` anchoring when the accepted in-cycle set is empty.

```text
if R_actual_in_cycle is non-empty:
  R = cycle_filter(dedupe(sort(R_actual_in_cycle)))
else:
  R = {cycle.start}
```

PR #103 characterized the pre-runtime frontier effects:

```text
ordinary valid journal: L was often redundant with an accepted actual coordinate
empty/fallback journal: cycle.start visible through the frontier fallback
producer disagreement: raw frontier could reintroduce a rejected coordinate
```

PR #105 implemented the selected ownership:

```text
R_actual owns accepted actual projection coordinates.
A_empty owns explicit empty-state anchoring.
L owns record-frontier context, not row membership.
```

See `docs/DAILY_TREND_ROW_MEMBERSHIP_PRODUCER_DECISION.md`.

PR #105 already changed runtime behavior; the unresolved questions below are separate and remain open:

```text
whether a separate current terminal row should exist
whether every cycle day should be materialized
how VM as_of or the human header should be renamed or reframed
```

Do not bundle any further row-set work with header, reserve, Outlook, K, or shared temporal-kernel work.

## 15. Delta remains unresolved

Current `delta` compares adjacent rendered `daily` values.

It depends on:

```text
D
predecessor row P
row set R
and inherited daily dependencies
```

Changing per-row future income will intentionally change some delta values.

The first runtime slice should characterize those consequences but must not redesign delta semantics unless required for correctness of the selected one-line dependency change.

## 16. Header remains unresolved

Current human header uses VM `as_of = L` for section-level days remaining.

The selected row product does not automatically decide header semantics.

Possible future meanings include:

```text
section generated/current frontier context
selected report observation
latest row coordinate
```

Do not bundle header repair with row future-income cutoff.

## 17. Current VM `as_of` remains compatibility evidence

The selected product does not require immediately renaming or deleting:

```text
vm.as_of
```

Current VM field remains local `L` evidence.

However the field must not be treated as proof that historical row O equals `L`.

A later cleanup may separate:

```text
last_recorded_on
section observation
row observation rule
```

when enough consumer evidence exists.

## 18. Protected property

The first protected property remains:

```text
observation consistency
```

For the selected product, the initial requirement is:

> O-shaped historical row terms must be explainable from row observation `O_row = D`; local record frontier `L` must not silently redefine them.

This does not mean every term uses only D.

Examples:

```text
coordinate actual state -> S + D + C
future plan income      -> S + D + C
cycle denominator       -> D + C
source-history audit    -> requires K if claimed
freshness context       -> L
```

## 19. Historical gate for the first slice

PR #101 handled the first selected runtime slice by moving planned_future_income cutoff ownership from report-local `L` to row `D`.
PR #105 later handled row-membership ownership separately.

The first slice remained compatible with:

```text
current source snapshot S
cycle boundary C
plan classification / anchor semantics
reserve logic
header semantics
no K
no shared temporal kernel
```

The later row-membership slice changed only the selected row-set ownership model.

## 20. Historical test gate for the first slice

The same characterization pair that motivated PR #101 remains the useful evidence split:

```text
A. later unrelated L movement should not move row-local future income
B. backdated source change at/before D may still change the row through coordinate-local actual state
```

This distinguishes:

```text
observation consistency
```

from:

```text
historical immutability
```

## 21. Non-goals

Do not:

```text
implement historical K
add recorded_at columns
make repo bitemporal
wire Daily Trend to Outlook O
replace every L with D
replace every L with ctx.as_of
change cycle resolution
rewrite reserve
redesign row membership
redesign delta
redesign header
change summary
create TemporalFrame
extract temporal.bqn
unify LatestActualDateInCycle helpers
change source TSV
```

## 22. Decision summary

```text
Selected product direction:
  A1-like current-source coordinate replay

Household question:
  from source snapshot S supplied to this run,
  what does each cycle coordinate D look like from D?

Initial row observation:
  O_row = D

Knowledge claim:
  none beyond current source snapshot S
  K unavailable / not claimed

Position of L:
  freshness / record-frontier context
  not owner of historical row observation

First runtime slice:
  planned_future_income cutoff
    L -> D

Row membership ownership:
  implemented in PR #105
    accepted actual coordinates -> R_actual
    cycle.start -> A_empty when empty

Explicitly deferred:
  reserve
  delta redesign
  header
  K
  shared temporal kernel
```

The selected contract is intentionally modest.

It does not reconstruct the past as once known.

It projects each past coordinate from the source state actually supplied to the run, while preventing an unrelated local frontier from silently owning the row's observation frame.
