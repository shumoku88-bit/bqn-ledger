# src_next current usage

Status: **current production report engine**
Date: 2026-06-29

`src_next/` is no longer a future-only migration candidate. It is the engine used by the daily report path.

## Current entrypoints

- Daily operation hub: `tools/bl`
  - primary day-to-day command hub now used for report viewing, section selection, checks, and routing to safe edit UI
  - report display routes through `tools/main-ui.sh` / `tools/report` / `src_next/report.bqn`
  - TSV writes are delegated to approved editor paths; `tools/bl` itself is a launcher
- Daily human report, non-interactive: `tools/report`
  - runs `src_next/report.bqn`
  - defaults to `LEDGER_DATA_DIR`, then `config/system_defaults.tsv`
- Report section UI: `tools/main-ui.sh`
  - lower-level report UI used by `tools/bl`
- Machine-readable compact summary: `tools/report-next-summary`
  - runs `src_next/summary.bqn`
  - retained name is historical
- Low-level diagnostic wrapper: `tools/report-next`
  - runs `src_next/main.bqn`
  - use only for diagnostics or historical comparison, not as the normal report path

There is no root `main.bqn` production engine in the current tree. Old docs that say daily production is `bqn main.bqn` are historical migration notes.

## Current dataflow

```text
<base>/*.tsv + config/*.tsv
  -> src_next/loader.bqn / src_next/context.bqn
  -> Posting IR / Canonical Daily Cube / TBDS
  -> src_next/report.bqn      (human report)
  -> src_next/summary.bqn     (machine summary)
```

`<base>` means `LEDGER_DATA_DIR` when set, otherwise the configured default base directory. Public `data/` is sandbox data.

## Documentation rule

For current behavior, prefer these docs:

- `README.md`
- `docs/AI_CODEMAP.md`
- `docs/ARCHITECTURE.md`
- `docs/MAINTENANCE.md`
- this file

Treat `docs/archive/src-next-migration/` as migration history unless a current doc explicitly links to a specific archived decision record. Its local reading guide is `docs/archive/src-next-migration/README.md`; the 2026-06-29 inventory is `docs/archive/audits/SRC_NEXT_DOCS_INVENTORY-2026-06-29.md`.

## Safety boundary

`src_next/` report and summary paths are read-only. Source TSV writes still go through approved editor paths such as `tools/edit` and `tools/add-ui.sh`.
