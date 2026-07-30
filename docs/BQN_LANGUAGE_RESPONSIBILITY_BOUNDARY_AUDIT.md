# BQN language responsibility boundary audit

Status: active first-pass boundary map

Date: 2026-07-30

Repository baseline: `7c51e792a321a6241b2df3b217289792ec6b700d`

Related records:

- `docs/BQN_PRIMITIVE_USAGE_INVENTORY.md`
- `docs/BQN_CODE_SHAPE_BIAS_AUDIT.md`
- `docs/BQN_REFACTORING_REVIEW_GUIDE.md`
- `docs/ARCHITECTURE.md`

## 1. Question

This audit asks a different question from primitive usage:

> Where is BQN expressing the actual shape of the household-accounting problem, and where is BQN merely carrying general orchestration, file, CLI, or failure-handling work that another language could perform equally well or more safely?

The purpose is not to remove BQN from the repository, introduce a second language for novelty, or classify procedural syntax as automatically bad.

The purpose is to make each language responsibility explicit so that later work can choose among three different responses:

1. make an existing BQN kernel more directly array-oriented;
2. keep a non-array boundary in BQN because co-location and a single-process system are valuable;
3. thin, isolate, or eventually externalize a boundary whose BQN-specific value is weak.

## 2. Decision rule

A module has a strong BQN reason when its central question is about one or more of:

- aligned columns or Facts;
- masks and selected evidence;
- classification, grouping, pivots, or coordinates;
- sparse or dense array construction;
- rank, cells, axes, shape, or nested major-cell identity;
- exact reductions over selected values;
- projections from canonical Facts into semantic results.

A module has a weak BQN reason when its central question is mainly:

- command-line arity and usage messages;
- filesystem existence, readability, path joining, or process exit;
- shell execution, locking, atomic replacement, or backup policy;
- long route-by-route control flow;
- forwarding values between already-defined owners;
- byte-level operational safety without a meaningful array transform.

A weak BQN reason does not require immediate removal. A one-language system can still be the better design when the boundary is thin, stable, inspectable, and avoids a serialization protocol.

## 3. Three responsibility classes

### 3.1 Class A: BQN-native kernel

The module's principal meaning is an array or coordinate transformation. BQN is not merely the implementation language; its data model exposes the question.

Examples:

- `src/accounting/` grouping, balance, MatrixResult, pivot, period, category, and daily calculations;
- canonical Fact projections in `src/ledger/`;
- parser kernels using Scan, Group, masks, and exact token conversion;
- semantic result construction in `src/sections/`.

Default response:

- keep in BQN;
- remove incidental loops or mutable reconstruction when a direct primitive exposes the same contract;
- retain named accounting, diagnostic, provenance, and publication stages.

### 3.2 Class B: boundary-support BQN

The module performs ordinary system work, but it is thin and directly feeds or receives a BQN kernel. Keeping it in BQN preserves one process and avoids an additional wire format.

Examples:

- `src/application/source_io.bqn`;
- `src/application/report_source_adapter.bqn`;
- small request-validation or rendering adapters;
- pure editor rewrite functions next to strict ledger owners.

Default response:

- keep while thin;
- separate effects from pure transforms;
- prevent policy or route duplication from accumulating here;
- do not judge it by primitive density.

### 3.3 Class C: orchestration-dominant boundary

The module is mostly a sequence of route checks, source reads, error exits, and calls to already-owned capabilities. Its central structure is control flow rather than an array transform.

Examples requiring investigation:

- `src/application/report_destination_cli.bqn`;
- route-specific validation and source enumeration in `tools/report`;
- write executors, backup/replace operations, and process-level editor commands;
- large CLI dispatch blocks that duplicate a static catalog or manifest contract.

Default response:

- first make ownership data-driven or split pure request construction from effects;
- then measure whether the remaining boundary is small enough to keep in BQN;
- consider another language only after the protocol and failure contract are stable.

## 4. Current architecture already contains a useful separation

The production flow is explicitly layered:

```text
source files and report request
→ application adapters
→ strict ledger Facts
→ accounting capabilities
→ semantic sections
→ report dispatch and rendering
→ shell tools and cache
```

This is a good starting shape. `src/accounting` does not import report composition, and report sections do not read files or the clock. The problem is therefore not that every concern is fused together.

The new question is whether some boundary modules have grown too much route policy or operational control flow, and whether some pure kernels still hide direct BQN transformations.

## 5. First-pass observations

### 5.1 `src/accounting`: strong BQN responsibility

The accounting layer operates over canonical Facts, selected coordinates, exact coefficients, masks, grouped contributors, and MatrixResult values. This is the clearest BQN-native region.

The previous audit found a localized drift rather than a language mismatch: several modules manually reconstructed uniqueness even though monadic `⍷` already states the array question directly.

PR #451 and PR #452 corrected two instances without moving ownership or changing accounting meaning.

Decision:

- keep accounting kernels in BQN;
- continue kernel-by-kernel review;
- do not replace explicit diagnostics or provenance merely to shorten expressions.

### 5.2 `src/ledger`: mixed, but usually BQN-justified

Ledger admission contains general validation and structured diagnostics, but it also converts Journal, Account, Plan, Budget, Cycle, and Config evidence into aligned canonical Facts.

The parser and admission stages often need:

- text masks and grouping;
- exact-decimal conversion;
- aligned column construction;
- Transaction and Posting coordinates;
- provenance and rejection arrays.

Decision:

- keep canonical admission in BQN while these transforms remain central;
- distinguish necessary staged diagnostics from incidental mutable reconstruction;
- do not replace structured diagnostic values with abrupt assertions.

### 5.3 `src/sections`: strong to medium BQN responsibility

Sections combine presentation-neutral accounting evidence into one semantic result and approved renderers. Matrix and list construction remain natural BQN work.

Some section functions mix:

- coordinate remapping;
- optional lookup;
- contributor union;
- result publication;
- human text rendering.

Decision:

- keep semantic result construction in BQN;
- examine dense pure row kernels for Cells or Rank only after their cell contracts are explicit;
- keep human rendering separate from accounting ownership.

### 5.4 `src/report`: medium BQN responsibility

The static catalog, request validation, result dispatch, and renderer selection are small data-driven structures over arrays of entries and functions. BQN is reasonable here even though another language could also implement them.

The catalog is already a useful single source for key, label, owner, shape, and surface support.

Decision:

- keep the static catalog and pure request admission in BQN;
- use them as the source for more route metadata where semantics truly match;
- avoid making the catalog own filesystem or CLI policy that belongs at the application boundary.

### 5.5 `src/application/source_io.bqn`: weak but acceptably thin BQN responsibility

This module resolves paths, reads raw files, strips carriage returns, splits lines, and excludes blank/comment rows. Almost none of this requires an array language.

However, it is only a thin read-only adapter. Schema admission and accounting remain downstream. Moving it to another language would require a process or serialization boundary without currently removing much complexity.

Decision:

- keep it in BQN for now;
- keep it small and policy-light;
- do not let it absorb schema admission, accounting rules, or route dispatch.

### 5.6 `src/application/report_source_adapter.bqn`: useful thin seam

The source adapter joins explicit paths, reads the required source forms, and immediately calls strict snapshot owners. It makes the effectful edge visible and keeps accounting modules pure.

Decision:

- keep this seam;
- treat it as the desired shape for boundary-support BQN;
- route-specific source selection should not expand indefinitely through copy-pasted blocks.

### 5.7 `src/application/editor_actual.bqn`: a good mixed-boundary pattern

This module already separates:

- `LoadTransactionRows`, which performs configuration, source reads, admission, and process exit;
- `CompletionEvidenceFromRows`, which is a pure mask, debit/credit selection, exact amount, and projection kernel.

The pure function has a clear BQN reason. The loader has a weaker language reason but remains a compact adapter.

Decision:

- preserve and copy this split pattern elsewhere;
- test pure `...FromRows` or `...FromFacts` functions independently;
- prevent file/process behavior from entering the pure projection.

### 5.8 `src/application/report_destination_cli.bqn`: orchestration-dominant candidate

This file validates CLI shapes, reads sources, resolves cycles, calls composition functions, prints diagnostics, and exits for each retained report key.

Its repeated form is:

```text
match key
→ validate coordinate count
→ read key-specific sources
→ fail on source/admission errors
→ call one composition function
```

This is largely general route orchestration. BQN contributes little beyond ordinary arrays of arguments and conditional blocks.

The file is therefore not evidence that the accounting kernel should leave BQN. It is evidence that the application boundary may need thinning or a data-driven request plan.

Decision:

- do not rewrite it into denser BQN notation;
- investigate extracting pure key-specific request construction from process exit and source reads;
- compare the route contract against the static report catalog and request manifests;
- consider eventual replacement only after duplicate policy is removed.

### 5.9 `tools/report`: operational shell is appropriate, but route duplication is not

The shell tool correctly owns process-level concerns:

- caller working directory;
- safe basenames;
- file readability;
- `exec`;
- manifest file access;
- shell exit behavior.

These are stronger shell responsibilities than BQN responsibilities.

However, it also contains a large key-by-key `case` that repeats argument counts and source requirements also understood by the BQN CLI composition.

Decision:

- keep operational safety in shell;
- investigate whether one admitted route-plan representation can remove duplicated route metadata;
- do not move filesystem checks into accounting or report sections.

## 6. What “use another language” should mean here

A language split is justified only when it creates a clearer stable boundary, not merely because a function looks procedural.

Before moving a responsibility out of BQN, record:

1. the exact input and output contract;
2. exact-decimal representation;
3. nested contributors and provenance representation;
4. diagnostic stage, code, message, and order;
5. empty/error publication behavior;
6. byte and path behavior where writes are involved;
7. process and serialization cost;
8. which side owns compatibility.

Likely future language-boundary candidates include:

- filesystem-safe write execution;
- locking, backup, and atomic replacement;
- long-lived UI or service integration;
- external database or network adapters.

Poor first candidates include:

- accounting grouping and pivots;
- canonical Fact construction;
- contributor-aware semantic results;
- Journal parsing before its admitted output contract is independently stable.

## 7. Change policy

Every future slice must declare which kind of change it is.

### A. BQN-kernel clarification

Example:

- mutable uniqueness reconstruction → `⍷` Deduplicate;
- proven dense row operation → Cells or Rank;
- repeated coordinate scan → Classify, Group, or one pivot.

Required result: the same owner and semantics, with a more direct array question.

### B. Boundary thinning

Example:

- split file reads from a pure `FromFacts` function;
- replace route-by-route procedural publication with an admitted route plan;
- derive repeated route metadata from one owner.

Required result: effects and kernel meaning become easier to inspect without introducing another language.

### C. Language extraction

Example:

- move atomic file replacement or locking into a dedicated shell, Haskell, Rust, or Go boundary.

Required result: a stable protocol, fewer responsibilities in BQN, and no duplicate policy.

Correctness changes must remain separate from all three.

## 8. Ranked continuation backlog

| Priority | Area | Question | Change class | Decision |
|---:|---|---|---|---|
| 1 | `src/accounting/date_category_flow.bqn` | Can envelope-category uniqueness use native `⍷` while preserving category order and diagnostics? | A | investigate now |
| 2 | `src/sections/daily_flow.bqn` | Can `SortedUnique` become Grade Up followed by Deduplicate without changing date or contributor order? | A | investigate after priority 1 |
| 3 | `tools/report` + `src/application/report_destination_cli.bqn` | Which route metadata is duplicated across shell and BQN? | B | observation-only audit |
| 4 | report application boundary | Can key-specific source/coordinate admission produce a pure route plan before any source read? | B | investigate after duplication map |
| 5 | selected dense section kernels | Do explicit `¨` row operations have a stable Cells/Rank contract? | A | analysis-only experiment first |
| 6 | editor command paths | Which functions already have pure `FromRows`/`FromFacts` cores, and which mix effects with projection? | B | inventory first |
| 7 | write execution | Can byte replacement, locking, backup, and rollback be one explicit non-BQN executor? | C | defer until operation protocol is fixed |
| 8 | Journal parser | Should parsing move to Haskell or another language? | C | reject as an early move; stabilize independent contract first |

## 9. Next finite slice

The next production rewrite remains deliberately small:

> Replace `date_category_flow.bqn`'s mutable envelope-label uniqueness reconstruction with monadic `⍷` Deduplicate, preserving Account-derived category order, duplicate diagnostics, reserved-name admission, and all downstream flow results.

This is a Class A change. It improves the BQN kernel and does not answer the larger language-extraction question by itself.

In parallel, the next observation-only boundary slice should compare:

- route keys;
- allowed coordinate counts;
- required source basenames and types;
- optional Plan conditions;
- failure codes;
- source-read timing;

between `tools/report`, `src/application/report_destination_cli.bqn`, the report catalog, and request manifests.

No application rewrite should begin until that duplication map exists.

## 10. Conclusion

The current repository does not present a binary choice between “all BQN” and “BQN only for matrices.”

A better target is:

```text
thin operational shell or adapter
→ strict admitted Facts
→ visibly BQN-native accounting and projection kernels
→ thin publication boundary
```

Some procedural BQN is justified glue. Some is a sign that effects and pure transforms should be separated. Some is historical drift that can be replaced by a direct array primitive.

The repository should therefore evolve by responsibility, not by glyph count and not by language loyalty.