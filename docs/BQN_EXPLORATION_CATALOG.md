# BQN Exploration Catalog

Status: current living catalog

## Purpose

This catalog preserves BQN questions that are worth seeing again.

It is not a backlog, a primitive-coverage checklist, or an instruction to rewrite the runtime. It records promising formulations, alternate representations, newly revealed capabilities, and understood non-uses so a later AI or contributor can resume from the accumulated observation instead of rediscovering the same landscape from zero.

Read this catalog together with the current owner and focused tests. Runtime code and contracts remain the source of truth when a card has become stale.

## Working rule

For each relevant BQN task:

1. read the exploration playbook and this catalog;
2. compare the relevant cards with current runtime shapes and contracts;
3. freely add, combine, split, revise, or retire cards when new evidence appears;
4. select no more than one coherent production slice for adoption;
5. keep unselected ideas visible as probes, personal-book experiments, new capabilities, or parked non-uses.

Catalog order is not priority order. A small playful probe may be more useful than the first card.

## Card fields

A card should contain only the fields that preserve the discovery. Useful fields are:

```text
Question or capability:
Current owner or analogous runtime code:
BQN lens:
What becomes visible:
Known contract or risk:
Current destination:
Revisit signal:
Next useful probe:
```

## Current exploration cards

### MatrixResult row validation through Cells or Rank

- **Question or capability:** Can MatrixResult row and column alignment be stated more directly as a cell contract rather than repeated Each predicates?
- **Current owner:** `src/accounting/matrix_result.bqn`.
- **BQN lens:** Each `¨`, Cells `˘`, and Rank `⎉`.
- **What becomes visible:** The distinction between the outer sequence of rows, each row as a cell, and the scalar boolean result of validating one row.
- **Known contract or risk:** Values and contributors are currently nested rows. Empty input, one-row input, malformed row shape, and contributor alignment must remain explicit. A Rank formulation must not invent fill or silently regularize ragged evidence.
- **Current destination:** analysis-only probe; strong first probe candidate.
- **Revisit signal:** MatrixResult row representation changes, or a focused comparison demonstrates clearer shape semantics without contract loss.
- **Next useful probe:** Compare Each, Cells, and Rank on synthetic empty, rectangular, and ragged rows while printing shape, rank, and boolean results.

### Dense Pivot through Table

- **Question or capability:** Can the already-dense row × column lookup in `sparse_pivot` be expressed more directly as a Table-generated coordinate product?
- **Current owner:** `src/accounting/sparse_pivot.bqn` after exact grouping is complete.
- **BQN lens:** Table `⌜`, Cells, and alternate rectangular output representations.
- **What becomes visible:** The full Cartesian product of admitted row and column coordinates and the fact that the pivot intentionally publishes a dense view.
- **Known contract or risk:** Table naturally produces a true higher-rank result, while MatrixResult currently stores nested rows. Values, missing-value zeroes, contributors, row order, and column order must remain aligned. This is a better Table probe than changing sparse grouping itself.
- **Current destination:** analysis-only probe.
- **Revisit signal:** A rectangular MatrixResult experiment succeeds, or a dense presentation needs direct row × column semantics.
- **Next useful probe:** Compare nested Each lookup with Table over tiny synthetic groups, including missing cells and multi-contributor cells.

### Explicit temporal axes and Shift

- **Question or capability:** What useful household-accounting questions appear when time is represented as an explicit ordered axis?
- **Current analogues:** recent transactions, Daily Flow dates, cycle dates, and future movement or interval sections.
- **BQN lens:** Shift Before `»` and Shift After `«`.
- **What becomes visible:** Previous calendar day, previous active transaction day, next observed balance point, changes between adjacent periods, and gaps in activity.
- **Known contract or risk:** Calendar adjacency and observed-event adjacency are different meanings. Current newest-first reporting is suffix selection plus reverse, not descending sort or Shift.
- **Current destination:** new capability plus personal-book experiment.
- **Revisit signal:** A concrete movement, interval, streak, gap, or adjacent-period question is chosen.
- **Next useful probe:** Build two synthetic axes, calendar days and active transaction days, and compare the questions each Shift answers.

### Presentation-only MatrixResult axis exchange

- **Question or capability:** Could a report offer the same admitted evidence with rows and columns exchanged?
- **Current analogues:** MatrixResult consumers and renderers.
- **BQN lens:** Transpose `⍉`.
- **What becomes visible:** The symmetry between date × category, account × period, and other presentation axes.
- **Known contract or risk:** Transposing values alone is incorrect. Row labels, column labels, contributors, coordinate metadata, empty dimensions, and rendering ownership must move together. Accounting owners should remain presentation-neutral.
- **Current destination:** new capability; analysis-only probe when a concrete report requests it.
- **Revisit signal:** A user-facing report benefits from an axis-swapped view.
- **Next useful probe:** Transpose a synthetic MatrixResult as one structure and verify that every value retains the same source-qualified contributor path.

### Journal view-edit-reconstruct

- **Question or capability:** What would a pure canonical Journal transformation look like when described as viewing, editing, and reconstructing a structure?
- **Current analogues:** `src/editor/`, `src_edit/`, and editor Actual candidate generation.
- **BQN lens:** Under `⌾`, Undo `⁼`, and deliberately narrow canonical subsets.
- **What becomes visible:** Which parts of an edit are a reversible structural view and which parts depend on external textual evidence.
- **Known contract or risk:** Production editor correctness includes bytes, comments, metadata, ordering, identity, admission, stale checks, backup, and atomic publication. No exact inverse has been proven for the full Journal surface.
- **Current destination:** personal-book experiment and pure toy probe only.
- **Revisit signal:** A deliberately canonical in-memory Journal subset receives an exact round-trip contract.
- **Next useful probe:** Define a tiny synthetic transaction structure with no comments or optional metadata, then characterize view-edit-reconstruct and failed round trips.

### Tacit routing without erasing domain stages

- **Question or capability:** Which small kernels become clearer through function composition while retaining names for accounting stages?
- **Current analogues:** narrow transformations inside ledger, accounting, sections, and tests.
- **BQN lens:** Left `⊣`, Right `⊢`, Constant `˙`, Atop `∘`, Over `○`, and Before/After `⟜` forms.
- **What becomes visible:** Argument routing, shared preprocessing, selected functions, and the boundary between a semantic stage and incidental plumbing.
- **Known contract or risk:** Repository code often uses names because admission, coordinate resolution, grouping, publication, or diagnostic order is meaningful. Tacitization and glyph density are not goals.
- **Current destination:** personal-book experiment or small analysis-only probe.
- **Revisit signal:** A bounded named function contains only incidental routing and its train form exposes the same question more directly.
- **Next useful probe:** Compare one tiny pure kernel in explicit, partially tacit, and fully tacit forms, then record which names remain useful.

### Assert versus structured diagnostics

- **Question or capability:** Is there a private invariant or development-only boundary where primitive Assert improves a probe or test without replacing domain diagnostics?
- **Current analogues:** `tests/test_lib.bqn` named Assert helper and strict admission diagnostics.
- **BQN lens:** Assert `!`.
- **What becomes visible:** The difference between an impossible internal state, an expected invalid input, and a test failure with useful context.
- **Known contract or risk:** Production rejection is ordered structured data. Primitive Assert aborts rather than preserving those values and is not a replacement for fail-closed admission.
- **Current destination:** personal-book or development-only probe.
- **Revisit signal:** A truly private invariant is identified after admission, or a tiny experiment benefits from immediate failure.
- **Next useful probe:** Express the same synthetic invariant with primitive Assert, the repository test helper, and a structured Diagnostic value.

### Nested rows, rectangular arrays, and depth

- **Question or capability:** Which accounting shapes become easier to reason about when nested rows are compared with true rectangular arrays or explicit depth contracts?
- **Current analogues:** MatrixResult, Facts columns, namespace records, posting rows, and contributor sequences.
- **BQN lens:** Solo/Couple `≍`, Pair `⋈`, Cells `˘`, Rank `⎉`, and Depth `⚇`.
- **What becomes visible:** Scalar versus one-item-list distinctions, major cells, raggedness, uniform frames, and whether nesting represents domain meaning or implementation convenience.
- **Known contract or risk:** Current namespaces and ragged contributor/posting structures are semantic in several owners. Regularizing them merely to admit more primitives can flatten evidence.
- **Current destination:** personal-book experiment and representation probe.
- **Revisit signal:** A concrete owner has repeated shape checks, or two representations can be compared without changing the public contract.
- **Next useful probe:** Model the same tiny accounting result as namespaces, nested rows, and a rectangular array, then compare selection and validation expressions.

### Insert and exact accounting reduction

- **Question or capability:** What is the exact boundary between a generic reduction and the repository's diagnostic-bearing exact sum?
- **Current owner:** exact amount arithmetic and `scale.Sum` consumers.
- **BQN lens:** Insert/Fold `˝`.
- **What becomes visible:** The algebraic reduction itself and the additional accounting evidence required around it.
- **Known contract or risk:** A primitive fold over numeric values does not by itself preserve scale validation, exactness diagnostics, or malformed-input rejection.
- **Current destination:** personal-book experiment; parked for direct production replacement.
- **Revisit signal:** A pure already-admitted exact-integer kernel appears where no diagnostic-bearing arithmetic remains.
- **Next useful probe:** Compare ordinary Fold with `scale.Sum` over valid, empty, and deliberately malformed synthetic values.

### Ordering, identity, and valence candidates

- **Question or capability:** Do Grade Down `⍒`, first-occurrence identity `⊒`, or Valences `⊘` directly own any current domain operation?
- **Current analogues:** recent newest-first selection, durable source identity/provenance, and narrow function APIs.
- **What becomes visible:** The difference between sorting and reversing a selected suffix, between generated occurrence coordinates and durable identity, and between deliberate APIs and dual-valence convenience.
- **Known contract or risk:** Current newest-first semantics are not descending sort. Posting and transaction identity are provenance-bearing. No current API needs valence dispatch merely for compactness.
- **Current destination:** parked non-use.
- **Revisit signal:** A real descending-order report, occurrence-index question, or genuinely shared monadic/dyadic operation appears.

### Root and unrelated arithmetic

- **Question or capability:** Does Root `√` answer a real household-accounting or representation question in the retained portfolio?
- **Current destination:** parked non-use and personal-book mathematics experiment.
- **Revisit signal:** A concrete statistical, geometric, or financial model requiring roots is deliberately introduced.

## Maintenance

- Add a card when an idea would otherwise be lost across chats or reviews.
- Revise a card when current code, tests, or representation changes its assumptions.
- Mark a card graduated when it becomes a selected production slice, and link the PR or focused evidence.
- Remove a card only when it duplicates another card or no longer preserves useful reasoning.
- Do not convert catalog order, card count, or primitive count into progress metrics.

The catalog is successful when it keeps BQN possibilities available without turning curiosity into compulsory churn.