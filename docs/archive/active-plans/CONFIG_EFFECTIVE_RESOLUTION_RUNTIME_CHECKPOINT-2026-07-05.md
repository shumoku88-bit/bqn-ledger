# Config Effective Resolution Runtime Checkpoint

Status: A4 runtime checkpoint / docs-only / no new runtime authorization
Date: 2026-07-05
Parent plan: `CONFIG_RESOLUTION_SEMANTICS_PLAN-2026-07-05.md`
Entry checkpoint: `CONFIG_EFFECTIVE_RESOLUTION_ENTRY_CHECKPOINT-2026-07-05.md`
Minimal slice proposal: `CONFIG_MINIMAL_EFFECTIVE_DEFAULTABLE_SLICE_PROPOSAL-2026-07-05.md`
Classification item: A4 Partial `config.tsv` semantics

## Purpose

Record what A4 proved through merged PR #55 and decide how further work may continue.

PR #55 crossed a runtime boundary:

```text
before
  raw file selection
  + raw Lookup/Get
  + per-accessor fallback or Required behavior

after
  raw semantics preserved
  + repository default source kept separate
  + narrow effective resolution for two approved keys
```

No new runtime work is authorized here.

## Executive decision

A4 has proved one minimal BQN-owned typed sparse-override path.

Decisions:

1. record PR #55 as the first successful effective-resolution runtime proof,
2. keep raw `Get` and `Lookup` separate from effective application meaning,
3. keep effective resolution narrow,
4. do not add a third key merely because the mechanism exists,
5. do not turn `LoadConfig` into a global merged config table,
6. keep quarantined and dormant keys outside expansion,
7. keep generic resolver/schema work deferred,
8. observe unconditional repository-default file loading without fixing it now,
9. choose any next A4 runtime slice only from a newly selected concrete problem,
10. do not treat A4 as current TODO work merely because active-plan docs exist.

## Evidence through PR #55

```text
PR #41  characterize file replacement and fallback
PR #42  classify key classes and quarantine states
PR #43  distinguish raw missing from explicit empty
PR #45  characterize required-key failure
PR #46  add presence-aware raw Lookup
PR #47  type POLICY_BUDGET_STYLE
PR #48  type POLICY_RISK_STYLE
PR #49  defer generic abstraction
PR #50  investigate POLICY_INCOME_CADENCE ownership
PR #52  classify income cadence as dormant future policy
PR #53  reopen minimal effective-config ownership
PR #54  approve exact two-key proposal
PR #55  implement and test the first runtime proof
```

## What PR #55 proved

Exact keys:

```text
HOUSEHOLD_GROUP_LIFE
HOUSEHOLD_GROUP_RESERVE
```

Runtime semantics:

```text
local non-empty value -> local value
local explicit empty  -> fail closed
local missing         -> repository default
```

Sparse inheritance is tested in both directions:

```text
LIFE override    -> RESERVE inherits default
RESERVE override -> LIFE inherits default
```

Explicit empty values are tested independently for both keys.

## Raw versus effective boundary

Raw observation remains conceptually:

```text
Lookup
  missing         -> ⟨0, ""⟩
  explicit empty  -> ⟨1, ""⟩
  explicit value  -> ⟨1, value⟩

Get
  missing         -> ""
  explicit empty  -> ""
```

Effective accessors are separate:

```text
HouseholdGroupLifeLabels
  -> effective defaultable resolution

HouseholdGroupReserveLabels
  -> effective defaultable resolution
```

Therefore a raw key may remain missing while an effective accessor returns a repository-owned default.

That distinction is now implemented behavior.

## Current runtime shape

Conceptually:

```text
selected raw source
  -> Lookup / Get

repository default source
  -> internal RepositoryLookup

approved effective accessors
  -> internal EffectiveDefaultable
```

Important:

- the repository lookup is not a public config API,
- the effective helper is not exported as a general resolver API,
- only two accessors consume it,
- `HOUSEHOLD_GROUP_ORDER` still uses current `Required` behavior.

## What PR #55 did not prove

Do not infer:

```text
all defaultable keys should migrate
all optional keys need effective resolution
all config rows should merge
all validation should be eager
all validation should be lazy
duplicate-key behavior is solved
unknown-key behavior is solved
UI ownership is solved
HOUSEHOLD_GROUP_ORDER is solved
BUDGET_* ownership is solved
POLICY_INCOME_CADENCE has runtime meaning
```

## A4 phase alignment

Original plan:

```text
Phase 0  contract-only decision
Phase 1  dedicated config verification
Phase 2  effective application config resolution
Phase 3  fixture simplification
Phase 4  UI preference ownership review
```

Current assessment:

```text
Phase 0  substantially complete
Phase 1  substantially complete for inspected first-slice semantics
Phase 2  minimally proven in runtime for two approved keys
Phase 3  not started; not automatically next
Phase 4  not started; not automatically next
```

A4 should not claim global Phase 2 completion.

It may claim:

> one minimal effective application-config boundary has been implemented and tested.

## Decision 1: stop counting accessors

A4 progress is not measured by remaining-key count.

Do not continue with a third, fourth, and fifth key merely because the mechanism exists.

Expansion requires a separate decision naming:

1. exact key,
2. current consumer,
3. approved key class,
4. missing behavior,
5. explicit-empty behavior,
6. why raw access is insufficient,
7. compatibility effect,
8. focused tests.

## Decision 2: keep generic work deferred

This checkpoint does not authorize:

- schema tables,
- class registries,
- generic enum/default frameworks,
- global resolver objects,
- shared all-key validation passes.

The current helper remains narrow until a concrete new case proves abstraction pressure.

## Decision 3: observe eager repository-default loading

Current runtime reads `config/default_config.tsv` while constructing `LoadConfig`, even when a local non-empty included value will later win.

Observation:

```text
value resolution
  remains local-first

source loading
  currently reads repository defaults eagerly
```

Unused fallback values are not validated when a local non-empty value wins, so the two-key truth table remains intact.

Decision now:

```text
observe
not fix immediately
```

Revisit only with a concrete failure, compatibility issue, portability issue, or clear design benefit.

## Decision 4: unresolved topics stay separate

### Duplicate keys

PR #55 does not solve duplicate semantics.

Do not bundle duplicate detection into unrelated resolver expansion.

### Unknown keys

No global unknown-key errors while shared config contains multiple ownership domains, including UI rows.

### Optional keys

Do not resume optional semantics merely because an effective helper exists.

`POLICY_INCOME_CADENCE` remains dormant with runtime work frozen.

### Quarantine

Do not pull these into effective resolution:

```text
HOUSEHOLD_GROUP_ORDER
BUDGET_PREFIX
BUDGET_ID_OPENING
BUDGET_ID_UNASSIGNED
BUDGET_ID_SPENT
```

Current states remain:

```text
HOUSEHOLD_GROUP_ORDER -> derived-candidate
BUDGET_*              -> legacy-contract-review
```

## TODO alignment

`TODO.md` is the preferred source for choosing active work.

A4 is not currently listed as a `Now` item there.

Therefore:

> Active A4 plan documents do not by themselves authorize another A4 implementation slice.

After this checkpoint, either:

```text
A. pause A4 and choose current TODO work
```

or:

```text
B. promote one concrete A4 problem into a new small TODO/docs decision
```

Do not treat momentum as priority.

## Candidate future A4 questions

These are questions, not approved tasks.

### A. Completion criteria

Is A4 sufficiently resolved for now after:

- raw semantics characterization,
- presence-aware Lookup,
- two typed policy defaults,
- first effective sparse override,
- quarantine of ambiguous keys?

Possible outcome:

```text
A4 complete enough for now
remaining topics split into future work
```

### B. Duplicate-key contract

Only if duplicate ambiguity becomes the highest-value config risk.

### C. Eager default-source loading

Only if concrete pressure appears.

### D. One new exact effective key

Only with approved ownership and a demonstrated consumer problem.

### E. UI ownership review

Only if shared-file ownership causes bugs or blocks stricter validation.

## Recommended next decision

Do not select another runtime key immediately.

Preferred question:

> Is A4 sufficiently resolved for now, or is there one concrete remaining config problem important enough to promote into current work?

## A4 state after this checkpoint

```text
file replacement semantics             characterized
raw missing vs explicit empty          characterized
presence-aware raw Lookup              implemented
raw Get compatibility                  preserved
typed POLICY_BUDGET_STYLE              implemented
typed POLICY_RISK_STYLE                implemented
POLICY_INCOME_CADENCE                  dormant; runtime frozen
minimal effective sparse override      implemented
runtime proof keys                     LIFE / RESERVE
raw/effective semantic separation      implemented for first slice
global merged config table             not implemented
generic resolver/schema framework      not implemented
duplicate-key runtime contract         not implemented
global unknown-key policy              deferred
HOUSEHOLD_GROUP_ORDER                  quarantined
BUDGET_*                               quarantined
UI ownership review                    not started
fixture simplification                 not started
```

## Boundary

This checkpoint authorizes no runtime change.

Do not bundle:

- third-key migration,
- global merge,
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

## Recommendation

Record PR #55 as the successful first runtime proof, then pause automatic A4 expansion.

Any next A4 step should begin from a newly selected concrete problem rather than mechanism reuse.

A4 remains open pending an explicit completion-or-next-problem decision.
