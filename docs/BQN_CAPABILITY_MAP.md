# BQN capability map

Status: current

## Purpose

This is a compact memory surface for humans and coding agents. Read it before creating or changing BQN code so that a familiar procedural formulation does not hide a more direct BQN expression.

Dense classical array-language style is a first-class production option. A train, modifier composition, rank/cell expression, or partially tacit kernel should not be treated as an exotic final optimization when it states the whole transformation more directly. Compactness is acceptable when semantic axes and protected contracts remain recoverable from the code, boundary names, comments, and tests.

This is not a glyph quota. A feature belongs in production when it makes the data shape, accounting question, or protected boundary clearer. Familiarity with conventional procedural syntax is not itself a clarity criterion.

## BQN-native, not merely array-native

**Array-native is a floor, not the target. BQN-native is the target.**

Turning loops into masks, classifications, columns, Group, or reductions is useful, but a generic array/group-by design can still stop before the language has contributed much. Before settling on such a formulation, ask whether BQN's own data model and composition vocabulary expose the problem more directly:

- leading-axis and major-cell structure;
- rank, Cells, nested depth, and based arrays;
- fill and empty-cell behavior;
- structural transforms and axis reordering;
- modifiers that make the operated cell/rank explicit;
- trains, bindings, and right-to-left composition that remove mechanical plumbing;
- Group, Table, Under, Scan, and other primitives as parts of a larger BQN expression rather than isolated replacements for loops.

A useful warning question is: **could this design be translated almost mechanically into a generic dataframe/group-by pipeline, k/q-style key grouping, or ordinary loops over columns without reconsidering its structure?** If yes, scan the BQN capability surface again before declaring the kernel finished.

This is not a distinctiveness contest. Do not add a train, Rank, Depth, Table, Under, or another glyph merely to make code look unlike k, q, J, APL, SQL, or a conventional language. If `⊐` followed by `⊔` is genuinely the clearest BQN expression, use it. The requirement is that the design has been derived from BQN's shapes, cells, ranks, depth, fills, and composition model rather than stopping at a language-agnostic algorithm expressed with BQN syntax.

BQN-native also does not mean flattening every domain boundary into a dense kernel. Keep accounting names, exact-arithmetic failures, diagnostics, identity, provenance, admission, publication, effects, and write authority explicit when those names protect meaning.

Primary references:

- BQN documentation: https://mlochbaum.github.io/BQN/doc/index.html
- primitive reference: https://mlochbaum.github.io/BQN/doc/primitive.html
- syntax overview: https://mlochbaum.github.io/BQN/doc/syntax.html
- language specification: https://mlochbaum.github.io/BQN/spec/index.html
- BQN–Dyalog APL dictionary: https://mlochbaum.github.io/BQN/doc/fromDyalog.html
- BQN–J dictionary: https://mlochbaum.github.io/BQN/doc/fromJ.html

## Start from shape

Before selecting syntax, identify:

- the input rank, shape, fill, and nested depth;
- the semantic axes and their observable order;
- which axes are selected, classified, grouped, reduced, scanned, or preserved;
- the desired output rank and public empty-cell behavior;
- which evidence columns must remain aligned, including contributors and provenance.

Try to turn a loop variable into an axis or coordinate before translating the loop into BQN punctuation. Then ask whether the resulting axis transformation can be seen as one composition rather than a sequence of temporary assignments. Do not stop merely because the result is now an array expression; ask whether its cell/rank/depth structure and composition are the natural BQN view of the problem.

## Classical array-language composition

Classical APL style is useful here as a way of seeing the whole array relationship at once. Re-derive the expression in BQN rather than transliterating glyph for glyph, but keep these principles active:

- right-to-left dataflow can replace imperative chronology;
- trains and modifier composition can expose a transformation without naming every wire between functions;
- Cells, Rank, Depth, Table, structural transforms, grouping, and reduction can make axes executable rather than descriptive;
- tacit or partially tacit code is acceptable inside a bounded pure kernel;
- a one-screen composition may be clearer than many individually obvious lines whose overall relationship is hard to see;
- comments may carry the axis legend, ordering, fill, and invariant contract while the code remains dense.

Preserve names where they carry accounting meaning or mark admission, exactness, diagnostics, identity, provenance, publication, effects, or write authority. Do not preserve a local name merely because the corresponding subexpression might be unfamiliar.

Density is not code golf. Reject a compact form when it hides semantic axes, changes edge shapes, obscures a failure boundary, or makes the protected contract unverifiable. Do not reject it merely because it requires BQN fluency.

## Complete primitive-function recall

The following groups contain every primitive function glyph. Remember both monadic and dyadic meanings.

| Family | Glyphs | Questions to ask |
| --- | --- | --- |
| Arithmetic, comparison, logic, ordering | <code>+ - × ÷ ⋆ √ ⌊ ⌈ &#124; ¬ ∧ ∨ < > ≠ = ≤ ≥</code> | Can pervasive scalar work stay aligned? Can grade, min/max, boolean masks, or span state the rule directly? |
| Shape and structure tests | `≡ ≢` | Is the question about depth, match, rank, length, shape, or non-match rather than explicit traversal? |
| Identity and structural transformation | `⊣ ⊢ ⥊ ∾ ≍ ⋈ ↑ ↓ ↕ « » ⌽ ⍉` | Can reshape, joining, prefixes, windows, shifting, rotation, or axis reordering expose the intended view? |
| Selection, search, classification, grouping | `/ ⍋ ⍒ ⊏ ⊑ ⊐ ⊒ ∊ ⍷ ⊔` | Can indices, grade/bins, select/pick, classify, occurrence counts, membership, find, deduplicate, or Group replace repeated masks and rescans? |
| Assertion | `!` | Is this an admitted invariant that should fail at the boundary rather than become control-flow scaffolding? |

Canonical complete function string:

```text
+-×÷⋆√⌊⌈|¬∧∨<>≠=≤≥≡≢⊣⊢⥊∾≍⋈↑↓↕«»⌽⍉/⍋⍒⊏⊑⊐⊒∊⍷⊔!
```

## Complete primitive-modifier recall

The following groups contain every primitive modifier glyph.

| Family | Glyphs | Questions to ask |
| --- | --- | --- |
| Composition and dispatch | `˙ ˜ ∘ ○ ⊸ ⟜ ⊘ ◶ ⎊` | Can a train, binding, valence split, function choice, or narrow catch replace staged plumbing and expose the complete dataflow? |
| Cells, elements, products, rank, depth | `˘ ¨ ⌜ ⎉ ⚇` | Is the operation aligned by element, major cell, arbitrary rank, nested depth, or every pair of two axes? Can the axis live in the modifier rather than in an index loop? |
| Reversible views and updates | `⁼ ⌾` | Is the code taking a view, transforming it, and reconstructing the original shape? |
| Reduction and iteration | <code>´ ˝ &#96; ⍟</code> | Is this a fold, insertion across an axis, scan, reversible operation, or repeated function rather than explicit state mutation? |

Canonical complete modifier strings:

```text
1-modifiers: ˙˜˘¨⌜⁼´˝`
2-modifiers: ∘○⊸⟜⌾⊘◶⎉⚇⍟⎊
```

## Language capabilities beyond primitive glyphs

Remember these before inventing helpers or control structures:

- functions apply right-to-left; modifiers bind left-to-right; trains compose functions without intermediate names;
- `⟨⟩`, `[]`, and `‿` express lists, arrays, and strands with different structural roles;
- based arrays, fill elements, leading-axis behavior, major cells, rank, and nested depth are separate dimensions of the data model;
- blocks can be immediate values, functions, 1-modifiers, or 2-modifiers and may use multiple bodies and predicates;
- `𝕨 𝕩 𝕗 𝕘 𝕤` and their function-role forms expose arguments, operands, and self-reference directly;
- `←`, `↩`, and `⇐` define, modify, and export; namespaces should normally be publication boundaries rather than row containers inside a kernel;
- recursion and block control flow remain available when the problem is genuinely sequential or failure-staged;
- system values provide implementation-dependent I/O, formatting, timing, importing, debugging, and other effects; verify support in the active CBQN version before relying on one;
- an APL or J idiom is a useful candidate prompt, not a transliteration recipe: consult the official dictionaries, then re-derive the expression using BQN's based arrays, syntactic roles, fills, and leading-axis model;
- comments can state semantic axes and invariants without forcing the implementation into a verbose narrative form.

## Problem-shape prompts

Scan these prompts before preserving an existing implementation shape:

1. Can row namespaces become aligned columns?
2. Can a loop index become an explicit axis or coordinate?
3. Can repeated masks become one `⊐` classification followed by `⊔` Group?
4. Can index-driven mapping become `¨`, `˘`, `⎉`, `⚇`, or aligned dyadic Each?
5. Can a nested pair of loops become `⌜` Table?
6. Can append mutation become Group, Fold, Insert, Scan, Reshape, or Join?
7. Can sorting plus repeated lookup become Grade, Bins, Index Of, Progressive Index Of, Member Of, or Find?
8. Can extract-transform-rebuild become Under or Undo?
9. Can hand-built matrix traversal become Transpose, Reorder Axes, Cells, Rank, or leading-axis selection?
10. Can branching be represented as masks, selection, Choose, or Valences without hiding diagnostics?
11. Can a temporary helper disappear into a train or modifier composition while keeping the accounting question readable?
12. Can a chain of single-use local names become one right-to-left composition whose axes remain visible?
13. Can a concise contract comment carry axis, order, fill, and invariant information that should not be encoded as procedural scaffolding?
14. Would partially tacit code show the stable transformation more clearly while retaining names only at semantic boundaries?
15. Is explicit staged code genuinely required by effects, dependent failure, exact arithmetic, diagnostics, identity, provenance, or write safety?
16. After becoming array-native, is the kernel still only a generic classify/group/reduce pipeline, or have BQN's cell/rank/depth/fill/structural semantics been considered?
17. Does a modifier, structural transform, train, or based-array view reveal a relationship that named column plumbing still hides?

## Repository use

For a BQN change:

1. read this whole page, `docs/BQN_SIMPLIFICATION.md`, the target owner, and focused evidence;
2. describe the transformation in terms of input shape, axes, coordinates, rank/depth/cells, fill, and output shape;
3. consider every capability family above, including trains and dense composition, then select the expression that fits;
4. perform the BQN-native warning check: do not stop at a language-agnostic group-by/column algorithm without reconsidering BQN's own structural model;
5. preserve public meaning and delete the replaced procedural path in the same coherent slice;
6. retain names at semantic boundaries, but do not require names for every mechanical intermediate;
7. use small executable CBQN probes when rank, fill, grouping, modifier, train, or empty-array behavior is uncertain;
8. open the official reference instead of guessing when a primitive, modifier, monadic/dyadic meaning, fill rule, or rank behavior is not active in memory.

Explain the axis/cell model and protected contract in the PR when it clarifies the change. A PR does not need to defend compactness merely because the code is dense, nor enumerate rejected glyphs as ceremony. Do not create a capability-audit file, primitive-count target, mandatory glyph-coverage report, or cross-language distinctiveness score.
