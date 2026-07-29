# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P12: editor extraction is complete. src_edit and src/editor have zero src_next imports; historical Journal/travel semantics have real owners, temporal status is shared accounting, and Journal post-write validation no longer builds report context.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
editor gate: green, zero old imports, no forwarding modules
tracked blockers: 65 src_next modules, 74 named tests, 33 named checks, 35 fixture families, seven route/consumers
next slice: classify retained non-src-next tests/helpers versus old-owner deletion and build atomic deletion rehearsal
remaining gates: test/check/fixture/docs cleanup, UI/route cutover, separately authorized private readiness
exclude: production switch, old-key deletion, private ledger inspection
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
