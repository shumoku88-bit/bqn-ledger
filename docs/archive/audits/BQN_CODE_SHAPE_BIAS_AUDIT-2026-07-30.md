# BQN code-shape bias audit

Status: completed repository-wide observation for the fixed baseline

Date: 2026-07-30

Repository baseline: `221c4234af615cbf31bb9e22a7600efed58b088c`

Primitive inventory: `docs/BQN_PRIMITIVE_USAGE_INVENTORY.md`

Review gate: `docs/BQN_REFACTORING_REVIEW_GUIDE.md`

## 1. Question

This audit asks:

1. Why are 23 official BQN primitives absent from the current runtime?
2. Does the repository contain a systematic code-shape bias that obscures useful array transformations?
3. Which one bounded rewrite is safest to investigate first?

The audit does not treat primitive coverage, brevity, tacit style, or glyph count as quality targets.

## 2. Important baseline and history note

The fixed baseline is the current `main` observed at the start of this investigation:

`221c4234af615cbf31bb9e22a7600efed58b088c`

PR #440 previously demonstrated and squash-merged a native `⍷` Deduplicate rewrite for `src/accounting/matrix_result.bqn`. However, merge commit `102d01351536dc87a3ddc96b766a78dd35f2f7ae` and the current `main` are on divergent histories. The current `main` still contains the manual `Contains` plus mutable `Unique` implementation.

Therefore:

- the old PR is useful prior evidence;
- it is not evidence that the improvement exists in the current runtime;
- any accepted rewrite must be rebuilt directly from current `main` as a new finite slice;
- no old stacked branch should be merged as-is.

The existing branch `rebuild/matrix-result-deduplicate-current-main` is also unsuitable as a clean head: it is behind current `main` and contains unrelated report changes.

## 3. Repository profile

The mechanical inventory covers 192 tracked BQN source files:

- production: 82
- editor: 41
- tools: 1
- tests: 68

The most frequent primitive families include:

- `∾` Join / Join To
- `¨` Each
- `⊑` Pick
- `⍟` Repeat
- comparisons, masks, Fold, Scan, Group, Choose, and explicit namespace construction

The following higher-order or cell-oriented mechanisms are absent:

- `˘` Cells
- `⌜` Table
- `˝` Insert
- `⎉` Rank
- `⚇` Depth
- `⍉` Transpose / Reorder Axes

This contrast is real, but it is not by itself a defect.

## 4. Classification of the 23 unused primitives

### 4.1 No current domain question

| Glyph | Classification | Reason |
|---|---|---|
| `√` | absent and currently irrelevant | No current accounting, parsing, reporting, or editor capability asks for a square root or root calculation. Adding one would invent a domain question. |
| `⍉` | absent and currently irrelevant | Current MatrixResult values are already constructed in the required row-major presentation axis order. No current capability swaps axes. |

These should remain unused until a real capability requires them.

### 4.2 Existing representation makes another form more direct

| Glyph | Classification | Reason |
|---|---|---|
| `≍` | equivalent current representation | The repository commonly constructs explicit nested records and tuples with `⟨...⟩`; Solo/Couple would rarely clarify ownership or field meaning. |
| `⋈` | equivalent current representation | Pairing and enlistment are currently expressed with explicit list construction and Join. Some local expressions may be shorter with `⋈`, but no repeated semantic kernel has yet been identified. |
| `⍒` | existing form is semantically safer | Newest-first Transaction output preserves canonical source order by taking a suffix and reversing it. Sorting descending would ask a different question and could change stable order. |
| `⊒` | existing identity model is safer | Posting and Transaction indices, posting ordinals, provenance, and source identity are explicit facts. Reconstructing occurrence ordinals from values could collapse distinct identity semantics. |

### 4.3 Named-stage and explicit-block preference

| Glyph | Classification | Reason |
|---|---|---|
| `⊣` | deliberate style / no proven kernel | Identity/Left is most useful in trains or argument-routing expressions. Current code preserves named stages and explicit block arguments. |
| `⊢` | deliberate style / no proven kernel | Identity/Right has the same issue. Its absence is consistent with low train usage, not missing capability. |
| `˙` | deliberate style / no proven kernel | Constant functions are usually written as small named blocks because returned values often carry domain meaning. |
| `∘` | deliberate style / investigate only when local | Atop could compress compositions, but current named intermediate values often document accounting or admission stages. |
| `○` | deliberate style / investigate only when local | Over may clarify symmetric argument transformation, but no repeated current kernel has yet justified removing named transformations. |
| `⟜` | local asymmetry, not a defect | The repository uses `⊸` Before/Bind heavily. The opposite orientation has not been needed by current expression shapes. |
| `⊘` | deliberate style / no current valence API | Public functions generally declare one explicit input shape rather than exposing unrelated monadic and dyadic behavior under one name. |

Custom modifier special names are also absent. This is consistent with the repository convention that accounting, admission, publication, and editor owners remain visible as named functions or namespaces. A custom modifier should not be introduced until multiple real consumers prove an identical higher-order contract.

### 4.4 Diagnostic-value architecture makes abrupt mechanisms inappropriate

| Glyph | Classification | Reason |
|---|---|---|
| `!` | absent because existing semantics are safer | The repository accumulates structured diagnostics with stable stage, code, message, ordering, and fail-closed result shapes. Assert would abort rather than preserve these values and should not replace admission diagnostics. |

`!` could still be valid in a private impossible-state proof or development-only check, but no such bounded candidate is currently established.

### 4.5 Natural future questions, but no current rewrite target

| Glyph | Classification | Reason |
|---|---|---|
| `»` | naturally applicable to a future capability | Previous-day, previous-transaction, moving-difference, or adjacency reports could use Shift Before. Current newest-first selection is not adjacency processing. |
| `«` | naturally applicable to a future capability | Next-day or next-transaction comparison is a plausible future question, but no current contract requires it. |
| `⌜` | candidate experiment, not production rewrite | Date × category and row × column products exist. However, direct Table construction may create dense intermediates and obscure sparse grouping, exact sum failures, and contributors. |
| `˘` | candidate experiment | Some row-wise validation and formatting expressions may be major-cell operations. Current values are often ragged arrays or namespaces, so Cells is not automatically equivalent. |
| `˝` | candidate experiment | Axis Insert may apply to dense MatrixResult reductions, but current accounting reductions often operate over selected exact evidence and return diagnostic result objects. |
| `⎉` | candidate experiment | Rank could replace some nested `Each`, but only after cell, frame, output shape, and fill behavior are written explicitly. |
| `⚇` | currently defer | Nested data is mostly semantically named namespace fields rather than anonymous depth-polymorphic trees. Explicit field access is usually clearer. |

### 4.6 High-risk reversible editor mechanisms

| Glyph | Classification | Reason |
|---|---|---|
| `⌾` | defer | Under may describe pure view-edit-reconstruct kernels, but editor code must preserve exact bytes, ordering, comments, metadata, and rejection behavior. No first-slice candidate should begin here. |
| `⁼` | defer | Undo requires a trustworthy inverse and exact reconstruction contract. Journal and TSV write paths are too safety-sensitive for an exploratory first rewrite. |

## 5. Actual code-shape findings

### 5.1 The dominant style is explicit staged transformation

Across accounting, sections, Journal admission, application composition, and editor commands, the recurring shape is:

```text
validate input
→ accumulate ordered diagnostics
→ conditionally derive named coordinates or result rows
→ publish a canonical success or empty/error namespace
```

`⍟` is heavily used as conditional execution. `∾↩` often preserves diagnostic order or incrementally publishes candidate rows only after a local exactness check. In these regions, mutation-looking syntax is not always incidental mutation; it frequently carries staged evidence.

This means a repository-wide ban on `↩`, `∾↩`, nested blocks, or `⍟` would damage readability and contracts.

### 5.2 Namespace and ragged-data structure explains part of the Cells/Rank absence

Many values are not uniform numeric arrays. They include:

- arrays of contributor-index arrays;
- arrays of transaction references;
- namespaces containing aligned columns;
- Journal blocks with optional metadata;
- diagnostics with named fields;
- ragged debit and credit account lists.

`¨` and explicit `⊑` often operate on these semantically named or ragged values. A Rank or Cells rewrite is valid only where a stable rectangular cell model already exists.

Therefore the zero usage of `˘` and `⎉` is a useful question, but not evidence that the whole repository is incorrectly scalarized.

### 5.3 A real localized bias exists: manual uniqueness reconstruction

The following current-main modules contain local `Contains` plus mutable `Unique` logic or depend on the same shape:

- `src/accounting/matrix_result.bqn`
- `src/accounting/sparse_group.bqn`
- `src/accounting/date_category_flow.bqn`
- `src/sections/daily_flow.bqn`

The shape is:

```text
items
→ scan each item
→ repeated membership test against accumulated result
→ append first occurrences
→ compare original and unique counts, or use sorted unique values
```

BQN already provides monadic `⍷` Deduplicate, and the repository already uses `⍷` elsewhere. This is not an unused-primitive problem. It is a localized drift problem where an available direct array primitive is used in some owners but manually reconstructed in others.

This is the strongest concrete bias found by the audit.

### 5.4 Nested `Each` in sparse grouping is a legitimate investigation target, not an immediate rewrite

`src/accounting/sparse_group.bqn` explicitly iterates row-axis indices and column indices, constructs a mask for each coordinate, exact-sums selected coefficients, preserves contributors, and emits only nonempty sparse groups.

A Table-based experiment could expose the row × column coordinate product. However, a naïve rewrite could:

- construct a dense row × column intermediate;
- calculate empty cells that the current sparse result omits;
- change diagnostic accumulation order;
- change exact-sum failure publication;
- flatten or reorder contributors.

Decision: investigate later in an isolated experiment. Do not select it as the first production rewrite.

### 5.5 Daily Flow has dense-row construction, but its current semantics are mixed

`src/sections/daily_flow.bqn` constructs dense rows from:

- optional income evidence;
- an expense row from a sparse pivot;
- net value and combined contributors;
- date text lookup and remapping.

Some row construction may eventually admit Cells or Rank. However, the same loop also performs optional lookup, contributor union, sign policy preparation, and canonical publication. It is not a clean first Rank rewrite.

The local `SortedUnique` helper is a narrower future candidate after the simpler MatrixResult and sparse-group uniqueness slices.

### 5.6 Descending order and adjacency are not currently being manually reconstructed

`src/accounting/recent_transactions.bqn` uses:

```text
canonical transaction order
→ bounded suffix
→ reverse
```

This means newest-first, while preserving the canonical order among selected transactions. It is not equivalent to Grade Down and does not require Shift Before or Shift After.

Decision: no rewrite.

### 5.7 Editor safety explains why Under and Undo remain absent

The write side does more than transform arrays. It validates commands, reconstructs Journal blocks or TSV rows, retains source identity and metadata, and emits machine-readable write operations. Exact text and rejection behavior are contracts.

Decision: Under and Undo remain research topics for the personal BQN book or isolated probes, not current editor refactor candidates.

## 6. Bias verdict

### Not found

The audit did not find evidence that the repository as a whole is merely procedural, unaware of BQN, or incapable of whole-array programming.

Current code already uses:

- masks and Replicate;
- Classify, Group, Deduplicate/Find;
- Fold and Scan;
- coordinate lookup;
- sparse grouping and pivots;
- function selection with Choose;
- exact arithmetic capabilities;
- arrays of aligned facts and presentation-neutral MatrixResult values.

### Found

The audit found three narrower tendencies:

1. **manual uniqueness drift** across several owners despite native Deduplicate being available;
2. **heavy local construction with `¨`, `⊑`, and `∾↩`**, partly justified by namespaces, ragged values, and ordered diagnostics, but worth reviewing kernel by kernel;
3. **very low use of cell/rank notation**, which should be tested against selected dense pure kernels rather than corrected globally.

The first is actionable now. The second and third require bounded experiments.

## 7. Candidate backlog

| Priority | Owner / kernel | Candidate | Risk | Decision |
|---:|---|---|---|---|
| 1 | `src/accounting/matrix_result.bqn` axis uniqueness | replace local `Contains`/`Unique` with monadic `⍷` | low | investigate now |
| 2 | `src/accounting/sparse_group.bqn` row-axis uniqueness | replace local uniqueness reconstruction with `⍷` | low to medium | investigate after priority 1 |
| 3 | `src/accounting/date_category_flow.bqn` envelope category uniqueness | use `⍷` for the already-admitted category axis | medium | defer until exact nested/string semantics are pinned |
| 4 | `src/sections/daily_flow.bqn` `SortedUnique` | Grade Up followed by Deduplicate | medium | defer; preserve date and contributor ordering |
| 5 | `src/accounting/sparse_group.bqn` coordinate product | compare nested `¨` with Table-based coordinate construction | high | analysis-only experiment |
| 6 | selected MatrixResult row validation | compare explicit row `¨` with Cells/Rank | medium | analysis-only experiment |
| 7 | editor structural rewrites | Under / Undo | very high | reject as early slice |
| 8 | custom modifier extraction | shared higher-order validation or publication mechanism | high | reject until multiple identical consumers exist |

## 8. First finite rewrite selected

The first rewrite candidate is:

> Rebuild MatrixResult opaque-axis uniqueness directly from current `main` using native major-cell `⍷` Deduplicate.

Why this candidate:

- pure accounting constructor;
- exact owner is clear;
- only axis uniqueness changes;
- prior PR #440 supplies useful characterization evidence;
- current main visibly lacks the accepted improvement;
- empty axes, adjacent duplicates, and non-adjacent nested duplicates can be pinned;
- no report, Journal, editor, source, or output policy needs to move;
- the change makes the actual question direct: original axis count equals deduplicated axis count.

Required scope:

- `src/accounting/matrix_result.bqn`
- `tests/test_accounting_matrix_result.bqn`

Required unchanged behavior:

- row and column coordinate order and values;
- duplicate diagnostic codes and diagnostic order;
- scale admission;
- dense row/column alignment admission;
- canonical empty MatrixResult on every error;
- successful values, contributors, indices, and shape;
- all downstream report and editor behavior.

## 9. Stop signs for the rewrite phase

Do not:

- insert unused primitives merely to increase coverage;
- combine MatrixResult uniqueness with sparse grouping or Rank experiments;
- import old divergent branch ancestry;
- remove diagnostic stages;
- change success/error publication beyond what focused evidence proves;
- alter output bytes or source data;
- extend the slice beyond the two declared files.

## 10. Conclusion

The repository does have a recognizable style bias, but it is mostly the shadow cast by its real requirements: named ownership, ragged evidence, ordered diagnostics, provenance, and write safety.

The actionable distortion is smaller and more concrete:

> several modules manually rebuild uniqueness even though native major-cell Deduplicate is already available and already used elsewhere.

The correct response is not a repository-wide BQN rewrite. It is a sequence of small, independently evidenced substitutions beginning with MatrixResult axis uniqueness.
