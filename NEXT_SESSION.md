# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P12: exact deletion rehearsal is complete. The tracked simulation removes 401 paths while preserving final evidence; no old BQN import/named path survives and all runtime/document references have exact actions.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
rehearsal gate: ready_for_atomic_diff; 45 migrations, three replacements, zero unclassified actions
tracked blockers: 65 modules, 74 named + 26 compatibility tests, 33 named checks, 34 old fixtures, 35 runtime references
next slice: prepare final tools/report, metadata/query, Command Hub/UI/cache replacement diff without switching production
remaining gates: final route integration, separately authorized private readiness, reviewed atomic cutover
exclude: production switch, old-key deletion, private ledger inspection
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
