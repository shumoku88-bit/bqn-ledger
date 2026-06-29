# src_next migration archive

Status: **historical archive**
Date: 2026-06-29

This directory contains migration notes from the old engine to `src_next/`.

Current behavior is documented in:

- [`../../SRC_NEXT_CURRENT.md`](../../SRC_NEXT_CURRENT.md)
- [`../../AI_CODEMAP.md`](../../AI_CODEMAP.md)
- [`../../ARCHITECTURE.md`](../../ARCHITECTURE.md)
- [`../../MAINTENANCE.md`](../../MAINTENANCE.md)

Current daily operation starts from `tools/bl`. Non-interactive human reports use `tools/report`, which runs `src_next/report.bqn`.

## Reading rule

Treat statements in this directory as historical if they say:

- production default is `bqn main.bqn`
- `src_next` is not production/default
- Stage 4b has not started
- default switch is still pending
- household decisions must use `bqn main.bqn`

For the inventory of this archive, see:

- [`../audits/SRC_NEXT_DOCS_INVENTORY-2026-06-29.md`](../audits/SRC_NEXT_DOCS_INVENTORY-2026-06-29.md)
