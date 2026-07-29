# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P10J: tracked cutover inventory is reproducible and confirms cutover remains blocked by metadata/query/UI and 35 live editor files importing 14 src_next modules. Next build destination six-field metadata and source-independent UI listing proof.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
measured blockers: 71 modules, 35 editor imports, 79 named tests, 33 named checks, 35 fixture families, 7 route/consumers
clean boundary: destination src_next imports = 0
next proof: catalog-derived key/label/category/owner/human_output/structured_output TSV+JSON, then parallel UI listing
later: final report-summary/query; editor dependency extraction; deletion rehearsal
human gates: external query/script answer and separately authorized private readiness
exclude: production switch, old-key deletion, private inspection
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
