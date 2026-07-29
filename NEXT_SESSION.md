# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P10I: destination routes/cache are complete and operational readiness/inspection now live outside the report catalog as `ledger-check`/`ledger-inspect`. Next perform final tracked cutover inventory and readiness gating without switching production.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
operations: ledger-check admits strict sources; ledger-inspect shows canonical Fact provenance; neither enters all/cache
next proof: tracked route/key/cache/metadata/label/query caller inventory mapped to atomic deletion/replacement diff
human gates: ask moko about external compact/query scripts; private Issues/Daily Scope/source migration still separately authorized
exclude: production switch or private inspection in inventory slice
forbid: forwarding check/debug wrappers, diagnostic compact keys, dual catalogs/routes
cutover only after: inventory green + external consumer answer + private readiness instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
