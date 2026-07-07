# Temporal Legacy Evidence Correction - 2026-07-07

Status: docs-only historical correction / evidence addendum
Owner: other
Canonical: no
Canonical temporal principle: `docs/TIME_AS_AXIS.md`
Foundation being corrected: `docs/archive/audits/TEMPORAL_HISTORY_AND_FUTURE_FOUNDATION-2026-07-07.md`
Evidence source: private archived repository `shumoku88-bit/bqn-ledger-legacy`
Exit: retain as historical evidence; later canonical decisions may cite this document but should not silently absorb its inferences

## 0. Purpose

The temporal foundation merged after PR #88 was written before the archived private repository `bqn-ledger-legacy` had been inspected.

That foundation was intentionally cautious about the public-history boundary. It stated that public `bqn-ledger` history could prove local `L` existed by the initial public release, but could not prove:

```text
when src_next Outlook first introduced local L
whether local L existed at Outlook birth
whether L was introduced before or after parity work
whether an explicit observation path already existed in src_next context
```

The archived legacy repository now provides direct historical evidence for those questions.

This document corrects that evidence boundary.

It does not invalidate the broader future-facing principles in the foundation.

It strengthens and narrows the historical account.

## 1. Non-goals

This correction does not authorize:

- changing Outlook runtime behavior,
- changing Daily Trend runtime behavior,
- replacing local `L` with `ctx.as_of`,
- adding a report-wide observation field,
- deleting `actual_snapshot.Build`,
- restoring the old giant `BuildAt` record,
- changing cycle resolution,
- adding a universal `TemporalFrame`,
- choosing Daily Trend Candidate A or B,
- changing source TSV,
- declaring every migration choice a bug.

The document also does not claim access to the intentions or private reasoning of the original implementation author.

It records code and migration history.

## 2. What this corrects in the PR #88 foundation

The foundation's strongest now-stale boundary was approximately:

```text
local L existed by initial public release
but the exact pre-public introduction moment is unavailable
```

That boundary is superseded by the legacy repository evidence below.

The corrected statement is:

```text
src_next Outlook can be inspected at its introduction commit
and local L is present in that first implementation
```

The foundation's inference that L may have acted as a compatibility or reconstruction proxy remains plausible, but can now be grounded in a more specific sequence.

## 3. Old production engine: explicit O and last-journal L were separate

At the historical point inspected in the legacy repository, the old production engine had:

```text
report_engine.BuildAt(explicit as_of)
```

with default `Today` only when no explicit value was supplied.

The old engine used the explicit observation input for:

```text
snapshot cutoff
cycle resolution inputs
Outlook daily denominator
future-plan windows
Daily Trend observation window
```

The old Outlook helper separately calculated:

```text
last_journal_date
```

as the maximum recorded journal coordinate.

It also explicitly kept:

```text
plan_open_cutoff_dn = as_of
```

separate from `last_journal_date`.

Therefore the historical old engine had a real conceptual distinction:

```text
O = report observation date
L = last recorded journal coordinate / recency context
```

This is stronger than merely saying the old engine had an `--as-of` option.

## 4. src_next context at Outlook birth had no observation field

Commit:

```text
4f13c0686177e40225e61223880d507722061a33
src_next: add outlook module (Sec 9 - Daily Amount)
```

At that commit, `src_next/context.bqn` returned approximately:

```text
ctx = {
  base
  cy
  resolved
  cube
  tbds
}
```

There was no:

```text
ctx.as_of
```

and no report-wide observation input in the context.

This changes the fairest interpretation of the local clock decision.

The first src_next Outlook did not ignore an already-available clean observation field.

Instead:

```text
src_next context had no O boundary
        |
        v
Outlook needed a reference date for days-left and daily amounts
        |
        v
Outlook created a local latest-journal date
```

This is evidence of a missing boundary at implementation time, not proof of accidental negligence.

## 5. src_next Outlook birth commit already equated local L with `as_of`

The same introduction commit created `src_next/outlook.bqn` with:

```text
LatestActualDateInCycle(base, cy)
```

and:

```text
as_of = LatestActualDateInCycle(base, cy)
```

The initial helper admitted journal dates approximately satisfying:

```text
date >= cycle.start
```

without an observed upper cycle bound.

The initial ViewModel then exposed:

```text
as_of        = local L
last_journal = local L
journal_lag  = 0
```

Therefore local L was not a later drift inside src_next Outlook.

It was present at Outlook birth.

## 6. Daily Trend birth also used local L

Commit:

```text
770d0518f563714db44d8f8fb239aea562382b9a
src_next: add daily_trend module (Sec 10 - Daily Trend)
```

The initial Daily Trend implementation also defined a local:

```text
LatestActualDateInCycle
```

and used it as:

```text
as_of
```

for the observation window.

The initial formula was simpler than the later production-like Trend:

```text
reserve = 0
fund = liquid
```

So the historical order matters:

```text
local-L observation frame first
        |
        v
richer Trend semantics later
```

## 7. Later Daily Trend moved old-style formulas onto the local-L frame

Before production adoption, src_next Daily Trend had grown to include:

```text
planned_future_income
fixed reserve
fund = liquid + planned_future_income - reserve
```

But its report-local `as_of` still came from local L.

The resulting shape was approximately:

```text
future income cutoff = L
last-actual fallback = L
fund                  = f(D, L, C, ...)
```

At the same historical point, old production Daily Trend had the corresponding shape with explicit O:

```text
future income cutoff = O
last-actual fallback = O
fund                  = f(D, O, C, ...)
```

This supports a stronger historical reading than the PR #88 foundation could make:

```text
src_next first established a local-L frame
then production-like Trend formulas were reconstructed on top of it
```

A plausible interpretation is that the old O-dependent semantics were rebuilt in a system that still lacked an explicit observation boundary, leaving L in the O-shaped position.

That is an inference from code sequence, not a proven statement of author intent.

## 8. Migration documents explicitly recognized the O/L difference

The legacy manual comparison procedure states that:

```text
src_next had no --as-of option
src_next used the latest in-cycle journal date as as_of
current engine defaulted to Today
```

It further classified differences caused only by this `as_of` mismatch as:

```text
expected/current-engine-difference
```

and stated that no extra fix was required when calculation itself was otherwise consistent.

This changes the classification of local L in the historical story.

It was not merely an invisible bug nobody noticed.

It was an explicitly recognized migration difference.

The unresolved question was not whether the difference existed.

The unresolved question was whether that difference should remain after production adoption.

## 9. The comparison procedure initially treated as_of mismatch as diagnostic evidence

The manual comparison procedure required recording:

```text
current engine as_of
src_next as_of
```

and warned that remaining-days differences could follow from an as_of mismatch.

Importantly, the procedure described `as_of` as a diagnostic comparison area rather than automatically requiring equality.

This was a sound evidence boundary:

```text
same field name
  != guaranteed same semantics
```

## 10. Automated field parity later injected src_next L into old-engine O

The public fixture field-level comparison script later used this sequence:

```text
run src_next summary
        |
        v
read src_next_outlook_as_of
        |
        v
call old engine with --as-of "$src_next_outlook_as_of"
        |
        v
compare fields
```

Therefore the automated parity check proved approximately:

```text
Given the same cutoff date value,
do comparable calculations match?
```

It did not prove:

```text
Does src_next obtain that date from the same temporal meaning as the old engine?
```

This distinction is central.

The check was useful and legitimate calculation parity evidence.

It was not semantic O/L equivalence evidence.

## 11. `actual_snapshot.BuildAt` was added after local-L policy already existed

Commit:

```text
0c43bca7eb1d24785767e89553ad479b817e263e
src_next: add as-of actual snapshot view
```

Historical timestamp:

```text
2026-06-25 21:54:58 JST
```

This commit added:

```text
actual_snapshot.BuildAt(ctx, as_of)
```

with a real hard cutoff:

```text
journal date <= supplied as_of
```

It also added the default:

```text
Build(ctx)
  -> local latest actual date
  -> BuildAt(ctx, local L)
```

Crucially, Outlook continued to choose its own local L and then called:

```text
actual_snapshot.BuildAt(ctx, L)
```

Therefore the historical sequence was:

```text
local-L policy exists first
        |
        v
explicit hard-cutoff mechanism added later
        |
        v
caller still supplies local L
```

This directly supports the current cutoff-ownership findings from PRs #86 and #87.

## 12. The as-of snapshot commit was also a parity-improvement commit

The same commit recorded that previously differing comparable fields now matched, including:

```text
liquid snapshot
liquid daily
safe liquid daily
```

This suggests the new `BuildAt` mechanism was used to improve calculation scope equivalence.

But the cutoff policy remained local-L based.

Thus the migration improved:

```text
how a chosen cutoff is enforced
```

without necessarily changing:

```text
who chooses the cutoff
or what semantic meaning the chosen date has
```

## 13. Production switch followed approximately 25 minutes later

Commit:

```text
045cb293eb277b8c63370502a99afe5d35c3e711
feat: Stage 4b start + envelope fix + prod switch to tools/report
```

Historical timestamp:

```text
2026-06-25 22:20:00 JST
```

The sequence was therefore approximately:

```text
21:54:58
  add actual_snapshot BuildAt
  improve comparable liquid/daily parity

22:20:00
  start Stage 4b
  switch daily production entrypoint to tools/report -> src_next/report.bqn
```

This short interval does not prove inadequate review.

It does show that:

```text
hard-cutoff mechanism
parity closure
Stage 4b start
production entrypoint switch
```

were temporally compressed.

That compression is relevant when explaining how migration assumptions could survive into production.

## 14. Production-switch commit contained contradictory transition narratives

At the switch commit:

```text
tools/report
```

explicitly described itself as the default production report entrypoint and executed:

```text
src_next/report.bqn
```

The same commit's Stage 4b decision record still stated approximately:

```text
production default remains bqn main.bqn
src_next is observation-only
Outlook advice is prohibited
```

The same commit's `src_next/report.bqn` header also still described the report as an observation surface and said production remained on `bqn main.bqn` until default switch.

This is direct evidence of a migration seam:

```text
runtime entrypoint state
and
documented safety/transition state
were not fully synchronized at the switch moment
```

This does not establish bad intent.

It shows that multiple migration layers changed faster than all documentation contracts could converge.

## 15. Old engine removal followed the switch

Legacy history records a staged removal sequence including:

```text
Phase 2a: delete src/core/ old engine core
Phase 2b: delete src/reports/ src/views/ main.bqn old engine surface
Phase 3a: delete old-engine checks
```

Therefore the broad sequence is now directly supported:

```text
src_next parity work
        |
        v
production switch
        |
        v
old engine staged deletion
```

The old engine was not deleted before src_next comparison.

The more important question is what the comparison guaranteed.

## 16. Corrected strongest historical synthesis

The PR #88 foundation used a cautious sequence with a public-history gap.

The stronger legacy-backed sequence is:

```text
old production engine
  explicit report observation O
  separate last-journal frontier L
        |
        v
src_next context introduced
  no O field
        |
        v
src_next Outlook introduced
  local LatestActualDateInCycle L
  L exposed as as_of
  last_journal = L
        |
        v
src_next Daily Trend introduced
  local L controls observation window
        |
        v
richer production-like Trend semantics added
  O-shaped calculations run on local-L frame
        |
        v
migration procedure explicitly recognizes
  src_next L-as-as_of differs from old default O
        |
        v
automated parity check injects src_next L
  into old engine --as-of O
  and validates calculation equivalence at same date value
        |
        v
actual_snapshot BuildAt hard-cutoff mechanism added
  Outlook still supplies local L
        |
        v
production switch to src_next daily entrypoint
        |
        v
old engine staged deletion
        |
        v
2026-07 temporal investigation discovers
  O disconnect
  L dominance
  historical-cycle leak
  distributed cutoff ownership
```

## 17. What is now strongly supported

The following statements are strongly supported by repository history:

```text
1. Old production engine separated explicit observation O from last-journal L.

2. src_next context had no as_of field when Outlook was introduced.

3. src_next Outlook used local L as `as_of` from its first implementation.

4. src_next Daily Trend also used local L from its first implementation.

5. Migration docs explicitly recognized that src_next used latest in-cycle journal date as as_of and lacked --as-of.

6. Automated parity reused src_next's chosen date as the old engine's explicit --as-of input.

7. actual_snapshot.BuildAt was added after local-L cutoff policy already existed.

8. The production switch followed shortly after that parity improvement.

9. Old engine removal followed production adoption.
```

## 18. What remains inference

The following remains inference:

```text
local L was intentionally designed as a temporary compatibility proxy for missing O
```

The evidence fits that interpretation strongly, but the repositories do not expose a direct design statement saying:

```text
"Use L temporarily until observation time is implemented."
```

A more careful wording is:

```text
local L occupied the report-reference-date role in src_next while the context lacked an explicit observation boundary
```

That is observable.

Whether the choice was consciously temporary is not proven.

## 19. What should no longer be claimed

After this legacy review, avoid saying:

```text
We do not know when local L entered src_next Outlook.
```

We now know it was present at Outlook introduction.

Avoid saying:

```text
The O/L difference was completely unnoticed during migration.
```

The manual comparison procedure explicitly recognized it.

Avoid saying:

```text
Parity proved src_next and old engine had the same observation semantics.
```

The field check proved calculation equivalence after feeding the src_next-selected date into old-engine `--as-of`.

Avoid saying:

```text
actual_snapshot.BuildAt created the local-L policy.
```

Local-L policy predated `BuildAt`.

## 20. Updated interpretation of current PR #83/#84 evidence

Current characterization says:

```text
#83
O moves, L fixed
  -> Daily Trend unchanged

#84
O fixed, L moves
  -> Daily Trend changes
```

Legacy evidence now explains a plausible historical route to that result:

```text
Daily Trend was born with local L
then richer old-style temporal formulas were added on top of that frame
```

Therefore #83/#84 are not merely discovering a recent disconnection.

They are likely characterizing a migration-era frame choice that survived into production.

## 21. Updated interpretation of cutoff ownership

Current ownership map remains valid and is strengthened:

```text
BuildAt
  caller chooses cutoff

actual_snapshot.Build
  module chooses local L

Outlook
  caller module chooses local L
  then calls BuildAt

Snapshot section
  TBDS period boundary
```

Legacy history shows these ownership patterns formed incrementally rather than from one unified temporal design.

This supports the current rule:

```text
ownership before abstraction
```

## 22. Impact on future development

The legacy evidence does not imply a simple restoration patch.

Do not conclude:

```text
restore old engine O everywhere
```

because current architecture intentionally moved away from the old giant report record and now includes TBDS period-boundary views, different section ownership, and future extension space.

Do not conclude:

```text
keep L everywhere because migration accepted it
```

because the migration procedure itself treated the O/L difference as a known expected difference, not as proven semantic equivalence.

The better future question remains consumer-level:

```text
What household question does this consumer answer?
Who owns its observation/cutoff policy?
Does it need O, L, C, H, or another meaning?
```

## 23. Revised near-term decision gates

Before runtime change:

### Gate A: Outlook product question

Choose which question canonical Outlook answers.

Examples:

```text
Q1. Safe to spend from observation O until cycle end?
Q2. Safe to spend from last recorded frontier L until cycle end?
Q3. Safe to spend at O while separately displaying records-current-through L?
Q4. Historical replay at historical O?
Q5. Retrospective view using current knowledge?
```

### Gate B: ownership

Name who chooses each required value.

Example possibility only:

```text
report/query boundary owns O
journal recency computation owns L
cycle resolver owns C
Outlook owns horizon H
```

### Gate C: entry feasibility

Investigate how explicit O could enter current architecture without reusing mixed `ctx.as_of` and without recreating the old giant `BuildAt` record.

### Gate D: current consumer proof

When exhaustive repository search is available, prove current consumers of:

```text
actual_snapshot.Build
actual_snapshot.BuildAt
```

outside the already-inspected canonical surfaces.

### Gate E: one protected property

Choose one property for the first runtime slice.

Do not bundle:

```text
observation consistency
period containment
historical stability
cross-domain independence
reproducibility
```

## 24. Relationship to the PR #88 foundation

Keep the PR #88 foundation.

Its future-facing principles remain useful:

```text
different temporal meanings keep different names
new meanings are added sideways
old meanings are not silently redefined
only proven-equivalent meanings are unified
no universal TemporalFrame
ownership before implementation
```

This correction supersedes only the weaker historical boundary created by lack of access to the legacy repository.

Read the pair as:

```text
TEMPORAL_HISTORY_AND_FUTURE_FOUNDATION-2026-07-07.md
  -> broad foundation and future decision space

TEMPORAL_LEGACY_EVIDENCE_CORRECTION-2026-07-07.md
  -> stronger legacy-backed historical correction
```

## 25. Current working conclusion

The strongest current explanation is no longer:

```text
Maybe local L appeared somewhere before public history and later drifted.
```

It is closer to:

```text
Old engine had explicit O and separate L.

Early src_next context had no O boundary.

Outlook and Daily Trend were introduced with local L occupying the report-reference-date role.

Migration documents explicitly recognized the resulting as_of difference.

Later parity checks validated calculations by feeding src_next's selected L into the old engine's explicit O input.

A hard-cutoff BuildAt mechanism was added later, but callers retained local-L policy.

Production adoption followed shortly, then the old engine was removed.
```

This does not by itself choose a fix.

It gives a much firmer foundation for choosing one.

The next runtime decision should therefore be made with all four layers visible:

```text
household question
legacy semantics
current characterized behavior
future extension space
```

That is the corrected historical foundation.
