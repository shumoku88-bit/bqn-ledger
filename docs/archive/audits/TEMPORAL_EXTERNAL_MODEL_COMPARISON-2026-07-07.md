# Temporal External Model Comparison - 2026-07-07

Status: docs-only external model comparison / architecture archaeology
Owner: other
Canonical: no
Canonical temporal principle: `docs/TIME_AS_AXIS.md`
Current Outlook decisions: PRs #90-#96
Exit: retain as historical evidence; later canonical decisions may cite conclusions but should not silently inherit analogies

## 0. Purpose

Recent temporal work in `bqn-ledger` separated several meanings:

```text
D = event / projection coordinate
O = observation frame
L = last recorded actual-coordinate frontier
C = cycle / period boundary
H = forecast horizon
K = possible data / knowledge cutoff
system_today = external wall-clock default
```

The repository has now also introduced a caller-owned explicit Outlook path:

```text
outlook.BuildAt(ctx, O)
```

while preserving `L` separately as record-frontier context.

This raises a new architecture question:

```text
Are we rediscovering an existing temporal model?
```

This document compares current `bqn-ledger` semantics with established external models before any shared temporal abstraction is introduced.

The goal is to classify:

```text
A. existing wheels we should not rebuild
B. useful analogies that are not semantic identity
C. household-specific meanings that remain local
D. evidence required before a shared temporal kernel is justified
```

This is not a standards-conformance exercise.

It is a guard against both:

```text
unnecessary reinvention
```

and:

```text
false equivalence with a famous external concept
```

## 1. Evidence sources

Primary or project-authoritative sources inspected for this comparison:

### Apache Flink timely stream processing

```text
https://nightlies.apache.org/flink/flink-docs-stable/docs/concepts/time/
```

Relevant concepts:

```text
event time
processing time
watermarks
lateness
windows
```

### Google Dataflow model paper

```text
https://research.google/pubs/the-dataflow-model-a-practical-approach-to-balancing-correctness-latency-and-cost-in-massive-scale-unbounded-out-of-order-data-processing/
```

Relevant concepts:

```text
event-time ordering
windows
unbounded and out-of-order data
correctness / latency / cost tradeoff
```

### XTDB bitemporality documentation

```text
https://v1-docs.xtdb.com/concepts/bitemporality/
```

Relevant concepts:

```text
valid time
transaction time
domain time
retroactive correction
as-at / as-of queries
```

### Datomic database filters

```text
https://docs.datomic.com/reference/filters.html
```

Relevant concepts:

```text
as-of transaction filtering
since
history
point-in-time database values
```

### Microsoft Event Sourcing pattern

```text
https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing
```

Relevant concepts:

```text
append-only event stream
replay
projections / materialized views
snapshots as optimization
schema evolution and ordering costs
```

## 2. Evidence boundary

This comparison intentionally avoids claiming:

```text
bqn-ledger implements Flink semantics
bqn-ledger is a bitemporal database
bqn-ledger is an event-sourced system
bqn-ledger O equals Datomic as-of
bqn-ledger L equals a watermark
```

The purpose is to identify overlap and non-equivalence precisely.

## 3. Current bqn-ledger temporal baseline

Canonical `docs/TIME_AS_AXIS.md` already states:

```text
Time is not a label.
Time is an axis.
```

and distinguishes:

```text
coordinate time
observation time
external clock time
generation time
data cutoff
last recorded frontier
forecast horizon
period / cycle
```

Current implementation remains intentionally non-uniform.

Important current runtime examples:

### Human Outlook

```text
report entry selects O
  explicit --outlook-as-of
  or one-time system_today default
        |
        v
outlook.BuildAt(ctx, O)
```

Outlook separately derives current `L` from journal coordinate evidence.

### Daily Trend

Current `src_next/daily_trend.bqn` still derives local:

```text
LatestActualDateInCycle(base, cy)
```

and uses it as local `as_of`.

### actual_snapshot

```text
BuildAt(ctx, cutoff)
  caller owns cutoff

Build(ctx)
  module derives local L
```

### context

Current `ctx.as_of` source depends on constructor form and can also participate in cycle resolution depending on cycle mode.

Therefore the external comparison must start from multiple current meanings, not from one presumed global date.

## 4. Flink / Dataflow comparison

## 4.1 Existing wheel: multiple notions of time

Flink explicitly distinguishes:

```text
processing time
  = system time of executing machine

event time
  = timestamp of the event itself
```

and states that event-time progress depends on data rather than wall clocks.

This strongly supports a broad principle already present in `bqn-ledger`:

```text
external clock
!=
event coordinate
```

Approximate analogy:

```text
Flink processing time
  ~ external wall clock role

bqn-ledger system_today
  ~ external wall-clock input
```

But the analogy is limited.

Current `bqn-ledger` uses `system_today` primarily as a default observation input at report entry, not as a general execution-time basis for every time operation.

Therefore:

```text
system_today
!= Flink processing time semantics
```

## 4.2 Coordinate D partially resembles event time

Approximate analogy:

```text
Flink event time
  ~ timestamp embedded in an event

bqn-ledger D
  ~ event / projection coordinate
```

This is useful but incomplete.

`bqn-ledger` explicitly anticipates multiple domain coordinates:

```text
occurred_on
due_on
paid_on
belongs_to_period
```

while a particular stream element's event-time timestamp is one selected event-time coordinate for processing.

Therefore:

```text
D is a family of possible domain/projection coordinates
```

not one universal event-time field.

## 4.3 Critical non-equivalence: L is not a watermark

Flink watermarks represent event-time progress.

A watermark with timestamp `t` is a progress declaration that event time has reached `t`, with an expectation about older events, while acknowledging that late events can violate that expectation.

Current `bqn-ledger` `L` means approximately:

```text
maximum admitted recorded actual coordinate
```

Current Outlook producer evidence:

```text
max journal coordinate in producer scope
```

The selected frontier contract explicitly does not claim:

```text
all records through L are complete
no earlier Event will arrive later
input processing has progressed through L
knowledge is complete through L
```

Therefore:

```text
L != watermark
```

This is one of the strongest findings of this comparison.

Renaming `L` to:

```text
watermark
```

would be incorrect.

Treating `L` as an implicit completeness boundary would also be incorrect.

## 4.4 C partially resembles a window, but is not stream progress

Flink / Dataflow use windows to scope aggregation over unbounded data.

Current `bqn-ledger` has:

```text
cycle = [start, end_exclusive)
```

Approximate analogy:

```text
C
  ~ a time-window boundary used for selected aggregation
```

But current household cycle also carries domain meaning:

```text
income cadence
household spending period
pension-linked life cycle
```

and is a report query boundary rather than a stream-completion trigger.

Therefore:

```text
C may behave geometrically like a window
but is not a watermark-driven stream window contract
```

## 4.5 Reinvention classification

Existing wheel we should not rebuild:

```text
separate wall-clock time from event coordinate
separate event coordinate from progress/completeness signals
make windows explicit
expect out-of-order data to complicate temporal claims
```

Repository-specific work still needed:

```text
which household consumer owns O
what producer scope defines L
what household question C bounds
whether H coincides with C for a given product
```

## 5. Bitemporal comparison

## 5.1 Existing wheel: valid time and transaction time are distinct

XTDB exposes bitemporal queries using separate valid-time and transaction-time dimensions.

Its documentation shows query shapes equivalent to:

```text
what was valid at domain time V
as known at transaction time T
```

This is highly relevant to unresolved `bqn-ledger` historical products.

The previously named candidate questions:

```text
Q4 historical replay at historical O
Q5 retrospective view using present knowledge
```

are recognizably related to bitemporal query distinctions.

The external model demonstrates that these are not exotic questions invented by this repository.

## 5.2 D may partially resemble valid time

Current event / projection coordinate `D` may play a valid-time-like role when it means:

```text
when the event occurred
when the fact belongs in the modeled household timeline
```

But not every current `date` is proven to mean one canonical valid time.

Future coordinates such as:

```text
due_on
paid_on
belongs_to_period
```

are domain times with different meanings.

XTDB itself distinguishes native valid time from additional domain/user-defined times.

This supports current `TIME_AS_AXIS` policy:

```text
do not force every temporal attribute into one date
```

## 5.3 Critical non-equivalence: L is not transaction time

Current `L` is derived from event coordinates.

Example:

```text
L = max admitted journal.date
```

Transaction time instead records when information entered or changed in the database / transaction history.

These are fundamentally different.

Suppose a household Event occurred on:

```text
2026-01-03
```

but was entered on:

```text
2026-01-10
```

Current five-column journal only preserves the first date if that is the row coordinate.

It does not preserve the second date automatically.

Therefore:

```text
L != transaction time
```

and:

```text
max event coordinate
!= latest ingestion / knowledge time
```

## 5.4 Current bqn-ledger is not truly bitemporal

A true bitemporal reconstruction requires two independently preserved temporal dimensions.

Current source TSV does not generally preserve:

```text
recorded_at
transaction_time
knowledge_from
knowledge_to
```

for every fact or Event.

Current repository also allows source correction through ordinary TSV editing rather than preserving every correction as immutable transaction history.

Therefore current `bqn-ledger` cannot generally answer:

```text
What did the system know on 2026-01-05
about an Event whose domain date was 2026-01-03?
```

unless the required knowledge history happens to be recoverable from another artifact.

This means:

```text
current bqn-ledger is not a bitemporal database
```

and should not be described as one.

## 5.5 K is the closest open slot, but remains unimplemented

Current canonical vocabulary reserves:

```text
K = possible data / knowledge cutoff
```

A future `K` could support questions closer to:

```text
which input knowledge was admitted
```

But `K` is currently not implemented as preserved transaction history.

Adding one cutoff parameter would still not automatically make the data model bitemporal.

A cutoff can only filter history that exists.

## 5.6 Reinvention classification

Existing wheel we should not rebuild blindly:

```text
valid-time / transaction-time separation
as-at / as-of historical questions
retroactive correction models
```

Repository-specific questions remain:

```text
do we need knowledge-time history at all?
which household products require Q4 vs Q5?
should current repo preserve correction history?
or should stronger bitemporal semantics belong to the separate event-sourced project?
```

## 6. Datomic as-of comparison

## 6.1 Existing wheel: point-in-time database views

Datomic `as-of` returns a database view that ignores transactions after a selected transaction/time point.

This is a real historical database-state filter.

Current `bqn-ledger` uses the name `as_of` in several paths, but current meanings are not identical.

For example:

```text
actual_snapshot.BuildAt(ctx, O)
```

currently filters journal rows by:

```text
row coordinate <= O
```

That is an event-coordinate cutoff.

It is not a filter over preserved transaction history.

Therefore:

```text
bqn-ledger as_of
!= Datomic as-of
```

## 6.2 Main lesson: same name does not prove same axis

This external comparison strengthens a principle already discovered internally:

```text
API name as_of
!= semantic ownership proof
```

The question must remain:

```text
What history is being cut?
Event-coordinate history?
Transaction history?
Knowledge history?
Projection horizon?
```

This is directly relevant to current mixed `ctx.as_of` semantics.

## 7. Event Sourcing comparison

## 7.1 Existing wheel: event stream, replay, projections

The Event Sourcing pattern preserves changes as events, reconstructs state by replay, and commonly builds query-friendly projections / materialized views.

This resembles several `bqn-ledger` directions:

```text
source rows
  -> Event / Posting IR
  -> projection
  -> cube / TBDS / section ViewModels
```

The future separate household project is even closer because it is explicitly being considered as event-sourced.

## 7.2 Current bqn-ledger is not strict Event Sourcing

Current `bqn-ledger` source truth is not one immutable event stream.

It includes multiple source files such as:

```text
journal.tsv
plan.tsv
budget_alloc.tsv
accounts.tsv
cycle.tsv
issues.tsv
```

Current workflow also permits direct source editing for corrections and deletion.

There is no general immutable event sequence that preserves every mutation to all source state.

Therefore:

```text
current bqn-ledger != strict Event Sourcing
```

Calling current journal rows "events" remains useful as a domain/projection concept, but does not by itself establish the architectural pattern.

## 7.3 Snapshots: useful analogy, different contracts

Event Sourcing guidance treats snapshots as an optimization over replayed event streams.

Current `bqn-ledger` has multiple snapshot-like concepts:

```text
actual_snapshot.BuildAt
canonical Snapshot section via TBDS
cached/materialized report structures
```

These do not all have Event Sourcing snapshot semantics.

The shared word `snapshot` is not enough to unify them.

## 7.4 Reinvention classification

Existing wheel we should not rebuild casually:

```text
append-only stream mechanics
entity stream ordering
optimistic concurrency
snapshot/replay infrastructure
event schema versioning
idempotent projection handling
```

If the future separate project becomes truly event-sourced, those concerns should be treated as established engineering problems rather than invented locally from scratch.

Current `bqn-ledger` should not be retrofitted merely to resemble that pattern.

## 8. Cross-model comparison matrix

```text
bqn-ledger meaning     Flink/Dataflow             Bitemporal / XTDB          Datomic               Event Sourcing

D coordinate           partial event-time        partial valid/domain time  not tx as-of           event payload/domain date

O observation          query frame               query perspective          superficially as-of    replay/query boundary candidate

L recorded frontier    NOT watermark              NOT transaction time       not basis-t             not stream position by default

C cycle boundary       partial window analogy     domain interval/window     query range             projection boundary candidate

H horizon              future window boundary     domain/query horizon       not core as-of           projection policy

K knowledge cutoff     no direct identity         closest to knowledge/tx     possible tx filter       replay/admission boundary candidate

system_today           partial wall-clock analogy not valid/tx time          wall-clock instant input runtime clock/default
```

The key result is:

```text
no external column maps one-to-one onto the whole current model
```

## 9. What is clearly wheel reinvention

The repository should avoid building its own general-purpose versions of:

```text
calendar library
Gregorian date validation framework
generic interval algebra
stream watermark engine
late-event processing framework
bitemporal database index
transaction-time history engine
generic event store
optimistic concurrency protocol
event schema migration framework
```

unless a concrete repository requirement cannot be met by a simpler dependency or by keeping the problem out of this repository.

## 10. What is not merely wheel reinvention

The following are household-specific enough to remain legitimate local design work:

```text
which household question Outlook answers
who owns Outlook O
how pension / income cadence defines C
whether safe-spend horizon H equals C for a product
how L is displayed as record freshness without completeness claims
Closed Actual vs Open Plan / Forecast separation
integer-yen accounting invariants across temporal projections
```

These are composition and ownership decisions, not generic temporal infrastructure.

## 11. Shared temporal kernel question

A possible future module has been informally imagined as:

```text
src_next/temporal.bqn
```

or:

```text
src_next/temporal_relation.bqn
```

This comparison changes the recommendation.

## 11.1 Decision: do not create a shared temporal kernel yet

Current evidence is insufficient.

Today, the strongest candidate shared logic is Outlook-local:

```text
ClassifyRecordFrontier(O, L)
  -> before_observation
  -> at_observation
  -> after_observation
  -> unavailable
```

But one consumer is not enough evidence that a shared module is needed.

The current implementation should remain local until another independent consumer requires the same producer-independent relation.

## 11.2 Extraction trigger

A shared temporal relation module becomes justified only when all of the following are true:

```text
1. A second independent consumer needs the same relation semantics.

2. Inputs arrive already named and selected.
   The helper does not choose O, L, C, H, or K.

3. The helper contains no producer policy.
   It does not read journal.tsv or cycle.tsv.

4. The helper contains no external clock policy.
   It does not read Today.

5. Unavailable state remains explicit.
   It does not invent cycle.start or O as fallback evidence.

6. Tests move input axes independently.

7. Extraction removes duplicated relation algebra,
   not merely similarly named functions.
```

## 11.3 Allowed shape of a future small kernel

Possible examples only after the trigger is met:

```text
RelativePosition(a, b)
  -> before | at | after

AbsDistanceDays(a, b)

HalfOpenContains(start, end_exclusive, x)
```

Even these helpers should be extracted only when exact semantics repeat.

The consumer should translate generic relation into domain vocabulary where needed.

## 11.4 Forbidden responsibilities for a shared kernel

Do not put these into a generic temporal module:

```text
LatestActualDateInCycle
RecordedFrontierInfo
BuildContext
cycle selection
Today default policy
Outlook O source
Daily Trend observation policy
watermark inference
knowledge completeness claims
bitemporal replay
```

Those functions choose or produce meanings and therefore carry ownership policy.

## 12. Current duplicate helper conclusion

Current similar helper names are not enough reason to deduplicate.

Observed examples:

### Outlook frontier producer

Current shape:

```text
journal date >= cycle.start
no upper cycle bound
absence explicit in RecordedFrontierInfo
```

### Daily Trend local latest producer

Current shape:

```text
cycle.start <= journal date < cycle.end_exclusive
fallback cycle.start
```

### actual_snapshot local latest producer

Current shape:

```text
cycle-contained
fallback cycle.start
```

These are not proven equivalent.

Therefore:

```text
same-looking LatestActualDateInCycle helpers
```

must not be unified before producer contracts are chosen.

## 13. Strongest findings

### Finding A

The repository is rediscovering a known broad truth:

```text
multiple notions of time must remain distinct
```

This is an existing wheel.

### Finding B

Current `L` is neither:

```text
watermark
transaction time
knowledge cutoff
```

It is a weaker recorded-coordinate frontier.

### Finding C

Current `O` is neither automatically:

```text
Datomic transaction as-of
XTDB transaction time
Flink processing time
```

It is a household/query observation frame whose exact effect is consumer-specific.

### Finding D

Current `bqn-ledger` cannot support true bitemporal historical knowledge reconstruction from existing source data alone because it does not preserve a general transaction/recorded-time history.

### Finding E

Current `bqn-ledger` is not strict Event Sourcing despite event/projection language.

### Finding F

A general temporal abstraction now would likely be premature wheel reinvention.

A small producer-free relation kernel may become justified later, but only after independent repetition.

## 14. Implications for the next temporal work

This comparison changes the recommended next move.

Do not proceed immediately with:

```text
summary -> same O wiring
```

merely because human Outlook now has explicit O.

Do not proceed with:

```text
extract ClassifyRecordFrontier into temporal.bqn
```

merely because the function looks generic.

Instead, inspect the next consumer and ask:

```text
Does it actually require the same relation?
Does it require O at all?
Does it need L or a stronger K?
Is its historical question Q4-like or Q5-like?
```

The best next evidence candidate remains Daily Trend because it still contains local-L observation policy and already has characterization history.

But external models add one new warning:

```text
do not treat Daily Trend local L as a watermark or knowledge frontier
```

The next Daily Trend decision should preserve that limitation explicitly.

## 15. Recommended next finite slice

Recommended next slice:

```text
docs/test-only:
classify Daily Trend against external temporal analogies
without changing runtime
```

Questions:

```text
1. Is Daily Trend asking an event-time/window question?

2. Is its local L merely a coordinate frontier,
   or is current code implicitly treating it as completeness?

3. Does historical replay require an O axis only,
   or eventually a preserved K / transaction-history axis?

4. Which current terms are O-relative,
   row-D-relative,
   C-relative,
   or accidentally L-relative?
```

One protected property should still be selected before any Daily Trend runtime change.

## 16. Non-goals carried forward

Do not:

```text
add universal TemporalFrame
rename L to watermark
claim L is transaction time
claim current repo is bitemporal
claim current repo is Event Sourcing
simulate transaction time from TSV file order
infer knowledge completeness from max journal date
make every consumer use Outlook O
create shared temporal helpers from name similarity alone
```

## 17. Decision summary

```text
Wheel reinvention risk:
  real

Existing wheels recognized:
  event time vs wall clock
  watermark / progress concepts
  windows
  valid vs transaction time
  point-in-time database views
  event replay / projections / materialized views

Critical non-equivalences:
  L != watermark
  L != transaction time
  O != Datomic as-of
  C != stream completion window
  current repo != bitemporal database
  current repo != strict Event Sourcing

Shared temporal kernel:
  not yet justified

Extraction trigger:
  second independent consumer
  same exact relation semantics
  producer-free
  policy-free
  clock-free
  explicit unavailable state

Next evidence target:
  Daily Trend external-model classification
  docs/test-only before runtime change
```

The main lesson is not that `bqn-ledger` should copy one external model.

It is that several mature fields already warn against collapsing temporal meanings, while the household-specific composition of `O`, `L`, `C`, and `H` remains a real local design problem.
