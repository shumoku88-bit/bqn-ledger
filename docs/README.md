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
- [`REPORT_PORTFOLIO_DECISION.md`](REPORT_PORTFOLIO_DECISION.md) — approved 2026-07-28 reset from 15-section parity to the retained Matrix/List/Card/Statement portfolio
- [`REPORT_PORTFOLIO_CONTRACT.md`](REPORT_PORTFOLIO_CONTRACT.md) — nine-key destination catalog and exact Account Matrix, Envelope & Backing, Daily Target, List, time, currency, and surface contracts
- [`DESTINATION_QUALITY_GATE.md`](DESTINATION_QUALITY_GATE.md) — completion gate for architecture, exact/evidence/failure semantics, auditability, readability, scenario proof, docs, and verification
- [`DESTINATION_COMPOSITION.md`](DESTINATION_COMPOSITION.md) — static final catalog, one-request/all/cache composition, and cutover boundary
- [`OPERATIONAL_COMMANDS.md`](OPERATIONAL_COMMANDS.md) — source-facing `ledger-check` and non-authoritative canonical Fact `ledger-inspect`
- [`REPORT_SURFACE_RETIREMENT_MAP.md`](REPORT_SURFACE_RETIREMENT_MAP.md) — per-old-section route/key/cache/metadata/query/test migration or atomic removal map
- [`LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`](LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md) — active canonical-facts report migration and final compatibility-eradication roadmap under the portfolio decision
- [`REPORT_CONSTRUCTION_INVENTORY.md`](REPORT_CONSTRUCTION_INVENTORY.md) — current 15-section facts/filter/axis/measure/result-shape inventory and first Matrix/Pivot proof selection
- [`RUNTIME_COMPATIBILITY_INVENTORY.md`](RUNTIME_COMPATIBILITY_INVENTORY.md) — current fallback/wrapper/test-seam/source-data classifications and mandatory deletion gates
- [`PUBLIC_SOURCE_READINESS_AUDIT.md`](PUBLIC_SOURCE_READINESS_AUDIT.md) — readonly public-fixture readiness counts for strict currency, Plan identity, role metadata, and source layout
- [`SRC_NEXT_EXPORT_CALLER_INVENTORY.md`](SRC_NEXT_EXPORT_CALLER_INVENTORY.md) — reproducible classification of all current exports by runtime/test/check/tool caller pressure
- [`REPORT_OUTPUT_MIGRATION_CONTRACT.md`](REPORT_OUTPUT_MIGRATION_CONTRACT.md) — current-surface baseline and retained-output parity vocabulary; 15-section preservation is superseded by the portfolio decision
- [`PRIVATE_SOURCE_READINESS_PROTOCOL.md`](PRIVATE_SOURCE_READINESS_PROTOCOL.md) — explicit-authorization boundary for readonly private audits and separately approved stale-safe migrations
- [`PHASE0_REPORT_ENGINE_CHARACTERIZATION.md`](PHASE0_REPORT_ENGINE_CHARACTERIZATION.md) — Phase 0 exit baseline for topology, exports, source-read pressure, timing, and the strict public proof fixture
- [`LEDGER_FACT_SCHEMA.md`](LEDGER_FACT_SCHEMA.md) — canonical Actual and strict Plan/Budget aligned Transaction/Posting facts, side tables, provenance, and all-or-nothing invariants
- [`ACTUAL_FACT_SUFFICIENCY.md`](ACTUAL_FACT_SUFFICIENCY.md) — mapping from all report/editor Actual requirements to facts, diagnostics, narrow capabilities, or later source families
- [`CONFIG_CYCLE_ADMISSION.md`](CONFIG_CYCLE_ADMISSION.md) — strict pure config/cycle definitions and the boundary between source coordinates and report policy
- [`CYCLE_RESOLUTION.md`](CYCLE_RESOLUTION.md) — mode-specific pure fixed/calendarMonth/incomeAnchor resolution, explicit unavailable/error states, and source-qualified anchor provenance
- [`PLAN_COMPLETION_JOIN.md`](PLAN_COMPLETION_JOIN.md) — durable Plan/Actual relationship Join with exact amounts, Account directions, and explicit duplicate/ambiguous states
- [`PLANNED_PAYMENTS_SECTION.md`](PLANNED_PAYMENTS_SECTION.md) — destination List result composing cycle selection, completion, temporal state, exact totals, and human/compact/JSON rendering
- [`ACCOUNT_BALANCES_REPORT.md`](ACCOUNT_BALANCES_REPORT.md) — retained exact Account closing Matrix/List with explicit observation, zero Accounts, source-qualified provenance, and human/compact/JSON
- [`RECENT_JOURNAL_REPORT.md`](RECENT_JOURNAL_REPORT.md) — retained newest-first Transaction List with explicit limit, multi-posting lanes, exact amount, provenance, and human/compact output
- [`CYCLE_ACCOUNTS_REPORT.md`](CYCLE_ACCOUNTS_REPORT.md) — retained resolved-cycle Account Matrix with explicit observation, signed five-measure arithmetic, and source-qualified cells
- [`CYCLE_COMPARISON_REPORT.md`](CYCLE_COMPARISON_REPORT.md) — retained explicit-window comparison with aligned/complete policy, exact differences, and distinct provenance
- [`ENVELOPE_BACKING_CAPABILITY.md`](ENVELOPE_BACKING_CAPABILITY.md) — retained strict Envelope/Backing Statement with separated evidence systems and human/compact/JSON
- [`DAILY_TARGET_REPORT.md`](DAILY_TARGET_REPORT.md) — conservative exact asset/obligation capacity with once-only reservations, deficit state, and human/compact output
- [`ISSUES_REPORT.md`](ISSUES_REPORT.md) — strict durable non-accounting Issue admission and retained source-ordered open human List
- [`MONTHLY_ACCOUNTS_REPORT.md`](MONTHLY_ACCOUNTS_REPORT.md) — retained dense Month × Account movement with explicit month range, zero cells, provenance, and reconciliation
- [`ACCOUNT_PERIOD_CAPABILITY.md`](ACCOUNT_PERIOD_CAPABILITY.md) — pure selected-domain/layer opening, movement, closing, exact scale, and contributor Posting indices
- [`DATE_CATEGORY_FLOW_CAPABILITY.md`](DATE_CATEGORY_FLOW_CAPABILITY.md) — pure date × dynamic Account-metadata category sparse groups, income/net measures, and contributor Posting indices
- [`MONTH_CATEGORY_GROUPING.md`](MONTH_CATEGORY_GROUPING.md) — two-month extensibility proof and the narrow deterministic sparse Group operation shared by date/month consumers
- [`SPARSE_PIVOT_MATRIX.md`](SPARSE_PIVOT_MATRIX.md) — canonical dense MatrixResult constructor plus policy-free sparse Pivot used by date/month and direct dense consumers
- [`TRIAL_BALANCE_MATRIX_REPORT.md`](TRIAL_BALANCE_MATRIX_REPORT.md) — first section-local destination vertical proof from Account-period state through MatrixResult to human/compact output
- [`DAILY_FLOW_MATRIX_REPORT.md`](DAILY_FLOW_MATRIX_REPORT.md) — second Matrix section proof with dynamic categories, explicit observation/empty policy, contributors, and human-only output
- [`REPORT_CODE_REDUCTION_PLAN.md`](REPORT_CODE_REDUCTION_PLAN.md) — completed prepared-boundary and code-reduction track retained as recent implementation context
- [`TIME_AS_AXIS.md`](TIME_AS_AXIS.md) — temporal concepts
- [`archive/audits/PROJECTION_BQN_OWNERSHIP_AUDIT-2026-07-26.md`](archive/audits/PROJECTION_BQN_OWNERSHIP_AUDIT-2026-07-26.md) — ownership inventory and bounded cleanup sequence for `src_next/projection.bqn`
- [`archive/audits/PROJECTION_COMPATIBILITY_EXPORTS_CHARACTERIZATION-2026-07-26.md`](archive/audits/PROJECTION_COMPATIBILITY_EXPORTS_CHARACTERIZATION-2026-07-26.md) — repository callers, test pressure, documentation promises, external-search limits, and the selected P2a/P2b compatibility-export sequence
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
