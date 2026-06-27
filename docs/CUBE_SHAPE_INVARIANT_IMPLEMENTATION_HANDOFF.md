# Cube Shape Invariant Implementation Handoff

> **Note (2026-06-26):** 旧エンジン (, , ) は削除されました。この文書内の旧エンジンへの参照は履歴として残ります。現行エンジンは  です。
Status: **Codex / local-agent implementation handoff**
Created: 2026-06-22
Related:

```text
docs/CUBE_SHAPE_INVARIANT_PLAN.md
docs/SAFETY_PROFILE_INVARIANT_MAP.md
docs/CANONICAL_DAILY_CUBE.md
docs/CUBE_EVOLUTION_POLICY.md
src/core/build_cube.bqn
checks/check-forecast-zero.bqn
checks/check-cube-before-start.bqn
tools/check.sh
checks/check.sh
```

This handoff is for implementing the smallest safe Canonical Daily Cube shape invariant check.

The task is structural only.
It must not change `BuildCube` behavior or report numbers.

## Goal

Add a new direct check for the Canonical Daily Cube structural shape:

```text
Day × Account × Layer
```

Current concrete contract:

```text
cube_updates  = cube_days × 256 × 4
cube_balances = cube_days × 256 × 4
names         = 256
cube_dates    = cube_days
cube_ordinals = cube_days
```

After this implementation passes, `docs/SAFETY_PROFILE_INVARIANT_MAP.md` may later mark Canonical Daily Cube shape as `GUARDED` for rank / axis sizes.

## Non-goals

Do not do these in this task:

- Do not edit source TSV data.
- Do not change `BuildCube` behavior.
- Do not change `report_engine.BuildAt` output.
- Do not change report numbers.
- Do not change human report output.
- Do not change golden report output.
- Do not rename layers.
- Do not decide whether layer 3 means `forecast` or `budget_alloc_sum`.
- Do not make layer 3 zero as part of this check.
- Do not add source-to-layer provenance checks in this task.

## Important boundary

This task checks only shape.

```text
YES:  there are exactly 3 cube axes: Day, Account, Layer
YES:  Account axis has 256 slots
YES:  Layer axis has 4 slots
YES:  projection layer indexes are in 0..3
YES:  projection account indexes are in 0..255

NO:   layer 3 semantic cleanup
NO:   forecast-vs-budget_alloc_sum decision
NO:   projection source meaning proof
NO:   report behavior changes
```

Layer source meaning remains a separate `PARTIAL` invariant.

## File to add

Add:

```text
checks/check-cube-shape.bqn
```

Use `BuildCube` directly:

```text
src/core/build_cube.bqn
```

Use account metadata the same way `report_engine.bqn` does, by building metadata first:

```text
src/core/account_space.bqn
```

## Fixtures to check

Use these fixtures at minimum:

```text
fixtures/basic
fixtures/empty-journal
fixtures/forecast-zero
```

Why these:

- `fixtures/basic`: ordinary non-empty cube.
- `fixtures/empty-journal`: empty cube case must still be `0‿256‿4`.
- `fixtures/forecast-zero`: existing layer-3-related fixture, but only shape/range should be checked here.

## Required assertions

For each fixture:

1. `cube_days = ≠ cube_dates`
2. `cube_days = ≠ cube_ordinals`
3. `≢ cube_updates ≡ ⟨ cube_days, 256, 4 ⟩`
4. `≢ cube_balances ≡ ⟨ cube_days, 256, 4 ⟩`
5. `≠ names = 256`

For `fixtures/empty-journal`, also explicitly assert:

```text
cube_days = 0
≢ cube_updates ≡ ⟨0, 256, 4⟩
≢ cube_balances ≡ ⟨0, 256, 4⟩
```

For fixtures with non-empty `cube_projections`, assert:

```text
all projection.layer values are in 0..3
all projection.acc_idx values are in 0..255
```

Guard projection checks for the empty case.

## Suggested BQN structure

Follow the style of existing check files.

Suggested imports:

```bqn
tx ← •Import "../core/build_cube.bqn"
rmeta ← •Import "../core/account_space.bqn"
```

Suggested helper outline:

```bqn
Fail ← {
  •Out 𝕩
  •Exit 1
}

Assert ← {
  msg ← 𝕩
  ok ← 𝕨
  ok ◶ ⟨ {𝕩 ⋄ Fail msg}, {𝕩 ⋄ @} ⟩ @
}
```

Suggested fixture runner:

```bqn
CheckBase ← {
  base ← 𝕩
  meta ← rmeta.Build base
  r ← tx.BuildCube ⟨ base, meta ⟩

  # shape assertions here
}
```

Be careful with BQN list/array merging.
If storing string lists, use enclose where necessary.
For this check, prefer immediate assertions and avoid building complex nested status output.

## Projection range checks

A conceptual version:

```bqn
HasProjs ← 0 < ≠ r.cube_projections
layers ← {𝕩.layer} ¨ r.cube_projections
accs ← {𝕩.acc_idx} ¨ r.cube_projections

# only when HasProjs
∧´ (0 ≤ layers) ∧ (layers < 4)
∧´ (0 ≤ accs) ∧ (accs < 256)
```

Adapt syntax as needed.
Do not fail on empty projections just because no projections exist.

## Check entry point wiring

Both files currently exist and are nearly identical check entry points:

```text
tools/check.sh
checks/check.sh
```

Before wiring, inspect whether both are intentionally maintained.

Preferred safe approach:

- Add `bqn checks/check-cube-shape.bqn >/dev/null` near other cube-related checks in both files if both are still intended entry points.
- If one file is only a stale copy, update the active one and document why the other was not changed.

Place the new line near:

```text
bqn checks/check-cube-before-start.bqn >/dev/null
bqn checks/check-forecast-zero.bqn >/dev/null
```

## Test command

Run the repository check command after implementation.

Preferred:

```sh
bash tools/check.sh
```

If local convention uses the other entry point too, also run:

```sh
bash checks/check.sh
```

Report exact results.

## Documentation updates after implementation

If the implementation passes, update:

```text
docs/SAFETY_PROFILE_INVARIANT_MAP.md
docs/CUBE_SHAPE_INVARIANT_PLAN.md
TODO.md
```

Expected invariant-map update:

```text
Canonical Daily Cube shape: GUARDED
```

with a note:

```text
Direct check covers cube rank, day axis length, 256 account axis, 4 layer axis, empty cube shape, projection layer range, and projection account range.
```

Keep this separate:

```text
Layer source meaning: PARTIAL
```

Do not mark layer source meaning as guarded.

## Acceptance criteria

The task is done only if:

- [ ] `checks/check-cube-shape.bqn` exists.
- [ ] It checks at least `fixtures/basic`, `fixtures/empty-journal`, and `fixtures/forecast-zero`.
- [ ] It asserts `cube_updates` and `cube_balances` shape as `cube_days × 256 × 4`.
- [ ] It asserts `cube_dates` and `cube_ordinals` length equals `cube_days`.
- [ ] It asserts `names` length is 256.
- [ ] It asserts empty cube shape is `0‿256‿4`.
- [ ] It guards projection range checks for empty projections.
- [ ] It does not assert layer 3 semantics.
- [ ] It is wired into the active check entry point.
- [ ] `bash tools/check.sh` passes, or failure is reported exactly.
- [ ] No source TSV data changed.
- [ ] `BuildCube` behavior did not change.

## Suggested Codex prompt

```text
Read docs/CUBE_SHAPE_INVARIANT_IMPLEMENTATION_HANDOFF.md and docs/CUBE_SHAPE_INVARIANT_PLAN.md.

Implement only the small Canonical Daily Cube shape invariant check.

Add checks/check-cube-shape.bqn.
Use BuildCube from src/core/build_cube.bqn and account metadata from src/core/account_space.bqn.
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
Do not change human report output or golden outputs.

Wire the check into the active check entry point. If both tools/check.sh and checks/check.sh are maintained, update both consistently.
Run bash tools/check.sh and report the exact result.
```

## Reviewer note

This check is a guardrail, not a refactor.

If implementing it requires changing `BuildCube`, stop and report why.
