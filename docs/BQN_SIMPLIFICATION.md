# BQN simplification

Status: current

## Purpose

Make the accounting question visible through BQN's own data model and composition, and remove machinery that does not protect user-visible meaning.

A successful BQN simplification may be dense. Readability in this repository is not measured by resemblance to procedural code or by the number of named intermediate steps. A kernel is readable when its axes, cells, rank/depth relationships, transformations, and protected contracts can be understood as one coherent BQN expression.

## BQN-native, not merely array-native

**Array-native is a floor, not the target. BQN-native is the target.**

Replacing loops with masks, aligned columns, classification, Group, Pivot, or reduction is often a good first move, but it is not automatically the end of the design. A generic array/group-by pipeline can be written naturally in many languages. Before declaring a kernel simplified, ask whether BQN's own semantics offer a more revealing formulation through:

- leading-axis and major-cell structure;
- Cells, Rank, nested Depth, or Table;
- based arrays and fill behavior;
- structural transforms and axis reordering;
- modifiers that encode the operated cell/rank instead of index plumbing;
- trains, bindings, and right-to-left composition;
- Under, Scan, Group, and reduction as parts of one structural transformation rather than isolated loop replacements.

Use this warning test: if the design could be translated almost mechanically into a generic dataframe/group-by pipeline, k/q-style keyed grouping, or ordinary loops over columns without reconsidering its structure, scan the BQN capability map again before stopping.

This is not a requirement to be unlike k, q, APL, J, SQL, or any other language. Shared mathematical ideas are expected. Do not add glyphs for distinctiveness. A simple `⊐` → `⊔` relation may be the most BQN-native answer when it exposes the semantic coordinate directly. The requirement is to derive the implementation from BQN's shapes, cells, ranks, depth, fills, and composition model rather than merely transliterating a language-agnostic algorithm.

BQN-native also does not mean erasing domain boundaries. Exact arithmetic, diagnostics, admission, identity, provenance, publication, effects, and writer authority should remain explicitly named when those names protect meaning.

## Normal entrance

For ordinary BQN code work, read only:

1. `docs/ARCHITECTURE.md`;
2. `docs/BQN_CAPABILITY_MAP.md` in full;
3. this file;
4. the target owner and its focused tests.

The capability map is a mandatory memory refresh for BQN code changes, not a requirement to use more glyphs or produce an audit. Read a specialized contract only when the change touches that boundary. Use Git history when historical context is needed; the current tree is current instruction.

## Protect

- public accounting values and exact arithmetic;
- observable ordering and required provenance;
- public source admission, rejection, and diagnostics;
- public commands and output bytes when a change claims meaning preservation;
- fill, empty-cell, missing-coordinate, and unavailable/error shapes that are part of the public result.

## Free to change

- module boundaries and internal ownership splits when all consumers move together;
- intermediate namespaces, stages, local names, and publication construction;
- internal representations and staging that do not protect a capability contract or an exact-operation result;
- loops, repeated masks, wrappers, helpers, and tests that only pin implementation shape;
- single-use mechanical names that merely spell out a direct composition;
- verbose forms introduced only to resemble conventional non-array-language code.

## Separate capability boundaries from BQN kernels

Purity does not identify a function's role. A pure accounting owner may contain a capability boundary that admits request coordinates, checks cross-source compatibility, distinguishes success, unavailable, and error results, converts exact-arithmetic failures into public diagnostics, or assembles identity and provenance. Do not classify every pure function in `src/accounting/` as a BQN kernel.

Ledger admission owns source-internal invariants such as canonical Fact shape, source provenance, and admitted references. A shallow capability boundary owns request-specific and cross-source contracts such as selected mode, period order, requested domain or layer, and compatibility between independently admitted sources.

Inside the successful path, a bounded BQN kernel should receive admitted, aligned inputs and perform the direct structural transformation. It must not repeat source validation, perform property-by-property defensive Record checks, or hide the transformation behind a ladder of nested predicate blocks. When guards dominate an owner, split the shallow capability boundary from the successful kernel rather than deleting public contract checks.

This rule prohibits defensive control-flow nesting that obscures semantic axes. It does not prohibit nested arrays, ragged contributor or evidence cells, depth-sensitive operations, or other structures that honestly represent the data.

Exact arithmetic must be checked at the exact operation that can fail. The surrounding capability boundary owns conversion of that failure into the public diagnostic and result shape; an earlier source-admission boundary cannot pre-admit every later normalization or grouped sum.

## Preferred form

Prefer:

- shapes, cells, axes, coordinates, aligned arrays, and explicit nested structure over row objects;
- classify, Group, Pivot, Cells, Rank, Depth, Table, Transpose, Under, Scan, reduction, trains, and modifier composition when they state the question directly;
- a dense BQN kernel when it keeps classification, structural transformation, cell/rank behavior, and aggregation in one visual field;
- one shallow capability boundary, one bounded BQN kernel, and one publication boundary when those roles are present;
- updating all affected consumers in the same coherent slice and deleting the old path;
- net deletion of production machinery, shallower control-flow nesting, fewer whole-evidence scans, and fewer accidental intermediate representations.

A train, partially tacit expression, modifier composition, rank/cell/depth expression, or structural view is not a last resort. Use it when it exposes the dataflow or acted-on structure more directly than a ladder of assignments. Do not expand it solely because a conventional-language reader might prefer named steps.

A simplification that adds production code must explain what irreducible contract required the increase. Line count is evidence, not the definition of simplicity: a slightly longer expression may be better when it makes BQN's structural view explicit, while a much longer procedural translation is not better merely because every step has a name.

## Density and comments

Keep names at semantic boundaries:

- source admission and canonical Facts;
- accounting concepts and public result columns;
- exact-arithmetic and diagnostic boundaries;
- identity, contributor, and provenance publication;
- I/O, mutation, and write authority.

Inside a bounded BQN kernel, inline or compose mechanical steps that are used once and do not carry independent accounting meaning. The goal is not maximum tacitness. The goal is to remove scaffolding until the BQN relationship is visible.

Use a short contract comment before a dense kernel when needed:

```bqn
# e: Envelope Accounts in canonical Account order
# x: expense Accounts; p: open Plan rows
# x→e preserves Account-first contributors; p→e preserves Plan source order
# Group coordinates retain trailing empty e cells
```

Comments should state axes, shapes, rank/depth/cell interpretation, ordering, fill, empty behavior, exactness, and accounting invariants. Do not translate the code into prose line by line:

```bqn
# Avoid: "create coordinates", "group values", "sum groups"
```

Tests should protect the contract named by the comment, not force the temporary names or line layout used by one implementation.

## Procedural shape versus BQN-native shape

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

A first array-native improvement is often one classification and aligned grouping:

```bqn
coordinates ← items⊐evidence.keys
cells ← (coordinates∾⟨≠items⟩)⊔evidence.values
Publish items‿ExactSum¨cells
```

That is preferred to the row loop because the relationship axis is visible. But do not assume the second form is automatically finished. Ask next whether `cells` are really major cells, nested evidence cells, a rank-specific view, or one side of a Table; whether publication can be a train or aligned cell operation; whether fill or based-array behavior removes a special case; and whether a structural transform makes the whole relation clearer.

The BQN-native endpoint may remain the simple classification/Group form. The important point is that the second question was asked and the final representation follows BQN's data model rather than stopping at a generic group-by template.

## When staging is justified

Use explicit staged code when a named role protects:

- fail-closed source admission before canonical Facts are published;
- request-coordinate or cross-source admission at a shallow capability boundary;
- exact arithmetic at the normalization, sum, or dependent operation that can fail, plus conversion of that failure into public diagnostics;
- success, unavailable, and error result selection;
- identity or provenance construction;
- effects, publication buffering, or write safety;
- a complicated expression whose axes/cells/rank/depth cannot be recovered from code plus a concise contract comment.

Staging is not forbidden by directory or by purity. It becomes suspect when repeated source validation, defensive Record checks, or a guard ladder buries the successful BQN transformation. Split that wrapper from the bounded kernel. Do not flatten nested arrays or ragged evidence merely to satisfy a control-flow rule.

Do not use staging as a universal readability policy. Unfamiliar BQN is a reason to consult the reference and test a probe, not a reason to translate the kernel back into ordinary loops and temporary records.

## Retrospective policy

A stronger BQN-native rule does **not** invalidate every previously reviewed owner.

Do not reopen ownership, admission, exact-arithmetic, identity, provenance, writer-safety, or publication changes merely because they were made under an earlier array-native vocabulary. Those boundaries are not judged by how many BQN structural features they expose.

Previously closed **algorithmic kernels** should receive a later focused BQN-native retrospective only when there is evidence that the review stopped at a language-agnostic array shape. Good triggers include:

- the final kernel is mostly classify/group/reduce but rank/cell/depth/fill/structural alternatives were never considered;
- row-to-column conversion removed loops but left mechanical column plumbing that BQN composition may subsume;
- explicit index traversal remains where Cells, Rank, Table, Group, Under, Scan, or structural transforms may express the same relationship;
- the closeout claims "array-native" as the endpoint without explaining why the chosen representation is natural in BQN.

Do not reopen an owner solely because another language could express the same mathematics. The retrospective asks whether BQN has more to contribute to the representation, not whether the algorithm is unique to BQN.

Keep this retrospective separate from the current checked owner queue so the queue does not churn backward. Record concrete candidates and revisit them as a cross-cutting BQN-native pass after the current accounting review inventory, unless a current owner directly depends on the questionable representation.

## Workflow

- Start from input and output shape, semantic axes, rank/depth/cells, fill and empty behavior, contributor alignment, and observable ordering before choosing syntax.
- Scan every capability family in `docs/BQN_CAPABILITY_MAP.md`; select the features that expose the problem most directly, including dense composition where appropriate.
- Ask whether a chain of single-use names can become one train, modifier composition, rank/cell/depth expression, structural transform, classification, or grouped reduction.
- After reaching an array-native form, perform the BQN-native warning check before stopping.
- Use an executable CBQN probe and the official reference when rank, depth, fill, grouping, modifier, train, monadic/dyadic, or empty-array behavior is uncertain.
- A coherent slice may span an owner and all of its consumers. It is not required to fit in one file.
- Create characterization only for behavior that is public, ambiguous, or genuinely at risk. Do not create a test-only PR by default.
- Keep an actual correctness decision separate from a meaning-preserving rewrite. Do not split one representation replacement into ceremonial stages.
- Algorithm-only changes do not require README, TODO, architecture, catalog, or audit updates.
- Run focused evidence, full `tools/check.sh`, coverage, and final current-main review before merge.

Do not replace deleted machinery with compatibility aliases, forwarding modules, utility bags, universal contexts, or a new generic framework.
