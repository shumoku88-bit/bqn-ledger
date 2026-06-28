# Architecture Next: cycle-ledger-core

Status: draft
Branch: `refactor/cycle-ledger-core`
Scope: design-first refactor plan for `bqn-ledger`

## 1. Why this branch exists

This branch exists to redesign the current `bqn-ledger` core as a clearer cycle-oriented report engine without breaking the working `main` branch.

The current system is already useful for daily life. Therefore, `main` should remain the stable place for practical household-accounting reports.

This branch is a separate work area for clarifying the architecture before implementation changes are merged back.

In short:

- `main` is the working household-accounting tool.
- `refactor/cycle-ledger-core` is the design and refactor workbench.
- Code changes should follow written contracts, not the other way around.

## 2. Core idea

The system is not primarily a general accounting application.

It is a report engine for reading a living cycle.

The design should preserve the current strengths:

- canonical data is stored in human-readable TSV files
- BQN reads canonical data and produces derived views
- BQN does not rewrite canonical data
- reports should be stable, inspectable, and reproducible
- the user should be able to understand the source records directly

The proposed internal model remains:

```text
Day × Account × Layer
```

The initial layers are fixed as:

```text
actual    records from journal.tsv
plan      records from plan.tsv
budget    records from budget_alloc.tsv and budget-related projections
forecast  reserved for future projections
```

`forecast` may remain unused at first. It is a reserved layer, not an implementation obligation.

## 3. Design stance

This refactor should make the existing system clearer, not larger for its own sake.

The desired direction is:

```text
small report surface
clear data contracts
stable internal array model
explicit checks and warnings
```

The system should first answer practical questions:

- What is the current cycle?
- How much remains until the next income date?
- Is food spending safe?
- Is daily spending safe?
- Are planned payments visible?
- Are actual and planned records drifting apart?
- Are there missing or unavailable sections?

The implementation should not start by chasing every possible report.

## 4. Canonical data files

The expected canonical data files are:

```text
data/journal.tsv        actual records
data/plan.tsv           planned records
data/budget_alloc.tsv   budget or envelope allocation records
data/accounts.tsv       account names, display names, roles, and attributes
data/cycle.tsv          living-cycle boundaries
data/config.tsv         minimal settings, if needed
```

These files are the source of truth.

Derived files, caches, exports, or report outputs are not canonical unless explicitly documented elsewhere.

## 5. Non-goals for the first phase

The first phase should not attempt to do all of the following:

- replace every existing report section
- introduce a new event-first data model
- rewrite canonical TSV files from BQN
- solve full double-entry export
- solve tax export
- build a general-purpose accounting system
- make `forecast` fully functional

Those may be future projects, but they are not required for the first architecture pass.

## 6. First report contract

The first report surface should stay close to the survival/reporting needs:

```text
1. current cycle summary
2. remaining amount until next income date
3. food / daily remaining amount
4. plan vs actual difference
5. incomplete planned items
6. checks / warnings / unavailable sections
```

This report surface is intentionally smaller than the internal model.

The internal model may be `Day × Account × Layer`, but the user-facing first report should remain compact.

## 7. Why implementation should wait

Implementation should wait until the branch has enough written contracts to answer:

- What does each TSV file mean?
- What does each layer mean?
- What is the minimum report that must remain correct?
- What should happen when data is missing?
- What should be warning, unavailable, or error?
- Which parts of the current engine feel unclear or insufficient?

The purpose is not to freeze all decisions in advance.

The purpose is to prevent accidental architecture, where the code decides the meaning before the user has named the need.

## 8. Current discomforts and open questions

This section is intentionally left as a living notebook.

Use it to collect the user's current dissatisfaction, uncertainty, and friction with the existing core engine before changing code.

Possible categories:

### 8.1 Core engine discomforts

- The user wants the core to preserve the strengths of BQN array processing, not merely be a general script written in BQN syntax.
- Open question: what would make this engine feel acceptable or convincing to an experienced BQN programmer?
- Open question: should the core expose a clear array shape contract, such as `Day × Account × Layer`, more explicitly than it does now?
- Open question: which parts should be ordinary named functions for clarity, and which parts should use more idiomatic array transformations?

### 8.2 Report output discomforts

- The current report has 12 sections and the user currently considers all of them necessary for daily workflow (see `docs/MAIN_SECTIONS.md`).
- The first `src_next` report surface may be compact, but production replacement must not silently remove report sections.
- Any section removal must be an intentional replacement decision, not an accidental simplification.
- See `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` for the section-level parity matrix tracking each section's status in `src_next`.

### 8.3 Data file discomforts

- The user wants to leave room for multiple currencies without implementing full multi-currency accounting in the first phase.
- Open question: should canonical records include a currency field now, even if all current values are JPY?
- Open question: should the internal cube remain single-currency at first, with currency treated as metadata or a future axis?
- Open question: should currency conversion be explicitly out of scope for the first phase?

### 8.4 Plan / budget / actual relationship discomforts

- TBD

### 8.5 AI maintenance discomforts

- The user wants a design that is easier to hand to AI agents without accidental damage to canonical data or report meaning.
- Open question: should the project define allowed and forbidden edit zones for AI-assisted work?
- Open question: should design documents describe which files are canonical, derived, experimental, or helper-only?

### 8.6 Naming and mental-model discomforts

- TBD

### 8.7 Dependency discomforts

- The current project depends partly on Go and shell scripts.
- The user wants to explore whether dependencies can be minimized, but does not yet have enough knowledge or experience to decide safely.
- Open question: what should be implemented in BQN itself?
- Open question: what should remain in shell because it is simple orchestration?
- Open question: what should remain in Go because BQN would make it awkward or fragile?
- Open question: should the project define a minimal core mode that needs only BQN and TSV files?

### 8.8 Information to gather

Before implementation, gather opinions or examples about:

- idiomatic BQN structure for small real-world report engines
- array-first design patterns for tabular financial data
- when BQN code should prefer explicit named steps over dense tacit style
- practical portability of BQN file I/O and command-line scripts
- whether Go and shell should be treated as optional helpers rather than core dependencies

## 9. Migration rule

Nothing from this branch should be merged into `main` merely because it is cleaner.

A change should be merged only when it improves clarity or reliability while preserving the daily usefulness of the current system.

Before merging implementation changes, compare the new output against the current output using fixtures or known real-world cases.

## 10. Suggested next documents

After this file, the next design documents should be:

```text
docs/DATA_CONTRACT.md
docs/REPORT_CONTRACT.md
docs/MIGRATION_PLAN.md
```

These should stay short at first.

The goal is to create enough rails for safe refactoring, not to build a paperwork castle.
