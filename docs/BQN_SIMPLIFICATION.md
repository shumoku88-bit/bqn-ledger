# BQN simplification

Status: current

## Purpose

Make the accounting question visible as an array transformation and remove machinery that does not protect user-visible meaning.

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
- public commands and output bytes when a change claims meaning preservation.

## Free to change

- module boundaries and internal ownership splits when all consumers move together;
- intermediate namespaces, stages, local names, and publication construction;
- internal representations and diagnostic staging inside a pure kernel;
- loops, repeated masks, wrappers, helpers, and tests that only pin implementation shape.

## Prefer

- columns, axes, coordinates, and aligned arrays over row objects;
- classify, Group, Pivot, Cells, Rank, Table, Transpose, Under, Scan, and reduction when they state the question directly;
- one admission boundary, one array kernel, and one publication boundary;
- updating all affected consumers in the same coherent slice and deleting the old path;
- net deletion of production machinery, shallower nesting, and fewer whole-evidence scans.

A simplification that adds production code must explain what irreducible contract required the increase.

## Workflow

- Start from input and output shape, semantic axes, fill and empty behavior, contributor alignment, and observable ordering before choosing syntax.
- Scan every capability family in `docs/BQN_CAPABILITY_MAP.md`; select only the features that expose the problem more directly.
- Use an executable CBQN probe and the official reference when rank, depth, fill, grouping, modifier, monadic/dyadic, or empty-array behavior is uncertain.
- A coherent slice may span an owner and all of its consumers. It is not required to fit in one file.
- Create characterization only for behavior that is public, ambiguous, or genuinely at risk. Do not create a test-only PR by default.
- Keep an actual correctness decision separate from a meaning-preserving rewrite. Do not split one representation replacement into ceremonial stages.
- Algorithm-only changes do not require README, TODO, architecture, catalog, or audit updates.
- Run focused evidence, full `tools/check.sh`, coverage, and final current-main review before merge.

Do not replace deleted machinery with compatibility aliases, forwarding modules, utility bags, universal contexts, or a new generic framework.
