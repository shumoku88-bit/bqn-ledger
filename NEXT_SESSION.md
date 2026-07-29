# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P10K: final six-field destination metadata now derives from the static catalog in TSV/JSON and passes source-independent listing proof. External compact consumer search found no untracked executable/script usage. Next build final report-summary/exact ledger query proof.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
metadata: 9 final keys, categories, destination owners, yes/metadata fields; no household read
external compact gate: green by explicit user-directed executable/config/automation search; legacy repo/log/docs are not consumers
next proof: tools/report-summary over compact all manifest and exact ledger_* query with no old translation
later: editor dependency extraction; tracked deletion rehearsal; separately authorized private readiness
exclude: production switch, old-key deletion, private ledger inspection
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
