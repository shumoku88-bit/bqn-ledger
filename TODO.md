# Notes and open directions

## Current state

- Strict Native Journal plus Plan, Budget, Account, Cycle, Issues, and Daily Target scope admission is production.
- Canonical Transaction/Posting Facts live under `src/ledger`; reusable calculations live under `src/accounting`.
- Daily reporting uses the ten-key catalog under `src/report` and `src/sections`; Daily Flow is the retained date × category Actual matrix.
- `tools/report`, `tools/report-summary`, `tools/query`, Command Hub metadata, and cache publication all use the same explicit request manifests.
- The retired report runtime and its compatibility tests, fixtures, checks, and entrypoints have been physically removed.

## Current directions

- Exercise the retained portfolio in daily use and adjust explicit manifest observations/targets when household decisions change.
- Keep editor Issues on the canonical strict eight-column schema.
- Prefer narrow accounting capabilities and source-qualified contributors over broad contexts or universal report records.
- Keep operational readiness and inspection outside the report catalog.
- Do not add FX conversion, mixed-domain totals, a universal Cube, or a generic query DSL without a concrete decision.
- Keep `libri-di-casa` convergence optional: prefer standalone BQN while it remains sufficient, while preserving one authoritative writer, semantic source roles independent of physical format, durable provenance, and neutral report results; do not build or activate an integration protocol before a concrete unmet need and finite contract are proven.

## Data boundary

Canonical household data lives in the private data repository. Changes there use its Git history and must not be copied into public fixtures or reports.
