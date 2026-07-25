# Documentation

The documents in this directory explain the current system, record experiments, and preserve earlier thinking.

They are maps, not gates. Read the files that help with the question in front of you. When code and an old document disagree, investigate the current behavior and improve whichever side is stale.

## Start with the project

- [`../README.md`](../README.md) — what the project is and how to run it
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — current data flow and major components
- [`AI_CODEMAP.md`](AI_CODEMAP.md) — code-oriented map of the repository
- [`../TODO.md`](../TODO.md) — current notes and open directions

## Data and editing

- [`DATA_DIR_SETUP.md`](DATA_DIR_SETUP.md) — data directory layout
- [`CONVENTIONS.md`](CONVENTIONS.md) — source conventions
- [`JOURNAL_META.md`](JOURNAL_META.md) — Journal and companion metadata
- [`BQN_EDITOR_USAGE.md`](BQN_EDITOR_USAGE.md) — editor usage
- [`PRODUCTION_EDITOR_DIRECTION.md`](PRODUCTION_EDITOR_DIRECTION.md) — current editor structure

## Accounting and projections

- [`POSTING_IR_CONTRACT.md`](POSTING_IR_CONTRACT.md) — normalized posting representation
- [`CANONICAL_DAILY_CUBE.md`](CANONICAL_DAILY_CUBE.md) — the existing Day × Account × Layer view
- [`TBDS_CONTRACT.md`](TBDS_CONTRACT.md) — trial-balance dataset boundary
- [`REPORT_CONTRACTS.md`](REPORT_CONTRACTS.md) — report sections and values
- [`TIME_AS_AXIS.md`](TIME_AS_AXIS.md) — temporal concepts

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
