# AI code map

## Start here

1. `TODO.md` — current directions
2. `docs/ARCHITECTURE.md` — production data flow and boundaries
3. `docs/BQN_EXPLORATION_PLAYBOOK.md` — standing BQN opportunity scan, experiment destinations, and new-capability discovery
4. `docs/BQN_EXPLORATION_CATALOG.md` — living questions, probes, parked observations, and revisit signals
5. `docs/BQN_REFACTORING_REVIEW_GUIDE.md` — production adoption gate for a selected finite BQN slice
6. `docs/LIBRI_DI_CASA_INTEGRATION_BOUNDARY.md` when work can affect future source, writer, identity, provenance, or presentation ownership
7. `README.md` — commands and configuration
8. Relevant focused contract or test
9. `docs/archive/` only for historical decisions

## BQN exploration lane

Every BQN design, review, refactor, parser, accounting, reporting, editor, or testing task performs a BQN opportunity scan before selecting work.

Actively consider direct primitives and modifiers, cells/rank/axes, whole-array dataflow, alternate representations, inverses, tacit compositions, and newly revealed household-accounting capabilities. Surface the strongest useful candidates even when they are not production-ready.

Read the living exploration catalog before treating a candidate as new. Compare its cards with current runtime code and tests, then revise stale assumptions or preserve new discoveries there.

Place each idea deliberately in one of four destinations:

- production finite slice;
- analysis-only probe under `experiments/bqn/`;
- personal BQN book experiment;
- parked non-use record with its reason.

Primitive coverage, glyph count, and tacitization are not goals. “Keep the explicit staged form” is a valid scan result when it best exposes diagnostics, evidence staging, or publication boundaries.

Probes may compare many formulations freely. Do not promote multiple candidates into production automatically. Discuss the landscape, select at most one coherent production slice, and keep the other discoveries visible in the catalog, experiments, or personal book.

## Runtime map

### `src/ledger/`

Strict domain owners: Account and config admission, currency registry, Native Journal structure/complete admission, Plan/Budget companion admission, Issues admission, exact decimal/date coordinates, canonical Transaction/Posting Facts, source tables, and typed transaction rows.

### `src/accounting/`

Presentation-neutral exact capabilities: Account period/balance, cycle resolution and comparison, sparse group/pivot and MatrixResult, Plan completion Join, Envelope backing, Daily Target, month/date grouping, and recent transactions. Contributors remain source-qualified.

### `src/sections/`

One bounded semantic result per retained question: `envelope_backing`, `account_balances`, `recent_journal`, `planned_payments`, `cycle_accounts`, `cycle_comparison`, `monthly_accounts`, `daily_flow`, `daily_target`, and `issues`. Renderers consume only their section result.

### `src/report/`

`catalog.bqn` is the only final key/order/surface owner. `request.bqn` admits exact final requests and `all`. `compose.bqn` dispatches narrow signatures; `render.bqn` dispatches approved surfaces. Metadata is catalog-derived and source-independent.

### `src/application/`

Effectful boundaries and CLIs: source adapters, report request/selection/manifest config, selected report composition, strict readiness, inspection, funding scope, Daily Target scope, and editor Actual/config adapters.

### Editor

- `src_edit/` — command adapters and safe candidate generation.
- `src/editor/` — pure historical Journal/travel rewrite semantics.
- `tools/edit-bqn`, `tools/add-ui.sh` — preview/confirm/stale-check/backup orchestration.

Issues use the canonical eight-column schema and strict post-write admission.

## Tool entrances

- `tools/report` — one explicit retained request or fail-closed `all` manifest.
- `tools/report-summary` — compact manifest through the same report route.
- `tools/query` — exact `ledger_*` lookup/list/keys.
- `tools/report-section-metadata` — catalog metadata without household reads.
- `tools/report-cache` — atomic complete cache publication.
- `tools/main-ui.sh` — Command Hub over explicit manifest config.
- `tools/ledger-check` / `tools/ledger-inspect` — operational readiness/provenance.
- `tools/check.sh` — canonical repository check suite.

## Change rules

- Keep source admission, accounting, section, and composition dependencies one-way.
- Prefer standalone BQN while it remains sufficient; possible `libri-di-casa` convergence is optional, not the target architecture.
- Preserve one authoritative writer and a replaceable confirmed-accounting adapter; do not make physical source names a permanent accounting abstraction.
- Do not add broad context records, historical transaction shapes, aliases, or fallback source discovery.
- Move an owner with all callers; leave no forwarding module.
- Keep private household values out of public fixtures, experiments, and docs.
- Treat new functionality discovered through BQN exploration as a separate correctness decision, not a meaning-preserving refactor.
- Update current docs and remove completed plans as part of each change.