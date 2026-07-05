# Config Typed Policy Checkpoint

Status: A4 checkpoint / docs-only / no new runtime authorization
Date: 2026-07-05
Parent plan: `CONFIG_RESOLUTION_SEMANTICS_PLAN-2026-07-05.md`
Key decision: `CONFIG_KEY_CLASSIFICATION_DECISION-2026-07-05.md`
Classification item: A4 Partial `config.tsv` semantics

## Purpose

Record what was actually learned from the first two typed `defaultable` policy keys before expanding A4 to more keys or introducing shared resolver machinery.

This checkpoint is based on the implementation and verification sequence through PRs #41, #42, #43, #45, #46, #47, and #48.

Important:

- this document does not authorize another runtime behavior change,
- this document does not authorize broad resolver refactoring,
- this document does not authorize external live-config edits or migration,
- the next implementation slice still requires explicit approval.

## Evidence sequence

### PR #41: characterize current config semantics

Established focused tests around current file-level replacement and accessor-level fallback behavior.

### PR #42: classify config keys

Adopted runtime classes:

- `defaultable`
- `optional`
- `ui-only`
- `required-explicit`

and quarantine states:

- `derived-candidate`
- `legacy-contract-review`

The decision explicitly rejected this inference:

```text
current accessor uses Required
        !=
future key class is required-explicit
```

### PR #43: characterize missing versus explicit empty

Established that raw parsed config preserves a distinction:

```text
missing         -> key absent
explicit empty  -> key present with ""
```

while current `Get` collapses both to `""`.

### PR #45: characterize current `Required` failure

Recorded current subprocess failure behavior for missing and explicit-empty household group keys before changing semantics.

### PR #46: add presence-aware lookup

Added:

```text
Lookup key -> ⟨found, value⟩
```

without changing existing `Get`, `Required`, or existing consumers.

This made three states observable:

```text
missing         -> ⟨0, ""⟩
explicit empty  -> ⟨1, ""⟩
explicit value  -> ⟨1, value⟩
```

### PR #47: first typed `defaultable` policy key

`POLICY_BUDGET_STYLE` adopted:

```text
missing         -> documented default `envelope`
explicit empty  -> fail closed
explicit value  -> validate existing enum values
```

### PR #48: second typed `defaultable` policy key

`POLICY_RISK_STYLE` adopted:

```text
missing         -> documented default `conservative`
explicit empty  -> fail closed
explicit value  -> validate existing enum values
```

The PR also exposed verification-design friction and corrected an earlier overstatement about validation timing.

## What is now established

### 1. Presence-aware lookup is the correct primitive for typed key semantics

For keys where missing and explicit empty have different meaning, `Get` is insufficient because it erases presence information.

Current position:

```text
Lookup
  preserves presence

Get
  remains compatibility behavior
```

Do not remove or globally replace `Get` merely because typed keys now use `Lookup`.

### 2. Two `defaultable` policy keys share one semantic shape

Both implemented keys now follow:

```text
missing local key
  -> repository-owned documented default

explicit empty
  -> invalid unless a key contract explicitly allows it

explicit value
  -> key-specific validation
```

This is enough to establish a repeated semantic pattern.

It is not yet enough to justify a general resolver framework.

### 3. Similarity is not sufficient evidence for immediate abstraction

During PR #48, a generic accessor-selection probe failed while small direct probes worked.

This does not prove that shared resolver logic is wrong.

It does prove that:

- abstraction should not be introduced merely because two code blocks look similar,
- BQN execution/selection details must be verified rather than assumed,
- test-helper abstraction and runtime semantic abstraction are separate decisions.

### 4. Validation timing is not yet a settled global contract

An earlier explanation overstated explicit-empty failure as a `LoadConfig`-time contract.

The follow-up investigation corrected that claim and recorded accessor-invocation failure behavior instead.

Checkpoint conclusion:

> Do not standardize all config validation as load-time or accessor-time yet.

Before choosing one model, inspect:

1. which consumers invoke each accessor,
2. whether invalid unused config must fail globally,
3. whether warnings or derived namespace fields trigger access indirectly,
4. whether a future effective-config object changes the timing boundary.

### 5. Exit behavior and message text are different contract strengths

Current tests are not uniform:

- `POLICY_BUDGET_STYLE` has an error-message assertion,
- `POLICY_RISK_STYLE` currently has the fail-closed exit contract fixed without requiring exact message text.

Checkpoint conclusion:

> Exit status is the minimum negative contract. Exact text is a stronger interface and should be fixed only when a consumer or operator workflow depends on it.

Do not mechanically copy exact-message assertions to every config error.

## Checkpoint decisions

### Decision 1: shared resolver logic

**Decision: do not introduce a shared enum/default resolver yet.**

Reason:

- only two runtime keys currently demonstrate the pattern,
- the semantic pattern is real but abstraction pressure is still modest,
- PR #48 showed that apparently simple generalization can create verification friction,
- the next useful evidence comes from a different class, `optional`, not a third copy of `defaultable`.

Allowed later reconsideration trigger:

- a third implementation repeats the same logic with no meaningful semantic difference,
- or duplicated logic produces a concrete defect or drift,
- or tests demonstrate a stable BQN abstraction with clearer ownership.

### Decision 2: validation timing

**Decision: do not globally standardize validation timing yet.**

For now:

- preserve each approved accessor contract,
- test the actual invocation boundary,
- document timing where it becomes externally meaningful,
- do not infer load-time validation from namespace construction shape alone.

A later centralized effective-config object may reopen this decision.

### Decision 3: error/output contract

**Decision: treat non-zero exit as the minimum fail-closed contract.**

Exact message text is required only when explicitly justified.

Guideline:

```text
negative semantic contract
  -> exit status / fail closed

operator-facing stable interface
  -> optionally assert message fragment
```

Avoid making punctuation or incidental wording a repository-wide compatibility surface.

## What is intentionally not decided

This checkpoint does not decide:

- complete effective-config overlay implementation,
- global eager validation,
- global lazy validation,
- duplicate-key runtime handling,
- global unknown-key errors,
- `HOUSEHOLD_GROUP_ORDER` ownership,
- `BUDGET_*` ownership or cleanup,
- UI config split,
- physical `policy.tsv` / `ui.tsv` split,
- external live-config migration,
- fixture mass cleanup.

## Recommended next evidence slice

The next candidate should test a different runtime class rather than copy the same `defaultable` pattern again.

Preferred candidate:

```text
POLICY_INCOME_CADENCE
  class: optional
```

Current classification says:

```text
missing        -> absent / disabled / unavailable
explicit empty -> disabled only where documented
```

Before implementation, the next slice should first answer:

1. Is missing distinct from explicit empty for this key in desired semantics?
2. Does explicit empty mean `disabled`, `unspecified`, or merely legacy compatibility?
3. Should an invalid non-empty value fail when the accessor is invoked?
4. Is the current warning on missing part of the desired contract?
5. Which consumers depend on empty string specifically?

Recommended order:

```text
focused investigation
  -> optional-key decision
  -> negative/compatibility tests
  -> one-key runtime slice only after approval
```

## Compatibility boundary

Continue preserving:

- existing full-ish public sandbox config,
- existing full-ish external live config without rewrite,
- no automatic live-config editing,
- extra UI-owned keys in shared config must not break application resolution,
- no fixture mass cleanup bundled with semantic change,
- no public copying of external live values.

## A4 state after this checkpoint

A4 remains open.

Completed evidence:

- current behavior characterized,
- key classes decided,
- missing vs explicit empty observed,
- current `Required` failure characterized,
- presence-aware lookup added,
- two `defaultable` policy keys typed and verified,
- validation-timing overstatement corrected,
- shared-resolver / timing / error-contract checkpoint recorded.

Next work should gather evidence for `optional` semantics before another runtime change.
