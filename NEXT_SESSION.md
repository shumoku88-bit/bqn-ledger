# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P11B: the first editor extraction moved pure Split/SplitKeepEmpty/ToNum to src/text/parse.bqn, repointed every consumer, and physically deleted src_next/util.bqn without a wrapper. Live editor blockers fell from 35 files/14 modules to 33 files/13 modules.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
removed owner: src_next/util.bqn; neutral owner: src/text/parse.bqn
migrated: 12 editor imports plus current-engine/test callers; two editor files now fully src_next-free
next slice: extract loader.bqn I/O/path/line parsing (24 editor consumers) to a bounded application support owner
remaining gates: other editor dependencies, retained helper migration, deletion rehearsal, separately authorized private readiness
exclude: production switch, old-key deletion, private ledger inspection
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
