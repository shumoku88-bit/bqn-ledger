# Config Minimal Effective Defaultable Slice Proposal

Status: A4 docs-only proposal / no runtime authorization
Date: 2026-07-05
Parent checkpoint: `CONFIG_EFFECTIVE_RESOLUTION_ENTRY_CHECKPOINT-2026-07-05.md`
Key classification: `CONFIG_KEY_CLASSIFICATION_DECISION-2026-07-05.md`
Classification item: A4 Partial `config.tsv` semantics

## Purpose

Define the smallest BQN-owned runtime candidate that can prove typed sparse override semantics without a global config merge or generic config framework.

Exact scope:

```text
HOUSEHOLD_GROUP_LIFE
HOUSEHOLD_GROUP_RESERVE
```

No runtime change is authorized by this document.

## Why these two keys

Both keys are already:

- classified `defaultable`,
- backed by repository-owned defaults,
- consumed by real application paths,
- still accessed through current `Required` behavior,
- outside quarantine,
- non-UI.

Current defaults:

```text
HOUSEHOLD_GROUP_LIFE=daily,flex
HOUSEHOLD_GROUP_RESERVE=reserve
```

Current accessors conceptually remain:

```text
HouseholdGroupLifeLabels
  -> Required HOUSEHOLD_GROUP_LIFE

HouseholdGroupReserveLabels
  -> Required HOUSEHOLD_GROUP_RESERVE
```

This gives A4 a clean proof target:

> A sparse local config can override one approved value while inheriting another approved repository default.

## Exact scope

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

This is not a six-key resolver, global application-config merge, or schema framework.

## Ownership decision

BQN owns effective application meaning for the two approved keys.

The shell layer does not resolve them.

The BQN-only canonical path must remain valid.

## Raw versus effective boundary

Keep current raw APIs compatible:

```text
Path
LoadConfig
Lookup
Get
Required
```

Therefore:

- `Lookup` remains raw presence-aware lookup,
- `Get` keeps current missing-to-empty compatibility,
- `Required` keeps current behavior for consumers outside this slice,
- `Path` keeps current file-selection behavior,
- `LoadConfig` is not redefined into a merged effective table.

Add a separate narrow effective-resolution boundary for the two approved keys.

Conceptual name only:

```text
EffectiveDefaultable
```

The final BQN function name is not decided here.

## No merged config table

Preferred shape:

```text
repository default source
        +
local source when present
        |
        v
resolve one approved key
```

Rejected first-slice shape:

```text
merge every default row
        +
merge every local row
        =
one global effective config table
```

Reason:

- UI and quarantined keys would enter the same ownership boundary,
- duplicate and unknown-key policy are not ready globally,
- the proof only needs two `defaultable` keys,
- source-preserving resolution is smaller and easier to review.

## Resolution rule

For each included key:

```text
local non-empty value
  -> use local value

local explicit empty
  -> ERROR

local key missing
  -> use repository default

repository default missing
  -> ERROR

repository default explicit empty
  -> ERROR
```

Truth table:

| Local state | Repository default | Result |
|---|---|---|
| missing | non-empty | repository default |
| non-empty | non-empty | local value |
| explicit empty | non-empty | ERROR |
| missing | missing | ERROR |
| missing | explicit empty | ERROR |
| non-empty | missing | local value |
| non-empty | explicit empty | local value |

The last two rows intentionally avoid validating an unused fallback value.

This proposal does not standardize all config validation as eager or lazy.

## Data-source boundary

Current `Path` chooses one file and falls back to the repository default when no local file exists.

That raw contract remains unchanged.

A future runtime slice may introduce the smallest internal source distinction needed to consult:

```text
repository default source
local source if present
```

Illustrative internal names only:

```text
LoadRepositoryDefaults
LoadLocalOverridesIfPresent
```

The implementation may use a smaller shape if it preserves the same contract.

## Consumer cut

Only these accessors are candidates to move to effective resolution:

```text
HouseholdGroupLifeLabels
HouseholdGroupReserveLabels
```

Do not change:

```text
HouseholdGroupOrderLabels
```

`HOUSEHOLD_GROUP_ORDER` remains a `derived-candidate` outside this slice.

## Central sparse-override proof

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

This proves:

```text
one local override
        +
one inherited approved default
        =
typed sparse override
```

without a global merged config.

## Required focused tests

### No local config

Expected:

```text
LIFE    -> daily,flex
RESERVE -> reserve
```

### Sparse LIFE override

Local:

```text
HOUSEHOLD_GROUP_LIFE=daily,flex,weekly
```

Expected:

```text
LIFE    -> daily,flex,weekly
RESERVE -> reserve
```

### Sparse RESERVE override

Local:

```text
HOUSEHOLD_GROUP_RESERVE=reserve,longterm
```

Expected:

```text
LIFE    -> daily,flex
RESERVE -> reserve,longterm
```

### Explicit empty LIFE

```text
HOUSEHOLD_GROUP_LIFE=
```

Expected: non-zero exit.

### Explicit empty RESERVE

```text
HOUSEHOLD_GROUP_RESERVE=
```

Expected: non-zero exit.

### Compatibility checks

Also prove:

- full-ish local config remains valid,
- extra UI-owned rows remain tolerated,
- raw `Lookup` behavior remains unchanged,
- raw `Get` behavior remains unchanged,
- BQN-only canonical path remains valid,
- `tools/check.sh` passes.

## Duplicate-key boundary

Duplicate semantics do not change in this slice.

Do not claim duplicate safety.

The broader A4 direction still prefers visible duplicate failure in a future tested resolver path, but that is a separate question from sparse default inheritance.

## Unknown-key boundary

No global unknown-key validation.

For this slice:

```text
LIFE key       -> resolve
RESERVE key    -> resolve
other key      -> outside this boundary
```

Extra rows are not automatically errors.

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
- global validation-timing decision,
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

## Proposed later runtime slice

If separately approved, limit the runtime PR to:

1. focused tests for the two-key truth table and compatibility boundary,
2. the minimum BQN source distinction needed to consult defaults and local overrides separately,
3. one narrow effective-resolution function or equivalent internal boundary,
4. migration of only `HouseholdGroupLifeLabels` and `HouseholdGroupReserveLabels`,
5. full checks.

No third key should be added merely because the mechanism can resolve it.

## Acceptance criteria for that later slice

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
