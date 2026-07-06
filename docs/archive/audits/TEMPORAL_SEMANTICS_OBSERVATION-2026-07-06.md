# Temporal Semantics Observation - 2026-07-06

Status: audit snapshot / docs-only observation
Owner: other
Canonical: no; current paths: `src_next/date.bqn`, `src_next/cycle.bqn`, `src_next/context.bqn`, report-section implementations, and their executable checks
Exit: after a separate temporal-semantics decision classifies the observed clocks and explicitly authorizes or rejects runtime changes; retain this file as historical evidence

Observation date: 2026-07-06

## Purpose

This is a point-in-time observation of time semantics currently present in `bqn-ledger`.

It was opened after Slice A of the temporal execution coverage work separated plan completion evidence from planned-value and temporal attachment. While reviewing the remaining `as_of` path before Slice B, multiple different notions of "current time" became visible.

The purpose is not to choose a new model yet.

The purpose is to record:

```text
what each clock appears to mean
who currently chooses it
where its value comes from
what fallback it uses
which consumers depend on it
where same-named behavior currently drifts
```

## Non-goals

This observation does not authorize:

- a `TemporalFrame` runtime object,
- a new time dimension in the canonical cube,
- replacement of all clocks with one global `as_of`,
- `--as-of` CLI implementation,
- wall-clock migration,
- status vocabulary changes,
- plan/envelope runtime changes,
- source TSV changes,
- automatic journal sorting,
- fixing any behavior classified here as suspicious.

A later decision may adopt, reject, split, or rename any candidate concept in this document.

## Executive finding

Current code does not appear to have one `as_of` policy.

It contains several distinct temporal meanings that currently share similar names or are passed through nearby paths:

```text
system clock time
cycle-resolution time
context/query anchor time
planned-status evaluation time
envelope pace/cutoff time
outlook snapshot/cutoff time
source-order tail time
```

The strongest observation is not merely duplicate code.

The stronger observation is:

```text
multiple temporal semantics exist
  + some use the same function name
  + some bypass ctx.as_of
  + some expose their basis date
  + some hide it
  + some depend on source order
  -> one report run can potentially contain multiple different "current" dates
```

## Observation map

### A. `system_today`

Current implementation:

```text
src_next/date.bqn
  Today
```

Observed source:

```text
OS command: date +%Y-%m-%d
```

Current boundary:

`checks/check-src-next-clock-boundary.sh` requires direct system-clock reads to stay in `src_next/date.bqn`.

Apparent meaning:

```text
civil date according to the host system clock
```

Current owner:

```text
src_next/date.bqn
```

Fallback:

```text
none visible at this layer
```

Known consumers:

- `src_next/cycle.bqn` default cycle-resolution path when there are no valid journal dates.

Observation:

The physical clock access boundary is comparatively explicit and well guarded. The open problem is not direct clock access. It is semantic use of dates after the clock boundary.

---

### B. cycle default resolution time

Current implementation:

```text
src_next/cycle.bqn
  ReadCycle
    DefaultAsOf
```

Observed source policy:

```text
valid journal dates exist
  -> maximum valid journal date

no valid journal dates
  -> date.Today
```

The maximum is derived by sorting valid journal dates and taking the last value.

Apparent meaning:

```text
date used to resolve a cycle when caller does not provide one explicitly
```

Candidate descriptive name only:

```text
cycle_resolution_as_of
```

Current owner:

```text
src_next/cycle.bqn
```

Fallback:

```text
system_today
```

Known consumers:

- dynamic cycle resolution,
- especially `calendarMonth`,
- default `BuildContext` setup through `cycle.ReadCycle base`.

Observation:

This is not necessarily a report evaluation date. It is at least a period-selection input.

---

### C. `ctx.as_of`

Current implementation:

```text
src_next/context.bqn
  BuildContext
```

Observed policy:

```text
BuildContext base
  -> read default cycle
  -> as_of = resolved cycle start
  -> read cycle again with that as_of

BuildContext ⟨base, explicit_as_of⟩
  -> as_of = explicit caller value
  -> read cycle with explicit as_of
```

Apparent meaning:

The current name is broad, but observed behavior is close to:

```text
context/query anchor used for cycle selection
```

Candidate descriptive names only:

```text
context_as_of
period_anchor
query_anchor
```

Current owner:

```text
src_next/context.bqn caller path
```

Fallback:

For normal string-only construction:

```text
resolved cycle start
```

Known consumers:

- `ctx` consumers may read the field,
- cycle selection during context construction.

Important observation:

Several temporal report sections do not use `ctx.as_of` as their evaluation date. They independently derive another date.

---

### D. planned-status evaluation time

Current implementation:

```text
src_next/planned_payments.bqn
  LatestActualDateInCycle
```

Observed source policy:

```text
journal rows inside [cycle.start, cycle.end_exclusive)
  -> collect dates
  -> sort dates
  -> maximum date
```

Fallback:

```text
cycle.start
```

Current consumer path:

```text
BuildViewModel
  -> compute local as_of
  -> plan_rows.Build ⟨base, cy, as_of⟩
  -> plan_status.Classify
```

Temporal vocabulary:

```text
plan_date <  as_of -> overdue
plan_date == as_of -> due
plan_date >  as_of -> future
completed evidence  -> completed
```

Apparent meaning:

```text
date through which planned status is evaluated under current compatibility behavior
```

Candidate descriptive names only:

```text
planned_status_as_of
latest_actual_date_in_cycle
data_through
```

Important observations:

1. `BuildViewModel` ignores `ctx.as_of` for status evaluation.
2. A normal unrelated journal row can advance planned-status `as_of`.
3. The human report exposes `future/due/overdue/completed` but not the basis date.
4. Planned JSON exposes item status but not the basis date.
5. The old temporal-status planning document explicitly preserved this as compatibility behavior and deferred the larger `as_of` decision.

Auditability consequence:

```text
overdue
```

is externally visible without:

```text
as_of = YYYY-MM-DD
```

---

### E. envelope pace / future-plan cutoff time

Current implementation:

```text
src_next/envelope_computation.bqn
  LatestActualDateInCycle
```

Observed source policy:

```text
journal rows inside [cycle.start, cycle.end_exclusive)
  -> collect dates in source order
  -> take last selected date
```

No sort is performed in this local function.

Fallbacks:

```text
valid cycle but no data
  -> unavailable/no_data

invalid/unavailable cycle
  -> unavailable/no_cycle
```

Current consumers include:

```text
elapsed
days_left
avg_spend
future_planned_spent cutoff
days_until_empty
```

Apparent meaning:

```text
envelope pace and future-plan evaluation cutoff
```

Candidate descriptive names only:

```text
envelope_pace_as_of
envelope_data_through
source_tail_date_in_cycle
```

Important observation:

This function has the same name as the planned-payments function but different behavior:

```text
planned_payments
  sorts in-cycle dates and takes maximum

envelope_computation
  takes last in-cycle date in source order
```

Therefore non-monotonic journal source order can potentially produce different dates in the same report run.

---

### F. outlook snapshot / remaining-plan time

Current implementation:

```text
src_next/outlook.bqn
  LatestActualDateInCycle
```

Observed source policy:

```text
journal date >= cycle.start
  -> collect dates
  -> sort
  -> maximum date
```

Observed boundary difference:

The local filter checks the lower cycle bound but does not check:

```text
date < cycle.end_exclusive
```

Fallback:

```text
cycle.start
```

Current consumers include:

```text
days_left
days_elapsed
actual_snapshot.BuildAt
remaining plan range
future planned liquid deltas
daily liquid amounts
```

Output visibility:

Unlike planned status, outlook machine output exposes:

```text
src_next_outlook_as_of
```

Apparent meaning:

```text
outlook snapshot and remaining-plan evaluation date
```

Candidate descriptive names only:

```text
outlook_as_of
snapshot_as_of
```

Important observation:

For historical-cycle queries with later journal data present, this function can potentially select a date after `cycle.end_exclusive` because its observed filter has no upper bound.

This is an inference from the current code path, not a characterized runtime decision.

---

### G. source-order tail date

There is no observed first-class object named `source_tail_date`.

However, source order becomes temporal meaning where code selects the last filtered journal date without sorting, as currently observed in envelope computation.

Apparent meaning:

```text
date carried by the physically last matching source row
```

This is different from:

```text
maximum date value
```

Candidate descriptive name only:

```text
source_tail_date
```

Important observation:

Current editor write paths append rows. Date validation checks date shape/calendar validity, accounts, amount, and metadata, but no observed validation requires newly appended journal dates to be monotonic relative to previous rows.

`docs/JOURNAL_META.md` forbids future-dated actual rows under the stated operating rule, but does not state that backdated actual entry is forbidden.

Therefore source tail and maximum date should not currently be assumed equivalent without a stronger contract or characterization.

## Same-name drift inventory

Three local functions currently use the name:

```text
LatestActualDateInCycle
```

Observed behavior differs.

| Location | Lower bound | Upper bound | Ordering | Selected value | Fallback |
|---|---:|---:|---|---|---|
| `planned_payments.bqn` | yes | yes | sort dates | maximum in-cycle date | `cycle.start` |
| `envelope_computation.bqn` | yes | yes | source order | last matching source-row date | `unavailable/no_data` or `unavailable/no_cycle` |
| `outlook.bqn` | yes | no observed upper bound | sort dates | maximum date after/on cycle start | `cycle.start` |

This table is the clearest current evidence that one function name does not represent one shared semantic contract.

## Context bypass inventory

A separate observation concerns `ctx.as_of`.

Current context construction exposes:

```text
ctx.as_of
```

but the following sections independently derive local dates:

```text
planned_payments
envelope_computation
outlook
```

Therefore:

```text
explicit context date
```

and:

```text
section-local evaluation date
```

are not currently the same concept in general.

This may be intentional, accidental, compatibility-preserving, or mixed. This audit does not decide.

## Output auditability inventory

### Planned

Human output:

```text
future / due / overdue / completed
```

Observed basis-date visibility:

```text
not exposed
```

JSON output:

```text
status per item
```

Observed basis-date visibility:

```text
not exposed
```

### Outlook

Machine output includes:

```text
src_next_outlook_as_of
```

### Envelope

Envelope calculations depend on a local date for pace/cutoff behavior, but this observation did not identify a general exposed field that names the same local basis as a first-class temporal contract.

Observation:

Different sections currently have different levels of temporal auditability.

## Characterization scenarios worth preserving before any semantic change

These are proposed investigation scenarios, not implementation authorization.

### Scenario 1: non-monotonic journal source order

```text
journal.tsv
  2026-07-10 ...
  2026-07-03 ...  # backdated row appended later
```

Questions:

```text
planned as_of?
envelope as_of?
outlook as_of?
ctx.as_of?
```

Expected observation from static reading:

```text
planned likely -> 2026-07-10
envelope likely -> 2026-07-03
outlook likely -> 2026-07-10, subject to cycle filter
```

Do not treat this expected observation as a runtime contract until characterized.

### Scenario 2: historical cycle plus later journal data

```text
selected cycle
  2026-07-01 <= date < 2026-08-01

journal also contains
  2026-08-02
```

Questions:

```text
planned as_of?
envelope as_of?
outlook as_of?
```

Static concern:

```text
outlook local filter may admit 2026-08-02
```

### Scenario 3: valid cycle with no in-cycle actual rows

Questions:

```text
planned fallback?
envelope fallback?
outlook fallback?
cycle-resolution fallback?
```

Observed current differences:

```text
planned -> cycle.start
envelope -> unavailable/no_data
outlook -> cycle.start
cycle default resolution -> maximum valid journal date elsewhere, or Today when none exist
```

### Scenario 4: explicit context `as_of`

Construct:

```text
BuildContext ⟨base, explicit_as_of⟩
```

Questions:

```text
which sections honor ctx.as_of?
which sections replace it with local latest-actual logic?
can one report contain mixed evaluation dates?
```

### Scenario 5: status auditability

Given an open plan row, hold row data constant and vary only evaluation date.

Questions:

```text
can human output explain why status changed?
can JSON consumer recover the basis date?
```

Current static observation:

```text
planned status can change with local as_of
but planned human/JSON output does not expose that date
```

## Candidate semantic vocabulary

These names are observation aids only.

They are not adopted contracts.

```text
system_today
  host civil date

data_through
  latest date the ledger is considered observed through

report_as_of
  date at which a report evaluates time-relative meaning

period_anchor
  date used to select/resolve a cycle or reporting period

source_tail_date
  date carried by the physically last matching source row
```

Additional section-specific names may still be necessary:

```text
planned_status_as_of
envelope_pace_as_of
outlook_as_of
snapshot_as_of
```

## Temporal Frame hypothesis

A possible future model is that event date and observation time are different axes.

Conceptually:

```text
event date
  = when an event is expected or occurred

observation frame
  = from which temporal position the event is evaluated
```

Example:

```text
plan date = 2026-07-10

report_as_of = 2026-07-05 -> future
report_as_of = 2026-07-10 -> due
report_as_of = 2026-07-11 -> overdue
```

This suggests a possible distinction between:

```text
Event space
  Day × Account × Layer

Temporal observation frame
  clock kind + evaluation date
```

However:

```text
TemporalFrame
```

is only a hypothesis at this stage.

This audit does not decide whether it should be:

- a namespace,
- a report-context field group,
- an independent projection input,
- an additional array axis,
- a small set of named scalar dates,
- or no new runtime abstraction at all.

## Relationship to current temporal coverage work

Current active follow-up:

```text
PLAN_TEMPORAL_EXECUTION_COVERAGE_JOIN-2026-07-06.md
```

Already established:

- temporal status is independent from envelope state,
- first useful join is aggregate-only,
- no per-plan funded claim,
- Slice A reduced duplicated plan selection/identity/completion ownership,
- Slice B was intended to add a readonly aggregate temporal coverage snapshot with explicit `as_of`.

This observation changes the question before Slice B.

The next question is no longer only:

```text
how do we pass explicit as_of into the snapshot?
```

It is also:

```text
which temporal meaning should that as_of represent?
```

Therefore this audit recommends review before implementing Slice B, without cancelling Slice B or authorizing a replacement design.

## Open questions

1. Is `data_through` a first-class ledger concept or merely a local compatibility heuristic?
2. Should `ctx.as_of` mean report evaluation date, period anchor, or something narrower?
3. Should period selection and report evaluation use separate fields?
4. Should planned status expose its basis date in human and machine output?
5. Should `LatestActualDateInCycle` disappear as a name unless one shared contract is adopted?
6. Is source order ever intended to define temporal recency?
7. Should historical-cycle reports be invariant to later journal rows outside the selected cycle?
8. Should an explicit caller `as_of` override section-local latest-actual heuristics?
9. Is a small `TemporalFrame` useful, or would named scalar dates be clearer?
10. If event date and observation date are independent axes, where should their join live?

## Suggested next review step

Do not implement a broad temporal abstraction from this audit alone.

Review the observation and classify each current clock as one of:

```text
intentional distinct meaning
compatibility behavior
accidental duplication
bug candidate
unknown / needs fixture
```

Then choose at most one next slice.

Possible outcomes include:

```text
A. characterize only
B. expose basis date only
C. unify one duplicate function only
D. define a temporal semantics decision doc
E. adopt a small explicit report_as_of path
F. reject TemporalFrame and keep named scalars
```

The classification should happen before Slice B adds another temporal consumer.

## Evidence paths reviewed

Runtime and checks:

- `src_next/date.bqn`
- `checks/check-src-next-clock-boundary.sh`
- `src_next/cycle.bqn`
- `src_next/context.bqn`
- `src_next/planned_payments.bqn`
- `src_next/plan_rows.bqn`
- `src_next/plan_status.bqn`
- `src_next/envelope_computation.bqn`
- `src_next/outlook.bqn`
- `src_next/report.bqn`
- `tools/report`
- `src_edit/journal_add_cmd.bqn`
- `src_edit/validate.bqn`

Contracts and plans:

- `docs/JOURNAL_META.md`
- `docs/REPORT_CONTRACTS.md`
- `docs/DOCS_LIFECYCLE_CONTRACT.md`
- `docs/archive/active-plans/PLAN_TEMPORAL_STATUS_PROJECTION_PLAN-2026-07-05.md`
- `docs/archive/active-plans/PLAN_TEMPORAL_EXECUTION_COVERAGE_JOIN-2026-07-06.md`

Fixtures/tests sampled:

- `tests/test_src_next_plan_status.bqn`
- `tests/test_src_next_planned_payments.bqn`
- `fixtures/plan-completion/*`

## Observation conclusion

The current repository appears to contain multiple meaningful temporal viewpoints rather than one missing global date variable.

The likely design risk is not simply:

```text
wrong date calculation
```

but:

```text
different temporal meanings
  hidden behind similar names
  consumed by different reports
  with different fallback and visibility rules
```

Before adding another temporal join, the repository should first decide which differences are intentional and which are drift.
