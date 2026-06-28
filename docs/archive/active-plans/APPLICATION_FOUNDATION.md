# Application Foundation Guide

Status: design guide / frozen (TUI凍結)
Date: 2026-06-22

> [!WARNING]
> 2026-06-28の指示により、TUI開発は一旦凍結されました。本ガイドは将来の参照用として残されています。

This document records what is still needed if `bqn-ledger` is treated as a foundation for a TUI, GUI, web UI, or other application shell.

The current core is already useful as a CLI-based household accounting foundation:

```text
data/*.tsv  = source of truth
BQN         = read, validate, calculate, report, export
Go editor   = safe source TSV append/editing boundary
tools/*.sh  = daily entry points / wrappers
TUI/GUI     = optional shell above the stable core
```

The missing pieces are mostly application outer shell contracts, not a replacement accounting engine.

---

## 1. Boundary principle

The application layer must not become another accounting engine.

Keep this split:

```text
source TSV  -> canonical input
BQN         -> canonical numeric engine / reports / checks / exports
Go editor   -> source TSV editor with safety rails
TUI/GUI     -> display, selection, input assistance, navigation
```

A TUI, GUI, or web app may:

- show reports and warnings
- guide input
- call `tools/edit` or other approved editor commands
- call BQN report/export/check commands
- keep UI-only state outside `data/*.tsv`

It must not:

- duplicate balance, envelope, cycle, plan, or comparison calculations
- reinterpret `journal.tsv`, `plan.tsv`, or `budget_alloc.tsv` differently from BQN
- write source TSV directly unless it goes through an approved editor path
- make derived UI state part of the accounting source of truth

Useful metaphor:

```text
CLI core is the ground.
TUI is the weather.
```

The weather may change. The ground must stay stable.

---

## 2. Stable operation API

An application shell needs stable commands with machine-readable output.

Current human-facing commands are already useful, but application shells benefit from explicit output formats.

Candidate operation groups:

```text
reports:
  show dashboard / snapshot / envelope / plan / actual comparison

plans:
  list open plans
  list all plans
  finish plan preview
  finish plan apply

journal:
  add actual expense/income/move
  inspect recent entries

budget:
  add allocation
  inspect envelope allocation/spend/balance

txn bundles:
  list txn_id bundles
  show one txn_id bundle
  show rows missing txn_id

checks:
  run lint
  run full check
  show warnings/errors with source file and line
```

Application-facing commands should eventually support formats such as:

```text
--format text   human display
--format tsv    stable app/table input
--format json   optional richer app input
```

Do not require TUI/GUI code to parse decorative human report text when a stable TSV/JSON export can exist.

---

## 3. Write boundary and recovery

Current safe write scope is intentionally narrow.

Already acceptable direction:

- append-only writes for approved source TSV operations
- preview before apply
- backup before write
- stale check before write
- post-write lint/check where appropriate

Still application-relevant gaps:

- existing row edit contract
- delete policy in an app shell
- multi-file transaction policy
- undo / restore from backup flow
- failure recovery after partial operation attempts
- user-facing explanation of whether a failed command wrote anything

Current preference remains conservative:

```text
append and approved editor operations = tool-assisted
large correction / deletion           = human reviews source TSV directly
```

Any app shell should preserve that safety boundary unless explicitly redesigned.

---

## 4. Schema version and migration

As soon as app shells exist, old data and new tools may drift.

Future application work should consider an explicit schema/version contract, for example:

```text
config.tsv or a small schema file:
  schema  ledger-main  1
```

Questions to decide later:

- how to detect older data layout
- how to handle missing metadata keys
- how to warn about unsupported schema versions
- whether migration is automatic, assisted, or manual
- whether real `data/*.tsv` migration is ever performed by an app shell

Schema handling should protect source TSV readability and avoid surprising rewrites.

---

## 5. UI state separation

Application state is not accounting data.

Keep UI-only state outside `data/*.tsv`:

```text
data/*.tsv        source of truth
.app-state/*      last opened view, filters, draft UI state
.cache/*          generated cache, safe to delete
.backup/*         write backups
out/*             regenerated exports
```

Examples of UI state:

- last selected section
- last selected account
- recent payee / party suggestions
- input drafts
- collapsed/expanded panes
- filters and sort order

These should not contaminate `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, or `accounts.tsv`.

---

## 6. Diagnostics and repair path

Application usability depends less on visual polish and more on clear error recovery.

A good app shell should be able to show:

- which file failed
- which line failed
- what rule failed
- what value was expected
- what was written or not written
- where the backup is
- what the human should inspect manually

Important future work:

```text
source/line diagnostics for event-level checks
machine-readable check output
clear severity levels: error / warning / info
```

This is especially important for `txn_id` bundles and future multi-posting lint.

---

## 7. Install, doctor, and environment checks

A real app wrapper needs a way to check its environment.

Candidate commands:

```text
make check
make doctor
make install
```

`doctor` could inspect:

- BQN executable availability
- Go editor build availability
- `tools/edit` wrapper availability
- `data/*.tsv` presence
- required config files
- optional `fzf` / `gum` availability
- whether `./checks/check.sh` passes
- whether generated `out/*` files are stale or missing

This should remain diagnostic, not a source data mutation path.

---

## 8. App-oriented view exports

Application shells should read compact view exports instead of scraping full human reports.

Possible future exports:

```text
out/app_dashboard.tsv
out/app_plan_open.tsv
out/app_envelope_rows.tsv
out/app_check_warnings.tsv
out/app_txn_bundles.tsv
out/app_actual_comparison.tsv
```

These are derived, regenerable files. They are not source data.

BQN remains responsible for producing the values. The app shell remains responsible for layout and interaction.

---

## 9. Locking and concurrent editing

As soon as several entry paths exist, stale writes become a real risk:

- hand-editing TSV
- `tools/edit`
- `tools/add-ui.sh`
- future TUI/GUI
- AI-assisted review

The Go editor already points in the right direction with stale checks and backups. Future app shells should preserve or strengthen this pattern:

- read file hash before preview
- re-check file hash before write
- refuse or re-preview when source changed
- never silently overwrite human edits
- make backup/restore visible

---

## 10. Minimal app foundation checklist

Before building a serious TUI/GUI, prefer to have:

```text
[ ] stable machine-readable report/export commands
[ ] stable machine-readable check output
[ ] clear app state directory outside data/*.tsv
[ ] documented write boundary for app shells
[ ] doctor command or equivalent environment check
[ ] source/line diagnostics for important lint failures
[ ] app-oriented view exports for dashboard/plans/envelopes/checks
```

This does not block small experiments. It only marks the difference between a playful shell and a reliable application layer.

---

## 11. Relation to other documents

Read this with:

- `README.md` for the user-facing overview
- `AGENTS.md` for AI work rules and entry points
- `docs/ARCHITECTURE.md` for core structure
- `docs/CANONICAL_DAILY_CUBE.md` for the stable numeric core
- `docs/GO_EDITOR_NEXT_PLAN.md` for source TSV editor boundaries
- `docs/COMMAND_HUB_DESIGN.md` for launcher / daily entry point thinking
- `docs/DECISION_MULTI_POSTING_INVESTIGATION.md` for `txn_id` and multi-posting direction
