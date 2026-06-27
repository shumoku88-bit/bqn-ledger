# Cube Shape Invariant Plan

> **Note (2026-06-26):** 旧エンジン (, , ) は削除されました。この文書内の旧エンジンへの参照は履歴として残ります。現行エンジンは  です。
Status: **implemented / active check** (2026-06-22)
Created: 2026-06-22
Related:

```text
docs/SAFETY_PROFILE.md
docs/SAFETY_PROFILE_INVARIANT_MAP.md
docs/CANONICAL_DAILY_CUBE.md
docs/CUBE_EVOLUTION_POLICY.md
src/core/build_cube.bqn
src/reports/report_engine.bqn
checks/invariants.bqn
checks/check-forecast-zero.bqn
checks/check-cube-before-start.bqn
```

This document plans a small invariant check for Canonical Daily Cube shape.

It does not implement the check.
It does not change `BuildCube`.
It does not decide the semantic meaning of layer 3.

## Goal

Add a small direct guard for the Canonical Daily Cube shape:

```text
Day × Account × Layer
```

Current concrete shape:

```text
cube_updates  = cube_days × 256 × 4
cube_balances = cube_days × 256 × 4
names         = 256
cube_dates    = cube_days
cube_ordinals = cube_days
```

This should turn the current invariant-map row:

```text
Canonical Daily Cube shape = DOC_ONLY
```

into at least:

```text
Canonical Daily Cube shape = GUARDED for rank / axis sizes
```

without changing any report number.

## Current evidence

### BuildCube returns the needed fields

`src/core/build_cube.bqn` returns:

```text
cube_days
cube_dates
cube_ordinals
cube_updates
cube_balances
cube_projections
names
accs
journal_rows
plan_rows
budget_alloc_rows
ctx
```

For non-empty projection input, `MaterializeDaily` builds:

```text
updates = cube_days ‿ 256 ‿ 4 ⥊ cell_sums
balances = +` updates
```

For empty input, `BuildCube` returns:

```text
cube_days    = 0
cube_updates = 0‿256‿4 ⥊ 0
cube_balances = 0‿256‿4 ⥊ 0
```

So both normal and empty cases can be checked without changing `BuildCube`.

### report_engine already assumes snapshot shape

`src/reports/report_engine.bqn` imports `src/core/build_cube.bqn`, calls `rtx.BuildCube`, and treats the snapshot as a 256×4 matrix:

```text
bal_as_of = 256 ‿ 4 shaped snapshot
bal_final = balances.bal_final
```

So a direct cube shape check protects an assumption already used by the report engine.

### Existing checks partially cover shape

`checks/check-forecast-zero.bqn` already asserts:

```text
≢ r.cube_updates  ≡ ⟨ r.cube_days, 256, 4 ⟩
≢ r.cube_balances ≡ ⟨ r.cube_days, 256, 4 ⟩
```

But that check is tied to a specific layer-3 fixture and historical forecast/budget_alloc_sum behavior.

A dedicated cube shape check should extract only the structural invariant and make it independent from layer-3 semantics.

## Important boundary: shape versus layer meaning

Do not mix these two questions:

```text
A. Is the cube shaped Day × 256 × 4?
B. What does layer 3 mean?
```

This plan is for A only.

Layer meaning is currently more delicate:

- `docs/CANONICAL_DAILY_CUBE.md` documents layer 3 as `forecast`.
- `docs/CUBE_EVOLUTION_POLICY.md` says layer 3 meaning still needs confirmation/cleanup.
- `checks/check-forecast-zero.bqn` notes that current implementation uses layer 3 as `budget_alloc_sum` for envelope allocation totals.

Therefore, do not write a new invariant that says:

```text
layer 3 must be forecast zero
```

The safe invariant is only:

```text
there are exactly 4 layers
```

and, optionally:

```text
layer indexes used by projections must be between 0 and 3
```

## Proposed check

Add a new file:

```text
checks/check-cube-shape.bqn
```

Suggested inputs:

```text
fixtures/basic
fixtures/empty-journal
fixtures/forecast-zero
```

Minimal assertions:

1. `cube_days = ≠ cube_dates`
2. `cube_days = ≠ cube_ordinals`
3. `≢ cube_updates ≡ ⟨ cube_days, 256, 4 ⟩`
4. `≢ cube_balances ≡ ⟨ cube_days, 256, 4 ⟩`
5. `≠ names = 256`
6. Empty fixture still has `cube_updates` and `cube_balances` shaped `0‿256‿4`.
7. If `cube_projections` is non-empty, every projection layer is in `0..3`.
8. If `cube_projections` is non-empty, every projection account index is in `0..255`.

Do not assert layer names in this first check.
Do not assert layer 3 semantic meaning.
Do not assert that layer 3 is zero.

## Example pseudo-BQN shape assertions

The implementation should adapt to existing BQN style, but the shape assertions are conceptually:

```bqn
shape_updates ← ≢ r.cube_updates
shape_balances ← ≢ r.cube_balances

shape_updates  ≡ ⟨ r.cube_days, 256, 4 ⟩
shape_balances ≡ ⟨ r.cube_days, 256, 4 ⟩

r.cube_days = ≠ r.cube_dates
r.cube_days = ≠ r.cube_ordinals
256 = ≠ r.names
```

Projection checks are conceptually:

```bqn
layers ← {𝕩.layer} ¨ r.cube_projections
accs   ← {𝕩.acc_idx} ¨ r.cube_projections

∧´ (0 ≤ layers) ∧ (layers < 4)
∧´ (0 ≤ accs) ∧ (accs < 256)
```

Guard the projection checks for empty projections.

## tools/check.sh integration

If implemented, add:

```text
bqn checks/check-cube-shape.bqn >/dev/null
```

near the other cube-related checks:

```text
check-cube-before-start.bqn
check-forecast-zero.bqn
```

## Expected status after implementation

After implementation and successful check integration:

`docs/SAFETY_PROFILE_INVARIANT_MAP.md` can change:

```text
Canonical Daily Cube shape: DOC_ONLY
```

to:

```text
Canonical Daily Cube shape: GUARDED
```

with a note such as:

```text
Direct check covers cube rank, day axis length, 256 account axis, 4 layer axis, empty cube shape, projection layer range, and projection account range.
```

Layer source meaning should remain `PARTIAL` until source-to-layer semantics get their own guard.

## Non-goals

- Do not edit source TSV data.
- Do not change `BuildCube` behavior.
- Do not change `report_engine.BuildAt` output.
- Do not rename layers.
- Do not decide whether layer 3 is forecast or budget_alloc_sum.
- Do not make layer 3 zero as part of this check.
- Do not add human report output.
- Do not change golden report files unless a later implementation intentionally changes human output, which this plan does not require.

## Suggested Codex / local-agent prompt

```text
Read docs/CUBE_SHAPE_INVARIANT_PLAN.md and implement only the small cube shape invariant check.

Add checks/check-cube-shape.bqn.
Use BuildCube directly from src/core/build_cube.bqn.
Check fixtures/basic, fixtures/empty-journal, and fixtures/forecast-zero.
Assert:
- cube_days equals length of cube_dates and cube_ordinals
- cube_updates shape is ⟨cube_days, 256, 4⟩
- cube_balances shape is ⟨cube_days, 256, 4⟩
- names length is 256
- empty cube remains 0‿256‿4
- projection layer values are 0..3 when projections exist
- projection account indexes are 0..255 when projections exist

Do not change BuildCube.
Do not change source TSV files.
Do not decide or alter layer 3 semantics.
Do not change human report output.
Add the check to checks/check.sh.
Run bash tools/check.sh or bash checks/check.sh, depending on the repository convention, and report the result.
```

## Open question before implementation

Use `tools/check.sh` or `checks/check.sh` as the authoritative entry point?

Both names appear in the repository history. The current implementation should check the actual repo convention before wiring the new check.

Do not duplicate check wiring unless both files are intentionally maintained as aliases.
