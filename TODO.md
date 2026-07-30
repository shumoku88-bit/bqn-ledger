# Notes and open directions

## Current state

- Strict Native Journal plus Plan, Budget, Account, Cycle, Issues, and Daily Target scope admission is production.
- Canonical Transaction/Posting Facts live under `src/ledger`; reusable calculations live under `src/accounting`.
- Daily reporting uses the twelve-key catalog under `src/report` and `src/sections`; Balance Sheet and Profit and Loss expose the currently admitted Actual statement semantics, while their unresolved classification/closing decisions remain explicit.
- `tools/report`, `tools/report-summary`, `tools/query`, Command Hub metadata, and cache publication all use the same explicit request manifests.
- The retired report runtime and its compatibility tests, fixtures, checks, and entrypoints have been physically removed.

## Current directions

- Exercise the retained portfolio in daily use and adjust explicit manifest observations/targets when household decisions change.
- Keep editor Issues on the canonical strict eight-column schema.
- Prefer narrow accounting capabilities and source-qualified contributors over broad contexts or universal report records.
- Keep operational readiness and inspection outside the report catalog.
- Keep BQN exploration permanently active: every relevant task should scan for direct primitives, cells/rank/axes, whole-array formulations, alternate representations, reversible views, and naturally revealed new capabilities.
- Use `docs/BQN_EXPLORATION_PLAYBOOK.md` to place ideas in a production finite slice, an analysis-only probe, a personal-book experiment, or a parked non-use record. Do not turn the exploration landscape into an automatic cleanup queue.
- Read and revise `docs/BQN_EXPLORATION_CATALOG.md` so questions, representation ideas, rejected formulations, and revisit signals survive across future AI work.
- Use `experiments/bqn/` for isolated shape and expression probes before a production decision. A probe may compare multiple formulations freely; production adoption remains one coherent slice at a time.
- Do not mistake exploration volume for architecture progress. Keep the observed seams visible: presentation package coupling, physical source names versus semantic roles, neutral result versus renderer ownership, single-writer authority, and repeated whole-evidence scans. None is an automatic rewrite queue; select one only through a concrete finite need.
- Do not add FX conversion, mixed-domain totals, a universal Cube, or a generic query DSL without a concrete decision. BQN exploration may still expose these or other new questions for discussion without implementing them.
- Keep `libri-di-casa` convergence optional: prefer standalone BQN while it remains sufficient, while preserving one authoritative writer, semantic source roles independent of physical format, durable provenance, and neutral report results; do not build or activate an integration protocol before a concrete unmet need and finite contract are proven.

## Data boundary

Canonical household data lives in the private data repository. Changes there use its Git history and must not be copied into public fixtures, experiments, or reports.