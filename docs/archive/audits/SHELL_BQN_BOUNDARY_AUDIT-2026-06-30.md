# Shell/BQN Boundary Audit — 2026-06-30

Status: active audit for PR #30 Batch 5
Scope: shell scripts under `tools/` that read source/config TSV or machine-readable BQN/editor output.

## Boundary rule

Shell may own UI, menu selection, wrapper plumbing, safe-write orchestration, file existence checks, and parsing of machine-readable outputs produced by BQN/editor commands.

Shell must not own ledger/accounting/household meaning from source TSV. In particular, role/account/date/plan-series semantics should come from BQN export, `src_edit` protocol, or config-specific readers.

## Classification

| ID | Location | Current behavior | Classification | Decision |
|---|---|---|---|---|
| B5-001 | `tools/add-ui.sh:accounts()` | Previously read `accounts.tsv` directly and filtered `role=` metadata with awk. | **Meaning in shell** | Replaced in this batch with `tools/edit account list [--role ROLE]`, backed by `src_edit/account_list_cmd.bqn`. |
| B5-002 | `tools/add-ui.sh` plan finish/edit selection | Parses `tools/edit plan list --format tsv` fields with `cut`. | OK: BQN/editor protocol parsing | Keep. The meaning and row ordering are owned by `src_edit/plan_list_cmd.bqn`; shell only selects a displayed row. |
| B5-003 | `tools/add-ui.sh` reverse selection | Previously read `journal.tsv` directly and formatted date/memo/from/to/amount for selection. | **Meaning moved to BQN/editor export** | Replaced with `tools/edit journal list --format tsv`, backed by `src_edit/journal_list_cmd.bqn`; shell now parses only the UI selection protocol. |
| B5-004 | `tools/main-ui.sh` source file list for preview/cache invalidation | Enumerates known source/config files to hash/check cache freshness. | OK: file plumbing | Keep. It does not interpret row/account meaning. |
| B5-005 | `tools/main-ui.sh` reads `config.tsv` key `fzf_preview_window`. | Config/presentation setting read in shell. | OK: presentation config | Keep unless config loading is later centralized. |
| B5-006 | `tools/lib/theme.sh` reads `config.tsv` / `system_defaults.tsv` for theme/base lookup. | Config/presentation setting read in shell. | OK: presentation config | Keep; not source TSV accounting meaning. |
| B5-007 | `tools/lib/system-defaults.sh` reads `config/system_defaults.tsv` and checks required files. | Path/default resolution and file existence. | OK: wrapper plumbing | Keep. |
| B5-008 | `tools/edit-bqn` parses safe-write output for `Backup:`. | Safe-write protocol parsing. | OK: write orchestration | Keep. |
| B5-009 | `tools/plan-finish-replenish-ui.sh` parses `tools/edit plan related --format tsv`. | BQN/editor protocol parsing. | OK: BQN/editor protocol parsing | Keep. Relation-key semantics are in `src_edit/plan_related_cmd.bqn`. |
| B5-010 | `tools/bl` maps fixed file names to editor/view actions. | File/menu selection. | OK: UI routing | Keep. |

## Reference replacement completed

`tools/add-ui.sh` no longer interprets `accounts.tsv` `role=` metadata. It calls:

```bash
tools/edit --base "$base_dir" account list --role asset
```

The export is implemented by `src_edit/account_list_cmd.bqn`, using `src_next/account_key.bqn` role resolution. This keeps account metadata semantics on the BQN side while preserving shell UI selection behavior.

## Reference replacement completed: journal reverse selection

B5-003 was replaced without broadening shell responsibility:

1. `src_edit/journal_list_cmd.bqn` defines a small read-only export for journal selection rows.
2. `tools/edit journal list --format tsv` exposes the protocol (`number date memo from to amount display`).
3. `checks/check-edit-bqn-journal-list.sh` verifies read-only behavior, TSV shape, invalid format fail-closed behavior, and empty memo preservation.
4. `tools/add-ui.sh` reverse selection consumes only the BQN/editor protocol and no longer reads `journal.tsv` directly.

Next boundary work should start with another audit row or a new audit entry before implementation; do not continue by editing random shell snippets.

## Follow-up audit: editor boundary整理 plan (2026-07-01)

Status: Batch A / docs-audit only. No implementation change in this batch.

Purpose: prepare `tools/edit-bqn` / `tools/add-ui.sh` / `src_edit` cleanup without creating throwaway work before later BQN narrow command extraction.

### Design direction

Do **not** start by splitting command groups around the current `src_edit/editor_cmd.bqn` invocation shape. Later narrow commands such as `src_edit/journal_reverse_cmd.bqn`, `src_edit/plan_edit_cmd.bqn`, or `src_edit/plan_finish_cmd.bqn` may replace those invocations.

Instead, first extract only shell responsibilities that remain valid regardless of which BQN command produced the protocol:

- capture BQN stdout/stderr and preserve useful errors
- parse/validate stdout protocols such as `OK\tAPPEND\t<target>` and `OK\tREPLACE\t<line>\t<id>`
- print preview text
- confirm or dry-run
- call `safe_append_checked` / `safe_replace_line_checked` / optional create-if-missing path
- surface backup / write result / post-check diagnostics

### Current command group inventory

| Area | Current shell location | BQN owner | Current shell responsibility | Keep after C案? | Notes |
|---|---|---|---|---|---|
| account list | `tools/edit-bqn` | `src_edit/account_list_cmd.bqn` | parse `--role`, dispatch read-only command | yes | OK. Shell does not interpret roles. |
| journal list | `tools/edit-bqn` | `src_edit/journal_list_cmd.bqn` | parse `--format`, dispatch read-only command | yes | OK. Shell validates presentation format only. |
| plan list / related | `tools/edit-bqn` | `src_edit/plan_list_cmd.bqn`, `src_edit/plan_related_cmd.bqn` | parse selector/format args, dispatch read-only command | yes | OK. Shell parses BQN-owned protocol only in UI. |
| journal/budget/plan add | `tools/edit-bqn` | `src_edit/journal_add_cmd.bqn`, `src_edit/plan_add_cmd.bqn` | parse CLI, capture BQN APPEND protocol, preview, confirm, safe append, post-check | yes | Good first target for protocol helper; do not alter CLI. |
| plan finish | `tools/edit-bqn` | `src_edit/plan_finish_cmd.bqn` | parse CLI, capture APPEND protocol, preview, confirm/apply, safe append, post-check | yes | BQN command already narrow; helper should not depend on command args. |
| journal reverse | `tools/edit-bqn` | `src_edit/journal_reverse_cmd.bqn` | parse CLI, capture extended APPEND protocol, show original/reversed summary, safe append, post-check | yes | Narrow command extraction done 2026-07-01. APPEND apply helper remains command-independent; summary fields are command-specific preview extras. |
| plan edit | `tools/edit-bqn` | `src_edit/plan_edit_cmd.bqn` | parse CLI, capture REPLACE protocol, preview diff, confirm, safe replace, post-check | yes | Narrow command extraction done 2026-07-01. REPLACE apply helper remains command-independent. |
| issue add | `tools/lib/edit-bqn-issue.sh` | `src_edit/issue_add_cmd.bqn` | parse CLI, capture APPEND protocol, preview, confirm, safe append or create-if-missing | yes with caveat | Existing-file append now uses common APPEND helper. Missing `issues.tsv` remains a deliberate create-if-missing exception for the optional file. |

### Responsibilities that should remain in shell

These are stable even after BQN narrow command extraction:

- public CLI option syntax and compatibility in `tools/edit`
- choosing which BQN command to run
- stdout/stderr capture and protocol fail-closed checks
- dry-run / confirmation UX
- invoking the single safe-write layer
- backup visibility and post-check orchestration
- UI row selection from BQN/editor TSV export protocols

### Responsibilities that should stay or move to BQN

These must not be reintroduced into shell:

- account role interpretation
- journal row parsing from source TSV
- plan completion / active-plan selection semantics
- plan relation / `series=` fallback semantics
- plan_id validation and generation
- metadata validation beyond syntax needed for shell argument handling
- date and amount validation for ledger rows

### `tools/add-ui.sh` boundary notes

`tools/add-ui.sh` currently consumes BQN/editor export protocols rather than source TSV directly:

- account candidates: `tools/edit account list [--role ROLE]`
- plan selection: `tools/edit plan list --format tsv`
- journal reverse selection: `tools/edit journal list --format tsv`

`cut -fN` usage in `tools/add-ui.sh` is acceptable only as parsing of those BQN-owned UI selection protocols. If field positions change, update the BQN command contract and checks together.

`plan_series` input in `tools/add-ui.sh` is an input convenience: the UI may append `series=<value>` when the user explicitly enters a series and did not already provide one. The meaning of series matching and related-plan fallback remains owned by `src_edit/plan_related_cmd.bqn`, not by UI shell. The shell-side validation is intentionally limited to safe token characters for interactive input; ledger validation and recurring-plan semantics remain in BQN.

### Next safe implementation batch

Batch B should introduce protocol helpers that are independent of BQN command names and argument shapes, likely in `tools/lib/edit-bqn-common.sh` or a new small helper file. Start with the common APPEND path; defer command-group module splitting until after the protocol helper boundary is proven by checks.

Batch B/C update (2026-07-01): common APPEND / REPLACE helpers now live in `tools/lib/edit-bqn-common.sh` and are used by journal/budget/plan add, plan finish, journal reverse append apply, plan edit replace apply, and existing-file issue append. `issue add` keeps only the missing-file `safe_create_checked` branch as an explicit optional-file exception.

Batch E update (2026-07-01): `journal reverse` and `plan edit` now use narrow commands (`src_edit/journal_reverse_cmd.bqn`, `src_edit/plan_edit_cmd.bqn`). The former aggregate `src_edit/editor_cmd.bqn` dispatcher was removed after active command paths were replaced and `tools/check.sh` passed.
