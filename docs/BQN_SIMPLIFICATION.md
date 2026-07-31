# BQN simplification

Status: current

## Purpose

Make the accounting question visible as an array transformation and remove machinery that does not protect user-visible meaning.

A successful BQN simplification may be dense. Readability in this repository is not measured by resemblance to procedural code or by the number of named intermediate steps. A kernel is readable when its axes, transformations, and protected contracts can be understood as one coherent array expression.

## Normal entrance

For ordinary BQN code work, read only:

1. `docs/ARCHITECTURE.md`;
2. `docs/BQN_CAPABILITY_MAP.md` in full;
3. this file;
4. the target owner and its focused tests.

The capability map is a mandatory memory refresh for BQN code changes, not a requirement to use more glyphs or produce an audit. Read a specialized contract only when the change touches that boundary. `docs/archive/` is historical evidence, never current instruction.

## Protect

- public accounting values and exact arithmetic;
- observable ordering and required provenance;
- public source admission, rejection, and diagnostics;
- public commands and output bytes when a change claims meaning preservation;
- fill, empty-cell, missing-coordinate, and unavailable/error shapes that are part of the public result.

## Free to change

- module boundaries and internal ownership splits when all consumers move together;
- intermediate namespaces, stages, local names, and publication construction;
- internal representations and diagnostic staging inside a pure kernel;
- loops, repeated masks, wrappers, helpers, and tests that only pin implementation shape;
- single-use mechanical names that merely spell out a direct composition;
- verbose forms introduced only to resemble conventional non-array-language code.

## Preferred form

Prefer:

- columns, axes, coordinates, and aligned arrays over row objects;
- classify, Group, Pivot, Cells, Rank, Table, Transpose, Under, Scan, reduction, trains, and modifier composition when they state the question directly;
- a dense classical array-language kernel when it keeps classification, structural transformation, and aggregation in one visual field;
- one admission boundary, one array kernel, and one publication boundary;
- updating all affected consumers in the same coherent slice and deleting the old path;
- net deletion of production machinery, shallower nesting, fewer whole-evidence scans, and fewer accidental intermediate representations.

A train, partially tacit expression, modifier composition, or rank/cell expression is not a last resort. Use it when it exposes the dataflow more directly than a ladder of assignments. Do not expand it solely because a conventional-language reader might prefer named steps.

A simplification that adds production code must explain what irreducible contract required the increase. Line count is evidence, not the definition of simplicity: a slightly longer expression may be better when it makes axes explicit, while a much longer procedural translation is not better merely because every step has a name.

## Density and comments

Keep names at semantic boundaries:

- source admission and canonical Facts;
- accounting concepts and public result columns;
- exact-arithmetic and diagnostic boundaries;
- identity, contributor, and provenance publication;
- I/O, mutation, and write authority.

Inside a bounded pure kernel, inline or compose mechanical steps that are used once and do not carry independent accounting meaning. The goal is not maximum tacitness. The goal is to remove scaffolding until the array relationship is visible.

Use a short contract comment before a dense kernel when needed:

```bqn
# e: Envelope Accounts in canonical Account order
# x: expense Accounts; p: open Plan rows
# x→e preserves Account-first contributors; p→e preserves Plan source order
# Group coordinates retain trailing empty e cells
```

Comments should state axes, shapes, ordering, fill, empty behavior, exactness, and accounting invariants. Do not translate the code into prose line by line:

```bqn
# Avoid: "create coordinates", "group values", "sum groups"
```

Tests should protect the contract named by the comment, not force the temporary names or line layout used by one implementation.

## Procedural shape versus array shape

A procedural-shaped BQN kernel often looks like this:

```bqn
rows ← ⟨⟩
{𝕊 item:
  mask ← item Matches¨ evidence
  values ← mask/evidence.values
  rows ∾↩ ⟨BuildRow item‿values⟩
}¨items
PublishRows rows
```

The preferred question is whether the same work is one classification and aligned grouping:

```bqn
coordinates ← items⊐evidence.keys
cells ← (coordinates∾⟨≠items⟩)⊔evidence.values
Publish items‿ExactSum¨cells
```

The second form is preferred because the mathematical structure is visible, not merely because it is shorter. It may be compressed further when a train or modifier composition makes the same structure clearer. Preserve an intermediate name only when it identifies an axis, accounting concept, protected boundary, reused result, or genuinely clarifying subexpression.

## When staging is justified

Use explicit staged code when the problem is genuinely sequential or when a named boundary protects:

- fail-closed admission before unsafe selection;
- dependent exact-arithmetic diagnostics;
- identity or provenance construction;
- effects, publication buffering, or write safety;
- a complicated expression whose axes cannot be recovered from code plus a concise contract comment.

Do not use staging as a universal readability policy. Unfamiliar BQN is a reason to consult the reference and test a probe, not a reason to translate the kernel back into ordinary loops and temporary records.

## Workflow

- Start from input and output shape, semantic axes, fill and empty behavior, contributor alignment, and observable ordering before choosing syntax.
- Scan every capability family in `docs/BQN_CAPABILITY_MAP.md`; select the features that expose the problem most directly, including dense composition where appropriate.
- Ask whether a chain of single-use names can become one train, modifier composition, rank/cell expression, structural transform, classification, or grouped reduction.
- Use an executable CBQN probe and the official reference when rank, depth, fill, grouping, modifier, train, monadic/dyadic, or empty-array behavior is uncertain.
- A coherent slice may span an owner and all of its consumers. It is not required to fit in one file.
- Create characterization only for behavior that is public, ambiguous, or genuinely at risk. Do not create a test-only PR by default.
- Keep an actual correctness decision separate from a meaning-preserving rewrite. Do not split one representation replacement into ceremonial stages.
- Algorithm-only changes do not require README, TODO, architecture, catalog, or audit updates.
- Run focused evidence, full `tools/check.sh`, coverage, and final current-main review before merge.

Do not replace deleted machinery with compatibility aliases, forwarding modules, utility bags, universal contexts, or a new generic framework.
