# POLICY_INCOME_CADENCE Ownership Decision

Status: A4 evidence decision / docs-only / no runtime authorization
Date: 2026-07-05
Investigation: `POLICY_INCOME_CADENCE_OWNERSHIP_INVESTIGATION-2026-07-05.md`
Parent checkpoint: `CONFIG_TYPED_POLICY_CHECKPOINT-2026-07-05.md`
Key: `POLICY_INCOME_CADENCE`
Current classification: `optional`
Ownership outcome: **B — dormant future policy key**

## Decision

`POLICY_INCOME_CADENCE` is currently treated as a **dormant future policy key**.

Meaning:

```text
historical policy intent exists
schema/accessor/value vocabulary exists
explicit values exist in repository data/tests
current behavioral ownership is not established
```

This decision is based on static consumer mapping plus a controlled four-state differential experiment.

It is not a deletion decision.

It is not authorization to add a consumer.

It is not authorization to change missing/explicit-empty runtime semantics.

## Evidence 1: exact src_next reference map

A temporary investigation harness searched `src_next/` for the exact terms:

```text
POLICY_INCOME_CADENCE
PolicyIncomeCadence
```

Observed exact runtime-reference file set:

```text
src_next/config.bqn
```

No other exact `src_next` reference was observed in the checked-out repository state.

Interpretation:

- `config.bqn` owns parsing/accessor/enum validation,
- no exact-named behavioral consumer was found in another `src_next` module.

Limitation:

> Exact-reference absence does not prove that a renamed or conceptually encoded consumer does not exist.

This is why dynamic observation was also required.

## Evidence 2: historical policy intent remains real

The investigation already recorded that the key was introduced in the Household Policy work and that the policy plan treats these as separate axes:

```text
period_resolver
income_cadence
```

The plan also treats:

```text
pension_bimonthly
```

as a policy-profile candidate rather than an accounting-core invariant.

Therefore the key is not classified as historical residue merely because a current consumer was not found.

## Evidence 3: controlled four-state experiment

### Goal

Hold ledger data and base path constant while varying only the cadence state.

### Base fixture

```text
fixtures/generalization-calendar
```

The experiment used a temporary copy.

No external live config was edited.
No source TSV was rewritten.
No runtime code was changed.

### States

```text
missing
explicit empty
bimonthly
monthly
```

For each state, only the `POLICY_INCOME_CADENCE` row state/value changed.

### Constant-path correction

An initial experiment used separate temporary directories per state.

That design was rejected because a report surface could observe the base path and create a false difference unrelated to cadence.

The corrected experiment used one constant temporary base path and rewrote only `config.tsv` between runs.

This correction is part of the evidence record.

## Evidence 4: stable observed surfaces

The corrected four-state experiment compared stdout and stderr byte-for-byte for:

### Machine surface

```text
src_next/summary.bqn
```

### Human report sections

```text
cycle
outlook
planned
daily-trend
actual-comparison
snapshot
issues
ytd
balances
trial-balance
```

Total observed surfaces:

```text
11
```

Result:

```text
missing         == monthly
explicit empty  == monthly
bimonthly       == monthly
```

for all compared stdout/stderr files on those stable surfaces.

The GitHub Actions run containing the corrected stable four-state experiment completed successfully, including repository `check.sh` and coverage.

## Important negative finding: not every report surface was safe to compare

The investigation initially observed differences in broader report comparisons.

That did not become evidence of cadence behavior.

### Full report

The full report differed between sequential runs/states during early experiments.

### Envelope section

The `envelopes` section also appeared to differ between `bimonthly` and `monthly`.

A repeatability control then ran:

```text
monthly
monthly
```

against the same base path and same ledger data.

Result:

```text
outputs differed
```

Therefore `envelopes` was not repeatable under this byte-for-byte experiment and was excluded from cadence-effect evidence.

Checkpoint conclusion:

> A surface difference is not evidence of config influence until same-state repeatability is established.

This prevented a false positive.

## Why outcome A was rejected

Outcome A was:

```text
active policy key
```

Current evidence does not support that classification because:

- no exact-named behavioral `src_next` consumer was found outside `config.bqn`,
- four cadence states produced identical output on 11 stable observed surfaces,
- current cycle resolution operates from period mode and income/date evidence rather than observed cadence consumption.

This does not prove repository-wide non-consumption.

It does mean active behavioral ownership is not established.

## Why outcome C was rejected

Outcome C was:

```text
historical residue
```

That is too strong because:

- the Household Policy design gives the axis explicit meaning,
- the key was deliberately introduced as policy/profile vocabulary,
- public data/tests contain explicit cadence values,
- future profile intent remains documented.

No deletion or deprecation evidence is sufficient yet.

## Why outcome D was not selected as primary

Outcome D was:

```text
descriptive profile metadata
```

This remains a plausible future interpretation.

However, current repository shape includes:

- enum schema vocabulary,
- a config accessor,
- runtime validation behavior,
- explicit policy-axis design intent.

Until ownership is redesigned, calling the key purely descriptive metadata would overstate a decision not yet made.

Therefore the narrower current decision is:

```text
B — dormant future policy key
```

## Consequence for A4 optional semantics

Do not yet convert `POLICY_INCOME_CADENCE` into a new typed optional runtime contract.

In particular, do not yet decide by implementation that:

```text
missing        -> absent
explicit empty -> disabled
```

or any other pair.

Reason:

> The repository still lacks an approved behavioral owner that can define what absent or disabled means.

## Current warning concern

The existing accessor can emit:

```text
CONFIG WARNING: POLICY_INCOME_CADENCE missing
```

when `Get` returns `""`.

Because default config explicitly stores an empty value, the warning can describe a present explicit-empty key as `missing`.

This remains a real semantics mismatch.

However, this decision does not authorize changing it yet.

A later focused slice may decide whether a dormant key should:

- emit no warning,
- emit an explicit dormant/unconfigured diagnostic,
- remain validation-only,
- move to a profile metadata contract,
- or gain a real behavioral consumer through a separate approved plan.

## Compatibility boundary

Preserve for now:

- current key name,
- current accepted non-empty enum vocabulary,
- existing public config values,
- existing external live config without rewrite,
- no automatic source TSV changes,
- no cycle resolver coupling,
- no profile auto-inference.

## Investigation harness lifecycle

The consumer-map and differential-test harness was temporary.

It was used to obtain evidence through draft PR CI and is intentionally removed after results are recorded.

Reason:

> Current non-observability must not accidentally become a permanent contract that prevents a future approved consumer.

The final PR for this decision should return to docs-only.

## A4 state after this decision

Established:

```text
POLICY_INCOME_CADENCE
  historical policy intent: yes
  explicit values: yes
  exact src_next behavioral consumer: not found
  stable observed 4-state output difference: not found
  repository-wide absence proof: no
  ownership: dormant future policy key
```

Recommended next step:

```text
stop runtime work on this key
  ->
decide later whether dormancy should be made visible in schema/docs/diagnostics
  ->
only revisit optional semantics after a behavioral or metadata owner is approved
```
