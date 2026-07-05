# Config Effective Resolution Entry Checkpoint

Status: A4 checkpoint / docs-only / no runtime authorization
Date: 2026-07-05
Parent plan: `CONFIG_RESOLUTION_SEMANTICS_PLAN-2026-07-05.md`
Key classification: `CONFIG_KEY_CLASSIFICATION_DECISION-2026-07-05.md`
Typed-policy checkpoint: `CONFIG_TYPED_POLICY_CHECKPOINT-2026-07-05.md`
Income-cadence decision: `POLICY_INCOME_CADENCE_OWNERSHIP_DECISION-2026-07-05.md`
Classification item: A4 Partial `config.tsv` semantics

## Purpose

Re-align the A4 plan with the repository state after PR #52 and decide the next architectural checkpoint before any further runtime slice.

A4 began as a plan to make partial `config.tsv` semantics explicit. Since then the repository has accumulated:

- dedicated config characterization tests,
- key classification,
- missing versus explicit-empty evidence,
- presence-aware lookup,
- two typed `defaultable` policy accessors,
- a typed-policy checkpoint,
- a focused optional-key ownership investigation,
- and an ownership decision that freezes runtime work on `POLICY_INCOME_CADENCE`.

The original plan and the executed sequence are now slightly out of alignment. This checkpoint records the actual state and narrows the next candidate boundary.

Important:

- this document does not authorize runtime behavior changes,
- this document does not authorize a broad config merge,
- this document does not authorize a generic config framework,
- this document does not authorize fixture cleanup,
- this document does not authorize live-config edits or migration,
- the next executable runtime slice still requires explicit approval.

## Executive decision

A4 keeps **typed sparse override** as its target direction.

The next architectural question is no longer:

```text
Which individual key should receive another one-off accessor rule?
```

It is:

```text
Can A4 enter a minimal effective-application-config resolution boundary
without broad merge semantics, generic framework work, or ownership drift?
```

Current decision:

1. keep typed sparse override as the A4 target,
2. freeze runtime work on `POLICY_INCOME_CADENCE`,
3. do not add another one-off typed accessor merely to continue key-by-key expansion,
4. keep generic enum/default helper abstraction deferred,
5. reopen effective application-config ownership as the next architectural boundary,
6. preserve current `Get` and `Lookup` compatibility unless a separate approved slice changes them,
7. keep UI ownership, `BUDGET_*`, and `HOUSEHOLD_GROUP_ORDER` outside the next slice.

## Evidence sequence through PR #52

### PR #41: current resolution semantics characterized

Established that current BQN file selection is replacement, not merge:

```text
local config exists
  -> read local config

local config absent
  -> read config/default_config.tsv
```

Also recorded that accessor-level fallback is distinct from file-level replacement.

### PR #42: key classes and quarantine states decided

Runtime classes:

- `defaultable`
- `optional`
- `ui-only`
- `required-explicit`

Quarantine states:

- `derived-candidate`
- `legacy-contract-review`

Important result:

> Current `Required` accessor shape does not prove future `required-explicit` semantics.

No current application key was approved into `required-explicit`.

### PR #43: missing versus explicit empty characterized

Raw parsed config preserves:

```text
missing         -> key absent
explicit empty  -> key present with ""
```

while current `Get` collapses both to `""`.

### PR #45: current required-key failure characterized

Recorded subprocess failure behavior for missing and explicit-empty household group accessors before changing semantics.

### PR #46: presence-aware lookup added

Added:

```text
Lookup key -> ⟨found, value⟩
```

with observable states:

```text
missing         -> ⟨0, ""⟩
explicit empty  -> ⟨1, ""⟩
explicit value  -> ⟨1, value⟩
```

Existing `Get` compatibility remained unchanged.

### PR #47: first typed `defaultable` policy key

`POLICY_BUDGET_STYLE` adopted:

```text
missing         -> documented default `envelope`
explicit empty  -> fail closed
explicit value  -> validate existing enum
```

### PR #48: second typed `defaultable` policy key

`POLICY_RISK_STYLE` adopted:

```text
missing         -> documented default `conservative`
explicit empty  -> fail closed
explicit value  -> validate existing enum
```

### PR #49: typed-policy checkpoint

Decided:

- do not introduce a shared enum/default resolver yet,
- do not globally standardize validation timing yet,
- treat non-zero exit as the minimum fail-closed negative contract,
- investigate a different runtime class before copying the same pattern again.

### PR #50: `POLICY_INCOME_CADENCE` ownership investigation

Found historical policy intent and explicit values, but no established behavioral owner in inspected major canonical surfaces.

### PR #51: temporary CI observation lab

Used a temporary harness to gather exact-reference and differential-output evidence.

The harness was intentionally not merged as a permanent contract.

### PR #52: `POLICY_INCOME_CADENCE` ownership decision

Classified the key as:

```text
B — dormant future policy key
```

Evidence included:

- exact `src_next` references only in `src_next/config.bqn` for the checked terms,
- a constant-path four-state experiment,
- identical output across 11 stable observed surfaces for:
  - missing,
  - explicit empty,
  - `bimonthly`,
  - `monthly`,
- exclusion of non-repeatable surfaces from causality evidence.

Consequence:

> Stop runtime optional-semantics work on this key until a behavioral or metadata owner is approved.

## A4 phase alignment after PR #52

The original plan proposed:

```text
Phase 0  contract-only decision
Phase 1  dedicated config verification
Phase 2  effective application config resolution
Phase 3  fixture simplification
Phase 4  UI preference ownership review
```

The actual repository sequence is now:

```text
Phase 0
  substantially complete

Phase 1
  substantially complete for the inspected first-slice semantics

Phase 2
  partially entered through two narrow per-key typed accessor changes
  central effective application-config resolution not implemented

Phase 3
  not started
  correctly deferred

Phase 4
  not started
  correctly deferred
```

This checkpoint treats the two typed accessors as approved narrow evidence slices, not as proof that Phase 2 is complete.

## Current runtime shape

Current `src_next/config.bqn` still selects one file:

```text
<base>/config.tsv exists
  yes -> local file
  no  -> config/default_config.tsv
```

It does not currently construct:

```text
default_config.tsv
        +
local overrides
        =
effective application config
```

At the same time, two accessors now implement typed missing behavior individually.

Conceptually, current behavior is closer to:

```text
selected config file
        |
        v
    LoadConfig
        |
   +----+------------------+
   |                       |
   v                       v
Get / Required       typed accessors
legacy behavior      key-local fallback
```

This was a safe incremental path.

It also means the original A4 root problem remains partially open:

> application config meaning is still distributed across file selection and per-key accessor behavior.

## Current key map

### Typed `defaultable` keys

```text
POLICY_BUDGET_STYLE
POLICY_RISK_STYLE
```

State:

- typed missing semantics implemented,
- explicit empty fails closed,
- explicit values validated,
- no generic helper abstraction authorized.

### Remaining approved `defaultable` keys

```text
HOUSEHOLD_GROUP_LIFE
HOUSEHOLD_GROUP_RESERVE
```

Current state:

- classification says `defaultable`,
- runtime accessors still use `Required`,
- no per-key typed migration is authorized by this checkpoint.

### Optional key with clear capability shape

```text
EXECUTION_PLANNED_PAYMENTS_ENVELOPE
```

Current state:

- classification says `optional`,
- runtime accessor still uses `Get`,
- no new typed optional contract is authorized here.

### Dormant future policy key

```text
POLICY_INCOME_CADENCE
```

Current state:

- historical intent exists,
- explicit values exist,
- behavioral ownership not established,
- runtime semantics work frozen.

### Quarantined derived candidate

```text
HOUSEHOLD_GROUP_ORDER
```

Current state:

- do not promote into effective resolution before ownership review.

### Quarantined legacy-contract keys

```text
BUDGET_PREFIX
BUDGET_ID_OPENING
BUDGET_ID_UNASSIGNED
BUDGET_ID_SPENT
```

Current state:

- do not clean up,
- do not newly default,
- do not newly require,
- do not merge into the next slice.

### UI-only keys

Examples:

```text
THEME
FZF_PREVIEW_WINDOW
```

Current state:

- keep UI ownership review separate,
- application config resolution must not accidentally claim accounting meaning for these keys.

## Decision 1: keep typed sparse override as the A4 target

The evidence accumulated so far does not invalidate the original target.

Current target remains:

```text
documented application defaults
        +
ledger-local overrides
        +
approved key-class semantics
        =
effective application config
```

However, this checkpoint rejects a broad immediate implementation.

The next candidate must be smaller than:

```text
merge every config key globally
```

and more meaningful than:

```text
add another independent accessor fallback
```

## Decision 2: freeze `POLICY_INCOME_CADENCE` runtime work

The key must not be used as the next optional-semantics implementation slice.

Do not currently implement:

```text
missing        -> absent
explicit empty -> disabled
```

or another typed pair merely because the key was previously classified `optional`.

Reason:

> absent and disabled have no durable runtime meaning until ownership exists.

A later separate decision may classify the key as:

- dormant policy vocabulary,
- profile metadata,
- deprecated residue,
- or an active policy key with a real consumer.

This checkpoint chooses none of those future redesigns.

## Decision 3: do not continue by one-off accessor count

A4 should not measure progress by the number of typed accessors.

Therefore the next step is not automatically:

```text
type a third policy key
```

or:

```text
copy fallback logic into each remaining defaultable accessor
```

Per-key changes remain possible later when a key-specific contract requires them.

They are not the preferred next architectural checkpoint.

## Decision 4: keep generic helper abstraction deferred

PR #49 remains valid.

Do not yet introduce a generic helper such as:

```text
ResolveEnumWithDefault
ResolveTypedKey
ConfigSchemaFramework
```

merely because two accessors share code shape.

Reason:

- only two current runtime keys demonstrate the repeated defaultable enum pattern,
- BQN abstraction behavior must be verified rather than assumed,
- helper abstraction and effective-config ownership are separate decisions.

## Decision 5: reopen effective-config ownership as the next boundary

Deferring a generic helper does not mean deferring the architectural ownership question forever.

These are different questions:

```text
Question A
  Should repeated enum/default code use one generic helper?

Question B
  Where is effective application config resolved?
```

Current answers:

```text
A -> still deferred
B -> eligible for the next focused design/execution decision
```

The next candidate should therefore test whether BQN can own a minimal effective application-config boundary without turning A4 into a broad framework rewrite.

## Preferred next executable candidate

Preferred shape:

> Prove one minimal effective-default resolution path for approved `defaultable` application keys while preserving current compatibility boundaries.

Conceptual example only:

```text
config/default_config.tsv
  HOUSEHOLD_GROUP_LIFE=daily,flex
  HOUSEHOLD_GROUP_RESERVE=reserve
  POLICY_BUDGET_STYLE=envelope

<base>/config.tsv
  POLICY_BUDGET_STYLE=none
```

Candidate effective result:

```text
HOUSEHOLD_GROUP_LIFE=daily,flex
HOUSEHOLD_GROUP_RESERVE=reserve
POLICY_BUDGET_STYLE=none
```

This example is not runtime authorization.

It illustrates the question to prove:

> Can an approved local override remain sparse while approved repository-owned defaults remain effective?

## Required design constraints for the next candidate

Any proposed runtime slice must state all of the following before implementation.

### 1. Exact key scope

The slice must name the keys it resolves.

No implicit all-key merge.

### 2. Raw compatibility boundary

State whether:

- `Get` remains raw selected-file lookup,
- `Lookup` remains raw presence-aware lookup,
- a separate effective lookup is introduced,
- or existing APIs change.

This checkpoint prefers preserving current raw compatibility unless a separate reason justifies change.

### 3. Explicit-empty behavior

For every included key:

```text
missing
explicit empty
explicit value
```

must remain distinguishable where the contract requires it.

### 4. Duplicate-key boundary

The original A4 plan calls for explicit duplicate behavior.

The next slice must not accidentally claim duplicate-key safety unless tested.

If duplicate handling is out of scope, say so explicitly.

### 5. Unknown-key boundary

Do not introduce global unknown-key errors while application and UI keys share the file.

Extra UI-owned keys must not break the application resolver merely by existing.

### 6. Full-ish config compatibility

Existing full-ish public and external live configs must remain usable without forced migration.

No automatic rewrite.

### 7. No fixture mass cleanup

Do not simplify fixtures in the same runtime PR if that obscures behavioral review.

### 8. BQN-only path remains valid

The canonical BQN report path must remain usable.

No new shell dependency for application config meaning.

## What is explicitly not next

Do not bundle:

- global config merge,
- generic config framework,
- global eager validation,
- global lazy validation,
- global unknown-key errors,
- UI config split,
- namespace redesign,
- `HOUSEHOLD_GROUP_ORDER` redesign,
- `BUDGET_*` cleanup or migration,
- `POLICY_INCOME_CADENCE` consumer implementation,
- profile inference,
- live config rewrite,
- source TSV mutation,
- fixture mass cleanup.

## Verification expectations for a future runtime slice

At minimum, the approved slice should define focused checks for:

```text
no-local-config behavior
full-ish local config compatibility
one sparse override case
missing versus explicit empty for included typed keys
invalid explicit value failure where applicable
extra UI-owned key tolerance
BQN-only canonical path
full tools/check.sh
```

Additional indirect household, envelope, or outlook checks should be chosen according to the exact key scope.

## A4 state after this checkpoint

Established:

```text
current file replacement semantics          characterized
key classes                                decided
missing vs explicit empty                  characterized
presence-aware Lookup                      implemented
two defaultable policy keys                typed
shared enum/default helper                 deferred
global validation timing                   deferred
minimum negative contract                  non-zero exit
POLICY_INCOME_CADENCE ownership             dormant future policy
income-cadence runtime semantics            frozen
effective application config overlay        not implemented
duplicate-key runtime contract               not implemented
global unknown-key policy                    deferred
UI ownership                                 deferred
HOUSEHOLD_GROUP_ORDER                        quarantined
BUDGET_*                                     quarantined
```

## Recommended next step

```text
A4 checkpoint complete
  ->
write one narrow effective-config entry proposal
  ->
name exact included keys and raw/effective API boundary
  ->
add focused tests before or with the minimal behavior slice
  ->
only implement after explicit approval
```

Preferred next question:

> What is the smallest BQN-owned effective-config slice that proves typed sparse override without becoming a global merge framework?

A4 remains open.
