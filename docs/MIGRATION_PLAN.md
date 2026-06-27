# Migration Plan

Status: draft
Branch: `refactor/cycle-ledger-core`
Scope: safe migration from the current engine toward the cycle-ledger architecture

## 1. Purpose

This document defines how to move from the current `bqn-ledger` engine toward the cycle-ledger architecture without breaking the working `main` branch.

The migration should be slow, inspectable, and reversible.

The goal is not to replace the current system quickly.

The goal is to preserve daily usefulness while making the core easier to understand, test, and maintain.

## 2. Branch roles

```text
main
  stable daily-use branch
  current reports remain usable
  canonical data remains protected

refactor/cycle-ledger-core
  design and refactor workbench
  architecture documents live here first
  implementation experiments may happen here after contracts are clear
```

`main` should not receive speculative architecture changes.

`refactor/cycle-ledger-core` should not be treated as production until its output has been compared against known current behavior.

## 3. Migration principles

### 3.1 Preserve behavior first

Internal cleanup should preserve existing report meaning unless a change is explicitly marked as intentional.

For behavior-preserving work:

```text
golden output should not change
```

### 3.2 Document before implementation

Implementation should follow the design contracts:

```text
docs/ARCHITECTURE_NEXT.md
docs/DATA_CONTRACT.md
docs/AXIS_CONTRACT.md
docs/PROJECTION_CONTRACT.md
docs/REPORT_CONTRACT.md
docs/REPORT_VALUE_CONTRACT.md
```

If code pressure reveals that a contract is wrong, update the contract deliberately.

Do not let accidental code shape become the architecture.

### 3.3 Keep canonical data safe

Canonical TSV files should not be rewritten by the refactor.

Any migration work must treat canonical files as read-only unless the user explicitly requests a narrow data edit.

### 3.4 Prefer small slices

Migration should proceed one small report slice at a time.

Avoid a large rewrite that changes loaders, projections, report state, display formatting, and checks all at once.

## 4. Phase 0: Current-state reference

Before implementation, gather a stable reference of current behavior.

Tasks:

- identify the current minimum daily-use command or report path
- identify fixtures or real-world cases used for checking
- identify existing golden outputs, if any
- note which reports are essential for daily use
- note which reports are research/debugging aids

Exit condition:

- there is a clear baseline for comparing the new path against the current path

## 5. Phase 1: Contract alignment

Ensure the design documents describe the intended architecture clearly enough to guide work.

Tasks:

- keep `ARCHITECTURE_NEXT.md` as the branch intent and discomfort notebook
- keep `DATA_CONTRACT.md` as the canonical TSV contract
- keep `AXIS_CONTRACT.md` as the BQN shape contract
- keep `PROJECTION_CONTRACT.md` as the record-to-cube bridge contract
- keep `REPORT_CONTRACT.md` as the first report surface contract
- keep `REPORT_VALUE_CONTRACT.md` as the section result contract
- add open questions rather than hiding uncertainty

Exit condition:

- the first implementation slice can be described without changing canonical data or all reports at once

## 6. Phase 2: Read-only loader path

Create or adapt a read-only loader path that can load canonical TSV data without changing it.

Goals:

- TSV reading is explicit
- external process calls are visible as I/O boundaries
- loader output is inspectable
- missing files and malformed rows produce structured checks
- account and currency fields are available for AccountKey resolution

Important note:

The current main branch hardening notes mention `core.bqn.LoadChars` using `•SH "cat"` and `date.bqn.Today` using `•SH "date"`.

This phase should clarify whether those remain acceptable boundaries, get renamed, or move toward native BQN file access.

Exit condition:

- canonical TSV files can be loaded into a stable intermediate representation
- the path is read-only

## 7. Phase 3: Axis and AccountKey sanity

Before building polished reports, verify that the intended axes can stand up.

Target shape:

```text
Day × AccountKey × Layer
```

First-phase currency rule:

```text
AccountKey = (Account, Currency)
```

Goals:

- derive or declare Day axis
- derive resolved AccountKey table
- declare Layer order once
- confirm that different currencies resolve to different AccountKeys
- avoid scattered hardcoded axis-size literals

Exit condition:

- the engine can print or inspect axis sizes and AccountKey resolution for a small fixture

## 8. Phase 4: Projection path

Build a projection path from canonical records into an internal model.

Conceptual flow:

```text
source record
  -> account resolution
  -> currency resolution
  -> AccountKey resolution
  -> day/cycle resolution
  -> layer assignment
  -> delta output
```

Goals:

- repeated projection patterns are made visible
- account and currency resolution is shared where practical
- layer assignment is explicit
- mixed-currency numeric totals are impossible by construction
- account-key-axis size is derived or declared once

This phase should address the current hardening note that projection functions repeat the same structure.

Exit condition:

- a small set of records can be projected into `Day × AccountKey × Layer` or a clearly documented equivalent

## 9. Phase 5: Projection sanity check

Before implementing a full report, validate the array foundation.

Recommended sanity path:

```text
canonical TSV
  -> projection rows
  -> cube shape
  -> simple sums by Day / AccountKey / Layer
```

Goals:

- verify that the cube shape is visible
- verify that layer totals are plausible
- verify that currency-separated balances stay separated
- verify that unsupported data becomes checks, not silent corruption

Exit condition:

- a tiny inspectable state proves that the array is standing correctly

## 10. Phase 6: Minimal report state

Build a grouped report state instead of a single giant public Record.

Preferred shape:

```text
state.cube
state.snapshot
state.cycle
state.plan
state.budget
state.envelopes
state.checks
state.meta
```

Goals:

- avoid a 100+ field `BuildAt`-style namespace as the public API
- make section dependencies visible
- separate computation state from display formatting
- keep field schema inspectable

This phase should address the current hardening note about splitting the large `BuildAt` result into meaningful sub-records.

Exit condition:

- at least one report section can consume only the state groups it needs

## 11. Phase 7: First SectionResult slice

Implement the smallest useful report slice first as a `SectionResult`.

Recommended first slice:

```text
current cycle summary
```

Alternative first slice:

```text
food / daily remaining amount
```

Choose the slice that is easiest to compare against current behavior.

Goals:

- compute section values before formatting text
- attach section status: `ok`, `warning`, `unavailable`, or `error`
- return a conceptual `SectionResult` with summary/table/messages
- compare against current report output or fixture expectations

Exit condition:

- one small section works through the new path without breaking the old path

## 12. Phase 8: Expand protected report surface

Add the remaining first-phase report sections one by one:

```text
1. current cycle summary
2. remaining amount until next income date
3. food / daily remaining amount
4. plan vs actual difference
5. incomplete planned items
6. checks / warnings / unavailable sections
```

Rules:

- add one section at a time
- compare output meaning against current behavior
- document intentional changes
- keep unsupported data visible via section status

Exit condition:

- the first report contract is covered by the new path

## 13. Phase 9: Dependency review

After the minimum report path works, review dependencies.

Questions:

- Can the minimum report run with BQN + TSV only?
- Which shell scripts are orchestration rather than core logic?
- Which Go code is truly needed?
- Which helper tools are optional conveniences?
- Are external process calls clearly marked?

Possible target shape:

```text
required:
  BQN
  canonical TSV files

optional helpers:
  shell
  Go
  gum
  fzf

optional readers:
  Pluto.jl
  static HTML
```

Exit condition:

- dependency roles are documented
- core vs helper vs reader boundary is clear

## 14. Phase 10: Merge strategy

Do not merge the whole branch merely because it is cleaner.

Merge only when a slice improves clarity or reliability and preserves daily usefulness.

Possible merge styles:

### 14.1 Documentation-only merge

Merge architecture documents first if they help guide future main work.

### 14.2 Behavior-preserving hardening merge

Merge internal restructuring only when:

- checks pass
- golden output is unchanged
- section behavior is documented

### 14.3 New-path merge behind command or flag

If the new path coexists with the old path, merge it behind a separate command or explicit invocation.

Do not replace the daily-use path until the user has trusted the new output.

## 15. What should not happen

Avoid these migration mistakes:

- rewriting the whole engine in one pass
- changing canonical data format before the data contract is stable
- mixing different currencies silently
- adding a separate Currency axis before it becomes a primary requirement
- making Go or shell removal the main goal before understanding their roles
- reducing BQN code to generic scripting with BQN syntax only
- creating a beautiful report state that no daily report actually needs
- merging because the branch feels cleaner rather than because it is safer

## 16. First implementation candidate

When implementation starts, the likely safest first candidate is not a full report rewrite.

Recommended first implementation candidate:

```text
create a read-only `src_next/` or equivalent experimental path
load canonical TSV files
resolve AccountKey table
produce projection rows
materialize a tiny cube
print projection sanity checks
```

This keeps the old engine alive while the new architecture grows beside it.

## 17. Open questions

- Should the first implementation path live under `src_next/` or inside existing `src/` modules?
- Should the first user-facing slice be `current cycle summary` or `food / daily remaining amount`?
- Which current command should be the comparison baseline?
- Are existing golden outputs sufficient, or should new fixtures be added first?
- Should documentation-only changes from this branch be merged to `main` before code changes?
- Should AccountKeys be explicitly declared in `accounts.tsv` or derived by loader/projection?
