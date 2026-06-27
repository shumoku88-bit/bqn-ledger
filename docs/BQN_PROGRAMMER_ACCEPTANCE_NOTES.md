# BQN Programmer Acceptance Notes

Status: draft review note  
Branch: `refactor/cycle-ledger-core`  
Scope: notes on whether this branch can become convincing to BQN programmers and senior engineers

## 1. Short answer

This branch has real potential to become convincing to BQN programmers and senior engineers.

The current state is not yet a polished BQN-native final form. It is better described as an honest prototype and design workbench that is already asking the right questions.

The important point is that the branch is not merely trying to write a household-accounting script in BQN syntax. It is trying to make the array model, data contracts, and report boundary visible enough that a reviewer can reason about the system.

## 2. Why the direction is promising

The branch already contains the right architectural posture:

```text
canonical TSV + BQN array engine + small report surface
```

This matters because a senior reviewer will usually care less about whether every line looks clever, and more about whether the system has stable contracts, bounded responsibilities, and a clear path from source records to report values.

The current direction has several strengths:

- `main` remains the daily-use branch.
- `refactor/cycle-ledger-core` is explicitly a design and refactor workbench.
- canonical TSV files remain protected.
- BQN remains the core calculator rather than a decorative wrapper.
- the proposed core has an explicit shape.
- report output is intentionally smaller than the internal model.

This is a strong starting point.

## 3. What may convince senior engineers

Senior engineers are likely to respond well to the following qualities:

### 3.1 Contracts before code

The branch has design documents for data, axes, projection, report contracts, report values, and migration.

That is a good sign. It means code is supposed to follow named contracts, rather than accidental implementation shape becoming architecture.

### 3.2 Stable migration posture

The migration plan says the current engine should not be replaced quickly. It should be moved slowly, inspectably, and reversibly.

This is important because the existing system is already useful in daily life. A rewrite that destroys daily usefulness would be a failure even if the new code looked cleaner.

### 3.3 A small first report surface

The first report surface focuses on survival and household-accounting needs:

```text
current cycle summary
remaining amount until next income date
food / daily remaining amount
plan vs actual difference
incomplete planned items
checks / warnings / unavailable sections
```

This restraint is good engineering. It keeps the first phase from becoming a general accounting application by accident.

## 4. What may convince BQN programmers

BQN programmers are likely to care about whether the system has a real array shape, not just procedural code written in BQN.

The branch has a promising core shape:

```text
Day × AccountKey × Layer
```

This is stronger than a vague pile of records because it gives the system a visible computational object.

The `AccountKey` idea is also promising:

```text
AccountKey = Account + Currency
```

This avoids silently mixing currencies without adding a fourth `Currency` axis too early. It is a pragmatic first-phase choice.

The design is not saying that more dimensions are always better. It is saying that identity and separation should be represented in the model before totals are produced.

That is the kind of thing an array programmer can respect.

## 5. Current implementation strengths

The `src_next` prototype is more than paperwork.

It already has an entrypoint that:

1. reads cycle information,
2. resolves an AccountKey table,
3. builds projection rows from `journal.tsv` and `plan.tsv`,
4. materializes a small cube,
5. prints cube sanity information,
6. verifies numeric totals.

This is a good first slice.

The strongest implementation idea is the path:

```text
source record
  -> account resolution
  -> currency resolution
  -> AccountKey resolution
  -> day/cycle resolution
  -> layer assignment
  -> delta output
  -> Day × AccountKey × Layer cube
```

This is the right kind of spine for a BQN-based report engine.

## 6. Current limitations

The current code is still more prototype than final BQN form.

That is acceptable, but it should be named honestly.

### 6.1 Calculation and formatting are still mixed

Functions such as table formatting and sanity output are useful for inspection, but the convincing final shape should separate:

```text
core calculation data
report state
rendered text
```

A BQN programmer will likely trust the engine more if the calculation path returns structured values first and formatting is pushed outward.

### 6.2 Row namespaces may be too record-like

The projection path currently uses row-like namespaces.

That is readable, but a stronger BQN shape may eventually represent projection data as a table or column-bundle that can be transformed more directly with array operations.

Possible direction:

```text
ProjectionRows = rows × projection_fields
```

or a small namespace of column vectors:

```text
projection.day_index
projection.account_key_index
projection.layer_index
projection.delta
projection.status
```

This would make filtering, grouping, and verification more visibly array-oriented.

### 6.3 Sentinel indexes need care

Unknown accounts currently use a sentinel index equal to `n`, with comments warning that it must not be used as a cube index.

That is understandable for a prototype, but it is a risk point.

A stronger design may separate validity from index value more explicitly:

```text
valid_mask
account_key_index
status
message
```

The cube materializer should only see rows whose indices are already proven valid.

### 6.4 Dense cube materialization is simple but possibly naive

The current dense cube materialization is easy to inspect:

```text
for each flat cell, sum deltas targeting that cell
```

This is good for a tiny prototype.

For larger data, it may become inefficient because every output cell scans the projection index vector.

That may be fine for a personal household-accounting engine, but if the goal is to satisfy a BQN reviewer, it is worth exploring a more array-native scatter/group/fold strategy later.

## 7. Phase 7 fixture expectation change

After Phase 7 added minimal `plan.tsv` projection, fixture expectations changed.

The old expectation for a fixture like `fixtures/unknown-account` was:

```text
valid projection rows: 0
```

This is no longer correct when `plan.tsv` contains valid rows that fall within
the cycle.

The new interpretation is layer-aware:

```text
actual layer may have 0 valid rows	skipped journal rows still reported
plan layer may have valid rows	plan total may be nonzero
```

For `fixtures/unknown-account`, the likely current outcome is:

```text
journal.tsv:
  credit-side unknown account -> skipped

plan.tsv:
  known accounts, in cycle -> valid plan row

therefore:
  skipped projection rows includes unknown journal row
  plan layer total may be nonzero
  actual total may remain zero
```

Old expectations like "valid projection rows: 0" should not be used as golden
values anymore. Skipped rows and layer totals should be interpreted per layer.

## 8. What would improve acceptance

To make this convincing to both BQN programmers and senior engineers, the next work should not be a full report rewrite.

The strongest path is:

1. Keep `main` stable.
2. Keep this branch as a design/refactor workbench.
3. Add a small fixture that proves the `src_next` path.
4. Compare key numbers against current `main` output.
5. Separate core calculation from rendering.
6. Make projection representation more array-oriented.
7. Make invalid-row handling impossible to accidentally index.
8. Add tests for cube shape, layer totals, skipped rows, and AccountKey separation.
9. Only then consider moving a small slice back into `main`.

## 9. Suggested acceptance checklist

A BQN programmer or senior engineer may be more likely to accept the architecture if the branch can demonstrate:

- The source TSV contract is explicit.
- The axis contract is explicit.
- `Day × AccountKey × Layer` is visible in code and tests.
- layer order is declared once.
- AccountKey resolution is deterministic.
- different currencies cannot be silently mixed.
- projection rows are inspectable.
- invalid rows do not enter cube indexing.
- cube totals can be checked against projection totals.
- report values are produced before formatting.
- daily-use report behavior can be compared against `main`.
- golden output or equivalent reference checks exist.

## 10. Recommended guiding phrase

Use three audiences:

```text
Contracts are for engineers.
Shapes are for BQN programmers.
Daily reports are for the user.
```

If those three layers stay separate, this branch can become persuasive without becoming bloated.

## 11. Final judgement

This branch is worth keeping.

It should not be rushed into `main`, but it has a real chance to become the place where the next core becomes understandable, inspectable, and more BQN-worthy.

The goal should not be clever BQN for its own sake.

The goal should be:

```text
simple source records
clear projection
visible axes
trustworthy cube
small reports
fail-closed checks
```

That is a path a serious BQN programmer and a senior engineer could both respect.
