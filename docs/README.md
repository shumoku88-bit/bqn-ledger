# Documentation

The documents in this directory explain the current system, record experiments, and preserve earlier thinking.

They are maps, not gates. Read the files that help with the question in front of you. When code and an old document disagree, investigate the current behavior and improve whichever side is stale.

## Start with the project

- [`../README.md`](../README.md) — what the project is and how to run it
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — current data flow and major components
- [`AI_CODEMAP.md`](AI_CODEMAP.md) — code-oriented map of the repository
- [`SRC_NEXT_CURRENT.md`](SRC_NEXT_CURRENT.md) — current production and diagnostic entrypoints
- [`DEVELOPER_INSPECTION_ENTRYPOINT.md`](DEVELOPER_INSPECTION_ENTRYPOINT.md) — named low-level inspection entrypoint and the temporary `main.bqn` compatibility wrapper
- [`../TODO.md`](../TODO.md) — current notes and open directions

## Data and editing

- [`DATA_DIR_SETUP.md`](DATA_DIR_SETUP.md) — data directory layout
- [`CONVENTIONS.md`](CONVENTIONS.md) — source conventions
- [`JOURNAL_META.md`](JOURNAL_META.md) — Journal and companion metadata syntax
- [`JOURNAL_METADATA_INVENTORY.md`](JOURNAL_METADATA_INVENTORY.md) — which Journal metadata is written, consumed, reconstructible, or a cleanup candidate
- [`BQN_EDITOR_USAGE.md`](BQN_EDITOR_USAGE.md) — editor usage
- [`PRODUCTION_EDITOR_DIRECTION.md`](PRODUCTION_EDITOR_DIRECTION.md) — current editor structure

## Accounting and projections

- [`POSTING_IR_CONTRACT.md`](POSTING_IR_CONTRACT.md) — normalized posting representation
- [`CANONICAL_DAILY_CUBE.md`](CANONICAL_DAILY_CUBE.md) — the existing Day × Account × Layer view
- [`TBDS_CONTRACT.md`](TBDS_CONTRACT.md) — trial-balance dataset boundary
- [`REPORT_CONTRACTS.md`](REPORT_CONTRACTS.md) — report sections and values
- [`TIME_AS_AXIS.md`](TIME_AS_AXIS.md) — temporal concepts
- [`archive/audits/PROJECTION_BQN_OWNERSHIP_AUDIT-2026-07-26.md`](archive/audits/PROJECTION_BQN_OWNERSHIP_AUDIT-2026-07-26.md) — current ownership inventory and bounded cleanup sequence for `src_next/projection.bqn`
- [`archive/audits/SRC_NEXT_MODULE_TOPOLOGY_AUDIT-2026-07-26.md`](archive/audits/SRC_NEXT_MODULE_TOPOLOGY_AUDIT-2026-07-26.md) — direct-import topology and the first bounded directory migration for `src_next`

## Reliability

- [`QUALITY_BAR.md`](QUALITY_BAR.md) — qualities valued in daily use
- [`SAFETY_PROFILE.md`](SAFETY_PROFILE.md) — data and calculation failure behavior
- [`THIRD_PARTY_DEPENDENCIES.md`](THIRD_PARTY_DEPENDENCIES.md) — external dependencies

## Ideas, experiments, and history

- `archive/active-plans/` contains sketches and plans that may still be interesting.
- `archive/completed-plans/` contains implemented plans and decision records.
- `archive/audits/` contains point-in-time investigations.
- Other archive directories preserve earlier migrations and refactors.

Archived material is available as evidence and inspiration. Git history preserves every previous version, so documents may be simplified, replaced, or removed when they stop helping.

## Finding something

Search by the concept, filename, function, field, or error message you are investigating. The repository has grown through many experiments, and useful knowledge may live in code, tests, fixtures, commit history, or an older document.
