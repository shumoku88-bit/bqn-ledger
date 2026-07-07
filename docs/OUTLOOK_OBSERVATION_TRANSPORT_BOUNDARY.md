# Outlook Observation Transport Boundary

Status: current decision / pre-runtime transport boundary
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Consumer question: `docs/OUTLOOK_HOUSEHOLD_QUESTION_DECISION.md`
Current paired characterization: `tests/test_src_next_outlook_observation_sensitivity.bqn`
Exit: revise or archive after a caller-owned explicit Outlook observation path is implemented, characterized, and wired intentionally

## 0. Purpose

PR #90 selected the canonical Outlook household question:

```text
At observation O,
what liquid spending room can the household rely on through cycle end C
under the selected Outlook policy,
while separately showing actual-record freshness L?
```

PR #91 then characterized current behavior under a fixed cycle:

```text
O moves, L fixed
  -> Outlook O-shaped outputs remain unchanged

O fixed, L moves
  -> Outlook O-shaped outputs change
```

The paired evidence is now strong enough to answer the next design question:

```text
How should caller-selected observation O reach Outlook?
```

This document selects that transport boundary before runtime repair.

## 1. Current evidence

### 1.1 Current Outlook manufactures its report reference date locally

Current `src_next/outlook.bqn` approximately does:

```text
as_of = LatestActualDateInCycle(base, cy)

snapshot = actual_snapshot.BuildAt(ctx, as_of)

days_left = C - as_of

remaining-plan cutoff = as_of

reported as_of = local L
last_journal   = local L
journal_lag    = 0
```

So current Outlook uses local latest-recorded frontier `L` in the role that the selected household question assigns to observation `O`.

### 1.2 Current context has an explicit-date path, but not one clean universal O contract

Current `context.BuildContext` supports:

```text
BuildContext(base)
BuildContext(base, explicit_date)
```

PR #85 characterized that:

```text
constructor form changes ctx.as_of source
cycle mode changes whether the same explicit date also moves period selection
```

In fixed mode:

```text
explicit date moves ctx.as_of
selected cycle stays fixed
```

In calendarMonth mode:

```text
explicit date moves ctx.as_of
and may move selected cycle
```

Therefore:

```text
ctx.as_of exists
```

is not sufficient proof that:

```text
ctx.as_of is canonical Outlook O
```

### 1.3 Current report entrypoints do not select explicit O

Current human report path approximately does:

```text
src_next/report.bqn
  -> ctx_mod.BuildContext base
  -> outlook.Build ctx
```

Current machine summary path approximately does:

```text
src_next/summary.bqn
  -> ctx_mod.BuildContext base
  -> outlook.Build ctx
```

Neither path currently exposes a caller-owned Outlook observation date.

Therefore changing an Outlook formula from local `L` to `ctx.as_of` would not by itself establish the selected ownership model.

It would substitute one available date value for another without first establishing who selected it and for what question.

## 2. Decision

The canonical transport direction is:

```text
caller / report query selects O
        |
        v
explicit Outlook observation boundary receives O
        |
        v
Outlook applies O to O-relative terms
```

The first runtime mechanism should be a consumer-specific explicit observation entrypoint with the conceptual shape:

```text
outlook.BuildAt(ctx, O)
```

The exact BQN signature may differ for language ergonomics, but the ownership must remain explicit.

The name `BuildAt` is a candidate because `actual_snapshot.BuildAt(ctx, cutoff)` already demonstrates a caller-owned hard-cutoff mechanism.

This document selects the ownership and transport shape, not code reuse or a universal API abstraction.

## 3. Why a consumer-specific explicit boundary is selected

The selected household question is Outlook-specific.

A consumer-specific boundary allows:

```text
Outlook O
```

to be introduced without claiming:

```text
all report consumers share one O
all sections interpret O identically
ctx.as_of is globally clean
cycle selection and observation are the same operation
```

This follows the current temporal principle:

```text
different meanings keep different names
new meanings are added sideways
only proven-equivalent meanings are unified later
```

The immediate goal is not to create a new architecture object.

The goal is to give one consumer a trustworthy caller-owned observation path.

## 4. Candidate transport paths considered

### A. Reuse `ctx.as_of` directly inside Outlook

Not selected as the first transport contract.

Reason:

```text
ctx.as_of source depends on constructor form
its cycle-selection effect depends on cycle mode
current production entrypoints do not explicitly select it as Outlook O
```

This does not mean `ctx.as_of` can never carry Outlook O.

A later caller may intentionally construct a context with a chosen O and pass that same value explicitly to Outlook.

What is rejected is the inference:

```text
field name says as_of
therefore Outlook may treat it as canonical O automatically
```

### B. Add consumer-specific explicit observation input

Selected direction.

Conceptual shape:

```text
outlook.BuildAt(ctx, O)
```

Benefits:

```text
caller ownership is visible
O is testable independently from L
fixed-cycle characterization can isolate observation movement
Outlook-specific semantics stay local to the consumer
production wiring can be a later separate slice
```

### C. Add report-wide `--as-of` and wire every section now

Not selected for the first slice.

This would bundle:

```text
CLI policy
context construction
cycle resolution
Outlook
Daily Trend
snapshot behavior
other section contracts
```

The current investigation explicitly rejects that bundle.

A report-wide explicit observation input may still be valuable later.

It must be introduced after consumer contracts are sufficiently clear.

### D. Read system clock inside Outlook

Rejected.

That would create another module-local clock and violate the existing clock-boundary principle.

### E. Add a universal `TemporalFrame`

Rejected.

No evidence requires one object containing:

```text
D, O, L, C, H, K, ...
```

The current design principle prefers explicit meanings and local ownership over premature aggregation.

## 5. Selected first runtime mechanism, but not yet runtime authorization

The selected mechanism target is:

```text
explicit caller-owned Outlook observation path
```

with conceptual shape:

```text
BuildAt(ctx, O)
```

A later runtime slice may implement that mechanism only after it can preserve the following separation:

```text
O = selected observation date
L = actual-record freshness frontier
C = cycle boundary
```

Expected O-relative dependencies include:

```text
actual snapshot visibility -> O
remaining-plan threshold   -> O + C + plan semantics
days_left                  -> O + C
days_elapsed               -> O + C
planned future liquid      -> O + C + plan semantics
daily amount denominator   -> O + C
reported Outlook as_of     -> O
```

Expected L-relative dependency includes:

```text
last recorded frontier -> L
```

This document does not yet authorize editing `src_next/outlook.bqn` because the current freshness fields expose one more unresolved seam.

## 6. Freshness seam exposed by O/L separation

Current Outlook returns approximately:

```text
as_of        = local L
last_journal = local L
journal_lag  = 0
```

When `O` and `L` are separated, `journal_lag` can no longer remain semantically explained by equality.

PR #91 already contains a case with:

```text
O = 2026-01-03
L = 2026-01-06
```

So a future explicit O path must handle not only:

```text
L < O
```

but also:

```text
L = O
L > O
```

Possible meanings are not equivalent:

```text
A. signed frontier offset
   O - L

B. nonnegative staleness only
   max(0, O - L)

C. relation + magnitude
   before / at / after observation

D. freshness relative to a separate data cutoff K
```

No option is selected here.

The current constant:

```text
journal_lag = 0
```

is behavioral evidence from collapsed O/L semantics, not a future contract.

## 7. Consequence for the next finite slice

Before implementing `Outlook.BuildAt`, resolve one narrow freshness question:

```text
What does Outlook need to communicate when L is before, equal to, or after O?
```

The next slice should remain docs/design or test-only.

It should use existing evidence, especially the PR #91 case:

```text
O fixed at 2026-01-03
L advances from 2026-01-03 to 2026-01-06
```

and should choose only the freshness relation needed to prevent the new explicit O path from inventing a misleading `journal_lag` meaning.

It should not bundle:

- production CLI `--as-of`,
- report-wide observation wiring,
- Daily Trend repair,
- cycle-resolution changes,
- `LatestActualDateInCycle` deduplication,
- snapshot API unification,
- `TemporalFrame`,
- source TSV changes.

## 8. Default `Build(ctx)` compatibility boundary

A future explicit observation mechanism does not automatically decide what current:

```text
outlook.Build(ctx)
```

should mean.

Possible later choices include:

```text
retain current local-L default for compatibility
make Build require a trustworthy caller-selected O
route Build through a report-level O default
remove ambiguous default after migration
```

No choice is made here.

The first explicit path should not silently change production behavior merely because a new mechanism exists.

This mirrors the ownership lesson from `actual_snapshot`:

```text
mechanism that enforces a cutoff
!=
policy that chooses the cutoff
```

## 9. Production wiring remains a separate decision

Current human and machine report entrypoints do not expose explicit Outlook O.

Therefore production adoption requires a later decision about caller policy.

Possible future sources include:

```text
explicit CLI --as-of
report query object
system_today default resolved once at entry
replay-specific caller input
```

These are not equivalent.

The transport contract selected here only requires:

```text
whatever selects O
must pass O explicitly across the Outlook boundary
```

It does not choose the final report-wide source.

## 10. Relationship to `actual_snapshot.BuildAt`

`actual_snapshot.BuildAt(ctx, cutoff)` is useful evidence because it shows:

```text
caller-owned explicit cutoff
```

can coexist with:

```text
module-owned default Build(ctx)
```

But Outlook must not copy the snapshot API mechanically.

The meanings differ:

```text
actual_snapshot BuildAt argument
  = hard actual cutoff

Outlook explicit O
  = household observation frame
  -> may drive snapshot cutoff plus plan windows, denominators, and display semantics
```

The same date value can be passed to both mechanisms when the consumer contract requires it.

That does not make their ownership meanings identical.

## 11. Runtime gate

A runtime slice adding an explicit Outlook observation path may proceed only after it can state:

1. caller owns O selection,
2. O crosses the Outlook boundary explicitly,
3. Outlook does not manufacture O from L,
4. O-relative terms are enumerated,
5. L remains separately derived freshness evidence,
6. `journal_lag` or its replacement has a defined meaning for `L < O`, `L = O`, and `L > O`,
7. current `Build(ctx)` production behavior is either preserved or changed by a separately stated decision,
8. report-wide CLI/context wiring remains outside the slice unless explicitly selected.

## 12. Decision summary

```text
Selected transport direction:
  caller-selected O
    -> explicit Outlook consumer boundary
    -> O-relative calculations

Selected first mechanism target:
  consumer-specific explicit path
  conceptually Outlook.BuildAt(ctx, O)

Not selected:
  blind ctx.as_of reuse
  module-local system clock
  report-wide global O bundle
  universal TemporalFrame

Current blocker before runtime:
  freshness relation / journal_lag meaning when O != L

Production behavior:
  unchanged
```

The current code shape is not protected.

The ownership boundary is.
