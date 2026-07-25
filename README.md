# BQN Ledger

> A plain-text household event ledger and report engine.

BQN Ledger keeps household accounting records in human-readable native Journal and TSV files, then uses BQN to build checks, projections, reports, exports, and editing tools.

The repository is both a daily-use ledger and a workshop for exploring accounting representations with arrays.

## Start here

- Try the demo below.
- Read [`docs/DATA_DIR_SETUP.md`](docs/DATA_DIR_SETUP.md) to use your own data directory.
- Read [`docs/BQN_EDITOR_USAGE.md`](docs/BQN_EDITOR_USAGE.md) for daily input.
- Read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the current data flow.
- Browse [`docs/README.md`](docs/README.md) for more documentation.
- Read [`AGENTS.md`](AGENTS.md) when working on the repository with an AI or another developer.

## Requirements

The report engine uses [CBQN](https://github.com/dzaima/CBQN). A build with FFI and Singeli support is recommended.

`fzf` and `gum` add optional interactive conveniences. The core report path works without them.

## Quick start

`fixtures/demo/` contains two synthetic household cycles.

```bash
# A short current snapshot
tools/report fixtures/demo --section snapshot

# Available report sections
tools/report fixtures/demo --list-sections

# Cycle comparison and year-to-date views
tools/report fixtures/demo --section actual-comparison
tools/report fixtures/demo --section ytd

# A historical outlook with a fixed observation date
tools/report fixtures/demo --section outlook --outlook-as-of 2026-02-21

# The complete report
tools/report fixtures/demo
```

For daily operation:

```bash
# Interactive command hub
tools/bl

# Check the environment and selected data directory
tools/doctor

# Run the project checks
tools/check.sh
```

## Data

A base directory contains the ledger's source and configuration files.

| File | Role |
|---|---|
| configured native Journal | Actual transactions |
| `plan.tsv` | Future plans |
| `budget_alloc.tsv` | Envelope allocations |
| `accounts.tsv` | Accounts and account metadata |
| `cycle.tsv` | Household cycle boundaries |
| `config.tsv` | Ledger and UI configuration |
| `issues.tsv` | Questions and decision notes |

The production data directory is selected with `LEDGER_DATA_DIR` or the configured default.

```bash
LEDGER_DATA_DIR=/path/to/ledger-data/data tools/report
```

Household data can live outside the repository while the public repository contains synthetic fixtures for development and discussion.

## Daily input

```bash
# Add an Actual transaction
tools/edit journal add \
  --date 2026-06-21 \
  --memo "スーパー" \
  --from assets:cash \
  --to expenses:食費 \
  --amount 1240

# List unfinished plans
tools/edit plan list

# Preview finishing a plan as an Actual transaction
tools/edit plan finish --index 4 --actual-date 2026-06-21
```

The editor provides preview, confirmation, backup, stale checks, and post-write checks. See [`docs/BQN_EDITOR_USAGE.md`](docs/BQN_EDITOR_USAGE.md).

## Model

The current path is:

```text
native Journal and companion TSV
  -> loader and checked projections
  -> Posting IR
  -> accounting and household views
  -> report / export / UI
```

One important materialized view is the Canonical Daily Cube:

```text
Day × Account × Layer
```

Its main layers are `actual`, `plan`, `budget`, and `forecast`. Other representations and projections can coexist when they illuminate different questions.

## Working on the repository

Code, documentation, tests, fixtures, tools, and architecture are open to revision. Experiments and unexpected discoveries are welcome, especially when they are easy to review and reverse.

Git history preserves earlier designs. Archived documents record the paths already explored without controlling the next one.

Useful entrances:

- [`AGENTS.md`](AGENTS.md)
- [`TODO.md`](TODO.md)
- [`docs/AI_CODEMAP.md`](docs/AI_CODEMAP.md)
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`docs/README.md`](docs/README.md)

## Why share it?

See [`docs/WHY_SHARE.md`](docs/WHY_SHARE.md).
