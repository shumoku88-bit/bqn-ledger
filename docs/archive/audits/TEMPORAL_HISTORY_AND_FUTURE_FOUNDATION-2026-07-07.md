# Temporal History and Future Foundation - 2026-07-07

Status: design foundation / historical synthesis / non-canonical
Owner: other
Canonical: no
Canonical temporal principle: `docs/TIME_AS_AXIS.md`
Current engine routing: `docs/SRC_NEXT_CURRENT.md`
Base evidence: historical old-engine audits, src_next migration records, current architecture/roadmap, merged temporal PRs #71-#87, and current runtime source paths
Exit: keep as a reasoning foundation until later decisions are split into narrower canonical contracts; retain as historical evidence after that

## 0. Purpose

This document exists because current temporal work reached a point where a local fix would be premature.

The immediate symptom began around Daily Trend and Outlook, but the evidence now spans:

```text
old engine observation behavior
src_next migration constraints
parity pressure
current production adoption
ctx.as_of construction
local latest-journal clocks
explicit hard-cutoff APIs
caller / module cutoff ownership
future temporal extension points
```

The purpose is to build a foundation for future development before changing runtime behavior.

This document asks:

```text
Where did the current temporal behavior come from?
What is known now?
What remains inference?
Which future directions must remain possible?
What decision gates should precede code changes?
```

The goal is not to finish the time model.

The goal is to avoid making the next change from a false history or an over-polished abstraction.

## 1. Non-goals

This document does not authorize:

- changing `src_next/outlook.bqn`,
- changing `src_next/daily_trend.bqn`,
- changing `src_next/actual_snapshot.bqn`,
- replacing local `L` with `ctx.as_of`,
- deleting `actual_snapshot.Build`,
- changing cycle resolution,
- adding a global `as_of`,
- adding a universal `TemporalFrame`,
- choosing Daily Trend Candidate A or B,
- implementing `--as-of` for the current report path,
- changing source TSV,
- introducing new required date columns,
- deciding that every report must share one observation contract.

It also does not claim that current behavior is wrong merely because meanings differ.

Different consumers may legitimately require different temporal contracts.

## 2. Evidence hierarchy

This synthesis uses evidence in the following order.

### 2.1 Current canonical policy

Primary current principles:

```text
docs/TIME_AS_AXIS.md
docs/ARCHITECTURE.md
docs/SRC_NEXT_CURRENT.md
```

These define current direction, not necessarily current runtime uniformity.

### 2.2 Current runtime characterization

Merged tests and audits from PRs #71-#87 are treated as evidence of current behavior.

Important examples:

```text
#73  local temporal clock drift
#76  Daily Trend historical stability
#78  Daily Trend row-frame mixing
#81  reserve stability correction evidence
#83  explicit observation disconnect
#84  local clock dominance
#85  ctx.as_of cycle semantics
#86  actual_snapshot observation paths
#87  actual snapshot cutoff ownership map
```

### 2.3 Historical runtime audits

Examples:

```text
docs/archive/audits/AS_OF_SECTION_AUDIT.md
docs/archive/completed-plans/REPORT_FIELD_MAP.md
```

These record old-engine behavior and are not current contracts.

### 2.4 Migration records

Examples:

```text
docs/archive/src-next-migration/SRC_NEXT_CURRENT_ENGINE_COMPARISON.md
docs/archive/src-next-migration/SRC_NEXT_ARCHITECTURE_DESIGN.md
docs/archive/src-next-migration/SRC_NEXT_REPORT_SECTION_PARITY.md
```

These are evidence of migration goals and constraints, not current specifications.

### 2.5 Public Git history

Public Git history can prove what existed at or after the initial public release.

It cannot prove the private/pre-public moment when a behavior was first invented.

That boundary matters for Outlook local `L`.

## 3. Canonical temporal principle before the current investigation

`docs/TIME_AS_AXIS.md` already distinguishes multiple meanings.

Approximate vocabulary:

```text
coordinate time
observation time / as_of
system_today
generated_at
data_cutoff
last_recorded_on
horizon_end
period / cycle
```

The same document explicitly says these meanings are not interchangeable.

It also says current `src_next` is not yet uniform:

```text
not all report aggregation is consistently cut by as_of
```

and warns against explaining every section as though it were.

Therefore the current investigation did not discover from nothing that multiple time meanings exist.

It discovered where current runtime paths violate, bypass, approximate, or mix those meanings.

## 4. Historical phase H0: old engine had a report-wide explicit observation frame

Historical old-engine evidence shows a clear shared entry shape.

```text
report_engine.Build
  -> read Today once
  -> BuildAt(as_of)

or

BuildAt(explicit as_of)
```

The old human report accepted:

```text
--as-of YYYY-MM-DD
```

The old engine materialized its Daily Cube, then observed/sliced values through the chosen `as_of` according to each view contract.

Important distinction:

```text
old engine had one report-wide observation input
but not every section used it in exactly the same way
```

Examples from the old audit:

```text
snapshot
  hard cutoff through as_of

YTD
  year start <= journal date <= as_of

cycle
  selected cycle rows <= as_of

planned
  lifecycle threshold relative to as_of

recent
  no as_of cutoff, file-order view

outlook
  snapshot and remaining-plan logic relative to as_of

daily trend
  trend points <= as_of plus as_of
```

So the old engine was not "one scalar controls everything".

It was closer to:

```text
one explicit observation input
  -> multiple consumer-specific temporal contracts
```

That distinction is important for future design.

## 5. Historical old Outlook semantics

The old-engine field map records:

```text
as_of
  = system today via Build
  = explicit value via BuildAt
  = observation date
```

It separately records:

```text
last_journal_date
  = max journal coordinate
  = as_of fallback only for empty journal
  = context / recency meaning
```

Old Outlook therefore had two distinct concepts available:

```text
O = report observation as_of
L = last journal coordinate / recency context
```

The old Outlook section used `as_of` for:

```text
snapshot assets
remaining plans
cycle days left
daily amount ranges
```

while `last_journal_date` was displayed as context and used for lag.

This is strong historical evidence that:

```text
observation time
and
last recorded frontier
were conceptually separate in the old engine
```

It does not prove every old implementation detail was ideal.

It does prove that collapsing O and L was not required by the household domain.

## 6. Historical phase H1: early src_next explicitly lacked observation-time semantics

Migration comparison notes state:

```text
src_next has no observation-time concept yet
```

The comparison helper intentionally used different old-engine `--as-of` values for:

```text
actual comparison
remaining-plan comparison
```

because early src_next materialized valid rows in a fixed cycle rather than reproducing the old observation boundary.

This is one of the strongest historical facts in the current investigation.

The migration did not begin with a complete replacement for old `O` semantics.

## 7. Historical phase H2: src_next architecture nevertheless anticipated explicit observation

The architecture design proposed:

```text
BuildLedgerContext(base)
  -> all valid Posting IR rows

BuildPeriod(ctx, period_start, period_end_exclusive, as_of)
  -> TBDS opening / movement / closing
```

This proposal is important for two reasons.

First:

```text
period selection
and
observation as_of
were expected to be distinct inputs
```

Second:

```text
cycle / period was explicitly classified as report query boundary,
not ledger loading boundary
```

So the long-term architecture direction did not require local latest-journal dates to act as universal observation time.

## 8. Historical phase H3: parity became a migration target

The migration parity plan required reproducing the old report sections before production replacement.

Outlook and Daily Trend were eventually marked:

```text
matched
```

The same parity document described Daily Trend as needing:

```text
daily observation points
```

and a dependency graph where:

```text
envelope computation
  -> outlook / daily amount

daily trend
  <- daily observation-point storage needed
```

This reveals a tension.

The migration wanted section parity and spoke about observation points, but early src_next lacked a complete observation-time concept.

That tension is a plausible place for compatibility proxies to appear.

## 9. Historical phase H4: initial public release already contained Outlook local `L`

At the initial public release commit, `src_next/outlook.bqn` already contained:

```text
LatestActualDateInCycle(base, cy)
```

and:

```text
as_of = LatestActualDateInCycle(base, cy)
```

The helper admitted journal dates satisfying approximately:

```text
date >= cycle.start
```

with no observed upper cycle bound.

Outlook then used that local date for:

```text
actual_snapshot.BuildAt(ctx, as_of)
days_left
remaining plan selection
future planned liquid values
daily amounts
reported as_of
```

This matters because it sets a hard evidence boundary.

Public history proves:

```text
local L existed by initial public release
```

Public history does not prove:

```text
who first introduced it
exactly when it was introduced
whether it was explicitly intended as permanent semantics
```

The introduction predates the available public history boundary.

## 10. Initial public release also already contained mixed context semantics

At the same initial public release, `src_next/context.bqn` already had the current broad shape:

```text
BuildContext(base)
  -> read default cycle
  -> use resolved cycle start as ctx.as_of
  -> read cycle again with that value

BuildContext(base, explicit_date)
  -> store explicit date as ctx.as_of
  -> pass it to cycle resolution
```

Therefore `ctx.as_of` was already not a clean old-engine `BuildAt(as_of)` replacement.

Its source depended on constructor form.

Its effect depended on cycle mode.

This weakens any historical story that says:

```text
Outlook should simply have used ctx.as_of
```

The current evidence says the available context field itself was semantically mixed.

## 11. Initial public release already had both `actual_snapshot.BuildAt` and local-default `Build`

At initial public release, `src_next/actual_snapshot.bqn` already exported:

```text
BuildAt(ctx, as_of)
```

with a hard cutoff:

```text
journal date <= as_of
```

and:

```text
Build(ctx)
  -> LatestActualDateInCycle(ctx.base, ctx.cy)
  -> BuildAt(ctx, local_date)
```

So even at the public history boundary, src_next already contained both:

```text
caller-owned explicit cutoff path
module-owned local latest-journal default path
```

This was not introduced by the July 2026 temporal investigation.

The investigation only characterized and named the distinction.

## 12. Historical phase H5: src_next became the production report engine

Current routing says:

```text
src_next is current production report engine
```

Daily operation flows through:

```text
tools/bl
  -> tools/report
  -> src_next/report.bqn
```

Machine summary flows through:

```text
tools/report-next-summary
  -> src_next/summary.bqn
```

Therefore migration-era temporal choices are no longer isolated prototype behavior.

They now sit inside the daily production engine.

This raises the cost of casual fixes and increases the value of characterization.

## 13. Historical phase H6: current investigation rebuilt the temporal evidence

The July 2026 sequence progressively narrowed the problem.

### 13.1 Producer drift

Multiple local clock helpers with similar names had different behavior.

Examples included:

```text
planned latest-in-cycle max

envelope physical source-tail behavior

Outlook lower-bounded but not upper-bounded local date
```

### 13.2 Consumer sensitivity

The same date shift could mean:

```text
hard cutoff
threshold
denominator
future cutoff
window length
period boundary
source order
presentation only
```

This showed that helper deduplication before consumer classification would be unsafe.

### 13.3 Daily Trend characterization

Evidence established:

```text
O moves, L fixed
  -> Daily Trend unchanged

O fixed, L moves
  -> Daily Trend changes
```

This strongly supports:

```text
current Daily Trend is governed by local L rather than explicit ctx.as_of
```

### 13.4 ctx.as_of characterization

Evidence established:

```text
constructor form changes ctx.as_of source
cycle mode changes whether explicit date moves period selection
```

Therefore:

```text
ctx.as_of is not a universally safe report observation value
```

### 13.5 actual_snapshot characterization

Evidence established:

```text
BuildAt(ctx, explicit_cutoff)
  -> obeys supplied hard cutoff

Build(ctx)
  -> derives local L
  -> ignores differing ctx.as_of values as cutoff inputs
```

### 13.6 cutoff ownership map

Current ownership was mapped approximately as:

```text
BuildAt
  caller chooses cutoff

Build
  actual_snapshot module chooses local L

Outlook
  Outlook chooses local L
  then calls BuildAt

canonical Snapshot section
  TBDS period closing semantics
```

This shifted the central question from:

```text
Which date is correct?
```

to:

```text
Who owns the temporal policy for this consumer?
```

## 14. Strongest historical synthesis

The evidence supports the following sequence strongly enough to use as a working foundation:

```text
old engine
  explicit report observation O exists
  L exists separately as journal recency context
        |
        v
src_next migration begins
  observation-time concept incomplete
  period/cycle materialization emphasized
        |
        v
parity pressure
  Outlook / Daily Trend must reproduce household-facing behavior
        |
        v
by initial public release
  local L-based Outlook exists
  local-default actual_snapshot.Build exists
  mixed ctx.as_of exists
        |
        v
parity sections marked matched
        |
        v
src_next becomes production engine
        |
        v
later temporal characterization reveals
  explicit O disconnects
  L dominance
  cycle leaks
  distributed cutoff ownership
```

This sequence is supported by runtime records and migration documents.

## 15. Important inference, not proven fact

A plausible interpretation is:

```text
local L became a compatibility / reconstruction proxy
while src_next lacked a complete observation-time boundary
```

This inference fits:

- old engine explicit O,
- migration note that src_next lacked observation time,
- parity pressure,
- local L already present by initial public release,
- current O/L disconnect evidence.

But it remains an inference.

The available public history does not expose the exact private/pre-public design moment when L was chosen.

Therefore this document does not call L a confirmed migration bug.

## 16. Current architecture must remain bigger than the old engine

Future work should not simply restore the old monolithic `BuildAt` design.

Current architecture deliberately moved away from the old giant record.

The old engine lesson is recorded as:

```text
BuildAt created a 100+ field giant record
sections became deeply coupled
changes became difficult
```

Current design instead prefers:

```text
BuildContext
  -> section Build(ctx)
  -> ViewModel
  -> Format / FormatHuman
```

Therefore a future explicit observation boundary should not recreate:

```text
one giant report record containing every temporal meaning
```

The old O concept may be worth recovering without recovering the old monolith.

## 17. Current accounting architecture constrains future temporal design

Current architecture includes:

```text
Source TSV
  -> Posting IR
  -> Ledger-wide validated postings
  -> Cube
  -> TBDS
  -> accounting reports
  -> household policy layer
  -> household views
```

Important current principle:

```text
cycle / period is report query boundary,
not ledger loading boundary
```

Therefore future temporal design should preserve the difference between:

```text
ledger-wide source truth
period query boundary
observation boundary
household forecast horizon
```

These are not the same problem.

## 18. Future development forces already present in current docs

The canonical time principle already anticipates possible future meanings.

Examples:

```text
occurred_on
due_on
paid_on
belongs_to_period
as_of
data_cutoff
last_recorded_on
horizon_end
generated_at
system_today
```

The roadmap also anticipates future changes such as:

```text
multi-currency
household policy evolution
structured outputs
new report / UI / AI consumers
```

These future features increase the danger of collapsing temporal meaning into one scalar.

Examples:

### Multi-currency

Exchange-rate selection may eventually require its own valuation date or knowledge boundary.

That should not automatically reuse household `as_of`.

### Settlement / payment timing

A future event may have:

```text
occurred_on
due_on
paid_on
settled_on
```

Those are coordinates or domain dates, not observation time.

### External data imports

A future bank-import path may require:

```text
data_cutoff
knowledge cutoff
imported_at
```

Those are not automatically `last_recorded_on`.

### Forecasting

A future forecast may require:

```text
observation O
horizon_end H
scenario rule S
```

without changing Actual.

### Event-sourced experiments

A future event-sourced household project may model knowledge/replay semantics differently.

That future should inform vocabulary and warnings, but should not force bqn-ledger into a universal event-sourcing abstraction.

## 19. Future-proof principle: add meanings sideways, not upward into one object

A future vocabulary may contain meanings such as:

```text
D = coordinate date
O = observation / replay frame
L = last recorded frontier
C = cycle / period boundary
K = data or knowledge cutoff
H = forecast horizon
G = generation time
S = settlement date
```

This does not imply:

```text
TemporalFrame(D,O,L,C,K,H,G,S)
```

The safer rule is:

```text
each calculation reads only the temporal meanings it needs
```

Examples:

```text
actual hard snapshot
  = f(O)

journal recency display
  = f(L)

period trial balance
  = f(C)

forecast
  = f(O,H)

historical replay with known-data boundary
  = f(O,K)
```

New meanings should be added sideways when concrete consumers require them.

## 20. Future-proof principle: ownership before abstraction

Before adding or changing a time value, answer:

```text
Who chooses it?
```

Possible owners include:

```text
source Event
projection contract
report/query entry boundary
consumer module
caller module
cycle resolver
external clock adapter
import boundary
user replay request
```

Only after ownership is clear should code placement be chosen.

This is the strongest lesson from current cutoff work.

## 21. Future-proof principle: `BuildAt`-like APIs are mechanisms, not policy proof

Current Outlook demonstrates:

```text
explicit BuildAt call
  != externally owned observation semantics
```

A caller can derive local L and pass it explicitly.

Therefore API shape alone does not prove semantic ownership.

Future reviews should inspect:

```text
where the argument came from
who chose it
what consumer question it answers
```

## 22. Future-proof principle: keep `L` if it has a real job

The investigation does not justify deleting local latest-recorded concepts.

Possible legitimate uses include:

```text
journal recency
input completeness context
last-recorded frontier display
lag warnings
"data known through" context
```

The problem is not the existence of L.

The problem is silent substitution:

```text
L used as observation O
without a named consumer decision
```

A future fix may preserve L and make its role clearer.

## 23. Future-proof principle: period boundary views may remain independent

The canonical Snapshot section currently uses TBDS period-closing semantics.

That is observably different from `actual_snapshot.BuildAt` hard observation snapshots.

Future design should not assume one must replace the other.

Possible stable coexistence:

```text
Period Closing Snapshot
  -> C / TBDS

Observation Snapshot
  -> O / hard cutoff
```

The shared word "snapshot" may need clearer naming later, but semantic coexistence can be legitimate.

## 24. Future-proof principle: preserve Closed and Open separation

Canonical time policy distinguishes:

```text
Closed
  Actual money
  assets / liabilities
  balance checks
  envelope balances

Open
  Plan
  forecast
  residual
  scenario
  unclassified behavior
```

Future temporal development should preserve this boundary.

Observation or scenario logic must not silently rewrite Actual.

This matters especially when future axes multiply.

## 25. Candidate future development shapes

These are not decisions.

They are compatibility spaces that should remain possible.

### Shape A: keep consumer-local clocks, but name and expose them better

```text
OutlookLatestRecordedOn
DailyTrendLatestRecordedOn
EnvelopeSourceTailDate
```

Advantages:

- minimal behavioral change,
- high compatibility,
- preserves local semantics.

Risks:

- replay remains weak,
- cross-section observation inconsistency may remain,
- local clocks may continue to drift.

### Shape B: explicit report/query observation boundary

```text
report entry chooses O
  -> selected consumers receive O
```

Advantages:

- reproducibility,
- replay,
- clearer observation consistency.

Risks:

- not every consumer should use O,
- current `ctx.as_of` cannot simply be reused,
- cycle selection and observation must stay distinct,
- parity changes may be broad.

### Shape C: dual explicit O + explicit L

```text
O = from where the report is observed
L = last recorded frontier / recency context
```

Advantages:

- closest to old conceptual separation,
- supports replay and recency together,
- avoids pretending missing recent data is observation time.

Risks:

- more visible temporal vocabulary,
- consumers must choose intentionally,
- requires careful output contracts.

### Shape D: report-specific query objects

Examples:

```text
OutlookQuery {
  observation
  period
  horizon
}

ActualSnapshotQuery {
  observation
}
```

Advantages:

- ownership is explicit,
- no universal TemporalFrame,
- future axes can be added locally.

Risks:

- more small records / namespaces,
- possible over-design if added before concrete need.

### Shape E: preserve current behavior and only characterize

Advantages:

- zero compatibility risk,
- more evidence can accumulate.

Risks:

- known historical-cycle leak remains,
- explicit replay remains incomplete,
- semantic debt may grow.

No shape is selected here.

## 26. Outlook-specific decision foundation

Before changing Outlook, answer the household question first.

Possible questions include:

```text
Q1. What can I safely spend from the report observation date O until cycle end?

Q2. What can I safely spend from the last recorded actual date L until cycle end?

Q3. What can I safely spend now, while also showing that records are only current through L?

Q4. For a historical cycle, what would Outlook have shown at historical observation O?

Q5. For a historical cycle, what does present knowledge say retrospectively?
```

These are different products.

Current code should not choose between them accidentally through a helper.

A runtime decision should first choose which question canonical Outlook answers.

## 27. Daily Trend-specific decision foundation

Daily Trend still has unresolved Candidate A / B semantics.

Approximate shapes:

```text
Candidate A
  historical row D observed from D or fixed historical frame

Candidate B
  historical row D retrospectively projected from observation O
```

Old runtime behavior was Candidate-B-like in some formulas because shared future income was relative to report-wide O.

Current src_next uses local L instead.

The current evidence therefore does not justify:

```text
historical rows must never change
```

or:

```text
historical rows should always use latest knowledge
```

Observation consistency remains the protected property until semantics are chosen.

## 28. ctx.as_of-specific decision foundation

Current `ctx.as_of` should not be promoted to global observation time without redesign.

Characterized behavior shows:

```text
constructor form changes value source
cycle mode changes period-selection effect
```

Possible future directions include:

```text
rename / narrow ctx.as_of
split cycle selection anchor from observation O
add explicit query observation at a higher boundary
leave context unchanged and pass O separately
```

No direction is selected here.

## 29. actual_snapshot-specific decision foundation

Current exported paths are semantically distinct:

```text
BuildAt
  caller-owned hard cutoff

Build
  module-owned local-L policy
```

Before changing them, determine:

```text
Does any current non-canonical consumer rely on Build(ctx)?
Is Build a compatibility API?
Should default policy remain module-owned?
Would renaming be safer than deleting?
```

Repository-wide consumer absence has not yet been proven exhaustively.

## 30. Test strategy for future temporal changes

Future temporal tests should move meanings independently.

Minimum useful matrix:

```text
A. O moves, source fixed, L fixed
B. L moves, O fixed
C. cycle C moves, O fixed
D. source order changes, coordinate set fixed
E. later unrelated Event appears
F. historical cycle selected with later source data present
G. empty journal
H. future plan exists across cutoff
I. same-day plan at cutoff
J. observation before first actual
K. observation after cycle end
```

Assertions should distinguish:

```text
row membership
balance cutoff
future plan inclusion
days-left denominator
status threshold
presentation label
recency context
```

Do not assert only final totals when the temporal mechanism matters.

## 31. Development gate before any runtime change

For one consumer only:

### Gate 1: name the consumer question

Example:

```text
What exact household question does Outlook answer?
```

### Gate 2: name required temporal meanings

Example:

```text
O?
L?
C?
H?
```

### Gate 3: assign ownership

Example:

```text
report entry owns O
Outlook owns H
journal recency view owns L
cycle resolver owns C
```

### Gate 4: characterize current behavior

Use fixture evidence.

### Gate 5: compare historical behavior

Determine whether a change is:

```text
restoration
intentional replacement
new semantics
bug fix
compatibility break
```

### Gate 6: define protected property

Choose one:

```text
observation consistency
period containment
historical stability
cross-domain independence
auditability
reproducibility
```

Do not bundle all properties.

### Gate 7: smallest runtime slice

Change one owner / one consumer / one property.

## 32. What not to do next

Do not begin with:

```text
replace every LatestActualDateInCycle
```

Do not begin with:

```text
wire every module to ctx.as_of
```

Do not begin with:

```text
add TemporalFrame
```

Do not begin with:

```text
restore old BuildAt giant record
```

Do not begin with:

```text
make all snapshot-like sections use one API
```

Do not begin with:

```text
add all future date fields to TSV
```

Each of these starts from implementation shape before consumer meaning.

## 33. Suggested near-term investigation sequence

This is a reasoning sequence, not an authorized runtime plan.

### Step 1: Outlook intent history

Already partially reconstructed here.

Remaining question:

```text
Was local L intended as permanent household semantics,
or was it a migration compatibility proxy?
```

Public history cannot fully answer the pre-public design moment.

Use behavior evidence and domain question rather than pretending the missing commit exists.

### Step 2: Outlook consumer question

Write a narrow decision note comparing Q1-Q5 from section 26.

Do not code.

### Step 3: external observation boundary feasibility

Investigate where an explicit O could enter without reusing mixed `ctx.as_of`.

Possible boundary:

```text
report/query entry
```

but do not implement until ownership is chosen.

### Step 4: actual_snapshot.Build consumer proof

When tooling permits exhaustive repository search, prove or disprove current consumers of the module-owned default path.

### Step 5: choose one protected property

Only then choose the next runtime slice.

## 34. Relationship to current TODO

Current `TODO.md` still routes toward a runtime decision choosing one protected property before Slice B.

Recent PRs #79-#87 added materially stronger evidence about:

```text
observation consistency
ctx.as_of ambiguity
actual_snapshot explicit/default paths
cutoff ownership
```

Therefore the TODO runtime-decision line should be revisited in a separate finite documentation slice before code changes.

This foundation does not silently rewrite TODO routing.

## 35. Future relationship to a separate event-sourced household project

A future event-sourced array-engine project may explicitly model:

```text
event occurrence
recorded knowledge
replay observation
plans
actuals
issues / decisions
budget state
```

That project may discover useful vocabulary.

But bqn-ledger should not be retrofitted merely to resemble it.

The safer relationship is:

```text
share lessons
share warnings
share tests where semantics match
keep architectures independent where ownership differs
```

This preserves the current repo as a durable daily tool while allowing a new research vehicle to explore stronger replay/event semantics.

## 36. Core principles carried forward

```text
Different temporal meanings keep different names.

New temporal meanings are added sideways when a consumer needs them.

Old meanings are not silently redefined.

Implicit fallback behavior should become explainable before it becomes shared.

Only meanings proven equivalent should be unified later.

Duplication is cheaper than semantic confusion.

Separation is a result of discovery, not a design goal by itself.

Do not complete the time model.

Keep future axes possible without forcing them into one object.

Preserve evidence before repair.

Decide ownership before implementation.
```

## 37. Current working conclusion

The strongest current story is not:

```text
src_next forgot to add one missing time axis
```

It is closer to:

```text
old engine had explicit report observation O

src_next migration began before observation semantics were complete

parity work reconstructed household-facing sections

local latest-journal dates were already present by the initial public release

those local dates survived parity and production adoption

current investigation revealed that O, L, ctx.as_of, period boundaries,
and cutoff ownership are not aligned uniformly
```

The next development step should therefore not be a mechanical date substitution.

The next development step should be a consumer-level ownership decision made with:

```text
history
current characterization
household meaning
future extension space
```

all visible at the same time.

That is the purpose of this foundation.
