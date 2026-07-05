# Config Minimal Effective Defaultable Slice Proposal

Status: A4 docs-only proposal / no runtime authorization
Date: 2026-07-05
Parent checkpoint: `CONFIG_EFFECTIVE_RESOLUTION_ENTRY_CHECKPOINT-2026-07-05.md`
Key classification: `CONFIG_KEY_CLASSIFICATION_DECISION-2026-07-05.md`
Classification item: A4 Partial `config.tsv` semantics

## Purpose

Define the smallest BQN-owned runtime candidate that can prove typed sparse override semantics without introducing a global config merge or generic config framework.

This proposal narrows the candidate to exactly two keys:

```text
HOUSEHOLD_GROUP_LIFE
HOUSEHOLD_GROUP_RESERVE
```

No runtime change is authorized by this document.

## Why these two keys

They are a useful first effective-resolution slice because all of the following are already established:

1. both are classified `defaultable`,
2. both have repository-owned defaults in `config/default_config.tsv`,
3. both still use current `Required` accessors,
4. both have real application consumers,
5. neither introduces enum-helper abstraction pressure,
6. neither is quarantined,
7. neither is UI-only.

Current repository defaults are:

```text
HOUSEHOLD_GROUP_LIFE=daily,flex
HOUSEHOLD_GROUP_RESERVE=reserve
```

Current accessors still behave conceptually as:

```text
HouseholdGroupLifeLabels
  -> Required HOUSEHOLD_GROUP_LIFE

HouseholdGroupReserveLabels
  -> Required HOUSEHOLD_GROUP_RESERVE
```

This creates a clean test of the A4 target:

> a sparse local config can override one approved value while inheriting another approved repository-owned default.

## Proposed exact scope

Included:

```text
HOUSEHOLD_GROUP_LIFE
HOUSEHOLD_GROUP_RESERVE
```

Excluded:

```text
HOUSEHOLD_GROUP_ORDER
POLICY_BUDGET_STYLE
POLICY_RISK_STYLE
POLICY_INCOME_CADENCE
EXECUTION_PLANNED_PAYMENTS_ENVELOPE
BUDGET_*
UI-only keys
all unknown keys
```

The exclusion is intentional.

This slice is not a six-key resolver, not a global application-config merge, and not a schema framework.

## Proposed ownership

BQN owns effective application meaning for the two approved keys.

The shell layer does not participate in resolving them.

The BQN-only canonical path must remain valid.

## Proposed raw/effective boundary

Keep current raw APIs compatible:

```text
Path
LoadConfig
Lookup
Get
Required
```

In particular:

- `Lookup` remains presence-aware lookup over the currently loaded raw config,
- `Get` keeps current missing-to-empty compatibility,
- `Required` keeps current behavior for consumers not migrated by this slice,
- `Path` keeps current file-selection behavior,
- `LoadConfig` is not redefined into a merged effective table.

Add a separate effective-resolution boundary for the two approved keys.

Conceptual name only:

```text
EffectiveDefaultable
```

The final BQN function name is not decided by this document.

## Do not build a merged config table

This proposal prefers source-preserving resolution:

```text
repository default source
        +
local source when present
        |
        v
resolve only an approved key
```

It does not propose:

```text
merge every default row
        +
merge every local row
        =
one global effective config table
```

Reason:

- a global table would pull UI and quarantined keys into the same ownership boundary,
- duplicate and unknown-key policy are not ready globally,
- the first proof only needs two `defaultable` keys,
- source-preserving lookup keeps the experiment narrow and reviewable.

## Proposed resolution rule

For each included key:

```text
local key present with non-empty value
  -> use local value

local key present with explicit empty value
  -> ERROR

local key missing
  -> use repository default

repository default missing
  -> ERROR

repository default explicit empty
  -> ERROR
```

This is the `defaultable` class contract already chosen by A4, specialized to the exact two-key scope.

## Resolution truth table

| Local state | Repository default state | Proposed result |
|---|---|---|
| missing | non-empty | use repository default |
| non-empty | non-empty | use local value |
| explicit empty | non-empty | ERROR |
| missing | missing | ERROR |
| missing | explicit empty | ERROR |
| non-empty | missing | use local value |
| non-empty | explicit empty | use local value |

The last two rows matter:

> an explicit valid local override does not require consulting a fallback value that will not be used.

This avoids turning repository-default validation into unrelated eager global validation.

## Proposed data-source shape

The candidate runtime slice may need an internal distinction that current `Path` and `LoadConfig` do not expose directly:

```text
repository default source
local source if it exists
```

Current `Path` chooses one file and falls back to the repository default when no local file exists.

This proposal does not change that raw contract.

Instead, a future runtime slice should introduce the smallest internal source boundary needed to resolve the two approved keys.

Conceptually:

```text
LoadRawConfig
  current compatibility path

LoadRepositoryDefaults
  repository default source

LoadLocalOverridesIfPresent
  local source only
```

These names are illustrative, not authorized API names.

The implementation may choose a smaller shape if it preserves the same contract.

## Proposed consumer cut

Only these accessors are candidates to consume effective resolution:

```text
HouseholdGroupLifeLabels
HouseholdGroupReserveLabels
```

Conceptually:

```text
HouseholdGroupLifeLabels
  -> CsvList (effective value for HOUSEHOLD_GROUP_LIFE)

HouseholdGroupReserveLabels
  -> CsvList (effective value for HOUSEHOLD_GROUP_RESERVE)
```

Do not change:

```text
HouseholdGroupOrderLabels
```

It remains outside this slice because `HOUSEHOLD_GROUP_ORDER` is a `derived-candidate`.

## Sparse override proof case

Repository defaults:

```text
HOUSEHOLD_GROUP_LIFE=daily,flex
HOUSEHOLD_GROUP_RESERVE=reserve
```

Sparse local config:

```text
HOUSEHOLD_GROUP_LIFE=daily,flex,weekly
```

Expected effective values:

```text
HOUSEHOLD_GROUP_LIFE=daily,flex,weekly
HOUSEHOLD_GROUP_RESERVE=reserve
```

This is the central proof case.

It demonstrates:

```text
one local override
        +
one inherited approved default
        =
typed sparse override
```

without constructing a global merged config.

## Required focused tests before or with runtime change

### 1. No local config

Expected:

```text
LIFE    -> daily,flex
RESERVE -> reserve
```

### 2. Sparse local override of LIFE

Local:

```text
HOUSEHOLD_GROUP_LIFE=daily,flex,weekly
```

Expected:

```text
LIFE    -> daily,flex,weekly
RESERVE -> reserve
```

### 3. Sparse local override of RESERVE

Local:

```text
HOUSEHOLD_GROUP_RESERVE=reserve,longterm
```

Expected:

```text
LIFE    -> daily,flex
RESERVE -> reserve,longterm
```

### 4. Explicit empty LIFE

Local:

```text
HOUSEHOLD_GROUP_LIFE=
```

Expected:

```text
non-zero exit
```

### 5. Explicit empty RESERVE

Local:

```text
HOUSEHOLD_GROUP_RESERVE=
```

Expected:

```text
non-zero exit
```

### 6. Full-ish local config compatibility

A full-ish local config with both values explicit remains valid.

No migration or rewrite is required.

### 7. Extra UI-owned key tolerance

Example local row:

```text
THEME=...
```

must not fail merely because the effective application boundary does not own it.

### 8. Raw compatibility

Existing `Lookup` and `Get` characterization remains valid.

The effective slice must not silently change their meaning.

### 9. Canonical BQN path

The BQN-only canonical report path remains valid.

### 10. Full repository checks

```text
tools/check.sh
```

must pass.

## Duplicate-key boundary

Duplicate-key semantics are not changed by this proposed slice.

This proposal does not claim duplicate safety.

The broader A4 decision still prefers visible duplicate failure in a future tested resolver path, but bundling that behavior here would mix two independent questions:

```text
Can sparse default inheritance work?
```

and:

```text
How should duplicate rows fail?
```

Keep them separate unless implementation evidence shows they cannot be separated safely.

## Unknown-key boundary

No global unknown-key validation.

For this slice:

```text
approved LIFE key       -> resolve
approved RESERVE key    -> resolve
other key               -> outside this boundary
```

Extra keys are not automatically errors.

## Validation timing

Do not use this slice to standardize all config validation as eager or lazy.

For the two included accessors, validate the value needed to produce the effective result.

Do not validate unrelated quarantined, optional, policy, or UI keys as a side effect.

## Compatibility boundary

Preserve:

- full-ish public config compatibility,
- external live config compatibility without rewrite,
- no automatic config editing,
- no source TSV mutation,
- current raw `Get` and `Lookup` meaning,
- extra UI-owned rows in shared config,
- BQN-only canonical execution.

## Explicitly not authorized

- runtime implementation,
- global config merge,
- global effective config table,
- generic schema framework,
- generic enum/default helper,
- global validation timing decision,
- duplicate-key behavior change,
- global unknown-key errors,
- `HOUSEHOLD_GROUP_ORDER` redesign,
- `BUDGET_*` cleanup or migration,
- `POLICY_INCOME_CADENCE` work,
- optional-key redesign,
- UI config split,
- fixture mass cleanup,
- live config rewrite,
- source TSV mutation.

## Proposed runtime slice after approval

If this proposal is approved, the next runtime PR should be limited to:

1. focused tests for the two-key truth table and compatibility boundary,
2. the minimum BQN source distinction needed to consult repository defaults and local overrides separately,
3. a narrow effective-resolution function or equivalent internal boundary,
4. migration of only `HouseholdGroupLifeLabels` and `HouseholdGroupReserveLabels` to that boundary,
5. full checks.

No third key should be added merely because the mechanism can resolve it.

## Acceptance criteria for the later runtime slice

The slice is successful only if all are true:

```text
sparse LIFE override inherits RESERVE default
sparse RESERVE override inherits LIFE default
explicit empty LIFE fails closed
explicit empty RESERVE fails closed
full-ish local config remains valid
extra UI rows remain tolerated
raw Get semantics remain unchanged
raw Lookup semantics remain unchanged
HOUSEHOLD_GROUP_ORDER remains outside scope
BUDGET_* remains outside scope
POLICY_INCOME_CADENCE remains frozen
BQN-only canonical path remains valid
full checks pass
```

## Recommendation

Approve this as the first effective-resolution runtime candidate:

```text
exact keys
  HOUSEHOLD_GROUP_LIFE
  HOUSEHOLD_GROUP_RESERVE

ownership
  BQN

resolution
  local non-empty value wins
  local explicit empty fails
  local missing inherits repository default

architecture
  preserve raw APIs
  preserve source distinction
  no global merged table
```

A4 remains open.
