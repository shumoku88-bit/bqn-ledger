# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 3A: strict config/cycle admission now separates default-domain selection, report policy, and unresolved period definition; generic Facts no longer reads an optional source-policy field. Next prove selected-domain opening/movement/closing directly from canonical Posting Facts on the public fixture.

```text
current daily production: tools/report -> src_next/report.bqn
completed: strict Actual/Plan/Budget/config/cycle pure destination boundaries
next capability: selected Domain + period + exact Account Trial Balance rows
exclude: formatting, Cube/TBDS/context imports, runtime routing, private sources
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
