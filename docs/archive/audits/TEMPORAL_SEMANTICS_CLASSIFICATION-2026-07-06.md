# Temporal Semantics Classification - 2026-07-06

Status: audit snapshot / docs-only classification review
Owner: other
Canonical: no; canonical temporal principle: `docs/TIME_AS_AXIS.md`
Exit: after one separately approved runtime or characterization slice consumes this classification; retain as historical decision evidence

Review date: 2026-07-06

## Purpose

Classify the clocks mapped by:

```text
docs/archive/audits/TEMPORAL_SEMANTICS_OBSERVATION-2026-07-06.md
```

The classification categories are:

```text
intentional distinct meaning
compatibility behavior
accidental duplication
bug candidate
unknown / needs fixture
```

This review does not change runtime behavior.

## Important evidence discovered during classification

The repository already has a current temporal design principle:

```text
docs/TIME_AS_AXIS.md
```

That document is not a speculative note. It declares itself a design principle for future decisions and already separates:

```text
coordinate time
observation time (`as_of`)
external clock time (`system_today`)
generation time (`generated_at`)
data cutoff (`data_cutoff`)
last recorded coordinate (`last_recorded_on`)
future observation boundary (`horizon_end`)
period / cycle windows
```

It also states that these times can coexist and are not substitutes for one another.

Therefore this classification should not invent a parallel vocabulary unless current concepts prove insufficient.

## Classification method

For each observed clock or clock-like behavior, record:

```text
classification
confidence
evidence
reason
needs_fixture
recommended treatment
```

Confidence is qualitative:

```text
high
medium
low
```

`bug candidate` does not mean a confirmed defect. It means current behavior conflicts with or lacks support from the current temporal contract strongly enough that a focused fixture should precede any fix.

---

## 1. `system_today`

### Classification

```text
intentional distinct meaning
```

Confidence:

```text
high
```

Current implementation:

```text
src_next/date.bqn
  Today
```

Evidence:

- `docs/TIME_AS_AXIS.md` defines external clock time separately from event coordinate and observation time.
- It states that `system_today` supplies a default to `as_of`; it is not a Cube coordinate.
- `checks/check-src-next-clock-boundary.sh` restricts direct clock reads to `src_next/date.bqn`.

Reason:

The host civil date is a real external input and should remain distinct.

Needs fixture:

```text
no for classification
```

Recommended treatment:

```text
preserve
```

Do not use it as a substitute for event date, `last_recorded_on`, cycle boundary, or generation time.

---

## 2. observation time `as_of`

### Classification

```text
intentional distinct meaning
```

Confidence:

```text
high
```

Evidence:

`docs/TIME_AS_AXIS.md` defines `as_of` as the observer position used to cut snapshots and time-relative views without rewriting event coordinates.

It also states the intended external flow:

```text
system clock
  -> system_today
  -> default only
  -> as_of
```

Reason:

This is the central answer to:

```text
from which date is this report/view being observed?
```

Needs fixture:

```text
not for concept
```

Runtime paths still need characterization because current `src_next` sections do not uniformly honor one observation date.

Recommended treatment:

```text
preserve canonical meaning
```

Do not redefine `as_of` to mean:

```text
maximum journal date
source tail date
cycle start
data cutoff
horizon end
```

---

## 3. period / cycle boundary

### Classification

```text
intentional distinct meaning
```

Confidence:

```text
high
```

Evidence:

- `docs/TIME_AS_AXIS.md` defines cycle as a window over coordinate time.
- `docs/ARCHITECTURE.md` states that cycle is not a basic Cube axis.
- current cycle contract uses `[start, end_exclusive)`.

Reason:

A period answers:

```text
which coordinate interval is selected?
```

This is different from:

```text
from which observation date is the selected interval viewed?
```

Needs fixture:

```text
existing cycle fixtures apply
```

Recommended treatment:

```text
preserve as separate meaning
```

---

## 4. current cycle default-resolution date

Observed implementation:

```text
src_next/cycle.bqn
  DefaultAsOf
```

Observed policy:

```text
valid journal dates exist
  -> maximum valid journal date

none exist
  -> Today
```

### Classification

```text
compatibility behavior
+
unknown / needs focused decision
```

Confidence:

```text
medium
```

Evidence:

- current implementation clearly uses this policy.
- `docs/TIME_AS_AXIS.md` distinguishes period resolution from observation time.
- historical `AS_OF_SECTION_AUDIT.md` already flagged that cycle resolution based on data state rather than explicit `as_of` needs a decision.
- `TIME_AS_AXIS.md` says current section boundaries are not yet uniformly `as_of`-cut.

Reason:

The concept of a period-selection input is intentional, but the current algorithm:

```text
max journal date, else Today
```

is not established as the universal canonical meaning of `as_of`.

Needs fixture:

```text
yes before changing cycle resolution
```

Especially:

```text
historical observation date
later journal row exists
calendarMonth or incomeAnchor cycle resolution
```

Recommended treatment:

```text
preserve for now
name/ownership decision later
```

Do not silently replace it during unrelated report work.

---

## 5. current `ctx.as_of`

Observed implementation:

```text
src_next/context.bqn
```

Normal string-only construction currently behaves approximately as:

```text
read default cycle
  -> ctx.as_of = resolved cycle.start
  -> read cycle with that value
```

Explicit tuple construction can carry a caller-provided date.

### Classification

```text
bug candidate
+
incomplete semantic migration
```

Confidence:

```text
medium-high
```

Evidence:

- current canonical `TIME_AS_AXIS.md` defines `as_of` as observation time.
- current `ARCHITECTURE.md` repeats that distinction.
- canonical temporal principle says report entry should obtain one default observation date and pass it explicitly.
- current normal `ctx.as_of` path is cycle-start-shaped rather than observation-time-shaped.
- planned, envelope, and outlook sections independently derive local dates instead of consistently consuming `ctx.as_of`.

Reason:

The field name strongly claims observation-time semantics, while the default value path appears to serve period-resolution/context construction instead.

This may be migration residue rather than an isolated logic bug.

Needs fixture:

```text
yes
```

Required characterization:

```text
BuildContext base
BuildContext ⟨base, explicit_as_of⟩
```

and which report sections honor each value.

Recommended treatment:

```text
do not rename or repurpose immediately
characterize first
```

The likely design question is whether context needs separate named fields such as:

```text
as_of
period anchor / period selection input
```

but no new runtime fields are authorized by this review.

---

## 6. planned-status local date

Observed implementation:

```text
src_next/planned_payments.bqn
  LatestActualDateInCycle
```

Policy:

```text
maximum journal coordinate inside current cycle
fallback -> cycle.start
```

Used to classify:

```text
future
due
overdue
completed
```

### Classification

```text
compatibility behavior
```

Confidence:

```text
high
```

Evidence:

- temporal status planning explicitly documented current behavior.
- PR #64 intentionally preserved `LatestActualDateInCycle` as compatibility default during extraction.
- the classifier itself correctly receives explicit `as_of`; caller defaulting was deliberately left unchanged.

Reason:

This is known historical behavior, not an accidental discovery.

However, semantic debt remains:

```text
maximum recorded journal coordinate
```

is closer to canonical `last_recorded_on` than canonical observation `as_of`.

Using it to derive status means planned status currently evaluates from a recording-recency proxy.

Needs fixture:

```text
existing status boundaries are tested
additional basis-date visibility test recommended
```

Recommended treatment:

```text
preserve until an explicit observation-time migration is approved
```

Do not reuse this compatibility default as the meaning of Slice B `as_of` merely because it already exists.

---

## 7. planned status basis-date visibility

Observed behavior:

```text
status exposed
basis date hidden
```

### Classification

```text
bug candidate
```

Confidence:

```text
medium
```

Evidence:

- human output exposes `future/due/overdue/completed`.
- planned JSON exposes item status.
- neither exposes the local date used to derive that status.
- status meaning is time-relative by definition.

Reason:

A consumer cannot audit:

```text
overdue relative to what date?
```

Recommended treatment:

```text
candidate small output-contract slice
```

Do not add the field inside this classification review.

---

## 8. envelope local `LatestActualDateInCycle`

Observed implementation:

```text
src_next/envelope_computation.bqn
```

Policy:

```text
filter journal rows to cycle
preserve source order
take last matching row date
```

Used for:

```text
elapsed
days_left
avg_spend
future plan cutoff
days_until_empty
```

### Classification

```text
bug candidate
+
accidental duplication
```

Confidence:

```text
medium-high
```

Evidence:

- same-named function differs from planned and outlook implementations.
- no reviewed current contract establishes source file order as temporal recency for envelope pace.
- editor append paths allow valid backdated rows; no observed monotonic date-order requirement exists.
- canonical `TIME_AS_AXIS.md` defines `last_recorded_on` as maximum adopted journal coordinate, not physical source tail.
- source order is legitimately meaningful for some views such as recent rows, but that is a separate purpose.

Reason:

A backdated append can potentially move envelope pace time backward while maximum recorded coordinate remains later.

Needs fixture:

```text
yes, high priority
```

Minimal scenario:

```text
2026-07-10 actual
2026-07-03 backdated actual appended later
```

Characterize:

```text
envelope local date
elapsed
avg_spend
future plan cutoff
```

Recommended treatment:

```text
characterize before fix
```

Do not automatically replace with planned helper until desired meaning is chosen.

---

## 9. outlook local `LatestActualDateInCycle`

Observed implementation:

```text
src_next/outlook.bqn
```

Policy:

```text
journal date >= cycle.start
sort
maximum
```

No observed upper filter:

```text
date < cycle.end_exclusive
```

Used for:

```text
days_left
days_elapsed
actual snapshot
remaining plans
daily amounts
```

### Classification

```text
bug candidate
+
compatibility residue possible
```

Confidence:

```text
medium-high
```

Evidence:

- current function name says `InCycle` but observed filter lacks the upper cycle bound.
- current `TIME_AS_AXIS.md` separates `as_of`, period window, and `horizon_end`.
- historical `AS_OF_SECTION_AUDIT.md` records the prior engine outlook as explicitly `as_of` based and bounded plan range to cycle end.
- current machine output exposes `src_next_outlook_as_of`, so the local date is externally visible as an observation basis.

Reason:

For a historical cycle with later journal data, the local date may move outside the selected period and then influence snapshot and daily calculations.

Needs fixture:

```text
yes, high priority
```

Minimal scenario:

```text
selected cycle [2026-07-01, 2026-08-01)
journal contains 2026-08-02
```

Recommended treatment:

```text
characterize before fix
```

The likely question is not only whether to add an upper bound. It is whether outlook should consume observation `as_of`, `last_recorded_on`, or another explicit input.

---

## 10. source-tail date used as recency

Observed emergent behavior:

```text
physical last matching row date
```

### Classification

```text
accidental duplication / emergent semantics
```

Confidence:

```text
high
```

Evidence:

- no first-class current temporal contract found for source-tail date as recency.
- append order and coordinate order are not guaranteed equivalent by reviewed editor validation.
- canonical temporal principle already has separate concepts for `last_recorded_on` and period boundaries.

Reason:

Source order can be a valid presentation axis, but it should not silently become observation time or recording recency.

Needs fixture:

```text
covered by non-monotonic journal scenario
```

Recommended treatment:

```text
do not promote to canonical clock
```

---

## 11. `last_recorded_on`

### Classification

```text
intentional distinct meaning
```

Confidence:

```text
high
```

Evidence:

`docs/TIME_AS_AXIS.md` explicitly defines it as the maximum coordinate among adopted journal events and distinguishes it from `as_of`.

Reason:

The ledger may be observed on one date while actual recording only reaches an earlier date.

Example:

```text
as_of:            2026-07-10
last_recorded_on: 2026-07-07
```

This is not a contradiction.

Recommended treatment:

```text
prefer this existing concept over inventing broad `data_through`
```

If later implementation needs a wider data-availability concept, evaluate `data_cutoff` separately.

---

## 12. `data_cutoff`

### Classification

```text
intentional distinct meaning
```

Confidence:

```text
high for concept
```

Runtime state:

```text
currently unimplemented as shared contract
```

Evidence:

`docs/TIME_AS_AXIS.md` defines it as the boundary of which input events are admitted and explicitly states that it need not equal `as_of`.

Recommended treatment:

```text
keep reserved
```

Do not use it as a synonym for latest journal date.

---

## 13. `horizon_end`

### Classification

```text
intentional distinct meaning
```

Confidence:

```text
high for concept
```

Runtime state:

```text
currently unimplemented as shared field
```

Evidence:

`docs/TIME_AS_AXIS.md` defines it as the future-side observation boundary for plan/forecast/outlook.

Reason:

An outlook can be observed at:

```text
as_of = 2026-07-10
```

while looking ahead to:

```text
horizon_end = 2026-08-01
```

Recommended treatment:

```text
keep distinct from as_of and cycle end
```

---

## 14. `generated_at`

### Classification

```text
intentional distinct meaning
```

Confidence:

```text
high for concept
```

Runtime state:

```text
not currently implemented
```

Recommended treatment:

```text
no action now
```

Do not confuse report generation date with observation date.

---

## 15. `TemporalFrame` abstraction hypothesis

### Classification

```text
unknown / not yet justified
```

Confidence:

```text
high that implementation is premature
```

Evidence:

- the observation audit found multiple clocks.
- however current canonical temporal principle already provides a vocabulary of distinct scalar meanings.
- `TIME_AS_AXIS.md` explicitly warns against increasing temporal abstraction before fixtures can explain it.

Reason:

A new runtime object may eventually help, but current evidence does not show that a namespace or new array axis is better than explicit named dates.

Recommended treatment:

```text
reject-now as implementation
keep as hypothesis
```

First preference:

```text
explicit named temporal values
```

Only introduce a grouped runtime abstraction after repeated consumers demonstrate a real shared contract.

---

# Consolidated classification table

| Observed item | Classification | Confidence | Fixture before change? |
|---|---|---|---|
| `system_today` | intentional distinct meaning | high | no |
| observation `as_of` | intentional distinct meaning | high | no for concept |
| period / cycle | intentional distinct meaning | high | existing coverage |
| cycle default resolution policy | compatibility + unknown | medium | yes |
| current `ctx.as_of` default semantics | bug candidate / incomplete migration | medium-high | yes |
| planned local status date | compatibility behavior | high | basis visibility recommended |
| planned hidden basis date | bug candidate | medium | yes/contract test |
| envelope local source-order date | bug candidate + accidental duplication | medium-high | yes, priority |
| outlook local date | bug candidate + possible compatibility residue | medium-high | yes, priority |
| source-tail recency | accidental emergent semantics | high | covered by fixture |
| `last_recorded_on` | intentional distinct meaning | high | no for concept |
| `data_cutoff` | intentional distinct meaning, unimplemented | high | future |
| `horizon_end` | intentional distinct meaning, unimplemented | high | future |
| `generated_at` | intentional distinct meaning, unimplemented | high | future |
| `TemporalFrame` runtime abstraction | unknown / premature | high | do not implement yet |

## Main conclusion

The classification does **not** support one global date variable.

It also does **not** yet support a new `TemporalFrame` runtime abstraction.

The strongest current direction is:

```text
keep distinct meanings distinct
reuse existing canonical vocabulary
make observation as_of explicit
keep last_recorded_on separate
keep period/cycle separate
reserve data_cutoff and horizon_end for their actual meanings
characterize local clock drift before fixing it
```

## Decision for Slice B `as_of`

The current temporal coverage plan requires an explicit `as_of`.

Based on current canonical temporal semantics, the classification result is:

```text
Slice B as_of
  = observation time
```

It should **not** silently mean:

```text
latest actual journal coordinate
source tail date
cycle start
cycle end
data cutoff
```

This is a semantic classification, not implementation authorization.

Current blocker:

```text
normal src_next report path does not yet provide one consistently consumed observation as_of
```

Therefore Slice B should not copy one of the local `LatestActualDateInCycle` helpers merely to obtain a date.

## Recommended next finite slice

Before implementing Slice B, add characterization only for the two strongest runtime bug candidates:

```text
A. envelope non-monotonic source order
B. outlook historical cycle with later journal data
```

Boundary:

```text
fixtures + tests/checks only
no behavior change
no source TSV migration
no TemporalFrame object
no report status rename
```

Why these two:

- both can make one report run use a date that does not match its apparent semantic name,
- both are small enough to characterize independently,
- both provide evidence for whether later runtime work should share `last_recorded_on`, explicit `as_of`, or separate inputs.

After characterization, choose exactly one runtime slice.

Possible later slices:

```text
1. fix envelope source-order recency
2. fix outlook period leak
3. expose planned basis date
4. restore explicit report observation as_of path
```

Do not bundle them.

## Evidence reviewed

Current temporal principles:

- `docs/TIME_AS_AXIS.md`
- `docs/ARCHITECTURE.md`

Current runtime:

- `src_next/date.bqn`
- `src_next/cycle.bqn`
- `src_next/context.bqn`
- `src_next/planned_payments.bqn`
- `src_next/plan_status.bqn`
- `src_next/plan_rows.bqn`
- `src_next/envelope_computation.bqn`
- `src_next/outlook.bqn`
- `src_next/report.bqn`
- `tools/report`
- `src_edit/journal_add_cmd.bqn`
- `src_edit/validate.bqn`

Current/recent planning evidence:

- `docs/archive/audits/TEMPORAL_SEMANTICS_OBSERVATION-2026-07-06.md`
- `docs/archive/active-plans/PLAN_TEMPORAL_STATUS_PROJECTION_PLAN-2026-07-05.md`
- `docs/archive/active-plans/PLAN_TEMPORAL_EXECUTION_COVERAGE_JOIN-2026-07-06.md`
- PR #63
- PR #64
- PR #68
- PR #70

Historical evidence used only as background:

- `docs/archive/audits/AS_OF_SECTION_AUDIT.md`

The historical audit is not treated as current runtime truth. It is used only to identify prior intent and previously known drift questions.

## Final classification statement

The current difficulty around planned payments, envelopes, outlook, and cycle time is best understood as:

```text
an existing multi-time design principle
+
incomplete migration into current src_next runtime
+
section-local compatibility behavior
+
a small number of likely drift points
```

The next safe move is characterization, not another temporal abstraction.
