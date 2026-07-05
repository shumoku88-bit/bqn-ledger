# POLICY_INCOME_CADENCE Ownership Investigation

Status: A4 focused investigation / docs-only / no runtime authorization
Date: 2026-07-05
Parent checkpoint: `CONFIG_TYPED_POLICY_CHECKPOINT-2026-07-05.md`
Parent plan: `CONFIG_RESOLUTION_SEMANTICS_PLAN-2026-07-05.md`
Classification decision: `CONFIG_KEY_CLASSIFICATION_DECISION-2026-07-05.md`
Key under investigation: `POLICY_INCOME_CADENCE`
Current class: `optional`

## Purpose

Determine who currently owns the meaning of `POLICY_INCOME_CADENCE`, whether any production consumer depends on it, and whether its present config/accessor shape represents:

- an active policy key,
- a dormant future policy key,
- historical residue,
- or descriptive profile metadata.

This investigation must happen before changing missing/explicit-empty semantics.

Important:

- this document does not authorize runtime behavior changes,
- this document does not authorize deleting the key,
- this document does not authorize adding a new consumer,
- this document does not authorize live-config migration,
- this document does not authorize changing cycle resolution,
- this document does not authorize profile implementation.

## Why ownership comes before optional semantics

The A4 checkpoint recommended `POLICY_INCOME_CADENCE` as the next `optional` evidence slice.

Initial inspection found a more basic question:

> Before deciding what missing and explicit empty mean, determine whether the key currently has an execution owner at all.

A key can be syntactically optional while still being semantically ambiguous.

For example:

```text
missing
explicit empty
bimonthly
monthly
weekly
irregular
```

cannot be assigned durable runtime meaning until the repository knows what behavior the value is supposed to influence.

## Current observed behavior

### 1. Accessor collapses missing and explicit empty

Current `PolicyIncomeCadence` uses `Get`:

```text
v <- Get POLICY_INCOME_CADENCE
```

Therefore:

```text
missing         -> ""
explicit empty  -> ""
```

The accessor then:

- emits `CONFIG WARNING: POLICY_INCOME_CADENCE missing` when value length is zero,
- validates only non-empty values,
- returns the value unchanged.

Accepted non-empty values are:

```text
bimonthly
monthly
weekly
irregular
```

### 2. Presence-aware observation already exists

Focused config tests already prove that `Lookup` distinguishes:

```text
missing         -> ⟨0, ""⟩
explicit empty  -> ⟨1, ""⟩
explicit value  -> ⟨1, value⟩
```

For `POLICY_INCOME_CADENCE`, current tests include:

```text
missing         -> ⟨0, ""⟩
default config  -> ⟨1, ""⟩
calendar fixture-> ⟨1, "monthly"⟩
```

So observation is not blocked by parser limitations.

### 3. Default config explicitly stores empty

`config/default_config.tsv` contains:

```text
POLICY_INCOME_CADENCE=
```

This means the repository itself currently provides an explicit-empty state.

Because the accessor uses `Get`, explicit empty can still trigger a warning worded as `missing`.

This is a concrete semantics mismatch:

```text
key present with explicit empty
        ->
warning says missing
```

No runtime change is authorized by this finding.

### 4. Public sandbox stores an explicit value

`data/config.tsv` contains:

```text
POLICY_INCOME_CADENCE=bimonthly
```

Focused config tests also exercise:

```text
bimonthly
monthly
```

Therefore the key is not only a schema declaration. Current repository data and tests carry explicit values.

## Origin and historical intent

### Introduction commit

Commit:

```text
12557521792db5e4b96a68645fe5c24f062e58aa
```

Message:

```text
Household Policy: audit fixes + move personal data out
```

The commit added policy-profile schema entries including:

```text
POLICY_BUDGET_STYLE
POLICY_RISK_STYLE
POLICY_INCOME_CADENCE
HOUSEHOLD_GROUP_*
```

It also added the warning behavior for missing `POLICY_*` values.

### Household Policy plan context

The active Household Policy plan explicitly classifies `income cadence` as a policy axis:

```text
monthly salary
weekly pay
pension bimonthly
irregular freelance
```

The same plan defines profile examples:

```text
monthly_salary
weekly_income
pension_bimonthly
freelance_irregular
```

and conceptual policy choices:

```text
period_resolver = income_anchor | calendar_month | fixed | rolling
income_cadence  = monthly | weekly | bimonthly | irregular
```

The plan explicitly states:

```text
pension_bimonthly is a policy profile candidate,
not a core invariant.
```

### Historical interpretation

Supported interpretation:

> `POLICY_INCOME_CADENCE` was introduced as part of moving household-specific lifestyle assumptions out of accounting core and into an explicit policy/profile layer.

This is historical intent, not proof of current runtime consumption.

## Current consumer investigation

### Search vocabulary

Do not search only for the exact config key.

Investigate at least:

```text
POLICY_INCOME_CADENCE
PolicyIncomeCadence
income cadence
income_cadence
bimonthly
monthly
weekly
irregular
pension_bimonthly
incomeAnchor
income_anchor
period_resolver
income_account
```

Reason:

- a consumer may rename the value,
- a consumer may encode one enum value directly,
- a consumer may use a profile label instead of the config key,
- historical code may precede the current accessor name.

### Current evidence: config accessor

Confirmed owner of parsing and enum validation:

```text
src_next/config.bqn
```

Current responsibility:

- retrieve value,
- warn on empty-length value,
- validate non-empty enum,
- expose `PolicyIncomeCadence` accessor.

This is configuration ownership, not evidence of behavioral consumption.

### Current evidence: cycle resolver

`src_next/cycle.bqn` resolves cycle behavior from `cycle.tsv` fields.

Observed inputs include:

```text
mode
start
end_exclusive
income_account
start_day
```

Supported modes include:

```text
fixed
incomeAnchor
calendarMonth
```

For `incomeAnchor`, the resolver uses actual/planned income dates for `income_account`.

No observed `POLICY_INCOME_CADENCE` read is required for that resolution path.

Current interpretation:

> Cycle period resolution and income cadence are distinct axes in the design, and the current cycle resolver appears to operate without cadence.

This supports the Household Policy plan's conceptual separation:

```text
period_resolver
!=
income_cadence
```

### Current evidence: outlook

`src_next/outlook.bqn` loads config and consumes:

```text
PolicyRiskStyle
HouseholdGroupLifeLabels
```

No `PolicyIncomeCadence` consumption was observed in the inspected build path.

### Current evidence: household policy diagnostics

`src_next/household_policy.bqn` consumes:

```text
PolicyBudgetStyle
HouseholdGroupLifeLabels
HouseholdGroupReserveLabels
HouseholdGroupOrderLabels
```

No `PolicyIncomeCadence` consumption was observed.

### Current evidence: report composition

Inspected machine and human report composition surfaces include major sections such as:

```text
snapshot
cycle
ytd
balances
envelopes
planned payments
outlook
daily trend
actual comparison
```

No dedicated income-cadence report surface was observed.

### Search limitation

GitHub code search did not return reliable results for the exact key/accessor during this investigation.

Therefore this document must not claim:

```text
consumer count = 0
```

Current supported wording is:

> No behavioral consumer has yet been found in the inspected major canonical surfaces; repository-wide absence is not yet proven.

## Working hypothesis

Current strongest hypothesis:

```text
historical policy intent exists
        +
explicit values exist in data/tests
        +
config accessor validates the enum
        +
current behavioral consumer not yet identified
        =
possible ownership gap
```

This is not yet a deletion argument.

It is evidence that parsing/schema presence and runtime ownership may have drifted apart.

## Candidate ownership outcomes

### Outcome A: active policy key

Evidence required:

- at least one current behavioral consumer,
- clear behavior difference by cadence value,
- consumer belongs above accounting core,
- missing/empty semantics can be tied to that behavior.

Possible action after separate approval:

- define optional semantics,
- preserve consumer contract,
- add focused compatibility/negative tests.

### Outcome B: dormant future policy key

Shape:

```text
historical design intent exists
schema/accessor/value exists
behavioral consumer not implemented
```

Risk:

- key looks operational although it does not affect behavior,
- explicit user data may create false confidence,
- warnings/validation imply stronger ownership than exists.

Possible later actions:

- mark dormant explicitly,
- remove misleading warning behavior,
- move to planned profile contract,
- or implement a real consumer only through a separate approved plan.

### Outcome C: historical residue

Shape:

```text
old design intent
no current consumer
no approved future owner
```

Possible later action:

- deprecation/removal decision,
- compatibility review,
- no immediate deletion.

### Outcome D: descriptive profile metadata

Shape:

```text
bimonthly describes household income pattern
but does not directly drive current calculations
```

Possible later action:

- keep as metadata/profile description,
- move ownership away from behavioral config accessor,
- do not pretend the value controls cycle resolution.

## Differential experiment plan

Static investigation should be paired with a controlled output-diff experiment.

### Goal

Hold ledger data constant and vary only cadence state.

Candidate states:

```text
A missing
B explicit empty
C bimonthly
D monthly
```

### Candidate surfaces

Run the same base data through canonical/production-facing surfaces such as:

```text
src_next/summary.bqn
src_next/report.bqn
stable report sections
```

Compare:

```text
exit status
stdout
stderr
machine summary fields
human report section bodies
```

### Interpretation

If changing:

```text
bimonthly
<->
monthly
```

produces no output difference across the exercised canonical surfaces, that is strong evidence that the key is not currently observable there.

It is not proof of repository-wide non-consumption.

If output differs, record:

- exact consumer path,
- exact changed field/section,
- whether the difference is accounting fact, period resolution, household policy, or presentation.

### Safety boundary

The experiment must:

- use fixtures or temporary copies,
- not edit external live config,
- not edit source TSV automatically,
- not bundle runtime changes,
- preserve exact base data except the cadence state under test.

## Investigation tasks

### Task 1: complete current consumer map

Search and inspect:

- `src_next/`
- tests
- shell entrypoints
- report composition
- config/schema consumers

Record each match as one of:

```text
behavioral consumer
validation-only
schema-only
test-only
docs-only
fixture/data-only
historical
```

### Task 2: complete history map

Trace:

- introduction commit,
- related Household Policy commits,
- PR discussions if available,
- profile/generalization docs,
- earlier naming such as `pension_bimonthly`.

Goal:

> identify intended consumer, not only intended value vocabulary.

### Task 3: run four-state differential experiment

Compare:

```text
missing
explicit empty
bimonthly
monthly
```

on selected stable surfaces.

### Task 4: make ownership decision

Choose one:

```text
A active policy key
B dormant future policy key
C historical residue
D descriptive profile metadata
```

If evidence is mixed, keep the key in investigation state.

### Task 5: only then decide optional semantics

Questions to answer after ownership is known:

1. Is missing a valid state?
2. Is explicit empty a distinct valid state?
3. Does empty mean disabled, unspecified, unknown, or not-applicable?
4. Is missing warning useful or misleading?
5. Should invalid non-empty values fail closed?
6. Does any consumer require exact empty string compatibility?

## Provisional findings

Current findings are provisional:

1. The key has real historical policy intent.
2. The intent was to avoid hard-coding pension/bimonthly lifestyle assumptions into core.
3. `income cadence` and `period resolver` were designed as separate policy axes.
4. Current cycle resolution appears to function from cycle mode and income-account/date evidence rather than cadence.
5. Default config explicitly stores empty while current accessor can call that state `missing`.
6. Public sandbox and tests carry explicit cadence values.
7. No behavioral consumer has yet been found in the inspected major canonical surfaces.
8. Repository-wide absence is not yet proven.

## Recommended next step

Do not change `PolicyIncomeCadence` yet.

Next approved work should be investigation-only:

```text
complete consumer map
  ->
run four-state differential experiment
  ->
record ownership decision
```

Only after that should A4 revisit missing/explicit-empty semantics for this key.

## A4 boundary after this investigation

A4 remains open.

This document narrows the next question from:

```text
What should optional mean?
```

to:

```text
Who owns this value, and what observable behavior does it control today?
```
