# Audit improvement backlog

Status: active backlog / docs-only
Created: 2026-06-30
Scope: `bqn-ledger` program structure, BQN source, shell tools, checks, and documentation boundaries

This document records concrete improvement candidates found during the program audit.
It is not an implementation claim. Items here should be converted into small PRs, each with a narrow acceptance criterion.

## Audit stance

The repository already has a clear core idea:

- source TSV files are the canonical data
- BQN owns meaning, calculation, validation, plain text report, and machine-readable export
- shell owns UI, selection, wrappers, and safe-write orchestration
- source TSV contracts should not be changed casually

The main opportunity is not to add features. The opportunity is to make the existing boundaries sharper, smaller, and harder to accidentally break.

## Current resolved item

### A0. Remove `eval` from `run_post_check`

Status: done in PR #29

The previous `run_post_check` built a command string and executed it through `eval`. That was unnecessarily fragile because `base_dir` flows into the `lint` post-check command.

Resolution:

- use a Bash command array
- execute the command directly
- print the command with `%q` quoting for readable diagnostics

No follow-up is needed unless a later shell scan finds another production-path command-string execution.

## Priority map

| Priority | Area | Main risk | Suggested PR style |
| --- | --- | --- | --- |
| P0 | shell execution boundary | unsafe or overly dynamic command execution | tiny single-purpose patches |
| P1 | `tools/edit-bqn` dispatcher | accidental growth, mixed responsibilities | docs-first split plan, then incremental extraction |
| P1 | optional file loading | missing file and read failure can collapse into the same state | loader contract + focused tests |
| P1 | date logic | duplicated date semantics and hidden drift | centralize date functions |
| P2 | shell/BQN meaning boundary | shell begins interpreting accounting/lifestyle semantics | replace shell parsing with BQN exports/protocols |
| P2 | report section architecture | section modules can drift in format and policy conventions | section contract checklist |
| P3 | performance/readability | repeated TSV reads or repeated derivations | only optimize after correctness boundaries settle |

## P0/P1 improvement candidates

### 1. Replace the remaining test-only hook `eval`

Status: candidate
Files:

- `tools/lib/safe-write.sh`
- `checks/check-safe-replace-line.sh`

Observation:

`safe_replace_line_checked` still has a test-only hook that runs `SAFE_WRITE_TEST_BEFORE_REPLACE_RENAME_HOOK` through `eval` when `BQN_LEDGER_TEST_MODE=1`.

This is not the same risk class as the former production post-check `eval`, because it is explicitly test-gated. Still, it keeps the habit of command-string execution alive.

Recommended design:

- make the hook a shell function name, not a command string
- check it with `declare -F -- "$hook"`
- call it as `"$hook"`
- update the check script to define a small function such as `append_race_marker`

Acceptance criteria:

- no `eval` remains in `tools/lib/safe-write.sh`
- `checks/check-safe-replace-line.sh` still simulates the race-before-rename case
- `tools/check.sh` passes

Suggested PR size: 2 files, tiny.

### 2. Split `tools/edit-bqn` by responsibility before it becomes the command hydra

Status: candidate
Files:

- `tools/edit-bqn`
- possibly new files under `tools/lib/` or `tools/edit/`

Observation:

`tools/edit-bqn` is already acting as a large dispatcher for multiple command families. It contains command routing, parsing, BQN invocation, protocol handling, and safe-write wiring in the same entrance corridor.

This conflicts with the existing constraint in `TODO.md` that `tools/edit-bqn` should not casually become a huge dispatcher.

Recommended target shape:

```text
tools/edit-bqn
  small CLI entrypoint
  parses top-level command only
  delegates to command modules

tools/lib/edit-common.sh
  shared argument helpers
  BQN command invocation
  protocol parsing helpers
  common safe-write bridge

tools/edit/journal.sh
  journal add / reverse path

tools/edit/budget.sh
  budget add path

tools/edit/plan.sh
  plan add / edit / finish / related path

tools/edit/issue.sh
  issue add path
```

Non-goal:

- do not redesign source TSV
- do not change CLI compatibility
- do not change editor protocol in the same PR

Acceptance criteria for the first PR:

- add only a design document or extract one tiny helper
- `tools/edit-bqn` keeps the same user-facing behavior
- `tools/check.sh` passes

Suggested sequence:

1. document the current subcommand groups and shared boundaries
2. extract common BQN invocation/protocol parsing
3. move one low-risk command family, probably `issue add`
4. move `journal add` / `budget add`
5. move `plan` commands last, because they carry more workflow assumptions

### 3. Make optional file loading distinguish missing from unreadable

Status: candidate
Files:

- `src_next/loader.bqn`
- callers of `ReadLinesOptional`
- checks/fixtures for missing optional sources

Observation:

`ReadLinesOptional` currently returns an empty list for any exception raised by `ReadLines`. The comment says it returns empty when a file is missing or unreadable. That makes two different states look identical:

- the optional file is intentionally absent
- the file exists but cannot be read or parsed as expected

For a ledger, silent collapse into empty input is dangerous because absence and failure have different meanings.

Recommended design:

- keep a missing-ok helper for truly optional files
- add a stricter helper for files that may be absent but must fail if present and unreadable
- document which source files are required and which are optional

Possible API shape:

```bqn
ReadLinesIfPresent ← {
  # missing -> ⟨⟩
  # present but unreadable -> fail
}
```

Caution:

BQN file-existence detection may need to be handled carefully. Do not replace one broad catch with another broad catch hidden under a new name.

Acceptance criteria:

- tests cover missing optional file
- tests cover present-but-unreadable file where feasible on the target platform
- existing fixture behavior for genuinely missing optional files is unchanged

Suggested PR size: medium, because call sites need review.

### 4. Centralize date logic

Status: candidate
Files to inspect:

- `src_next/date.bqn`
- `src_next/projection.bqn`
- `src_next/actual_comparison.bqn`
- other modules using day indexes, cycle ranges, or date text parsing

Observation:

Date functions are spread across multiple modules. The repository has `src_next/date.bqn`, but date validation/conversion logic also appears in projection/comparison paths.

Risk:

- one module accepts a date shape another rejects
- cycle boundary math drifts from report math
- future checks accidentally depend on subtly different epoch logic

Recommended design:

`src_next/date.bqn` should own:

- valid date text check
- date to ordinal/day index
- ordinal/day index to date text
- days between dates
- cycle half-open range helpers

Other modules should import those functions instead of defining their own.

Acceptance criteria:

- a grep for duplicate date conversion names no longer finds parallel implementations
- existing date/cycle fixtures pass
- at least one dedicated date contract check exists

Suggested PR style:

1. add/expand date module tests without moving logic
2. move one function at a time
3. delete duplicate implementations only after parity checks exist

### 5. Tighten shell/BQN meaning boundary

Status: candidate
Files to inspect:

- `tools/add-ui.sh`
- `tools/main-ui.sh`
- `tools/bl`
- `tools/lib/*`
- BQN exports used by shell tools

Observation:

The architecture boundary says shell should handle UI, selection, wrappers, and safe-write orchestration. Meaning and accounting/lifestyle rules belong to BQN or config-derived exports.

Some shell scripts still parse source TSV enough to make semantic choices, such as reading account metadata or role-like fields for UI candidate generation.

Risk:

- shell and BQN disagree about account meaning
- role/config changes require edits in multiple languages
- UI tools become a second ledger engine in miniature

Recommended design:

- shell may format and filter precomputed candidate rows
- BQN should export candidate lists or semantic summaries
- shell should avoid deriving account roles, budget roles, or lifecycle state directly from TSV when BQN already has that knowledge

Acceptance criteria:

- document each shell semantic read as allowed/temporary/disallowed
- replace one shell semantic parse with a BQN export in a small PR
- preserve existing UI behavior

### 6. Define a report section contract checklist

Status: candidate
Files to inspect:

- `src_next/report_sections.bqn`
- individual `src_next/*report*` or section modules
- `config/report_labels.tsv`
- report fixture checks

Observation:

The report architecture is powerful, but each section can accumulate local conventions for labels, formatting, missing-data behavior, warning status, and machine-readable output.

Recommended contract for each section:

- section key
- required context fields
- optional context fields
- empty-input behavior
- warning/error behavior
- label keys used
- human report output
- compact/machine output, if any
- fixture coverage

Acceptance criteria:

- add a docs-only checklist first
- choose one section and annotate it as the reference example
- later PRs can align other sections to the same shape

## P2/P3 cleanup candidates

### 7. Check repeated TSV reads and repeated context construction

Status: candidate, not urgent

Observation:

The repo values clarity over premature optimization, which is right for this project. Still, repeated reading/derivation can become confusing when CLI tools call BQN many times.

Recommended approach:

- do not optimize blindly
- first document the expensive paths
- add timing only if daily use feels slow
- prefer fewer public entrypoints over cache complexity

Acceptance criteria:

- identify top repeated calls
- no caching added unless measured need exists

### 8. Keep docs/current-state maps short and navigable

Status: candidate

Observation:

The project has many docs and completed-plan archives. This is useful, but the active navigation surface must stay small.

Recommended approach:

- keep `TODO.md` for only current/next tasks
- keep long audits in docs backlog files
- move completed histories into archive
- add short pointers instead of duplicating long plans

Acceptance criteria:

- this audit backlog remains a reference, not a dumping ground
- completed items are marked and eventually archived

## Suggested implementation order

### Batch 1: Safety burrs

1. Remove the remaining test-only hook `eval`.
2. Add a grep/check that prevents new non-test `eval` in `tools/lib/safe-write.sh` or all safe-write paths.

### Batch 2: Loader correctness

1. Document required vs optional source files.
2. Add tests for missing optional files.
3. Split optional missing from unreadable/present failure.

### Batch 3: Dispatcher boundary

1. Document `tools/edit-bqn` command groups.
2. Extract common shell helper functions.
3. Move the smallest command family out first.

### Batch 4: Date spine

1. Add date contract checks.
2. Move date conversions into `src_next/date.bqn`.
3. Delete duplicates.

### Batch 5: Shell/BQN boundary polishing

1. Inventory shell scripts that parse source TSV semantics.
2. Replace one parse with a BQN export.
3. Repeat only where it improves clarity.

## Non-goals

The audit does not recommend these as immediate changes:

- rewriting the project in another language
- changing source TSV format
- changing CLI behavior casually
- replacing BQN as the semantic/calculation core
- adding a database
- adding broad caching before measurement
- large refactors that mix behavior changes with file movement

## PR slicing rule

Each implementation PR should answer four questions:

1. What exact risk is reduced?
2. What behavior is intentionally unchanged?
3. What check proves the unchanged behavior?
4. What is explicitly left for later?

If a PR cannot answer those four questions, it is too large.
