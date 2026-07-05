# Config Effective Resolution Entry Checkpoint

Status: A4 checkpoint / docs-only / no runtime authorization
Date: 2026-07-05
Parent plan: `CONFIG_RESOLUTION_SEMANTICS_PLAN-2026-07-05.md`
Typed-policy checkpoint: `CONFIG_TYPED_POLICY_CHECKPOINT-2026-07-05.md`
Income-cadence decision: `POLICY_INCOME_CADENCE_OWNERSHIP_DECISION-2026-07-05.md`
Classification item: A4 Partial `config.tsv` semantics

## Purpose

Re-align A4 with the repository state after PR #52 and choose the next architectural checkpoint before further runtime work.

Important:

- no runtime behavior change is authorized,
- no broad config merge is authorized,
- no generic config framework is authorized,
- no fixture cleanup is authorized,
- no live-config edit or migration is authorized,
- the next runtime slice still requires explicit approval.

## Executive decision

A4 keeps **typed sparse override** as its target.

The next question is no longer:

```text
Which individual key should receive another one-off accessor rule?
```

It is:

```text
Can A4 enter a minimal effective-application-config resolution boundary
without broad merge semantics, generic framework work, or ownership drift?
```

Decisions:

1. keep typed sparse override as the A4 target,
2. freeze runtime work on `POLICY_INCOME_CADENCE`,
3. do not continue merely by adding another one-off typed accessor,
4. keep generic enum/default helper abstraction deferred,
5. reopen effective application-config ownership as the next architectural boundary,
6. preserve current `Get` and `Lookup` compatibility unless separately approved,
7. keep UI ownership, `BUDGET_*`, and `HOUSEHOLD_GROUP_ORDER` outside the next slice.

## Evidence through PR #52

- PR #41 characterized file-level replacement versus accessor-level fallback.
- PR #42 adopted `defaultable`, `optional`, `ui-only`, and `required-explicit`, plus quarantine states `derived-candidate` and `legacy-contract-review`.
- PR #43 proved raw missing and explicit empty are distinct while `Get` collapses both to `""`.
- PR #45 characterized current required-key failure.
- PR #46 added presence-aware `Lookup`:

```text
missing         -> ⟨0, ""⟩
explicit empty  -> ⟨1, ""⟩
explicit value  -> ⟨1, value⟩
```

- PRs #47 and #48 typed two `defaultable` policy keys:

```text
POLICY_BUDGET_STYLE
  missing         -> envelope
  explicit empty  -> fail closed
  explicit value  -> validate enum

POLICY_RISK_STYLE
  missing         -> conservative
  explicit empty  -> fail closed
  explicit value  -> validate enum
```

- PR #49 deferred shared enum/default abstraction and global validation-timing standardization.
- PRs #50 to #52 investigated `POLICY_INCOME_CADENCE`, used a temporary CI observation lab, and classified the key as:

```text
B — dormant future policy key
```

The four-state experiment found identical output on 11 stable observed surfaces for missing, explicit empty, `bimonthly`, and `monthly`. Non-repeatable surfaces were excluded from causality evidence.

Consequence:

> Stop runtime optional-semantics work on this key until a behavioral or metadata owner is approved.

## A4 phase alignment

Original plan:

```text
Phase 0  contract-only decision
Phase 1  dedicated config verification
Phase 2  effective application config resolution
Phase 3  fixture simplification
Phase 4  UI preference ownership review
```

Actual state after PR #52:

```text
Phase 0  substantially complete
Phase 1  substantially complete for inspected first-slice semantics
Phase 2  partially entered through two narrow typed accessor changes
         central effective application-config resolution not implemented
Phase 3  not started; correctly deferred
Phase 4  not started; correctly deferred
```

The two typed accessors are narrow evidence slices. They do not mean Phase 2 is complete.

## Current runtime shape

`src_next/config.bqn` still selects one file:

```text
<base>/config.tsv exists
  yes -> local file
  no  -> config/default_config.tsv
```

It does not construct:

```text
default_config.tsv
        +
local overrides
        =
effective application config
```

Meanwhile two accessors implement typed missing behavior individually.

Therefore the original A4 root problem remains partially open:

> application config meaning is still distributed across file selection and per-key accessor behavior.

## Current key map

| Key / group | Current A4 state |
|---|---|
| `POLICY_BUDGET_STYLE` | typed `defaultable` implemented |
| `POLICY_RISK_STYLE` | typed `defaultable` implemented |
| `HOUSEHOLD_GROUP_LIFE` | classified `defaultable`; runtime still `Required` |
| `HOUSEHOLD_GROUP_RESERVE` | classified `defaultable`; runtime still `Required` |
| `EXECUTION_PLANNED_PAYMENTS_ENVELOPE` | classified `optional`; runtime still `Get` |
| `POLICY_INCOME_CADENCE` | dormant future policy; runtime semantics frozen |
| `HOUSEHOLD_GROUP_ORDER` | `derived-candidate`; quarantined |
| `BUDGET_*` | `legacy-contract-review`; quarantined |
| UI-only keys | separate ownership review |

No new per-key migration is authorized here.

## Decision 1: keep typed sparse override

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

The next candidate must be smaller than a global merge and more meaningful than another independent accessor fallback.

## Decision 2: freeze income-cadence runtime work

Do not use `POLICY_INCOME_CADENCE` as the next optional-semantics slice.

Do not currently implement:

```text
missing        -> absent
explicit empty -> disabled
```

Reason:

> absent and disabled have no durable runtime meaning until ownership exists.

A future separate decision may classify the key as profile metadata, deprecated residue, active policy, or another explicit contract.

## Decision 3: do not progress by accessor count

A4 should not measure progress by the number of typed accessors.

The next step is not automatically:

```text
type a third policy key
```

or:

```text
copy fallback logic into each remaining defaultable accessor
```

Per-key changes remain possible when a key-specific contract requires them.

## Decision 4: keep helper abstraction deferred

PR #49 remains valid. Do not yet introduce generic helpers merely because two accessors share code shape.

Helper abstraction and effective-config ownership are separate questions:

```text
A: Should repeated enum/default code use one generic helper?
B: Where is effective application config resolved?
```

Current answers:

```text
A -> still deferred
B -> eligible for the next focused decision
```

## Decision 5: reopen effective-config ownership

The next candidate should test whether BQN can own a minimal effective application-config boundary without becoming a broad framework rewrite.

Preferred shape:

> Prove one minimal effective-default resolution path for approved `defaultable` application keys while preserving compatibility boundaries.

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

This is not runtime authorization. It identifies the property to prove:

> Can an approved local override remain sparse while approved repository-owned defaults remain effective?

## Required boundaries for the next proposal

Before implementation, state:

1. **Exact key scope**: name every included key; no implicit all-key merge.
2. **Raw versus effective API boundary**: state whether `Get`/`Lookup` remain raw, a separate effective lookup is introduced, or an existing API changes.
3. **Missing / empty / value behavior**: define all three where the key contract distinguishes them.
4. **Duplicate-key boundary**: do not claim safety unless tested; say explicitly if out of scope.
5. **Unknown-key boundary**: do not introduce global unknown-key errors while application and UI keys share the file.
6. **Compatibility boundary**: preserve full-ish public and external live configs without forced migration or automatic rewrite.
7. **Review boundary**: do not bundle fixture mass cleanup if it obscures behavior review.
8. **Canonical owner boundary**: keep the BQN-only canonical path valid; no shell dependency for application meaning.

## Explicitly not next

Do not bundle:

- global config merge,
- generic config framework,
- global eager or lazy validation standardization,
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

At minimum, define focused checks for:

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

## A4 state after this checkpoint

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
