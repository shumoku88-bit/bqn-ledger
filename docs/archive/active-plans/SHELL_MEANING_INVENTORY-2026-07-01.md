# Shell Meaning Inventory

Status: active inventory
Date: 2026-07-01

## Purpose

Inventory places where shell code currently knows ledger/report/UI meaning, so
future structured exports can reduce seams without changing behavior all at
once.

This is an inventory, not an implementation mandate. The next changes should be
small and reversible.

## Classification

```text
P0  shell reads source TSV and derives accounting/household meaning
P1  shell parses human report strings as data
P2  shell hard-codes semantic candidates, statuses, modes, or section metadata
P3  shell owns presentation labels or file identity only
OK  shell parses machine/editor protocol or config meant for shell use
TEST check-only parsing; acceptable unless it becomes runtime behavior
```

## Runtime inventory

| Priority | File / function | What shell currently knows | Source touched | Replacement candidate | Notes |
|---|---|---|---|---|---|
| OK | `tools/main-ui.sh::section_list` | Reads report section key/label/order from structured metadata export; appends UI-local `all`, `actions` | none | implemented: `tools/report-section-metadata` plus UI-local synthetic actions | Completed first replacement slice. `all` and `actions` remain UI commands, not BQN report sections. |
| P2 | `tools/main-ui.sh` command usage / `case "$cmd"` | Direct section command names and display menu surface | none | Same metadata export for section keys; keep command aliases in shell | Direct CLI compatibility may keep known aliases even after selector uses export. |
| P3 | `tools/main-ui.sh` cache invalidation `src_files` | Which source/config files affect report cache | source file mtimes only | possible future BQN/report cache manifest | Does not parse TSV meaning; it only tracks mtimes. Safe for now. |
| OK | `tools/main-ui.sh::select_section` | Reads `fzf_preview_window` from `<base>/config.tsv` | `config.tsv` | config is UI-owned | This is presentation config, not accounting meaning. Keep in shell unless config contract changes. |
| P2 | `tools/bl::menu_list` | Command hub action list and high-level categories | none | Keep shell-owned | These are app navigation actions, not ledger meaning. |
| P3 | `tools/bl::tsv_list`, `resolve_tsv_path` | Source TSV file names and presentation descriptions | file paths only | docs/config optional later | File identity is acceptable for manual editor doorway. It must not infer ledger meaning. |
| P2 | `tools/add-ui.sh::choose_mode` | Daily write modes and from/to role shape (`expense`, `income`, `budget`, etc.) | none | probably keep as UI intent menu; BQN editor validates | Shell chooses operation intent; BQN owns validation and account semantics. |
| OK/P2 | `tools/add-ui.sh::accounts`, `select_account` | Account roles requested by UI (`asset`, `expense`, `income`, `budget`) | no direct TSV read | already `tools/edit account list --role` | Good boundary: role interpretation is BQN-owned. Shell still owns which role a mode asks for. |
| P2 | `tools/add-ui.sh::choose_date_key`, `choose_plan_date_key` | Date presets `today`, `yesterday`, `tomorrow` | none | keep UI convenience | Not accounting meaning. Watch reproducibility if used in tests; editor/report core should still validate dates. |
| P2 | `tools/add-ui.sh::choose_budget_memo` | Budget memo presets `alloc`, `seed`, `move` | none | possible config/BQN budget candidate export | Low risk but budget-specific vocabulary lives in shell. |
| OK | `tools/add-ui.sh::choose_meta` presets | Reads metadata presets from `config/ui_meta_presets.tsv`; shell fallback is only generic `empty` / `custom` | `config/ui_meta_presets.tsv` optional | implemented: config-owned UI presets + BQN validation on write | Completed small cleanup: domain-specific `tax` / `biz` presets no longer live as shell fallback values. |
| P2 | `tools/add-ui.sh::meta_has_key` / `series=` addition | Knows `series` metadata key and allowed series characters | none | BQN editor plan-id/metadata helper | Shell currently adds a convenience `series=` token. Semantics are documented as owned by BQN, but the key leaks into shell. |
| OK | `tools/add-ui.sh` plan list / journal list selection | Parses BQN editor TSV protocol columns for display/index/id | no direct TSV read | already `tools/edit ... list --format tsv` | Acceptable protocol parsing. Keep column contract documented and checked. |
| OK/P2 | `tools/plan-finish-replenish-ui.sh` plan list / related parsing | Parses BQN editor TSV rows and relation key/value | no direct TSV read | already `tools/edit plan list/related --format tsv` | Acceptable as protocol parsing, but shell owns replenishment interaction policy. |
| P2 | `tools/plan-finish-replenish-ui.sh::add_months` and interval menu | Monthly/weekly follow-up date arithmetic | none | future BQN plan replenishment candidate/export | This is household workflow logic in shell. Candidate for later extraction if replenishment becomes canonical. |
| P2 | `tools/plan-finish-replenish-ui.sh` `series=$plan_series` append | Knows `series` metadata key for follow-up plan | none | BQN editor replenishment command | Same leak as add-ui, higher priority if recurring plan workflows expand. |
| OK | `tools/edit-bqn` and `tools/lib/edit-bqn-common.sh` | Parses BQN editor protocol headers (`OK APPEND`, `OK REPLACE`) and backup lines | target files via safe-write | keep shell protocol boundary | This is the intended write boundary, not ledger meaning. |
| OK | `tools/lib/system-defaults.sh` | Reads `config/system_defaults.tsv` defaults and required report file presence | config + existence checks | keep shell config boundary | Does not parse accounting rows. |
| OK | `tools/lib/theme.sh` | Reads `theme` from config and sets colors/gum args | `config.tsv` | keep shell presentation boundary | Presentation-only. |
| OK | `tools/doctor` | Checks tool availability and required/optional file presence | file existence, report smoke output | keep diagnostic shell | It greps report smoke text only as liveness, not data derivation. |

## Check / devtool inventory

These are not runtime UI behavior, so they are lower risk. They should still avoid
becoming copy-pasted runtime logic.

| Priority | File / function | What it parses | Notes |
|---|---|---|---|
| TEST | `checks/check-ui-smoke.sh` | Expected section labels, `--list-sections` keys | Check-only drift detection. Update when section metadata export becomes the UI source. |
| TEST | `checks/check-src-next-report.sh` | Human section headers | Human report golden/smoke checking is valid in tests. Not a UI API. |
| TEST | `checks/check-src-next-*.sh` | Machine summary keys and compact outputs | Acceptable contract checks. Prefer machine outputs over human report parsing. |
| TEST | `checks/check-edit-bqn-*.sh` | BQN editor protocol TSV | Acceptable protocol checks. |
| TEST | `tools/devtools-check.sh` | summary key counts, doc references, tool liveness strings | Devtool-only. |
| TEST | `tools/repo-index` | source/docs indexing | Devtool indexing, not ledger semantics. |

## Highest-value next slices

### Slice 1: `main-ui` section selector uses metadata export

Status: done in this branch.

Replacement:

```text
tools/main-ui.sh::section_list
  -> tools/report-section-metadata | select key,label
  + append UI-local rows: all, actions
```

Constraints kept:

- Do not change `tools/report` behavior.
- Do not remove `--list-sections` yet.
- Keep direct section commands compatible.
- Keep preview cache behavior unchanged.

### Slice 2: budget/meta presets audit

Status: partially done in this branch.

Decision for `choose_meta`:

- domain-specific presets live in `config/ui_meta_presets.tsv`
- shell fallback keeps only generic `empty` / `custom`
- BQN editor validation remains the write-time guard for `key=value` metadata

Remaining: decide whether `choose_budget_memo` should remain UI convenience,
move to config, or be exported by BQN/editor.

### Slice 3: recurring plan replenishment boundary

`plan-finish-replenish-ui.sh` currently owns date arithmetic and `series=`
follow-up creation. If this workflow becomes important, create a BQN editor
candidate/export or command so shell only selects among BQN-proposed follow-up
rows.

## Current conclusion

There are no obvious runtime P0 cases in the main UI path: shell is not directly
reading source TSV rows to compute accounting or household numbers.

The main leaks are P2:

- budget memo / series UI vocabulary
- replenishment follow-up date logic

Resolved in this branch:

- report section metadata hard-coded in shell → `tools/report-section-metadata`
- domain-specific meta preset fallback in shell → `config/ui_meta_presets.tsv`
