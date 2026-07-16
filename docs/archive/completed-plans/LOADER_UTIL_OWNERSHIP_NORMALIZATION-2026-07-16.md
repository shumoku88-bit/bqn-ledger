# Loader / Util Text and I/O Ownership Normalization Completion

Status: completed
Owner: architecture
Canonical: no; current runtime owners are `src_next/util.bqn`, `src_next/loader.bqn`, and `src_next/config.bqn`
Exit: retain as implementation and verification record; do not treat as authorization for broader module consolidation

## 1. Selection and baseline

This finite slice was selected by the maintainer on 2026-07-16 after:

- `docs/archive/audits/BQN_MODULE_GRANULARITY_AUDIT-2026-07-16.md`

Baseline main included the completed report section descriptor centralization and the module-granularity audit. No report, context, currency, travel, or editor redesign was selected.

## 2. Completed ownership

```text
src_next/util.bqn
  pure Split / SplitKeepEmpty / ToNum
  no file, shell, output, exit, clock, or process I/O

src_next/loader.bqn
  native path resolution and repository file reads
  imports util.Split / util.SplitKeepEmpty
  re-exports the established loader split APIs
  retains SplitTsv / SplitTsvKeepEmpty

src_next/config.bqn
  retains config parsing, path selection, fallback, warnings, and policy access
  routes its three required file-content reads through loader.ReadLines
  keeps util only for pure split helpers
```

The duplicated `Split` / `SplitKeepEmpty` implementations were reduced to one pure owner. The legacy `util.LoadChars` / `util.LoadLines` shell-`cat` path was removed.

## 3. Compatibility retained

The implementation preserves:

- `loader.ReadRaw`, `ReadLines`, and `ReadLinesOptional`;
- `loader.Split`, `SplitKeepEmpty`, `SplitTsv`, and `SplitTsvKeepEmpty` public imports;
- CR stripping;
- hash/backslash comment and empty-line filtering;
- leading, middle, and trailing empty-field behavior in the pure split contract;
- empty-column preservation for journal-like TSV;
- missing optional files returning an empty list;
- present-but-unreadable files failing closed;
- current config keys, values, fallback selection, warnings, and public behavior;
- all existing report, editor, currency, travel, and fixture behavior exercised by the repository suite.

## 4. Persistent verification

Added:

- `tests/test_src_next_loader_util_ownership.bqn`;
- `fixtures/loader-util-ownership/source.tsv` with CRLF, comments, a blank line, and an empty TSV column;
- `checks/check-loader-util-ownership.sh`;
- the focused ownership gate in `tools/check.sh`.

The focused test verifies exact split behavior, loader re-export equivalence, numeric helper retention, native line loading, CR removal, comment/blank filtering, and TSV empty-column preservation.

The static gate verifies:

- no file/process I/O symbols or legacy load functions remain in `util.bqn`;
- loader delegates both split functions to util;
- config imports loader and no longer calls `lib.LoadLines`;
- all three config file-content reads use `loader.ReadLines`.

## 5. Verification result

GitHub Actions workflow `check`, run 924, completed the following successfully on the implementation head:

- CBQN and tool setup;
- full `bash ./tools/check.sh`, including all BQN unit tests and the new focused ownership gate;
- existing `checks/check-loader-unreadable.sh`;
- current config/currency tests;
- broken-empty-column and other src_next fixtures;
- MCP lint/tests;
- coverage.

No private production data was accessed.

## 6. Explicitly not changed

This completion does not authorize or imply:

- deleting or merging `util.bqn` and `loader.bqn`;
- repository-wide module consolidation;
- splitting `context.bqn`, `config.bqn`, or `currency_setup.bqn`;
- changing config keys, path precedence, source schema, or source TSV data;
- changing report output, editor protocols, currency policy, or travel behavior;
- adding a generic I/O framework or dynamic loader;
- starting Outlook / `actual_snapshot`, Daily Capacity, or another parked lane.

## Result

```text
completed
```
