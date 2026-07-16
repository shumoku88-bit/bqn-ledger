# Loader / Util Text and I/O Ownership Normalization Plan

Status: selected finite implementation plan
Owner: architecture
Canonical: no; current runtime owners remain `src_next/loader.bqn`, `src_next/util.bqn`, and `src_next/config.bqn`
Exit: move to completed plans after focused equivalence checks and the full repository check pass

## 1. Selection

This finite slice was selected by the maintainer on 2026-07-16 after the read-only module granularity audit in:

- `docs/archive/audits/BQN_MODULE_GRANULARITY_AUDIT-2026-07-16.md`

It is ownership normalization only. It is not a repository-wide module consolidation campaign.

## 2. Current duplication

At the selected baseline:

- `src_next/loader.bqn` and `src_next/util.bqn` independently implement identical `Split` and `SplitKeepEmpty` functions;
- `loader.bqn` reads files through native `•FChars` / `•file.Exists`;
- `util.bqn` still exposes migrated `LoadChars` / `LoadLines` shell-`cat` I/O;
- `config.bqn` uses the legacy `util.LoadLines` path.

The duplicate implementations add maintenance drift without creating an independent semantic contract.

## 3. Target ownership

```text
src_next/util.bqn
  pure Split / SplitKeepEmpty / ToNum only

src_next/loader.bqn
  path resolution and repository file reads
  imports and re-exports util Split / SplitKeepEmpty
  preserves SplitTsv / SplitTsvKeepEmpty public behavior

src_next/config.bqn
  uses loader.ReadLines for file contents
  keeps util for pure split helpers
  keeps current config selection and fallback policy
```

## 4. Compatibility requirements

The implementation must preserve:

- `loader.ReadRaw`, `ReadLines`, and `ReadLinesOptional` contracts;
- `loader.Split`, `SplitKeepEmpty`, `SplitTsv`, and `SplitTsvKeepEmpty` public imports;
- comment and empty-line filtering;
- CR stripping;
- empty-column preservation for journal-like TSV;
- missing optional file returning an empty list;
- present-but-unreadable file failing rather than becoming empty;
- current config values, fallback selection, warnings, and error/exit behavior at the public command level;
- all report, editor, currency, travel, and fixture outputs.

## 5. Focused verification

Add persistent verification for:

1. exact pure split behavior, including leading, middle, and trailing empty fields;
2. equality of `util` split functions and loader re-exports;
3. loader line filtering and CR handling through a public synthetic fixture;
4. static ownership: `util.bqn` has no file, shell, or process I/O and `config.bqn` no longer calls `util.LoadLines`;
5. existing `checks/check-loader-unreadable.sh` behavior;
6. current config/currency tests and broken-empty-column fixture behavior;
7. full `bash ./tools/check.sh`.

## 6. Non-goals

This slice does not authorize:

- deleting `util.bqn` or `loader.bqn`;
- changing config keys, values, path precedence, or schema;
- changing source TSV data or formats;
- changing report output, editor protocols, currency policy, or travel behavior;
- splitting `context.bqn`, `config.bqn`, or `currency_setup.bqn`;
- adding a generic I/O framework, dependency injection layer, or dynamic loader;
- accessing private production data.
