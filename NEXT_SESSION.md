# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P12: retained helper classification is complete. Canonical ledger Facts tests are old-import free, the strict editor fixture is neutral, and every executable old reference has an exact migrate/delete disposition.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
classification gate: green, no unclassified executable reference and no migrate-or-delete action
tracked blockers: 65 modules, 74 named + 26 compatibility tests, 33 named checks, 34 old fixtures, 34 runtime references
next slice: dry-run the atomic deletion/replacement set and close the 58 current documentation references
remaining gates: rehearsal, UI/route cutover, separately authorized private readiness
exclude: production switch, old-key deletion, private ledger inspection
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
