# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P11D: 13 editor config imports now use bounded application owners for system filenames, config rows/path, Actual Journal basename, and Plan budget fields. src_next/config.bqn retains only current-report household policy. Live editor blockers are 26 files/11 modules.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
neutral editor owners: config_rows, system_defaults, editor_config_path, actual_journal_config, editor_plan_budget_config
strictness: duplicate/unsafe Actual source and missing required budget fields fail; no shell fallback or report policy in editor owners
newly src_next-free: actual_journal_file and three journal_canonical_surface command adapters
next slice: inspect 12 actual_source.bqn editor consumers and separate source routing from old Account/profile admission
remaining gates: 11 editor dependencies, retained helper decisions, rehearsal, separately authorized private readiness
exclude: production switch, old-key deletion, private ledger inspection
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
