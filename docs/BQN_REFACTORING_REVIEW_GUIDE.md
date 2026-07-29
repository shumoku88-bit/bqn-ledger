# BQN Refactoring Review Guide

Status: proposed review gate for bounded BQN refactors

## Purpose

This guide gives each BQN refactor a stable review method. It is not a code-golf rule and does not require one personal style across the repository.

The goal is:

> make the data transformation more visible while preserving accounting meaning, ownership, diagnostics, provenance, and fail-closed behavior.

Use this guide for small refactors in `src/`, `src_edit/`, retained shared owners, and their focused tests. Correctness changes and ownership migration remain separate slices.

## Hard gates

A refactor is not acceptable unless all applicable gates pass.

1. **Finite question**: one bounded transformation or ownership question is stated before editing.
2. **Meaning preservation**: observable values, ordering, diagnostics, provenance, exact arithmetic, and rejection behavior are unchanged unless a separate correctness slice explicitly authorizes a change.
3. **Owner preservation**: shortening must not create a utility bag, forwarding wrapper, universal context, or new hidden policy owner.
4. **Evaluation preservation**: an unselected branch, formatter, parser, or expensive calculation must not become eagerly evaluated.
5. **Edge evidence**: applicable empty, nested, not-found, duplicate, boundary, and malformed-input behavior is characterized.
6. **Focused scope**: the implementation and its focused tests form one coherent slice.
7. **Full verification**: focused tests, `tools/check.sh`, coverage, and final patch review pass against current `main`.

Line count is evidence, not a gate. A shorter program that hides a contract is worse.

## Review lenses

Record `green`, `improve`, `blocked`, or `not-applicable` for each applicable lens. Add concrete evidence, not admiration of a person or style.

### Marshall Lochbaum: expose the array transformation

Ask:

- Can repeated scans, mutable accumulation, or branch ladders become one visible primitive or coordinate transformation?
- Are input shape, intermediate coordinate, and output shape apparent?
- Is a first-class function selected before it is executed?
- Is the chosen BQN primitive the direct owner of the operation?

Good evidence includes `index-of` for exact lookup, `Deduplicate` for major-cell uniqueness, classify/group keys, masks, selections, and aligned function arrays.

Do not compress strict admission merely because it contains repeated diagnostic steps.

### Roger Hui: prove the semantic edges

Ask:

- What happens for empty input?
- What is the not-found value, and is it safe before selection?
- Are nested major cells compared with the intended equality?
- Are rank, scalar-versus-list, ordering, and duplicate semantics preserved?
- Are arithmetic and comparisons exact where the accounting contract requires exactness?

A primitive replacement is incomplete until its edge semantics are tested.

### John Scholes: keep the declaration readable

Ask:

- Does each named function express one purpose?
- Are meaningful stages such as admission, coordinate resolution, grouping, and publication still visible?
- Did shortening remove an incidental temporary, or did it erase a useful domain boundary?
- Can the function be read as a declaration of the result rather than a sequence of mutations?

Keep names where they carry accounting or application meaning. Shorten the kernel inside the named boundary.

### Adám Brudzewsky: leave a derivation path

Ask:

- Can a future reader see how the final idiom follows from the previous procedural form?
- Does one short comment explain the primitive's important contract rather than narrating syntax?
- Do focused tests show representative intermediate coordinates or selected indices?
- Is the before/after algorithm described in the PR body?

The final code may be compact. The review evidence should preserve the staircase used to reach it.

### Aaron Hsu: consider whole-array dataflow

Ask only for substantial pure kernels:

- Is the code repeatedly scanning all postings for every row, account, date, or cell?
- Can coordinates or lanes be encoded once and grouped, classified, or scattered in one pass?
- Can branch state become an aligned array rather than per-item control flow?
- Does the new dataflow remain deterministic and auditable?

This lens is usually `not-applicable` for small admission functions, I/O boundaries, and editor safety orchestration.

### Kenneth Iverson: judge whether notation reveals structure

Ask:

- Does the new expression show the structure of the accounting or reporting question more directly?
- Are incidental mechanics subordinated without hiding essential meaning?
- Does the notation suggest valid tests and further deductions?
- Is the result easier to verify formally or by focused examples?

The final decision is not “is this clever?” but “does this notation make the problem clearer?”

### Arthur Whitney: use extreme brevity as a probe

Ask:

- Is there a much smaller computational kernel hiding inside the current procedure?
- Which parts are essential contracts, and which are scaffolding?
- Would the extremely short form remain maintainable and diagnostically complete here?

This is a probe, not an acceptance criterion. Reject compression that depends on unstated assumptions or removes evidence needed by humans, tests, or future automated changes.

## Standard review sequence

### 1. State the finite question

Use one sentence:

> Can `<current procedural form>` become `<array-native form>` while preserving `<named contracts>`?

### 2. Freeze the contract

List the exact properties that cannot change. Include relevant ordering, empty behavior, diagnostics, provenance, arithmetic, output bytes, and evaluation behavior.

### 3. Write the array model before the final expression

Record:

```text
input cells / columns
→ coordinate, mask, classification, group, or selected function
→ output cells / columns
```

If this cannot be stated clearly, the slice is not ready for compression.

### 4. Characterize semantic edges

Add focused evidence for the applicable cases:

- empty
- unknown / not found
- nested cell
- non-adjacent duplicate
- invalid rank or shape
- boundary index
- eager versus conditional evaluation
- exact arithmetic failure

### 5. Implement the smallest coherent change

Prefer direct primitives over a new generic helper. Extract a shared owner only after multiple real consumers prove the same semantics.

### 6. Review with the lenses

Use the compact record below.

```markdown
## BQN refactor lenses

- Marshall: green — <visible array transformation>
- Hui: green — <edge semantics and tests>
- Scholes: green — <names and boundaries retained>
- Adám: green — <derivation/comment/test evidence>
- Aaron: not-applicable — <why>
- Iverson: green — <problem structure made clearer>
- Whitney: green — <compression considered without deleting contracts>
```

### 7. Decide

- **accept**: all hard gates pass and the notation reveals the transformation more directly.
- **revise**: meaning is preserved, but shape, naming, tests, or explanation remain unclear.
- **reject**: the change hides a contract, widens ownership, mixes correctness with refactoring, or depends on untested BQN behavior.

## Pull request evidence template

```markdown
## Finite question

Can ...?

## Before

<procedural stages>

## Array model

<input> → <coordinate/mask/group/function> → <output>

## Change

- ...

## Preserved contracts

- ...

## Edge evidence

- empty: ...
- not found: ...
- nested / duplicate: ...
- evaluation order: ...

## BQN refactor lenses

- Marshall: ...
- Hui: ...
- Scholes: ...
- Adám: ...
- Aaron: ...
- Iverson: ...
- Whitney: ...

## Verification

- [ ] focused test
- [ ] full `tools/check.sh`
- [ ] coverage
- [ ] current-main integration
- [ ] final bounded patch review
```

## Current examples

| PR | Kernel | Primary lenses | Important evidence |
|---|---|---|---|
| #437 | catalog exact lookup | Marshall, Hui | index-of absent bound; successful branch conditionally executed |
| #438 | request surface support | Marshall, Scholes | surface and catalog coordinates reused; diagnostic contract retained |
| #439 | renderer dispatch | Marshall, Hui, Adám | formatter selected as a value; BQN subject/function role failure recorded and corrected; all 17 routes golden-tested |
| #440 | MatrixResult axis uniqueness | Marshall, Hui, Iverson | native major-cell Deduplicate; empty and nested non-adjacent duplicate evidence |

These examples are not a permanent preferred syntax. They demonstrate the review method.

## Repository-specific stop signs

Do not use this guide to justify:

- removing or reordering diagnostics without a correctness decision
- weakening strict source admission
- flattening multi-posting or provenance evidence
- replacing exact arithmetic with convenient numeric arithmetic
- adding a universal report, editor, source, or accounting record
- adding compatibility aliases, forwarding modules, fallback parsing, or duplicate routes
- combining editor ownership migration with accounting algorithm changes
- editing private household sources without separate explicit authorization

A good BQN refactor makes the computational crystal clearer without sanding away the ledger's evidence.
