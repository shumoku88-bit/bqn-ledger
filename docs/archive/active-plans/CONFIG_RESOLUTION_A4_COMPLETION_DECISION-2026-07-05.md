# Config Resolution A4 Completion Decision

Status: A4 completion decision / docs-only
Date: 2026-07-05
Parent plan: `CONFIG_RESOLUTION_SEMANTICS_PLAN-2026-07-05.md`
Runtime checkpoint: `CONFIG_EFFECTIVE_RESOLUTION_RUNTIME_CHECKPOINT-2026-07-05.md`
Classification item: A4 Partial `config.tsv` semantics

## Decision

```text
A4 complete enough for now
```

A4 is closed as an active workstream.

This does not mean every possible config problem is solved.

It means the original A4 problem has been reduced far enough that remaining concerns should no longer continue under automatic A4 momentum.

Any future config work must re-enter as a newly selected concrete problem.

## Why A4 can close

A4 now has evidence and runtime proof for the main semantic gaps that motivated the work.

### File-selection behavior is characterized

Current behavior was captured before redesign:

- no local config can fall back to repository defaults,
- a present local config replaces the default file at raw file-selection level,
- partial local config is not a hidden full-file merge,
- accessor-level fallback is distinct from file replacement.

### Missing and explicit empty are distinguishable

Presence-aware raw lookup now preserves:

```text
missing         -> ⟨0, ""⟩
explicit empty  -> ⟨1, ""⟩
explicit value  -> ⟨1, value⟩
```

Existing raw `Get` compatibility remains:

```text
missing         -> ""
explicit empty  -> ""
```

This means raw observation can distinguish states when needed without breaking existing callers.

### Two defaultable policy keys have typed behavior

A4 established explicit missing, empty, and invalid-value behavior for:

```text
POLICY_BUDGET_STYLE
POLICY_RISK_STYLE
```

This proved typed accessor semantics without requiring a global resolver framework.

### Dormant policy ownership was investigated instead of guessed

`POLICY_INCOME_CADENCE` was not forced into runtime semantics.

Evidence led to the decision:

```text
dormant future policy key
runtime work frozen
```

This is an A4 success: absence of current meaning was recorded rather than invented.

### The first effective sparse override is implemented

Merged PR #55 proved effective resolution for exactly:

```text
HOUSEHOLD_GROUP_LIFE
HOUSEHOLD_GROUP_RESERVE
```

Semantics:

```text
local non-empty value -> local value
local explicit empty  -> fail closed
local missing         -> repository default
```

Sparse inheritance is tested in both directions.

### Raw and effective meaning are now separate

The current runtime has a real boundary between:

```text
raw Lookup / Get
```

and:

```text
effective application accessors
```

A raw key may remain missing while an approved effective accessor resolves a repository-owned default.

That separation was one of the important architectural goals of the A4 work.

### Ambiguous keys are quarantined instead of normalized by accident

A4 does not pretend that all keys share one semantic class.

Current quarantine remains:

```text
HOUSEHOLD_GROUP_ORDER -> derived-candidate
BUDGET_*              -> legacy-contract-review
```

Those keys are not pulled into effective resolution merely because a mechanism now exists.

## What completion means

After this decision:

```text
A4 is not a standing queue of config keys.
```

Do not continue with:

```text
pick another key
migrate it
pick another key
migrate it
```

The existence of `EffectiveDefaultable` is not authorization to expand it.

A future change must start from a concrete problem.

## Remaining concerns are split out

The following remain real concerns, but they are no longer blockers for A4 completion.

### Duplicate-key contract

Status:

```text
future independent work
```

Questions still include source scope, error timing, and compatibility.

Do not reopen A4 merely to add duplicate detection.

### Unknown-key policy

Status:

```text
deferred independent ownership question
```

Shared config still spans multiple ownership domains, including UI rows.

No global unknown-key rejection is implied by A4 completion.

### Eager repository-default loading

Status:

```text
observe
```

Current value resolution is local-first, while repository defaults are read eagerly during config construction.

This remains a non-blocking observation.

Revisit only with concrete failure, portability pressure, compatibility impact, or clear design benefit.

### UI ownership review

Status:

```text
future independent work
```

A physical or semantic UI split is not required to close A4.

### HOUSEHOLD_GROUP_ORDER

Status:

```text
derived-candidate
```

No redesign is authorized by this completion decision.

### BUDGET_* keys

Status:

```text
legacy-contract-review
```

No cleanup or migration is authorized here.

### Optional-key semantics

Status:

```text
future concrete-case work only
```

Do not resume optional-key work by default.

`POLICY_INCOME_CADENCE` remains frozen.

## A4 completion record

```text
file replacement semantics             characterized
raw missing vs explicit empty          characterized
presence-aware raw Lookup              implemented
raw Get compatibility                  preserved
required-key failure                   characterized
typed POLICY_BUDGET_STYLE              implemented
typed POLICY_RISK_STYLE                implemented
POLICY_INCOME_CADENCE                  dormant; runtime frozen
minimal effective sparse override      implemented
runtime proof keys                     LIFE / RESERVE
raw/effective semantic separation      implemented for first slice
global merged config table             intentionally not implemented
generic resolver/schema framework      intentionally not implemented
HOUSEHOLD_GROUP_ORDER                  quarantined
BUDGET_*                               quarantined
duplicate-key contract                 future independent work
unknown-key policy                     future independent work
UI ownership review                    future independent work
eager default-source loading           observe
```

## Reopening rule

A4 itself should not be reopened casually.

A future config task should be promoted separately and must name:

1. the concrete problem,
2. the affected key or source boundary,
3. the current consumer,
4. the observed failure or limitation,
5. why current raw/effective behavior is insufficient,
6. compatibility constraints,
7. focused tests,
8. explicit out-of-scope boundaries.

If a future task grows into a broader config-semantics program, that should receive a new workstream identity rather than silently reviving A4.

## TODO alignment

`TODO.md` remains the preferred source for selecting current work.

A4 should not be treated as active merely because its planning and decision documents remain in the archive staging area.

After merge of this completion decision:

```text
choose work from current TODO priorities
```

or:

```text
promote one newly observed concrete config problem as separate work
```

## Boundary

This decision authorizes no runtime change.

Do not bundle:

- third-key migration,
- global config merge,
- global effective table,
- generic schema framework,
- duplicate detection,
- unknown-key rejection,
- UI split,
- ORDER redesign,
- BUDGET cleanup,
- income-cadence work,
- optional-key migration,
- fixture mass cleanup,
- live config rewrite,
- source TSV mutation.

## Final decision

```text
A4 complete enough for now
```

The workstream is closed.

Remaining config concerns survive as independent future questions, not as unfinished A4 obligations.
