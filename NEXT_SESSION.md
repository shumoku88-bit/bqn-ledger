# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 1B: remove the complete admission path's transient `historical_external_plan` structural parser dependency and establish canonical strict admission ownership before wiring raw Actual to the Phase 1A facts. The aligned fact schema and public proof are complete in `src/ledger/facts.bqn`, `docs/LEDGER_FACT_SCHEMA.md`, and `tests/test_ledger_facts.bqn`.

```text
current daily production: tools/report -> src_next/report.bqn
completed proof: admitted Actual -> aligned Transaction/Posting facts
next boundary: raw strict Journal -> canonical complete admission -> facts
must preserve: diagnostics, no partial facts, exact scale, side, metadata, identity, source lines
not in this slice: Plan/Budget admission, Pivot, copied section, universal context
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
