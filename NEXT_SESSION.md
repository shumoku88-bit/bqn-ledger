# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P11C: read-only raw/filtered/optional/TSV operations now live in src/application/source_io.bqn; all 115 importer sites moved and src_next/loader.bqn was physically deleted without a wrapper. Live editor blockers are now 30 files/12 modules.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
removed owners: src_next/util.bqn, src_next/loader.bqn
neutral owners: src/text/parse.bqn, src/application/source_io.bqn
latest migration: 24 editor imports; issue_close, issue_list, plan_id became fully src_next-free
next slice: inspect 13 config.bqn editor consumers and separate source/config admission from old report policy
remaining gates: other editor dependencies, retained helper deletion decisions, rehearsal, separately authorized private readiness
exclude: production switch, old-key deletion, private ledger inspection
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
