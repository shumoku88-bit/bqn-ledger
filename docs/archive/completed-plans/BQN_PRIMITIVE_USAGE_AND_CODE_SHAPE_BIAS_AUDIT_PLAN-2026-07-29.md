# BQN primitive usage and code-shape bias audit plan

Status: active investigation plan

Date: 2026-07-29

Baseline main observed before branch creation: `221c4234af615cbf31bb9e22a7600efed58b088c`

Working branch: `docs/bqn-primitive-usage-bias-audit-plan`

## 1. Purpose

This investigation asks two related questions about the current `bqn-ledger` codebase.

1. Why are some BQN primitives and language mechanisms not used in the current implementation?
2. Does the repository as a whole contain a systematic code-shape bias that hides useful array transformations or repeatedly chooses incidental procedural structure?

The purpose is not to maximize primitive coverage, make the code shorter, or turn production code into a language showcase.

The purpose is:

> Preserve accounting meaning, diagnostics, provenance, exact arithmetic, evaluation behavior, editor safety, and ownership while checking whether the code expresses its actual array transformations as directly as it reasonably can.

`bqn-ledger` is broad enough that this question must be examined across the whole system, not only in reports or matrices. The current repository includes Journal parsing, strict admission, canonical Transaction and Posting Facts, accounting capabilities, matrices and pivots, report sections and renderers, application composition, and write-side editor commands.

## 2. Existing related records

This investigation is distinct from the historical `docs/archive/refactor-2026-06/ARRAY_AUDIT.md`.

That document observed the earlier `256×2` balance kernel and its transaction, date, and envelope axes. It remains useful historical evidence, but it does not answer the current repository-wide question about primitive usage and code shape after the canonical Facts and Native Journal migrations.

All later rewrites under this plan must use `docs/BQN_REFACTORING_REVIEW_GUIDE.md` as the review gate.

In particular:

- one finite question per slice
- correctness changes separated from representation or ownership refactors
- explicit preservation of ordering, diagnostics, provenance, exact arithmetic, rejection behavior, output bytes, and evaluation behavior
- focused evidence for empty, nested, not-found, duplicate, boundary, malformed, and conditional-evaluation cases when relevant
- no compression merely because an expression can be shorter

## 3. Initial observation, not yet the final inventory

A preliminary glyph search suggested that the following primitives may be absent from executable BQN code at the observed baseline.

### Primitive function candidates

- `√` Root
- `⊣` Left
- `⊢` Right
- `≍` Solo / Couple
- `⋈` Enlist / Pair
- `»` Shift Before
- `«` Shift After
- `⍉` Transpose / Reorder Axes
- `⍒` Grade Down / Bins Down
- `⊒` Occurrence Count / Progressive Index Of
- `!` Assert, excluding shebang occurrences such as `#!/usr/bin/env bqn`

### Modifier candidates

- `˙` Constant
- `∘` Atop
- `○` Over
- `⟜` After / Bind
- `⊘` Valences
- `⌾` Under
- `˘` Cells
- `⎉` Rank
- `⚇` Depth
- `⌜` Table
- `⁼` Undo
- `˝` Insert

### Custom modifier mechanism candidates

No current use was found for modifier block special names such as:

- `𝔽`, `𝕗`
- `𝔾`, `𝕘`
- `𝕣`

This list is deliberately provisional. A repository search can produce both false positives and false negatives because a glyph may occur in:

- comments or Markdown rather than executable code
- strings, expected output, fixtures, or generated material
- a shebang or shell source
- tests but not production
- archived code but not the current runtime
- code not returned by the search index

The first investigation slice must therefore replace this provisional list with a reproducible inventory over a fixed commit.

## 4. Important counterexamples already observed

The repository already uses several BQN mechanisms that might appear absent if only report code is inspected.

For example, `src/text/parse.bqn` performs bounded text splitting with:

```bqn
groups ← (+` mask) ⊔ 𝕩
```

This combines Scan and Group to derive text groups from separator positions. The parser therefore provides a real system use for an array-language mechanism that would be easy to miss in a report-only audit.

Other mechanisms already observed in current code include:

- Fold and Scan
- Each
- Group
- Deduplicate / Find
- Choose
- Catch
- Repeat
- Self / Swap
- masks, index generation, selection, sorting, reduction, and nested array construction

The audit must search all semantic regions before concluding that a language feature or array idea is missing.

## 5. Why a primitive may be unused

An unused primitive is not automatically a defect. Each absence must be classified rather than judged in advance.

Possible classifications include:

1. **No current domain need**
   - The repository does not currently ask the question that the primitive answers.

2. **Equivalent current representation**
   - The operation exists, but the current data shape makes another primitive or explicit expression more direct.

3. **Semantic mismatch**
   - A primitive is close to the needed operation but differs on empty, nested, rank, duplicate, not-found, ordering, or fill behavior.

4. **Evaluation-safety concern**
   - A compact form may eagerly evaluate an unselected parser, formatter, branch, file read, or expensive computation.

5. **Diagnostic or provenance preservation**
   - Explicit steps may be necessary because each rejection stage, contributor, source coordinate, or error code is part of the contract.

6. **Ownership and readability**
   - A named accounting, admission, publication, or editor boundary may be more important than a shorter tacit expression.

7. **Performance or implementation concern**
   - The primitive may allocate an unsuitable dense intermediate, obscure sparsity, or behave poorly for the current CBQN workload.

8. **Historical residue**
   - The code may preserve an older procedural implementation after the data model changed.

9. **Authoring bias**
   - Human or AI contributors may repeatedly choose familiar loops, mutable accumulation, branch ladders, or nested `Each` even where a coordinate transformation would be clearer.

10. **Deliberate repository convention**
    - The current style may intentionally prefer explicit named stages over trains, custom modifiers, or deep combinator use.

The audit result for each primitive should be one of:

- absent and irrelevant
- absent but naturally applicable to a future capability
- absent because the existing form is semantically safer or clearer
- absent because a candidate kernel deserves an experiment
- actually present after exact inventory

## 6. Repository-wide code-shape questions

The investigation must not begin by searching for places to insert particular glyphs. It must first inspect recurring computational shapes.

### 6.1 Repeated scans

Check whether code repeatedly scans all Transactions, Postings, Accounts, dates, or report routes for every output item.

Ask whether the same meaning could be expressed by:

- one coordinate encoding
- classify or group
- index-of
- aligned masks
- sparse group construction
- scatter or a single pivot

Do not apply whole-array rewrites to small admission functions or editor orchestration merely because a loop is visible.

### 6.2 Nested `Each` and manual cell selection

Check whether nested `¨`, explicit row and column index loops, or repeated `⊑` chains are expressing a stable cell or rank operation.

Candidate mechanisms to compare include:

- `˘` Cells
- `⎉` Rank
- `⌜` Table
- `⍉` Transpose / Reorder Axes

A replacement is acceptable only when the input cell, frame, output shape, fill behavior, and edge semantics become clearer.

### 6.3 Manual adjacency

Check date, cycle, transaction, and report-order code for explicit previous/next handling that may correspond to:

- `»` Shift Before
- `«` Shift After

Boundary fill and empty behavior must be characterized before any replacement.

### 6.4 Repeated branch ladders and dispatch

Check whether a fixed set of functions is repeatedly selected through branches after validation.

Potential comparisons include:

- `◶` Choose, already used in the repository
- `⊘` Valences
- first-class function arrays
- `∘`, `○`, or `⟜` where they expose rather than hide the dataflow

Do not replace a branch when lazy evaluation or a named diagnostic boundary is essential.

### 6.5 Structural edits and reversible views

Check pure editor rewrite kernels for transformations that temporarily expose a view, alter it, and reconstruct the source representation.

Potential comparisons include:

- `⌾` Under
- `⁼` Undo

These are high-risk candidates because write-side byte stability, ordering, comments, metadata, and rejection behavior must remain exact. They should be considered only after lower-risk pure kernels.

### 6.6 Accumulation and mutation

Check whether mutable accumulation with `↩` or `∾↩` is incidental or whether it is carrying required ordered diagnostics, provenance, or staged failure evidence.

Possible alternatives include Fold, Scan, grouping, aligned result arrays, or direct construction. Ordered diagnostics must not be reordered or collapsed without an explicit correctness decision.

### 6.7 Descending order and duplicate coordinates

Check whether manual reverse-sort or repeated duplicate counting corresponds to:

- `⍒` Grade Down
- `⊒` Occurrence Count

The investigation must distinguish value ordering, stable ordering, coordinate identity, and nested major-cell equality.

## 7. Corpus definition for the exact inventory

The first report must separate at least these corpora:

1. production runtime under `src/`
2. write-side runtime under `src_edit/` and `src/editor/`
3. executable BQN entry points under `tools/`
4. tests under `tests/`
5. current non-archived support code
6. archived BQN code and documentation examples

A primitive used only in a test, archived file, comment, string, or Markdown example must not be reported as production usage.

The inventory should record:

- glyph and official name
- role: function, 1-modifier, 2-modifier, syntax, or system value
- occurrence count by corpus
- exact paths and line numbers
- executable occurrence versus comment/string occurrence
- representative semantic use
- current owner directory

System values such as `•Import`, `•args`, `•Out`, `•Exit`, and file operations should be inventoried separately from BQN language primitives.

## 8. Bias analysis by semantic region

After the exact inventory, compare code shape across:

- `src/text` and Journal parsing
- `src/ledger` admission and canonical Facts
- `src/accounting` pure capabilities
- `src/sections` semantic results and renderers
- `src/report` catalog, request admission, dispatch, and formatting
- `src/application` composition and I/O adapters
- `src/editor` pure editor semantics
- `src_edit` command validation and operation rendering

For each region, record:

- dominant data shapes
- dominant primitive families
- repeated procedural forms
- places where explicit control flow is required
- possible array kernels hidden inside orchestration
- whether naming and ownership boundaries are appropriate

The goal is not uniform style. Different semantic regions may correctly have different primitive profiles.

## 9. Required outputs

The investigation should produce these outputs before broad rewriting begins.

### Output A: reproducible primitive inventory

A generated or mechanically reproducible inventory for the fixed baseline commit.

Suggested future report path:

`docs/BQN_PRIMITIVE_USAGE_INVENTORY.md`

### Output B: repository-wide code-shape audit

A human analysis explaining why primitives are absent and whether repeated structural biases exist.

Suggested future report path:

`docs/BQN_CODE_SHAPE_BIAS_AUDIT.md`

### Output C: candidate experiment backlog

A ranked list of bounded kernels. Each candidate must identify:

- current owner and file
- exact input and output shape
- current algorithm
- candidate primitive or array transformation
- semantic risks
- focused edge tests required
- expected readability benefit
- decision: investigate, defer, or reject

This backlog is evidence for later PRs, not authorization for a repository-wide rewrite.

## 10. Rewrite policy

No code should be changed merely to make an unused primitive become used.

A rewrite is eligible only when:

1. a specific existing kernel has been identified
2. the current input, intermediate coordinate or cell, and output shape are written down
3. unchanged behavior is explicit
4. focused tests cover relevant semantic edges
5. the candidate form makes the computational question more direct
6. ownership and meaningful stage names remain visible
7. the patch is one coherent finite slice
8. full repository verification passes on current `main`

Reject a rewrite when it:

- exists only to improve primitive coverage
- compresses diagnostics or provenance
- changes evaluation eagerness
- introduces a generic helper before multiple consumers prove identical semantics
- makes a parser, editor, or safety boundary harder to inspect
- creates dense intermediates that damage sparse-first behavior
- turns domain meaning into opaque notation

## 11. Investigation order

### Phase 1: exact inventory only

- fix the baseline SHA
- enumerate tracked BQN files by corpus
- distinguish executable code from comments, strings, Markdown, shell, and archived material
- publish the exact used and unused primitive table
- do not rewrite production code

### Phase 2: explain absence

For every unused candidate, classify why it is absent and identify natural repository questions it could answer, if any.

### Phase 3: code-shape bias audit

Search for recurring transformations rather than glyph opportunities. Compare manual and primitive-based forms in analysis notes or isolated experiments.

### Phase 4: select one finite experiment

Choose one low-risk pure kernel with strong tests. Likely early families include coordinate lookup, sorting, adjacency, matrix axis handling, or pure formatting transformations.

`Under`, `Undo`, custom modifiers, and write-side structural rewrites should remain later candidates unless unusually strong evidence appears.

### Phase 5: bounded Draft PRs

For each accepted candidate:

- create one Draft PR
- preserve correctness and ownership scope
- add focused evidence first
- run full CI and coverage
- review final patch against `docs/BQN_REFACTORING_REVIEW_GUIDE.md`
- record `accept`, `revise`, or `reject`

## 12. First finite slice for 2026-07-30

The first slice is investigation only:

> Produce an exact, reproducible primitive-usage inventory for the current repository, separated by production, editor, tools, tests, and archive corpora.

It must not include production rewrites.

Completion evidence:

- fixed main SHA recorded
- complete tracked `.bqn` file list
- official primitive list fixed to a named BQN documentation version or commit
- executable occurrences distinguished from non-executable text
- provisional list corrected
- results committed as one report or report plus inventory tool
- no accounting, report, parser, editor, source, or output behavior changed

Only after this slice is reviewed should the first rewrite candidate be selected.

## 13. Current stop signs

This plan does not authorize:

- forcing every BQN primitive into the repository
- rewriting all nested `Each` expressions
- converting named code indiscriminately into trains or tacit forms
- changing Journal grammar or admission semantics
- changing Transaction, Posting, provenance, contributor, diagnostic, Matrix, or report meaning
- combining ownership cleanup with algorithm changes
- modifying private household source data
- changing output bytes without a separate correctness decision

The desired result is not a repository with more glyphs.

The desired result is a repository where each important transformation is visible in the clearest form justified by its data shape and semantic contract.
