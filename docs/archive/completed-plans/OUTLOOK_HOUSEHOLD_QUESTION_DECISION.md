# Outlook Household Question Decision

Status: current decision / pre-runtime consumer contract
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Historical evidence: `docs/archive/audits/TEMPORAL_HISTORY_AND_FUTURE_FOUNDATION-2026-07-07.md` and `docs/archive/audits/TEMPORAL_LEGACY_EVIDENCE_CORRECTION-2026-07-07.md`
Exit: revise or archive after an explicit Outlook runtime contract and characterization-backed implementation consume this decision

## 0. Purpose

Current temporal work has established that Outlook cannot be repaired safely by choosing one existing date field and wiring everything to it.

The current engine contains distinct temporal meanings, including:

```text
D = coordinate date
O = observation / replay frame
L = local latest-recorded frontier
C = cycle / period boundary
H = possible forecast horizon
K = possible data / knowledge cutoff
```

`docs/TIME_AS_AXIS.md` is authoritative that these meanings must not be collapsed into one global date.

The immediate design question is therefore not:

```text
Which existing date variable should Outlook use?
```

It is:

```text
What household question does canonical Outlook answer?
```

This document selects that question before any runtime change.

## 1. Decision

Canonical Outlook should answer this household question:

> At observation date `O`, what liquid spending room can the household rely on through the active cycle end `C` under the selected Outlook policy, while separately showing that actual records are current only through `L`?

This is the Q3 direction from the temporal investigation:

```text
What can I safely spend at O,
while separately showing that records are current only through L?
```

The word `safely` is policy-sensitive.

This decision does not declare every visible asset, envelope balance, unassigned budget amount, or forecast amount safe to spend.

A value may be presented as safe only when the relevant Outlook policy and reserve semantics justify that label.

The central temporal decision is narrower:

```text
O = the date from which the household question is asked
L = the freshness frontier of recorded actual evidence
C = the active cycle boundary used by the question
```

`O` and `L` may differ.

## 2. Example

Suppose:

```text
O = 2026-07-07
L = 2026-07-05
C = 2026-08-15
```

The Outlook question is:

```text
What spending room is available as observed on 2026-07-07
through the active cycle end 2026-08-15?
```

The record-freshness statement is separately:

```text
actual records are current only through 2026-07-05
```

The household world does not become frozen at `L` merely because journal entry is two days behind.

At the same time, Outlook must not pretend that actual evidence is current through `O` when it is not.

Therefore:

```text
O != L
```

is a normal supported state, not an error to erase.

## 3. Why this question is selected

The alternative candidate questions are materially different products.

### Q1: spend from O until cycle end

```text
What can I safely spend from observation O until cycle end?
```

This captures the decision frame but does not by itself require record freshness to be visible.

The selected question retains the O-based decision frame and adds explicit L visibility.

### Q2: spend from L until cycle end

```text
What can I safely spend from last recorded frontier L until cycle end?
```

Not selected.

This would make journal recency the household observation frame.

That may be a legitimate specialized product, but it is not selected as canonical Outlook.

### Q4: historical Outlook at historical O

```text
For a historical cycle,
what would Outlook have shown at historical O?
```

Not selected here.

This is a historical replay / audit product and requires an explicit historical observation contract.

### Q5: retrospective present-knowledge Outlook

```text
For a historical cycle,
what does present knowledge say retrospectively?
```

Not selected here.

This is a present-knowledge retrospective product and is semantically distinct from historical replay.

Q4 and Q5 remain open future products.

They must not be smuggled into canonical Outlook through implicit local clocks.

## 4. Named temporal meanings

### 4.1 Observation `O`

Meaning:

```text
the date from which the household asks the Outlook question
```

Examples of O-relative concerns include:

```text
actual snapshot visibility
remaining-plan windows
days remaining in the active cycle
daily spending denominators
```

Ownership decision:

```text
report query / caller owns selection of O
Outlook consumes O and applies Outlook-specific semantics
```

This decision does not choose the current API that carries `O`.

In particular, it does not declare:

```text
ctx.as_of == canonical Outlook O
```

PR #85 characterized that current `ctx.as_of` source and effect depend on constructor form and cycle mode.

Therefore a later runtime slice must establish a trustworthy O path rather than blindly reusing a same-named field.

### 4.2 Last-recorded frontier `L`

Meaning:

```text
the freshness frontier of recorded actual evidence
```

Ownership decision:

```text
actual-record / journal evidence derives L
Outlook may display and use L as freshness context
L does not own the household observation frame
```

This decision does not yet standardize the producer algorithm for `L`.

A later contract must still define scope questions such as:

```text
which actual rows are admitted
whether period containment applies
whether data cutoff K exists
what empty-input fallback means
```

The current `LatestActualDateInCycle` helper is behavioral evidence, not automatically the future L contract.

### 4.3 Cycle boundary `C`

Meaning:

```text
the active household period boundary used by the Outlook question
```

Ownership decision:

```text
cycle / period resolution owns C
Outlook consumes C
```

This decision does not change current cycle resolution.

It also does not make `C` an event coordinate or observation date.

### 4.4 Horizon `H`

Meaning:

```text
the future boundary through which a projection is observed
```

For the selected canonical Outlook question, the primary spending-room horizon is initially the active cycle end.

That does not prove semantic identity:

```text
H == C forever
```

A future Outlook may legitimately expose forecasts beyond the active cycle.

Therefore horizon meaning remains separate even when a specific product currently chooses the same date value as `C`.

### 4.5 Data / knowledge cutoff `K`

Not selected or introduced by this decision.

If later required, `K` must remain distinct from both `O` and `L`.

## 5. Ownership summary

```text
O
  selected by report query / caller
  interpreted by Outlook

L
  derived from actual-record evidence
  consumed by Outlook as freshness context

C
  selected by cycle / period resolution
  consumed by Outlook

H
  selected by projection / consumer contract
  may currently coincide in value with C

K
  not introduced here
```

The key ownership rule is:

```text
Outlook must not silently manufacture O from L
```

This does not prohibit Outlook from reading `L`.

It prohibits using record freshness as an unnamed substitute for observation policy.

## 6. First protected property

The first protected temporal property for subsequent Outlook runtime work is:

```text
observation consistency
```

For Outlook, observation consistency means:

> Every O-relative term must have an explainable dependency on the selected observation frame `O`; a change in record freshness `L` must not silently redefine that observation frame.

This does not mean every term uses one date.

A valid Outlook can combine distinct frames intentionally:

```text
observation-relative term -> O
freshness term            -> L
period-bound term         -> C
projection horizon        -> H
```

A term may depend on more than one meaning when the household contract requires it.

The composition must be named and explainable.

## 7. Consequences of the selected property

The following are semantic directions for later runtime characterization and design.

They are not runtime changes in this docs-only slice.

### Actual snapshot used by Outlook

Expected dependency shape:

```text
Outlook actual snapshot visibility -> O
```

A hard-cutoff mechanism may be used to enforce this, but this decision does not mandate a specific function call.

In particular, it does not say:

```text
replace all actual_snapshot.Build with BuildAt
```

### Days left / elapsed

Expected dependency shape:

```text
days_left    -> O + C
days_elapsed -> O + C
```

Record freshness `L` must not silently become the denominator date merely because journal entry is behind.

### Remaining plans

Expected dependency shape:

```text
remaining-plan window -> O + C + plan lifecycle semantics
```

This decision does not redefine plan lifecycle or anchor behavior.

### Planned future liquid values

Expected dependency shape:

```text
future planned liquid contribution -> O + C + plan semantics
```

Again, `L` does not become the future-plan cutoff merely by being the latest journal coordinate.

### Daily spending amounts

Expected dependency shape:

```text
daily amount -> selected policy inputs + O + C
```

The exact policy inputs remain governed by Outlook risk/reserve semantics.

Observation consistency alone does not prove that a value deserves a `safe` label.

### Record freshness and lag

Expected dependency shape:

```text
last recorded frontier -> L
record lag              -> O - L
```

The precise lag definition must handle edge cases explicitly, including:

```text
L > O
empty actual input
out-of-period actual rows
future-dated rows
```

Those edge cases are not decided here.

### Next-cycle obligations

Not fully decided here.

Current Outlook has next-cycle obligation behavior at a boundary beyond the active cycle window.

A later finite slice should name whether that concern depends on:

```text
C
H
next-cycle boundary
or another explicit contract
```

It must not be bundled into the first O/L repair.

### Envelope breakdown

Not fully decided here.

Envelope values have their own allocation and backing semantics.

This decision does not claim that every envelope value is O-relative, nor that ledger unassigned is safe to spend.

Existing envelope safety notes in `docs/REPORT_CONTRACTS.md` remain unchanged.

## 8. Current runtime evidence

Current `src_next/outlook.bqn` approximately does:

```text
as_of = LatestActualDateInCycle(base, cy)

snapshot = actual_snapshot.BuildAt(ctx, as_of)

days_left = cycle_end_exclusive - as_of

remaining plans start at as_of

reported as_of = local L
last_journal   = local L
journal_lag    = 0
```

So current Outlook approximately collapses:

```text
O-shaped report reference role
and
L record-freshness role
```

into one local date value.

This document does not label that history as a simple bug.

It records that the selected future household question requires those meanings to be separable.

## 9. Historical evidence behind the decision

The archived legacy repository materially changes the fairest historical account.

Supported sequence:

```text
old production engine
  explicit O
  separate L
        |
        v
early src_next context
  no O field
        |
        v
Outlook birth
  local L used as as_of
        |
        v
migration docs
  O/L mismatch explicitly recognized
        |
        v
automated parity
  src_next-selected L injected into old-engine explicit O slot
        |
        v
same-date calculation parity demonstrated
  semantic O/L equivalence not demonstrated
        |
        v
BuildAt hard-cutoff mechanism added later
  caller policy remains local L
        |
        v
production adoption
```

Therefore the selected interpretation is not:

```text
L was an invisible accidental bug
```

and not:

```text
L and O were historically proven equivalent
```

The stronger reading is:

```text
local L occupied the report-reference-date role
while early src_next lacked explicit O

migration recognized the difference

parity validated calculations at the same date value
without proving temporal ownership equivalence

local-L policy then survived into production
```

This is why a consumer question is selected before code repair.

## 10. Relationship to Daily Trend

Daily Trend already selected observation consistency as its first protected temporal property in:

```text
docs/DAILY_TREND_OBSERVATION_CONSISTENCY_DECISION.md
```

Outlook selecting the same property does not imply:

```text
same O producer
same API
same row semantics
same historical product
same cutoff ownership
```

The property name is shared because both consumers need explainable temporal dependencies.

The consumer contracts remain separate.

## 11. Immediate next finite slice

After this decision, the next runtime-adjacent step should still be characterization, not repair.

Recommended test-only question:

```text
For current Outlook under a fixed cycle:

1. O moves while L is fixed
   -> which Outlook terms change?

2. O is fixed while L moves
   -> which Outlook terms change?
```

The characterization should cover a minimal set of O-shaped outputs, for example:

```text
reported as_of
days_left
actual snapshot liquid total
remaining planned liquid contribution
liq_daily
liq_safe_daily
last_journal / freshness context
```

The test must avoid assuming that current `ctx.as_of` is already canonical O.

If a trustworthy explicit O path does not exist for Outlook, the characterization slice should record that boundary rather than inventing one implicitly.

## 12. Runtime gate

A later Outlook runtime change may proceed only after it can state:

1. how caller-selected `O` reaches Outlook,
2. why that path is not merely a semantically mixed `ctx.as_of` reuse,
3. how `L` is derived and what scope it covers,
4. which terms depend on `O`, `L`, `C`, and any `H`,
5. which one protected property the slice enforces,
6. which current behaviors are intentionally changed,
7. which unrelated temporal consumers remain untouched.

The first runtime slice should be small enough that its changed dependency can be stated in one sentence.

## 13. Non-goals

This decision does not authorize:

- replacing every local `L` with `ctx.as_of`,
- wiring all report modules to one global `O`,
- deleting `actual_snapshot.Build`,
- making every snapshot call `BuildAt`,
- restoring the old giant `BuildAt` record,
- adding a universal `TemporalFrame`,
- changing Daily Trend semantics,
- changing cycle resolution,
- changing source TSV,
- adding required temporal columns,
- choosing Q4 historical replay semantics,
- choosing Q5 retrospective present-knowledge semantics,
- standardizing all `LatestActualDateInCycle` helpers,
- treating helper deduplication as semantic repair,
- claiming current Outlook is wrong merely because it differs from the old engine.

## 14. Decision summary

```text
Canonical Outlook household question:
  At observation O,
  what liquid spending room can the household rely on through cycle end C
  under the selected Outlook policy,
  while separately showing actual-record freshness L?

Selected first protected property:
  observation consistency

Ownership:
  caller/report query selects O
  actual-record evidence derives L
  cycle resolver selects C
  Outlook interprets their composition

Critical separation:
  O != L is supported
  L does not silently manufacture O

Runtime status:
  unchanged
```

The implementation may be rewritten later if that is clearer.

The protected object is not existing code shape.

The protected object is the explicitly chosen household meaning, backed by characterization evidence.
