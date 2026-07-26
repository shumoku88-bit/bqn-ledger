# src_next module topology audit — 2026-07-26

Status: current topology evidence and bounded migration direction  
Owner: architecture / module layout  
Scope: `src_next/**/*.bqn` direct `•Import` edges at main `26f0acd4b13bb8ed464b3030473a5637f46cbc4f`

## Question

Is the mostly flat `src_next/` tree still an appropriate layout, and what is the safest first directory migration?

## Method

`tools/src-next-import-graph` scans every BQN file under `src_next/`, ignores comment-only lines, resolves each direct string-literal `•Import` relative to its source file, and can emit:

- graph summary;
- source → target edge TSV;
- per-module direct-import and incoming-import counts;
- import cycles;
- Graphviz DOT.

`checks/check-src-next-import-graph.sh` verifies that the scanner sees root and nested modules, that required entrypoints are present, and that every detected direct import target exists. It is called from `checks/check-repo-index.sh`, which is already part of `tools/check.sh`.

This is a source-level direct-import graph. It does not prove the absence of:

- shell or tool invocations by path;
- test imports outside `src_next/`;
- documentation references;
- dynamically constructed imports;
- imports made by an unknown external clone.

Every actual file move must therefore add repository-wide path search, focused execution evidence, full CI, and documentation synchronization.

## Observed shape

| Metric | Value |
|---|---:|
| BQN modules under `src_next/` | 71 |
| Modules directly under `src_next/` | 69 |
| Modules already nested | 2 |
| Direct `•Import` edges | 276 |
| Missing or unreadable direct targets | 0 |
| Import cycles | 0 |

The only existing BQN subdirectory is `src_next/calc/`, containing `calc/main.bqn` and `calc/envelope_calc.bqn`.

The important observation is not merely that the tree is flat. The direct-import graph is acyclic. The modules are not trapped in a cyclic knot; directory migration can be staged as a sequence of small path changes.

## High fan-in modules

These files are shared hubs and should not be used as the first directory-migration experiment.

| Module | Incoming direct imports |
|---|---:|
| `projection.bqn` | 24 |
| `cube.bqn` | 22 |
| `actual_source.bqn` | 20 |
| `loader.bqn` | 20 |
| `report_labels.bqn` | 17 |
| `date.bqn` | 16 |
| `format.bqn` | 15 |
| `util.bqn` | 12 |
| `currency_setup.bqn` | 11 |
| `exact_decimal.bqn` | 10 |
| `tbds.bqn` | 9 |

Moving one of these first would mostly test mass path editing rather than whether the proposed neighborhood is semantically truthful. Several also still have ownership work in progress, especially `projection.bqn`.

## High fan-out orchestration modules

These files express broad composition boundaries and should also remain stable during the first experiment.

| Module | Direct imports |
|---|---:|
| `report.bqn` | 22 |
| `summary.bqn` | 21 |
| `context.bqn` | 13 |
| `selected_domain_context.bqn` | 11 |
| `envelope_computation.bqn` | 10 |
| `outlook.bqn` | 10 |
| `balances.bqn` | 9 |

Their location may eventually become clearer, but moving them first would combine entrypoint, orchestration, tool-path, check, and documentation changes.

## Natural neighborhoods visible in the graph

The graph and current semantic ownership suggest several neighborhoods, without yet declaring a final directory scheme.

### Checked-source and Journal admission

Examples:

- `journal_profile_stage1.bqn`
- `journal_posting_ir_stage2a.bqn`
- `journal_complete_source_admission.bqn`
- `journal_currency_proof_carrier_stage2a.bqn`
- `journal_supported_single_currency_admission*.bqn`
- `actual_source.bqn`

This is a real cluster, but it crosses production and test-only seams and is imported from editor code as well as report code. It needs a separate caller audit before movement.

### Arithmetic and currency policy

Examples:

- `exact_decimal.bqn`
- `currency_registry.bqn`
- `currency_setup.bqn`
- `currency_arithmetic.bqn`

This is coherent, but every file except the registry is already a shared hub. It is not the first move.

### Materialized views

Examples:

- `cube.bqn`
- `tbds.bqn`
- `trial_balance.bqn`
- `snapshot.bqn`

The names form a useful conceptual area, but their import directions differ: Cube and TBDS are low-level hubs, while trial balance and snapshot are consumers. A directory should not imply that they all own the same layer until this distinction is stated explicitly.

### Human and machine reporting

Examples:

- `report.bqn`
- `summary.bqn`
- report section modules
- report labels and formatting
- individual section builders

This is the largest visible composition neighborhood. It is also the highest-blast-radius region and should be migrated only after a smaller directory experiment proves the path-update procedure.

### Purpose-specific checked-fact queries

Current pair:

- `actual_expense_ranking.bqn`
- `exact_sparse_grouping.bqn`

`actual_expense_ranking.bqn` imports only `exact_sparse_grouping.bqn`. No other `src_next` module imports either file. The consumer is not wired into the public report, and repository references are concentrated in focused tests and the current purpose-specific projection documentation.

This is the smallest coherent nontrivial neighborhood.

## First migration slice

Create:

```text
src_next/queries/
  actual_expense_ranking.bqn
  exact_sparse_grouping.bqn
```

Meaning of `queries/` for this first slice:

- purpose-specific read-only computations over already checked facts;
- no source admission ownership;
- no valuation ownership;
- no public CLI promise merely because a file lives there;
- small query-local kernels may live beside their consumers when they do not yet justify a broader shared package.

Why this comes first:

1. It moves a coherent two-file unit rather than an isolated decorative file.
2. It has one internal edge and no incoming `src_next` edges.
3. It does not move production entrypoints or shared hubs.
4. Existing focused tests already characterize exact grouping, domain partitioning, ranking order, conservation, and contributor evidence.
5. It creates a real neighborhood for the planned second independent checked-fact query.
6. The name avoids collision with the mixed historical `projection.bqn` ownership shelf.

The migration should update all repository callers and current documents directly. These two files are not public CLI entrypoints and are not production report-wired, so the proposed slice should not leave permanent root-level wrappers. Before merge, repository-wide search must confirm that only explicit historical records retain the old paths.

## Migration evidence required

The first move is complete only when:

- both files exist only under `src_next/queries/`;
- their relative import works from the new directory;
- both focused BQN tests pass with updated imports;
- the direct-import scanner reports no missing targets;
- `tools/check.sh` and Coverage pass;
- current architecture, code map, TODO, Cube/TBDS contracts, and the active purpose-specific direction use the new paths;
- repository search distinguishes current references from archived historical evidence;
- final PR SHA, Ready/merge state, and post-merge main are verified.

## Later sequence

The audit does not approve a one-shot tree rewrite. After the `queries/` experiment:

1. finish the bounded `projection.bqn` ownership slices already recorded in the projection audit;
2. characterize Journal/admission callers across `src_next`, `src_edit`, tools, tests, and docs before creating a Journal neighborhood;
3. separate low-level materializers from report-facing views before choosing a `views/` layout;
4. migrate reporting only after entrypoint and section-owner boundaries are explicit;
5. move high fan-in support modules last, if a directory makes ownership clearer rather than merely hiding common files.

## Decision

The current flat tree is no longer an ideal final shape, but it is safe to evolve incrementally. The graph is acyclic and direct imports are intact. Begin with `src_next/queries/` as one reversible, low-blast-radius migration; do not pre-create a complete speculative directory skeleton.
