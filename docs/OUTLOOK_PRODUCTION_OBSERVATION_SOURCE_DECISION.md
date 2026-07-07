# Outlook Production Observation Source Decision

Status: current decision / pre-wiring production source contract
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Consumer question: `docs/OUTLOOK_HOUSEHOLD_QUESTION_DECISION.md`
Transport boundary: `docs/OUTLOOK_OBSERVATION_TRANSPORT_BOUNDARY.md`
Frontier relation: `docs/OUTLOOK_RECORD_FRONTIER_RELATION_DECISION.md`
Runtime mechanism: `src_next/outlook.bqn` explicit `BuildAt(ctx, O)` path
Exit: revise or archive after human report production wiring consumes this decision and is characterized

## 0. Purpose

The Outlook temporal sequence has now established:

```text
consumer question
  -> Q3-style O/L separation

protected property
  -> observation consistency

paired characterization
  -> current Outlook follows L rather than explicit O

transport boundary
  -> caller-selected O crosses an explicit Outlook boundary

frontier relation
  -> before / at / after / unavailable

runtime mechanism
  -> outlook.BuildAt(ctx, O)
```

The mechanism exists without changing current production report wiring.

The next question is narrower:

```text
For the human production report,
where does Outlook O come from?
```

This document selects that source policy.

## 1. Current entrypoint evidence

Current production human report path is approximately:

```text
tools/report
  -> src_next/report.bqn <base> [flags]
  -> ctx_mod.BuildContext base
  -> outlook.Build ctx
```

Current `tools/report` already forwards unknown report flags to `src_next/report.bqn` after resolving the base directory and color/cache options.

Current `src_next/report.bqn` does not select an explicit Outlook observation date.

Current `src_next/date.bqn` provides:

```text
Today()
  -> system date YYYY-MM-DD
```

Current canonical temporal policy in `docs/TIME_AS_AXIS.md` states approximately:

```text
system_today
  -> default only
  -> as_of
```

and prefers reading the external clock once at the report entrance rather than repeatedly inside consumer modules.

Therefore the production source question can be decided without adding another module-local clock.

## 2. Decision

For the human production report, Outlook observation `O` is selected as follows:

```text
explicit --outlook-as-of YYYY-MM-DD
  -> O = supplied date

otherwise
  -> O = system_today read once at src_next/report.bqn entry
```

Then:

```text
outlook.BuildAt(ctx, O)
```

is used for the Outlook section.

This decision is intentionally consumer-specific.

It does not introduce a report-wide global observation contract.

## 3. Why the explicit flag is `--outlook-as-of`

A generic flag:

```text
--as-of
```

is not selected for the first production wiring slice.

Reason:

Current sections do not yet share one proven observation contract.

The current temporal investigation has already characterized that:

```text
cycle summary
TBDS
actual snapshot
recent rows
planned payments
actual comparison
Daily Trend
Outlook
```

have different current temporal dependencies and ownership boundaries.

Introducing a generic report flag now could suggest:

```text
all sections are observed at this date
```

when that is not established.

The consumer-specific name keeps the promise narrow:

```text
--outlook-as-of affects Outlook O
```

A later report-wide input may be introduced if multiple consumers prove compatible ownership semantics.

That later input must not be inferred merely from equal date values.

## 4. Default source

When no explicit Outlook observation is supplied:

```text
O = system_today
```

selected once at the human report entry.

This follows the existing canonical principle that the OS clock supplies a default observation value rather than becoming an Event coordinate or a hidden module-local dependency.

The expected shape is:

```text
report entry
  -> read Today once
  -> O
  -> Outlook.BuildAt(ctx, O)
```

Not:

```text
Outlook
  -> read Today internally
```

and not:

```text
multiple sections
  -> each read system clock independently
```

## 5. Why current `ctx.as_of` is not selected as the default source

Not selected:

```text
O = ctx.as_of automatically
```

Reason:

PR #85 characterized that current `ctx.as_of` source and effect depend on:

```text
BuildContext constructor form
cycle mode
```

In the current default human report path:

```text
BuildContext(base)
```

may derive `ctx.as_of` from resolved cycle state rather than from the household observation question.

Therefore wiring production Outlook to `ctx.as_of` would reintroduce the same ownership ambiguity the explicit `BuildAt` path was created to avoid.

## 6. Cycle selection remains unchanged in the first wiring slice

The first human production wiring slice must keep current context and cycle construction unchanged:

```text
ctx = BuildContext(base)
```

Then select Outlook O separately:

```text
O = explicit --outlook-as-of or one-time system_today default
outlook.BuildAt(ctx, O)
```

This intentionally permits:

```text
cycle C
and
observation O
```

to be selected by different policies.

That is not automatically a bug.

It follows the canonical principle that observation time and period boundary are distinct meanings.

## 7. Consequence for O outside C

The first wiring slice must not silently clamp:

```text
O
```

to:

```text
cycle.start
cycle.end_exclusive
L
```

Current explicit Outlook mechanism already computes O-relative terms against C.

Examples:

```text
O before C.start
O inside C
O at or after C.end_exclusive
```

may produce materially different denominators and windows.

This decision does not define historical replay products Q4 or Q5.

It only requires that the selected O remain explicit rather than silently rewritten.

A later characterization slice may add specific outside-cycle behavior if needed.

## 8. Human report scope only

This decision applies to:

```text
tools/report
  -> src_next/report.bqn
```

It does not yet change:

```text
tools/report-next-summary
  -> src_next/summary.bqn
```

The machine summary is a separate caller surface.

Reasons to keep it separate include:

```text
reproducibility expectations
machine field compatibility
existing compact summary parity checks
caller API shape
```

The summary surface may later adopt an explicit Outlook O source after its own finite slice.

## 9. No change to default `outlook.Build(ctx)`

The first human production wiring slice does not need to redefine or delete:

```text
outlook.Build(ctx)
```

Current compatibility behavior may remain available for:

```text
existing tests
summary surface
other callers
migration evidence
```

The human report should opt into the new explicit path deliberately:

```text
outlook.BuildAt(ctx, O)
```

This preserves the distinction:

```text
mechanism exists
!=
all callers are switched at once
```

## 10. Validation contract

The explicit flag must be validated before Outlook consumes it.

Selected requirement:

```text
--outlook-as-of must be a valid YYYY-MM-DD date
```

Invalid or missing flag values should fail closed with a visible error.

Do not silently fall back to system today after the caller supplied an invalid explicit date.

That would erase caller intent.

## 11. Expected first runtime slice

The next runtime slice should change only the human report observation source and Outlook dispatch.

Conceptual changes:

```text
src_next/report.bqn
  + import date helper
  + parse --outlook-as-of
  + validate explicit date
  + otherwise read Today once
  + build Outlook via BuildAt(ctx, O)
```

Potential `tools/report` change:

```text
none required if the wrapper continues forwarding unknown flags
```

The slice should add focused tests for:

```text
explicit flag reaches Outlook O
invalid explicit flag fails
missing value fails
no flag uses one default O path
other report section dispatch remains unchanged
```

## 12. Protected property

The protected property remains:

```text
observation consistency
```

For this wiring slice, that means:

> The human Outlook section receives one named O selected at report entry, and local recorded frontier L does not silently redefine it.

This does not mean all human report sections use O.

## 13. Non-goals

This decision does not authorize:

- generic report-wide `--as-of`,
- changing `ctx.as_of` semantics,
- changing cycle resolution,
- wiring Daily Trend to O,
- changing snapshot section semantics,
- changing machine summary wiring,
- deleting `outlook.Build(ctx)`,
- unifying L producers,
- changing envelope temporal semantics,
- adding a universal `TemporalFrame`,
- changing source TSV,
- choosing historical replay Q4,
- choosing retrospective present-knowledge Q5.

## 14. Decision summary

```text
Human production Outlook O source:

  explicit --outlook-as-of DATE
    -> O = DATE

  otherwise
    -> O = system_today read once at report entry

Dispatch:
  outlook.BuildAt(ctx, O)

Cycle/context:
  unchanged in first wiring slice

Generic --as-of:
  not selected yet

Machine summary:
  separate future slice

Protected property:
  observation consistency
```

The selected source policy is deliberately narrow.

It gives the human Outlook section a real observation owner without pretending the entire report already shares one temporal frame.
