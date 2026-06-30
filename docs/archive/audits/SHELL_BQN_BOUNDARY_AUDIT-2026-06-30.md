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
| B5-003 | `tools/add-ui.sh` reverse selection | Reads `journal.tsv` directly and formats date/memo/from/to/amount for selection. | **Meaning in shell** | Candidate for next replacement. Add a BQN/editor `journal list` or `journal recent/list --format tsv` export, then parse that protocol in shell. |
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

## Next non-ad-hoc step

Do not continue by editing random shell snippets. The next targeted replacement should be B5-003:

1. Define a small BQN/editor export for journal selection rows.
2. Add a parity/smoke check using sandbox data.
3. Switch only `tools/add-ui.sh` reverse selection to that export.
4. Leave safe-write and UI display plumbing in shell.
