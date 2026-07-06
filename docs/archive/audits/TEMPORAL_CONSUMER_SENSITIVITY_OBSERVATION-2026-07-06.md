# Temporal Consumer Sensitivity Observation - 2026-07-06

Status: audit snapshot / docs-only observation
Owner: other
Canonical: no; canonical temporal principle: `docs/TIME_AS_AXIS.md`
Base evidence: merged PR #71 / #72 plus characterization branch for PR #73
Exit: after a separately approved decision or fixture slice consumes this map; retain as historical evidence

Observation date: 2026-07-06

## Purpose

Previous temporal work mapped where dates come from and classified the different clock meanings.

This observation turns the view around.

Instead of asking:

```text
which clock does a section create?
```

ask:

```text
if the relevant date moves by one day,
what observable meaning changes?
```

The goal is to map temporal **consumers** and their sensitivity.

This matters because two sections can both use a value named `as_of` while reacting very differently:

```text
status threshold only
balance cutoff
period selection
pace denominator
future-plan cutoff
historical comparison window
presentation label only
```

## Non-goals

This observation does not authorize:

- runtime fixes,
- a shared `LatestActualDateInCycle` helper,
- a new `TemporalFrame` object,
- `--as-of` CLI implementation,
- renaming current fields,
- changing cycle resolution,
- changing report output contracts,
- changing source TSV,
- merging PR #73,
- deciding which runtime bug candidate to fix first.

## Canonical frame

`docs/TIME_AS_AXIS.md` already distinguishes:

```text
coordinate time
observation time (`as_of`)
system_today
generated_at
data_cutoff
last_recorded_on
horizon_end
period / cycle
```

It also states that:

```text
all report aggregation is not yet consistently cut by as_of
```

and that current section boundaries must be inspected individually.

This consumer map follows that rule.

## Sensitivity vocabulary

### `hard_cutoff`

Moving the date changes which Events are admitted to a calculation.

Example:

```text
journal.date <= as_of
```

### `threshold`

Moving the date changes a categorical relation without necessarily changing amounts.

Example:

```text
future -> due -> overdue
```

### `period_selection`

Moving the date selects a different cycle/window, which can indirectly rebuild many downstream values.

### `denominator`

Moving the date changes elapsed/remaining days and therefore pace or per-day calculations.

### `future_cutoff`

Moving the date changes which Plan rows count as future/remaining.

### `window_length`

Moving the date changes the size of a comparison interval and its matching baseline interval.

### `presentation_only`

Moving or exposing the date changes labels/header context but not the underlying monetary calculation.

### `source_order`

The view depends on physical row position rather than coordinate-date order.

### `period_boundary`

The view is driven by `[start, end_exclusive)` rather than observation time.

## High-level finding

The report currently contains several different temporal sensitivity shapes.

The strongest consumer-side observation is:

```text
same repository
same report run
same broad word "current"
  -> threshold consumer
  -> hard cutoff consumer
  -> pace denominator consumer
  -> period-end consumer
  -> source-order consumer
  -> no temporal cutoff at all
```

Therefore a future explicit observation `as_of` path cannot safely be introduced by mechanically replacing every local date with one scalar.

The consumer contract must be known first.

---

# 1. Foundational consumer: `actual_snapshot.BuildAt`

Path:

```text
src_next/actual_snapshot.bqn
```

Observed input:

```text
explicit as_of
```

Observed sensitivity:

```text
hard_cutoff
```

Mechanism:

```text
journal row admitted when:
  row.date <= as_of
```

Affected outputs:

```text
account amounts
entries
liq_total
sav_total
inv_total
assets_total
liabilities_total
net_worth
liq_breakdown
```

One-day movement behavior:

```text
as_of D
  -> all known valid journal Events through D

as_of D+1
  -> previous set + valid Events on D+1
```

Important property:

This is one of the clearest current examples of canonical observation-time behavior. Event coordinates are not rewritten; the admitted snapshot changes.

Important scope note:

The cutoff is ledger-wide, not cycle-bounded.

Current default `Build(ctx)` does not consume `ctx.as_of`; it derives another local maximum in-cycle journal date and passes that into `BuildAt`.

Classification:

```text
consumer contract clear
caller default policy separate
```

---

# 2. Planned payments

Paths:

```text
src_next/planned_payments.bqn
src_next/plan_rows.bqn
src_next/plan_status.bqn
```

Observed local date source:

```text
maximum journal date inside selected cycle
fallback cycle.start
```

Observed sensitivity:

```text
threshold
```

Core relation:

```text
plan_date <  as_of -> overdue
plan_date == as_of -> due
plan_date >  as_of -> future
completion evidence -> completed
```

Affected outputs:

```text
human_statuses
future / due / overdue labels
human table status cells
JSON item status
```

Mostly unaffected by moving only the evaluation date:

```text
selected plan rows
plan identity
completion evidence
open_mask
open_total
actual matched amount
```

Important coupling:

The local date source scans all in-cycle journal dates.

Therefore an unrelated journal Event can advance the planned-status observation proxy and change another Plan row from:

```text
future -> due
or
due -> overdue
```

without changing that Plan row or its completion evidence.

Auditability note:

The time-relative status is exposed, but the basis date is not currently exposed in planned human or JSON output.

Sensitivity summary:

```text
small numeric surface
high semantic visibility
```

---

# 3. Envelope computation

Path:

```text
src_next/envelope_computation.bqn
```

Observed local date source:

```text
physically last matching in-cycle journal row date
```

PR #73 characterization evidence:

```text
source order:
  2026-01-10 actual 100
  2026-01-03 actual 100

current observed avg_spend:
  floor(200 / 3) = 66
```

Observed sensitivity:

```text
denominator
+
future_cutoff
```

Local date affects:

```text
elapsed
days_left
avg_spend
future_planned_spent
days_until_empty
dynamic envelope health status
```

Local date does not directly determine:

```text
allocated
actual_spent
remaining
```

Those are derived from selected cycle rows and envelope/account meaning.

Important coupling:

The local date source scans all journal rows inside the cycle, not only journal rows relevant to one envelope.

Therefore an unrelated in-cycle journal Event can change:

```text
elapsed
avg_spend
future plan cutoff
days_until_empty
health status
```

for a dynamic envelope even when that Event does not change the envelope's own `actual_spent`.

This is a stronger consumer-side observation than simple duplicate clock code.

It is cross-domain temporal coupling:

```text
unrelated Event coordinate
  -> shared local clock moves
  -> envelope pace meaning changes
```

---

# 4. Cycle Summary

Path:

```text
src_next/cycle_summary.bqn
```

Observed local date source:

```text
maximum journal date inside selected cycle
```

Observed sensitivity:

```text
denominator-like days remaining
+
future_cutoff
```

Local date affects:

```text
days_remaining
plan_expense_remaining
```

Mechanisms:

```text
days_remaining
  = cycle.end_exclusive - local date

remaining plan expense
  includes plan date >= local date
  and plan date < cycle.end_exclusive
```

Local date does not directly change:

```text
income_actual
expense_actual
net_actual
plan_expense total
```

Those come from period TBDS.

Important result:

One section mixes two temporal contracts:

```text
period totals
+
local latest-journal future cutoff
```

An unrelated journal Event can advance the local date and reduce `plan_expense_remaining` while period actual totals remain unchanged except for any Event amount effects.

---

# 5. Outlook

Path:

```text
src_next/outlook.bqn
```

Observed local date source:

```text
maximum journal date where date >= cycle.start
```

No observed upper cycle bound in the local helper.

PR #73 characterization evidence:

```text
selected cycle:
  [2026-07-01, 2026-08-01)

later journal row:
  2026-08-02

current local date:
  2026-08-02
```

Observed sensitivity:

```text
compound
  hard_cutoff
  + denominator
  + future_cutoff
  + presentation
```

Local date affects:

```text
days_left
days_elapsed
actual snapshot cutoff
liq_total
sav_total
inv_total
assets_total
liabilities_total
net_worth
liq_breakdown
remaining Plan set
future planned liquid net
planned future income
fixed reserve
liq_daily
liq_safe_daily
budget per-day values
machine as_of
human as_of
```

Mechanisms include:

```text
actual_snapshot.BuildAt(ctx, as_of)

remaining plan:
  plan.date >= as_of
  plan.date < cycle.end_exclusive

days_left:
  cycle.end_exclusive - as_of
```

Important consequence:

This is not a small status-only consumer.

A one-day shift can change several interacting terms at once:

```text
snapshot balance
+
future Plan inclusion
+
divisor days_left
```

Therefore the resulting daily amount can change nonlinearly.

Historical-cycle leak consequence:

If local `as_of` moves after `cycle.end_exclusive`:

```text
days_left -> 0
remaining plan set -> empty
actual snapshot may include later-cycle journal Events
```

while the selected cycle labels remain historical.

Sensitivity summary:

```text
highest observed compound temporal consumer
```

---

# 6. Daily Trend

Path:

```text
src_next/daily_trend.bqn
```

Observed local date source:

```text
maximum journal date inside selected cycle
```

Observed sensitivity:

```text
future_cutoff
+
trend endpoint
+
retroactive derived-row sensitivity
```

Local date affects:

```text
planned_future_income
as_of exposed in VM
current days-left display
trend date set endpoint/fallback
reserve fallback logic
```

Most important mechanism:

`planned_future_income` is computed once using:

```text
plan.date > current local as_of
plan.date < cycle.end_exclusive
```

Then the same scalar is used in every trend row:

```text
fund = row_liquid + planned_future_income - row_reserve
```

Therefore advancing the current local clock can change a Plan row's inclusion in `planned_future_income`, which can in turn change:

```text
fund
daily
Δdaily
top drops
```

for historical trend rows whose own coordinate date did not move.

This is the strongest new observation from the consumer-side review.

Potential property:

```text
historical trend rows may not be temporally stable
under later changes to the current local clock
```

This is a static inference from current data flow, not yet a fixture-characterized runtime claim.

Recommended future characterization question:

```text
same Event history and same historical row date
but later local as_of
  -> does old trend row change?
```

Do not fix from this observation alone.

---

# 7. Daily Flow

Path:

```text
src_next/daily_flow.bqn
```

Observed local date source:

```text
maximum journal date inside selected cycle
```

Observed sensitivity:

```text
mostly presentation / endpoint
```

The local date is used for:

```text
adding as_of to trend date candidates
VM as_of
human days_left
```

Daily monetary rows are calculated from the actual daily cube at each trend coordinate.

Important nuance:

Because local `as_of` is normally itself the maximum actual journal coordinate and actual coordinates are already included in `j_dates`, adding it to the trend-date candidates is usually redundant before deduplication.

Therefore compared with Daily Trend:

```text
same style of local clock helper
but much lower monetary sensitivity
```

This is evidence against mechanically unifying consumers solely because they share a helper shape.

---

# 8. Actual Comparison

Path:

```text
src_next/actual_comparison.bqn
```

Observed local date source:

```text
maximum journal date where date >= current cycle start
```

No observed upper cycle bound in the current local selection.

Observed sensitivity:

```text
window_length
+
period content
+
baseline content
+
status
```

Local date affects:

```text
current_end_exclusive = as_of + 1 day
elapsed_days
baseline_end_exclusive
current observation rows
baseline observation rows
aggregated current amounts
aggregated baseline amounts
differences
ratios
increased/decreased/new/stopped status
```

Important coupling:

A later journal Event can extend both:

```text
current comparison window
and
same-length baseline comparison window
```

Therefore one local date shift changes both sides of the comparison.

Potential historical-cycle leak:

Because the observed local date filter has only the lower bound, a later-cycle journal row can potentially extend the "current cycle elapsed" window beyond the selected cycle.

This is a static code-path observation and is not yet separately fixture-characterized.

---

# 9. Snapshot report section

Path:

```text
src_next/snapshot.bqn
```

Observed date assignment:

```text
as_of = cy.end_exclusive
```

Observed sensitivity:

```text
period_boundary
+
presentation label
```

Monetary outputs are derived from:

```text
ctx.tbds closing balances
```

not from:

```text
actual_snapshot.BuildAt(ctx, as_of)
```

Current code explicitly notes that the section no longer reads journal directly for actual snapshot behavior.

Affected temporal display fields:

```text
as_of
remaining_days
days_elapsed
status_label
```

But monetary state is period/TBDS-driven:

```text
liq_total
sav_total
inv_total
assets_total
liabilities_total
net_worth
```

Important naming observation:

Here `as_of` is assigned the half-open period boundary:

```text
cycle.end_exclusive
```

This is not obviously the same semantic shape as canonical observation time.

It resembles:

```text
period-end marker
```

The section itself currently documents this as:

```text
as_of is TBDS period end (cycle_end_exclusive)
```

Do not rename from this audit alone.

---

# 10. Trial Balance

Path:

```text
src_next/trial_balance.bqn
```

Observed date assignment:

```text
as_of = cy.end_exclusive
```

Observed sensitivity:

```text
period_boundary
```

Amounts come from TBDS:

```text
opening
period debit movement
period credit movement
closing
```

The section displays:

```text
Period: [start, end_exclusive)
As of : end_exclusive
```

Important naming observation:

Like Snapshot, the `as_of` field is a period-end boundary label rather than a separately supplied observation date.

This is a second independent example of:

```text
period boundary carried under as_of naming
```

---

# 11. YTD Summary

Path:

```text
src_next/ytd_summary.bqn
```

The module explicitly states that src_next summary has no `as_of` argument.

Observed boundary:

```text
calendar year containing cycle.end_exclusive
range end = cycle.end_exclusive
```

Observed sensitivity:

```text
period_boundary
```

Moving an external observation date alone does not change YTD behavior unless it causes a different selected cycle/end boundary.

Important property:

The rendered range exposes the actual boundary, which is more auditable than presenting a time-relative label without its basis.

---

# 12. Balances

Path:

```text
src_next/balances.bqn
```

Observed source:

```text
TBDS nonzero actual closing balances
```

Observed sensitivity:

```text
period_boundary via context
```

No direct observation-date consumer was found in this module.

For a fixed selected cycle, changing only a hypothetical `ctx.as_of` scalar does not directly alter this builder.

Changing the selected period can alter TBDS and therefore balances.

---

# 13. Expense Breakdown

Path:

```text
src_next/expense_breakdown.bqn
```

Observed source:

```text
TBDS actual period movements
```

Observed sensitivity:

```text
period_boundary via context
```

No direct observation-date consumer was found.

---

# 14. Readiness Check

Path:

```text
src_next/readiness_check.bqn
```

Observed source:

```text
ctx.cube
ctx.cy
metadata
source files
```

Observed sensitivity:

```text
period_selection / period_boundary
```

No direct observation-date cutoff was found.

Naming observation:

Current `future_journals` are identified as journal rows with:

```text
day_index >= ctx.cy.day_count
```

That means:

```text
after selected cycle end
```

not necessarily:

```text
after observation as_of
or
after system_today
```

This is another consumer-side semantic distinction worth preserving.

---

# 15. Recent Journal

Path:

```text
src_next/recent_journal.bqn
```

Observed sensitivity:

```text
source_order
```

Behavior:

```text
last N physical journal rows
then newest-first by reversing that selected source tail
```

No observation-time cutoff is applied.

Important contrast:

Source order is legitimate here because the explicit view contract is:

```text
recent source rows
```

This strengthens the distinction with Envelope, where source tail currently becomes pace recency without an equivalent presentation contract.

---

# 16. Issues

Path:

```text
src_next/issues.bqn
```

Observed sensitivity:

```text
none to date cutoff
```

Behavior:

```text
show all issues whose status == open
```

Issue date is displayed but not used as an observation filter.

Therefore moving observation time does not hide future-dated or later-dated open issues under current behavior.

This may be intentional. No decision is made here.

---

# 17. Report entry and context

Paths:

```text
src_next/report.bqn
src_next/context.bqn
src_next/cycle.bqn
```

Normal report entry:

```text
BuildContext base
```

No normal `--as-of` CLI path is present.

`BuildContext` does expose an explicit tuple form, but normal string construction behaves approximately as:

```text
resolve default cycle
ctx.as_of = resolved cycle.start
read cycle again with that value
```

Consumer sensitivity is mode-dependent.

## Fixed cycle

Changing explicit context `as_of`:

```text
ctx.as_of changes
selected fixed cycle does not
cube/tbds period does not
```

Sections that ignore `ctx.as_of` remain unchanged.

## calendarMonth cycle

`cycle.ReadCycle` uses explicit `as_of` to select month boundaries.

Changing it can change:

```text
selected period
context cube
TBDS
all period-driven consumers
```

This is `period_selection` sensitivity, not merely observation-cutoff sensitivity.

## incomeAnchor cycle

The current resolver derives anchors from journal/plan state and does not use `as_of` in the observed resolution body.

Therefore explicit context `as_of` can change while the selected anchor cycle remains unchanged.

Important result:

```text
same ctx.as_of field
has different downstream leverage by cycle mode
```

This is another reason not to treat `ctx.as_of` as a universally effective report clock yet.

---

# Consolidated section sensitivity table

| Section / consumer | Current temporal driver | Sensitivity shape | Main values affected |
|---|---|---|---|
| `actual_snapshot.BuildAt` | explicit `as_of` | hard_cutoff | balances, assets, liabilities, net worth |
| `planned` | max in-cycle journal date | threshold | future/due/overdue status |
| `envelopes` | source-tail in-cycle journal date | denominator + future_cutoff | avg spend, future plans, depletion, health |
| `cycle` | max in-cycle journal date | future_cutoff + days remaining | plan remaining, days remaining |
| `outlook` | max journal date after cycle start, no observed upper bound | compound | snapshot, plans, days, daily amounts |
| `daily-trend` | max in-cycle journal date | future_cutoff + retroactive derived sensitivity | fund, daily, deltas, top drops |
| `daily-flow` | max in-cycle journal date | mostly presentation / endpoint | header, days left, endpoint row behavior |
| `actual-comparison` | max journal date after cycle start, no observed upper bound | window_length | both periods, amounts, ratios, statuses |
| `snapshot` | `cycle.end_exclusive` | period_boundary | temporal labels; money via TBDS |
| `trial-balance` | `cycle.end_exclusive` | period_boundary | period accounting state |
| `ytd` | `cycle.end_exclusive` | period_boundary | YTD range and totals |
| `balances` | TBDS selected period | period_boundary | closing balances |
| `expense_breakdown` | TBDS selected period | period_boundary | period expense totals |
| `check` | cube/cycle | period_selection / boundary | skipped/future-by-period diagnostics |
| `recent` | physical source order | source_order | last N source rows |
| `issues` | open/closed status | no date cutoff | open issue list |
| `debug` | context cube | period context | numeric verification |

## Main consumer-side conclusions

### A. One global date variable is still unsupported

The consumer map reinforces the earlier classification.

A single scalar cannot automatically replace all current temporal inputs because consumers ask different questions:

```text
what Events exist by this observation date?
what is the Plan's relative status?
how many days have elapsed?
which Plans remain in the future?
which period is selected?
how long is the comparison window?
which physical rows were appended most recently?
```

### B. Shared helper shape does not imply shared consumer contract

Daily Trend and Daily Flow both have near-identical local latest-date helpers.

But their downstream sensitivity differs sharply:

```text
Daily Trend
  -> future-income cutoff and historical derived rows

Daily Flow
  -> mostly endpoint/presentation
```

Therefore deduplicating helper code before classifying consumer meaning could hide real semantic differences.

### C. Unrelated Events can move other domains

Several local date producers scan all journal rows.

Therefore an unrelated journal Event can change:

```text
planned status
envelope pace
cycle remaining Plan total
outlook snapshot / daily amount
daily trend future income cutoff
actual comparison elapsed window
```

This cross-domain coupling may be more important than the duplicate function names themselves.

### D. `as_of` currently names at least two consumer shapes

Observed examples:

```text
actual_snapshot.BuildAt
  -> true hard observation cutoff

snapshot / trial_balance
  -> cycle.end_exclusive period boundary label
```

This is a naming/contract observation, not a rename decision.

### E. Historical stability is now a first-class question

Daily Trend suggests a new property to test:

```text
Does a previously rendered historical row remain stable
when only the current observation proxy advances?
```

This property was not visible from the clock-producer map alone.

## Candidate next observations

No candidate is approved by this audit.

### Candidate 1: one-day sensitivity fixture matrix

Hold source Events fixed and vary only an explicit date input where possible:

```text
D
D+1
```

Observe:

```text
plan status
actual snapshot
future plan cutoff
per-day denominator
```

### Candidate 2: unrelated-event coupling

Add a journal Event in an unrelated account/category and observe whether it changes:

```text
planned status
envelope avg_spend
cycle plan remaining
```

### Candidate 3: Daily Trend historical stability

Render a historical trend row, advance the local latest journal date, and test whether the old row changes.

### Candidate 4: period-end `as_of` naming audit

Compare:

```text
snapshot
trial-balance
actual_snapshot
```

and decide whether `as_of` is one contract or two differently named boundaries.

### Candidate 5: reproducibility audit

Given:

```text
same TSV
same config
same code
```

classify which sections can still change solely because:

```text
system_today changed
cycle selection changed
local latest-journal proxy changed
```

## Recommended pause point

Do not choose a runtime fix from the producer map alone.

The consumer map suggests that the next runtime decision should answer:

```text
which semantic property are we trying to restore?
```

Possible properties include:

```text
period containment
observation consistency
historical stability
cross-domain independence
auditability
reproducibility
```

These are not equivalent.

A small fix to one local helper may improve one property while leaving another untouched.

## Evidence paths reviewed

Canonical principle:

- `docs/TIME_AS_AXIS.md`

Report assembly:

- `src_next/report.bqn`

Context / period:

- `src_next/context.bqn`
- `src_next/cycle.bqn`

Explicit observation cutoff:

- `src_next/actual_snapshot.bqn`

Time-relative / local-clock consumers:

- `src_next/planned_payments.bqn`
- `src_next/plan_status.bqn`
- `src_next/envelope_computation.bqn`
- `src_next/cycle_summary.bqn`
- `src_next/outlook.bqn`
- `src_next/daily_trend.bqn`
- `src_next/daily_flow.bqn`
- `src_next/actual_comparison.bqn`

Period-driven consumers:

- `src_next/snapshot.bqn`
- `src_next/trial_balance.bqn`
- `src_next/ytd_summary.bqn`
- `src_next/balances.bqn`
- `src_next/expense_breakdown.bqn`
- `src_next/readiness_check.bqn`

Other temporal shapes:

- `src_next/recent_journal.bqn`
- `src_next/issues.bqn`

Characterization evidence:

- PR #73
- `tests/test_src_next_temporal_clock_characterization.bqn`

## Final observation

The current repository does not merely have multiple clocks.

It has multiple **temporal response functions**.

Conceptually:

```text
consumer(event space, temporal input)
  -> observed meaning
```

Different consumers currently implement different response functions:

```text
step function       -> status threshold
prefix inclusion    -> actual snapshot
ratio denominator   -> envelope pace
window resize       -> actual comparison
period materialize  -> TBDS reports
source tail         -> recent rows
```

The next design move should preserve that distinction rather than flattening it into one global date.
