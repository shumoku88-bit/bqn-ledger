# Data Directory Setup

Status: current operational guide
Date: 2026-06-27

## Purpose

`bqn-ledger` treats source TSV files as the source of truth, but their directory is allowed to move.

The repository `data/` directory is a public sandbox. Real household data should normally live outside this repository and be selected with `LEDGER_DATA_DIR`.

```text
repo/data/              public sandbox / fixture-like sample
/path/to/ledger-data/data  real source TSV base directory
```

Do not hardcode one personal path into code or docs as the only supported location.

## Base directory contract

A usable report base directory contains at least:

```text
accounts.tsv
cycle.tsv
config.tsv
<the single actual source selected by config.tsv>
```

Daily operation normally also expects:

```text
plan.tsv
budget_alloc.tsv
```

Actual source selection is explicit:

```text
ACTUAL_SOURCE=journal
ACTUAL_JOURNAL_FILE=actual.journal
```

`ACTUAL_SOURCE=tsv` is the compatibility route. Journal mode never reads or writes `journal.tsv` and has no silent fallback.

For a new ledger, `config.tsv` must explicitly choose the budget policy instead of relying on the repository compatibility fallback:

```text
POLICY_BUDGET_STYLE=envelope
```

or:

```text
POLICY_BUDGET_STYLE=none
```

Choose `envelope` only when the ledger owner wants to use or try envelope-oriented policy, reports, and diagnostics. Choose `none` when envelope policy is not used. Missing is not a third choice. The current missing-key `envelope` fallback exists temporarily for older ledgers and fixtures.

The base directory is resolved in this order:

1. `LEDGER_DATA_DIR`, if set
2. `config/system_defaults.tsv` → `DEFAULT_BASE_DIR` (currently `data`, the sandbox)
3. tool-specific `--base <dir>` when explicitly passed

For daily use, prefer an absolute path:

```sh
export LEDGER_DATA_DIR=/path/to/ledger-data/data
```

A relative path such as `../ledger-data/data` can work inside this repository, but an absolute path is safer for shell startup files and tools launched from other directories.

## Daily verification

After changing or moving the source data directory, run:

```sh
tools/doctor
tools/main-ui.sh
tools/add-ui.sh --check
```

Expected result:

- `tools/doctor` reports the effective base directory and required TSV files.
- `tools/main-ui.sh` displays a report.
- `tools/add-ui.sh --check` confirms the read-only preflight for input paths.

If the configured directory is stale, tools should fail with a visible diagnostic instead of a blank screen or a long raw trace.

## Moving real data

When the real source data directory moves:

1. Move the data directory manually outside this repo.
2. Update the shell startup file or environment manager that sets `LEDGER_DATA_DIR`.
3. Open a new shell or reload the startup file.
4. Run `tools/doctor`.
5. Run `tools/main-ui.sh`.
6. Run `tools/add-ui.sh --check`.
7. Only then use `tools/add-ui.sh` or `tools/edit` for writes.

Do not change `config/system_defaults.tsv` to point at private real data. It is committed to the public repo and should remain a sandbox default.

## One-off commands

Use `--base` for temporary checks:

```sh
tools/main-ui.sh --base /path/to/ledger-data/data
tools/report --base /path/to/ledger-data/data  # if supported by the tool form, or tools/report /path/to/ledger-data/data
tools/add-ui.sh --base /path/to/ledger-data/data
```

For `tools/report`, the positional form is accepted:

```sh
tools/report /path/to/ledger-data/data
```

## AI / pit rule

When a pit sees report or UI failures, first check the effective base directory:

```sh
echo "$LEDGER_DATA_DIR"
tools/doctor
```

Do not assume `moko/data`, `data`, or any previous location is still current. The correct real-data path is an environment/operation setting, not a repository invariant.

Do not create, copy, or repair real source TSV files unless moko explicitly asks for that write.
