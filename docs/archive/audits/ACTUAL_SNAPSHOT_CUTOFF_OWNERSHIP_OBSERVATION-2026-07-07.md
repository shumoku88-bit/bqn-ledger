# Actual Snapshot Cutoff Ownership Observation - 2026-07-07

Status: audit snapshot / docs-only observation
Owner: other
Canonical: no; canonical temporal principle: `docs/TIME_AS_AXIS.md`
Base evidence: merged PRs #83-#86 plus current `src_next` call paths
Exit: after a separately approved runtime or contract decision consumes this map; retain as historical evidence

## Purpose

Recent characterization established that current temporal behavior cannot be reduced to one global `as_of`:

```text
Daily Trend
  explicit ctx.as_of moves, local L fixed
    -> unchanged

  explicit ctx.as_of fixed, local L moves
    -> changes

context
  constructor form changes ctx.as_of source
  cycle mode changes whether the same explicit date moves period selection

actual_snapshot
  BuildAt(ctx, explicit_as_of)
    -> explicit hard cutoff

  Build(ctx)
    -> local latest in-cycle journal date
    -> BuildAt(ctx, local_date)
```

This observation asks a narrower ownership question:

```text
who chooses the cutoff passed to actual_snapshot?
```

The goal is not to decide which owner is correct.

The goal is to map current caller ownership before any rewiring.

## Non-goals

This observation does not authorize:

- changing `actual_snapshot.Build`,
- deleting `Build`,
- replacing local dates with `ctx.as_of`,
- changing Outlook behavior,
- changing Snapshot section behavior,
- adding `TemporalFrame`,
- adding a global `as_of`,
- choosing Daily Trend Candidate A or B,
- changing source TSV.

## 1. `actual_snapshot.BuildAt`: calculation consumes caller-owned cutoff

Path:

```text
src_next/actual_snapshot.bqn
```

Current shape:

```text
BuildAt(ctx, as_of)
  -> admit known valid journal rows where row.date <= as_of
  -> calculate account amounts and snapshot totals
  -> expose the same as_of in the result
```

PR #86 characterizes this as a real hard cutoff.

With the same source data and fixed cycle:

```text
BuildAt(ctx, 2026-01-03)
  assets:other/JPY  = -1
  expenses:misc/JPY = 1

BuildAt(ctx, 2026-01-06)
  assets:other/JPY  = -2
  expenses:misc/JPY = 2
```

Ownership observation:

```text
BuildAt does not choose observation policy.
The caller chooses the cutoff value.
BuildAt enforces the supplied cutoff.
```

This separates two responsibilities:

```text
cutoff policy ownership
  -> caller

hard-cutoff calculation
  -> actual_snapshot.BuildAt
```

## 2. `actual_snapshot.Build`: module-owned local default policy

Current shape:

```text
Build(ctx)
  -> LatestActualDateInCycle(ctx.base, ctx.cy)
  -> BuildAt(ctx, local_latest_date)
```

PR #86 characterizes that differing `ctx.as_of` values do not change this default path when source data and local latest journal date are unchanged.

Example:

```text
early_ctx.as_of = 2026-01-03
late_ctx.as_of  = 2026-01-06

Build(early_ctx).as_of = 2026-01-06
Build(late_ctx).as_of  = 2026-01-06
```

Ownership observation:

```text
Build owns its own default cutoff policy.
ctx.as_of is not the cutoff owner on this path.
```

Therefore the two exported entry points are not merely convenience aliases:

```text
BuildAt
  caller-owned cutoff

Build
  module-owned local cutoff
```

## 3. Canonical Outlook: caller is explicit, but caller chooses local `L`

Path:

```text
src_next/outlook.bqn
```

Current call chain:

```text
outlook.Build(ctx)
  -> Outlook.LatestActualDateInCycle(base, cy)
  -> local as_of = L
  -> actual_snapshot.BuildAt(ctx, L)
```

This is an important distinction.

The call site is explicit:

```text
BuildAt(ctx, as_of)
```

but the cutoff is not necessarily an external observation frame `O`.

The caller itself derives a local journal-based date:

```text
Outlook local L
  -> passed explicitly to BuildAt
```

Therefore:

```text
explicit API call
  != proof of externally owned observation semantics
```

Current ownership is approximately:

```text
Outlook
  owns cutoff policy

actual_snapshot.BuildAt
  owns hard-cutoff calculation
```

Existing temporal characterization has already found that Outlook's local helper can consume a later journal date beyond a selected historical cycle end.

That consequence belongs to caller cutoff policy, not to `BuildAt` hard-cutoff mechanics.

## 4. Canonical Snapshot section does not currently use `actual_snapshot`

Paths:

```text
src_next/report.bqn
src_next/snapshot.bqn
```

Current human report assembly uses:

```text
snapshot.Build(ctx)
```

Current `snapshot.bqn` explicitly records:

```text
No longer reads journal.tsv directly
(previously used actual_snapshot)
```

Its current monetary values come from TBDS actual-layer closing balances.

Its displayed `as_of` is:

```text
cycle.end_exclusive
```

Therefore the report section named `snapshot` currently has a different temporal shape from `actual_snapshot.BuildAt`:

```text
Snapshot section
  -> TBDS period boundary / closing view

actual_snapshot.BuildAt
  -> ledger-wide hard observation cutoff
```

The shared word `snapshot` should not be treated as proof of shared temporal semantics.

## 5. Canonical top-level surfaces inspected

### Human report

Path:

```text
src_next/report.bqn
```

Observed assembly:

```text
snapshot section
  -> snapshot.Build(ctx)

outlook section
  -> outlook.Build(ctx)
    -> actual_snapshot.BuildAt(ctx, Outlook local L)
```

`report.bqn` does not directly import `actual_snapshot.bqn`.

### Machine summary

Path:

```text
src_next/summary.bqn
```

Observed assembly:

```text
snapshot
  -> snapshot.Build(ctx)

outlook
  -> outlook.Build(ctx)
```

`summary.bqn` does not directly import `actual_snapshot.bqn`.

## 6. Evidence boundary

This observation intentionally does not claim:

```text
actual_snapshot.Build has no consumer anywhere in the repository
```

Reason:

- GitHub code search did not return usable BQN symbol references for this repository,
- a full local clone was unavailable in the current investigation environment,
- therefore repository-wide absence was not proven by exhaustive grep.

What is supported by current evidence is narrower:

```text
canonical human report surface inspected
  -> no direct actual_snapshot.Build use

canonical machine summary surface inspected
  -> no direct actual_snapshot.Build use

canonical Snapshot section
  -> no longer uses actual_snapshot

canonical Outlook section
  -> uses actual_snapshot.BuildAt with Outlook-owned local L

actual_snapshot.Build
  -> characterized as module-owned local-L default path
```

Historical consumer-sensitivity audit also identifies `actual_snapshot.BuildAt` as the clearest explicit hard-cutoff consumer and records Outlook's `BuildAt(ctx, as_of)` chain.

## 7. Current ownership map

Approximate current shape:

```text
A. actual_snapshot.BuildAt(ctx, cutoff)

caller chooses cutoff
        |
        v
actual_snapshot enforces hard cutoff
```

```text
B. actual_snapshot.Build(ctx)

actual_snapshot chooses local latest in-cycle journal date L
        |
        v
BuildAt(ctx, L)
```

```text
C. Outlook

Outlook chooses its own local L
        |
        v
actual_snapshot.BuildAt(ctx, L)
```

```text
D. canonical Snapshot section

selected cycle / TBDS
        |
        v
period closing balances
        |
        v
as_of label = cycle.end_exclusive
```

## 8. Main finding

The strongest current finding is not:

```text
actual_snapshot has one wrong as_of
```

It is:

```text
cutoff ownership is distributed across entry points and callers
```

Specifically:

```text
caller-owned explicit cutoff
module-owned local latest-journal default
Outlook-owned local latest-journal cutoff
TBDS period-boundary Snapshot section
```

These are observably different temporal contracts.

Therefore a future fix should not begin with:

```text
replace L with ctx.as_of
```

or:

```text
make all snapshot-like things use BuildAt
```

The next decision must first identify which consumer owns observation policy.

## 9. Narrow next questions

No runtime change is authorized by this observation.

The next useful questions are:

```text
1. Is actual_snapshot.Build a compatibility/default API that should remain distinct?

2. Does any non-canonical current consumer depend on Build(ctx)'s module-owned L policy?

3. Should Outlook own its cutoff policy, or should a report/query boundary supply it?

4. Is Outlook's current local L intentional compatibility behavior or a migration artifact?

5. Should the canonical Snapshot section continue to use period-boundary semantics independently of observation snapshots?
```

The first runtime change, if any, should be chosen only after one of these ownership questions is answered.
