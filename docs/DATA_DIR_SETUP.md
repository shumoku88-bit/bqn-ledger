# Data Directory Setup

Status: current operational guide
Date: 2026-08-13

## Purpose

`bqn-ledger` treats the canonical eight-file Household root as source of truth, but its directory is allowed to move.

The repository `data/` directory is a public sandbox. Real household data should normally live outside this repository and be selected with `LEDGER_DATA_DIR`.

```text
repo/data/                    public sandbox / fixture-like sample
/path/to/canonical-household  real canonical Household root
```

`LEDGER_DATA_DIR` names the directory that directly contains the eight canonical files. Do not append a historical `data/` component unless those eight files actually live there.

Do not hardcode one personal path into code or docs as the only supported location.

## Base directory contract

A usable Household root contains exactly these physical owners:

```text
accounts.journal
actual.journal
plan.journal
entitlement.journal
envelope.toml
household.toml
report.toml
issues.tsv
```

There is no Budget source fallback, dual source, or Account-to-Envelope adapter. `entitlement.journal` owns explicit StockOrigin and native Endpoint transfers; `envelope.toml` owns current Envelope and Backing policy.

For `tools/bl`, the effective base directory is resolved with explicit intent winning over defaults:

1. command-line `--base <dir>`, when supplied
2. caller-provided `LEDGER_DATA_DIR`
3. ignored repository `.env` → `LEDGER_DATA_DIR`
4. `config/system_defaults.tsv` → `DEFAULT_BASE_DIR` (currently `data`, the public sandbox)

For daily use, prefer an absolute path to the canonical Household root itself:

```sh
export LEDGER_DATA_DIR=/path/to/canonical-household
```

A relative path such as `../canonical-household` can work inside this repository, but an absolute path is safer for shell startup files and tools launched from other directories.

## Daily verification

After changing or moving the source data directory, run:

```sh
tools/doctor
tools/bl check
tools/bl home
```

Expected result:

- `tools/doctor` reports the effective base directory and required canonical source files.
- `tools/bl check` admits the canonical eight-file Household.
- `tools/bl home` displays the Home calendar from that same root.

If the configured directory is stale, tools should fail visibly rather than searching parent or sibling directories. Path recovery is an operational decision, not accounting semantics.

## Moving real data

When the real source data directory moves:

1. Move or clone the canonical Household directory manually outside this repo.
2. Update the shell startup file, environment manager, or ignored `.env` that sets `LEDGER_DATA_DIR`.
3. Point it at the directory that directly contains `accounts.journal`, not at an old nested `data/` directory.
4. Open a new shell or reload the startup file.
5. Run `tools/doctor`.
6. Run `tools/bl check`.
7. Run `tools/bl home`.
8. Only then use writer routes.

Do not change `config/system_defaults.tsv` to point at private real data. It is committed to the public repo and should remain a sandbox default.

## One-off commands

Use `--base` for temporary checks:

```sh
tools/bl --base /path/to/canonical-household check
tools/bl --base /path/to/canonical-household home
tools/main-ui.sh --base /path/to/canonical-household
tools/add-ui.sh --base /path/to/canonical-household
```

For lower-level report commands, pass the same canonical Household root directly:

```sh
tools/report /path/to/canonical-household
tools/report-all /path/to/canonical-household JPY human
```

## Diagnosing a stale nested path

If the Command Hub header or an error shows a path such as:

```text
/path/to/canonical-household/data/accounts.journal
```

but `accounts.journal` actually lives directly in `/path/to/canonical-household`, the configured base is one directory too deep. Check both the inherited environment and the ignored `.env`:

```sh
printf 'LEDGER_DATA_DIR=%s\n' "${LEDGER_DATA_DIR-}"
grep '^LEDGER_DATA_DIR=' .env 2>/dev/null || true
tools/doctor
```

Correct the setting to the canonical root. Do not copy the eight files into the stale nested path merely to satisfy the old setting.

## AI / pit rule

When a pit sees report or UI failures, first check the effective base directory:

```sh
echo "$LEDGER_DATA_DIR"
tools/doctor
```

Do not assume `moko/data`, `data`, `ledger-data/data`, or any previous location is still current. The correct real-data path is an environment/operation setting, not a repository invariant.

Do not create, copy, or repair real source files unless moko explicitly asks for that write.
