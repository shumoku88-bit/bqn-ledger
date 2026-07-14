# Daily Trend Knowledge Boundary Decision

Status: current decision / pre-runtime temporal meaning correction
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Related semantics note: `docs/DAILY_TREND_TEMPORAL_SEMANTICS.md`
External comparison: `docs/archive/audits/TEMPORAL_EXTERNAL_MODEL_COMPARISON-2026-07-07.md`
Protected property: `docs/DAILY_TREND_OBSERVATION_CONSISTENCY_DECISION.md`
Exit: revise or archive after a concrete Daily Trend product contract and runtime slice consume this distinction

## 0. Purpose

Daily Trend currently has two historical semantic candidates:

```text
Candidate A
  fixed historical observation

Candidate B
  present-knowledge retrospective projection
```

External temporal-model comparison exposes a missing distinction inside that candidate pair.

The current vocabulary risks treating these two questions as equivalent:

```text
From what observation date is the row viewed?
```

and:

```text
Which source knowledge state is available to the row?
```

They are not equivalent.

This document separates:

```text
O = observation / replay frame
K = knowledge or source-admission boundary
```

before any Daily Trend runtime change.

## 1. Decision

Daily Trend must treat observation frame and knowledge boundary as distinct meanings:

```text
O != K
```

where:

```text
O
  = the date / frame from which the calculation is observed

K
  = the boundary describing which recorded knowledge or source history is admitted
```

Current `bqn-ledger` does not yet preserve a general canonical historical `K` axis.

Therefore current Daily Trend must not claim that a coordinate-cut or observation-cut historical row reconstructs:

```text
what the user knew at that historical date
```

unless an external historical source snapshot or another explicit knowledge-history artifact is supplied.

## 2. Why this decision is needed

The current unresolved semantics note says Candidate A may support:

```text
audit what the user could have known or acted on at that time
```

That statement is too strong for current source data.

Current source rows generally preserve domain / coordinate dates such as:

```text
journal.date
plan.date
budget_alloc.date
```

but do not preserve a general per-fact transaction-time history such as:

```text
recorded_at
knowledge_from
knowledge_to
transaction_time
```

Suppose an Event has coordinate date:

```text
D = 2026-01-03
```

but is entered into the source on:

```text
2026-01-10
```

A later report that filters current source rows by:

```text
row.date <= 2026-01-05
```

can still include that Event if the current TSV now contains the backdated row.

Therefore:

```text
coordinate cutoff at 2026-01-05
```

does not prove:

```text
knowledge as it existed on 2026-01-05
```

## 3. External-model lesson

Bitemporal systems distinguish a domain / valid-time axis from a transaction-time axis.

A query can ask approximately:

```text
what was true at domain time V
as known at transaction time T
```

The current repository does not preserve that second history generally.

This comparison does not require `bqn-ledger` to become bitemporal.

It only proves that:

```text
historical observation
```

and:

```text
historical knowledge state
```

must not be silently collapsed.

## 4. Current source capability boundary

Current `bqn-ledger` can generally reconstruct calculations from:

```text
current source TSV snapshot
current code
current config
explicit coordinate / observation parameters where supported
```

It cannot generally reconstruct from source data alone:

```text
the exact set of facts known on an arbitrary historical day
```

because later edits, backdated rows, and corrections are not represented as one canonical immutable transaction-time history.

An external artifact may sometimes provide a historical source state, for example:

```text
an archived source copy
a Git commit containing the source state
a backup snapshot
```

But such an artifact is not currently a canonical runtime `K` contract.

## 5. Correction to Candidate A

Previous shorthand:

```text
Candidate A: fixed historical observation
```

is too broad if read as historical knowledge replay.

The candidate must be decomposed.

### A1. Coordinate / observation cut over current source

Shape:

```text
current source snapshot S_now
+
row coordinate D
+
explicit observation rule O
```

Possible meaning:

```text
How does the current source project the historical coordinate D
under an observation rule tied to D or another explicit O?
```

This can be useful.

It may also be stable against later Events whose coordinates lie after the cutoff, depending on the formula.

But it does not guarantee:

```text
what was known at D
```

because current source may contain backdated or corrected facts added later.

### A2. Historical-knowledge replay

Shape:

```text
historical source knowledge K
+
observation O
+
row coordinate D
```

Meaning:

```text
What would the row have shown using only knowledge admitted by K?
```

This is the stronger audit product.

Current source model does not generally support it by itself.

It requires one of:

```text
preserved transaction / knowledge history
archived source snapshot
external versioned source artifact
another explicit historical knowledge mechanism
```

Therefore A2 is not currently available merely by adding `BuildAt(ctx, O)`.

## 6. Correction to Candidate B

Previous shorthand:

```text
Candidate B: present-knowledge retrospective projection
```

also hides a source-state assumption.

### B1. Current-source retrospective projection

Shape:

```text
current source snapshot S_now
+
historical row D
+
explicit retrospective observation policy
```

Meaning:

```text
What does historical coordinate D look like using the source state available now?
```

This product is feasible with current architecture in principle.

Historical rows may intentionally change when current source changes.

But reproducibility requires naming the source snapshot used.

The phrase:

```text
present knowledge
```

should therefore be understood narrowly as:

```text
the current source state supplied to this run
```

not as a preserved universal knowledge timeline.

### B2. Bounded-knowledge retrospective projection

Shape:

```text
selected historical or later K
+
historical D
+
selected O
```

Meaning:

```text
How does D look using knowledge admitted through K?
```

This is bitemporal-like.

Current source model does not generally support arbitrary B2 replay.

## 7. The candidate space is at least two-dimensional

The old A/B pair suggested one axis:

```text
fixed history
vs
retrospective history
```

The stronger model has at least two independent questions:

```text
Observation frame
  O

Knowledge/source frame
  K or current source snapshot S
```

Conceptual matrix:

```text
                         knowledge/source frame

                    current source S_now     historical K

observation O=D     A1-like current-source   A2 true historical-
                    coordinate replay        knowledge replay

other explicit O    B1-like current-source   B2 bounded-knowledge
                    retrospective view       retrospective view
```

This matrix is not a new runtime API.

It is a reasoning correction.

## 8. Current Daily Trend runtime position

Current `src_next/daily_trend.bqn` approximately has:

```text
D = trend row coordinate
L = local latest-journal coordinate
C = cycle boundary
```

and no explicit canonical Daily Trend `O` input.

It also reads current source files at execution time.

Therefore current runtime is not cleanly any of:

```text
A1
A2
B1
B2
```

It is better described as:

```text
current-source calculation
with mixed D / L / C dependencies
and no explicit knowledge-boundary contract
```

This is why current behavior alone cannot choose the semantic product.

## 9. Critical non-equivalence: L is not K

Current local `L` is derived from journal Event coordinates.

Approximate meaning:

```text
maximum admitted recorded journal coordinate
```

It does not record:

```text
when the row entered the source
when the user learned the fact
when a correction was made
which source snapshot was active
```

Therefore:

```text
L != K
```

and:

```text
L advancing
```

does not mean:

```text
knowledge history advanced in a bitemporal sense
```

Likewise:

```text
L fixed
```

does not prove the source knowledge state is unchanged.

A backdated edit can change source content without increasing maximum coordinate `L`.

## 10. Critical non-equivalence: O is not K

An explicit observation date can decide:

```text
which coordinate dates are visible
which future plan rows count
which denominator is used
```

but cannot by itself recover facts deleted or absent from a historical source state.

Therefore:

```text
O = 2026-01-05
```

is not enough to answer:

```text
what did the user know on 2026-01-05?
```

unless the admitted knowledge history is separately defined.

## 11. Consequence for `actual_snapshot.BuildAt`

Current:

```text
actual_snapshot.BuildAt(ctx, O)
```

filters current journal rows by coordinate:

```text
row.date <= O
```

This is a real coordinate cutoff mechanism.

It is not a transaction-time replay mechanism.

Therefore a future Daily Trend explicit observation path may reuse a hard cutoff mechanism where semantically appropriate, but must not claim that the resulting value reconstructs historical knowledge.

## 12. Consequence for auditability wording

The following claim is currently too strong without K:

```text
This row shows what the user knew at D.
```

Safer claims include:

```text
This row is calculated from current source state with coordinate cutoff O.
```

or:

```text
This row is calculated from archived source snapshot K with observation O.
```

Auditability requires naming both when both matter.

## 13. Consequence for reproducibility

Current reproducibility can be stated as:

```text
same source snapshot
same code
same config
same explicit temporal inputs
  -> same result
```

That is useful.

It differs from:

```text
same historical date D
  -> recover historical knowledge automatically
```

The latter is unsupported without preserved history.

## 14. Consequence for historical stability

Historical stability must now be stated relative to source knowledge state.

Possible property:

```text
Given fixed source snapshot S and fixed temporal inputs,
row D is stable.
```

Different property:

```text
When source snapshot changes with later knowledge,
row D remains stable.
```

These are not equivalent.

Candidate B1 may intentionally reject the second property while preserving the first.

## 15. Protected property remains observation consistency

This decision does not replace the previously selected first property:

```text
observation consistency
```

It strengthens it.

For Daily Trend, a time-sensitive term may need dependencies such as:

```text
row coordinate D
observation O
cycle boundary C
current local frontier L
knowledge/source boundary K
source snapshot identity S
```

Not every term needs every meaning.

The dependency must be explainable.

## 16. Do not retrofit bitemporality now

This decision does not authorize:

```text
add recorded_at to every TSV row
add transaction-time columns
append knowledge timestamps automatically
rewrite source storage
make Git history a runtime database
introduce XTDB / Datomic
treat file mtime as K
treat TSV row order as transaction time
```

Those would be major architecture choices.

The immediate correction is semantic honesty, not infrastructure replacement.

## 17. Do not simulate K from weak proxies

The following are not trustworthy generic substitutes for K:

```text
max journal date L
file modification time
current system_today
cycle end
source row order
Git commit time without explicit source-snapshot contract
```

A future product may intentionally use one of these for another meaning.

That does not make it historical knowledge time.

## 18. Relationship to future event-sourced household project

The separate future event-sourced project may choose to preserve stronger history such as:

```text
event occurrence coordinate
recorded-at time
correction events
replay observation
knowledge cutoff
```

That project may support products closer to A2 or B2.

Current `bqn-ledger` should not be retrofitted merely to match that future architecture.

The two projects can share vocabulary and warnings without sharing storage contracts.

## 19. Runtime gate after this decision

Before a Daily Trend runtime change, state:

```text
1. What exact product question is selected?

2. What is O?

3. What source state is used?
   current S_now or historical K?

4. Does the product claim historical knowledge?

5. If yes, where is K preserved?

6. Which terms depend on D, O, C, L, K, or source snapshot S?

7. Which current mixed dependencies intentionally change?
```

A runtime slice must not pass this gate by writing:

```text
use as_of
```

without naming which axis it controls.

## 20. Recommended next finite slice

The strongest next slice is docs/test-only:

```text
characterize backdated knowledge drift
```

Suggested experiment:

```text
fixed row coordinate D
fixed local max coordinate L
fixed cycle C

before source:
  no backdated Event X

after source:
  add Event X with coordinate < L
  so max coordinate L remains unchanged
```

Then observe whether a historical Daily Trend row changes.

Why this test matters:

```text
O fixed / L fixed / source knowledge changed
```

is a dimension not isolated by the current O-vs-L characterization pair.

It can prove directly that:

```text
L is not a complete proxy for source knowledge state
```

without introducing K or changing runtime.

## 21. Non-goals

Do not:

```text
choose Candidate A or B solely from this decision
implement K
add transaction time
change Daily Trend runtime
wire Daily Trend to Outlook O
replace L with ctx.as_of
create TemporalFrame
extract shared temporal kernel
change source TSV
claim current report is bitemporal
```

## 22. Decision summary

```text
New separation:
  O != K

Current capability:
  current-source replay with explicit coordinate/observation rules is possible

Current limitation:
  arbitrary historical knowledge replay is not generally available

Critical corrections:
  L != K
  O != K
  coordinate cutoff != what was known then

Candidate A/B status:
  retained as historical shorthand
  insufficient as a one-dimensional model

Stronger model:
  observation frame
  x
  knowledge/source frame

Next test:
  backdated Event changes source knowledge
  while max coordinate L stays fixed
```

The main correction is simple:

```text
A historical date is not a historical knowledge state.
```
