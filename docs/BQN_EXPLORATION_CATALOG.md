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
- **BQN lens:** Each `¨`, Cells `˘`, Rank `⎉`, Merge `>`, and the boundary between nested rows and true rank-2 arrays.
- **Observed evidence:** `experiments/bqn/matrix_result_cells_rank.bqn` and its result note compare equal, ragged, and empty nested rows with true `2×2` and `0×2` arrays. GitHub Actions run `30532900105` completed successfully.
- **What became visible:** On the current rank-1 sequence of nested row arrays, Each sees the inner row values and correctly distinguishes aligned from ragged rows. Cells and Rank 0 see the outer list's 0-cells and report length one instead. On a true rank-2 array the relationship reverses: Cells and Rank 1 directly own the row-length question while Each maps scalar elements.
- **Known contract or risk:** `Build` is an admission boundary that must represent malformed ragged candidate rows so it can return structured `matrix_*_columns_misaligned` diagnostics. Merging before validation would replace that domain diagnostic with a primitive shape error. Empty input, contributor cells, fills, and consumer representation remain part of any later canonical-array decision.
- **Current destination:** observed experiment; direct Each-to-Cells or Each-to-Rank production replacement parked.
- **Revisit signal:** MatrixResult deliberately separates permissive nested candidate input from a canonical post-admission output representation, or a consumer gains a concrete need for true row and column axes.
- **Next useful probe:** Characterize `nested candidate rows → structured validation → Merge canonical values and contributors`, including ragged rejection, contributor cells, and `0×N` shapes.

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
- **Current precedent:** `monthly-accounts` retains a semantic Month × Account Matrix while its human renderer presents Account rows × Month columns. That bounded renderer transpose is production and preserves the accounting result; it is not a generic MatrixResult transpose.
- **BQN lens:** Transpose `⍉`.
- **What becomes visible:** The symmetry between date × category, account × period, and other presentation axes.
- **Known contract or risk:** Transposing values alone is incorrect. Row labels, column labels, contributors, coordinate metadata, empty dimensions, and rendering ownership must move together. Accounting owners should remain presentation-neutral.
- **Current destination:** bounded production precedent for Monthly Accounts; generic structure-level transpose remains an analysis-only probe or separately selected capability.
- **Revisit signal:** A second user-facing report needs an axis-swapped view, or a neutral external consumer needs the transposed structure rather than terminal text.
- **Next useful probe:** Transpose a synthetic MatrixResult as one structure and verify that every value retains the same source-qualified contributor path.

### Single-classification grouping instead of repeated evidence scans

- **Question or capability:** Can admitted Postings be assigned row and column coordinates once, grouped once, and then scattered into dense results without scanning all selected evidence for every output cell?
- **Current owners:** `src/accounting/sparse_group.bqn`, `month_account_movement.bqn`, and date-level reductions in `date_category_flow.bqn`.
- **BQN lens:** coordinate encoding, Group, classify, sort/group boundaries, Table for an already-dense destination, and aligned contributor groups.
- **What becomes visible:** The intended pipeline `Posting → row coordinate × column coordinate → exact grouped reduction → dense Matrix`, rather than `every row × every column → rescan every Posting`.
- **Known contract or risk:** Current implementations are deterministic and adequate for household scale. A replacement must preserve row/column order, exact scale diagnostics, zero cells, contributor order and identity, empty axes, overflow behavior, and fail-closed publication. Performance alone does not authorize semantic simplification.
- **Current destination:** algorithm analysis-only probe; not an automatic optimization queue.
- **Revisit signal:** synthetic scaling evidence, a larger confirmed dataset, or a selected whole-array clarity slice demonstrates a material benefit.
- **Next useful probe:** Compare current and classify-once formulations over synthetic sparse and dense coordinates, including duplicate contributors, exact-zero groups, malformed coordinates, and empty axes; record both equivalence and scaling.

### Journal view-edit-reconstruct

- **Question or capability:** What would a pure canonical Journal transformation look like when described as viewing, editing, and reconstructing a structure?
- **Current analogues:** `src/editor/`, `src_edit/`, and editor Actual candidate generation.
- **BQN lens:** Under `⌾`, Undo `⁼`, and deliberately narrow canonical subsets.
- **What becomes visible:** Which parts of an edit are a reversible structural view and which parts depend on external textual evidence.
- **Known contract or risk:** Production editor correctness includes bytes, comments, metadata, ordering, identity, admission, stale checks, backup, and atomic publication. No exact inverse has been proven for the full Journal surface.
- **Current destination:** personal-book experiment and pure toy probe only.
- **Revisit signal:** A deliberately canonical in-memory Journal subset receives an exact round-trip contract.
- **Next useful probe:** Define a tiny synthetic transaction structure with no comments or optional metadata, then characterize view-edit-reconstruct and failed round trips.

### add-ui actions as an aligned catalog

- **Question or capability:** Can repeated action declarations in `tools/add-ui.sh` become one stable catalog without hiding the mode-specific human interaction?
- **Current analogue:** `tools/add-ui.sh` help text, accepted modes, selector rows, and interaction dispatch.
- **BQN lens:** aligned column arrays, namespace row projections, masks, Deduplicate `⍷`, Index Of `⊐`, function arrays, Choose `◶`, explicit publication views, exact character values, and a narrow text boundary.
- **Observed evidence:** `experiments/bqn/add_ui_action_catalog.bqn` established the aligned portfolio model. `experiments/bqn/add_ui_action_export.bqn`, `add_ui_action_metadata.tsv`, `add_ui_action_export_consumer.sh`, and the export result note compare a BQN-owned view, static TSV, and shell consumption. GitHub Actions runs `30535122149` and `30536814450` completed successfully.
- **What became visible:** One action coordinate can generate selector rows, validate alignment and uniqueness, reject duplicate and unknown keys, preserve source order, and publish only `key / label / family` to a thin client. The shell consumed the exact twelve-row export without receiving BQN namespaces or interaction control flow.
- **Learning from failed forms:** Function selection exposed BQN syntactic roles and led to Choose `◶`; namespace publication required an explicit value view; right-to-left evaluation rewarded named evidence values. The export probe additionally showed that `"\t"` is not a C-style tab escape in BQN. Naming the exact separator as `tab ← @+9` made the byte boundary explicit.
- **Known contract or risk:** The BQN-to-shell boundary is viable but adds generation, encoding, marker, failure-publication, and runtime-dependency decisions. A static TSV is already client-shaped and may be clearer for one consumer. `/dev/tty`, cancellation, fzf/gum selection, multi-posting loops, subprocess orchestration, status translation, and approved editor invocation remain effectful shell stages.
- **Current destination:** observed experiments retained. A production BQN exporter, static TSV owner, and direct shell ownership remain live alternatives; none is selected. Generic BQN-driven interaction choreography remains parked.
- **New capability:** an admitted action metadata surface could serve terminal menus, conversational clients, future thin presenters, and generated documentation from the same coordinates.
- **Revisit signal:** a second real metadata client appears, or help/admission/menu order and labels demonstrably drift across current shell declarations.
- **Next useful move:** on that signal, select one finite owner and characterize duplicate keys, unknown keys, order, encoding, unavailable export, and client fallback before changing production UI.

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
