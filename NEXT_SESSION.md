# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 2A: Actual fact sufficiency is mapped, Journal list/reverse/completion readers use canonical facts, and production cycle/context no longer falls back to `historical_external_plan`. Next admit strict Plan/Budget companion rows from the public proof fixture without five-field identity or implicit currency.

```text
current daily production: tools/report -> src_next/report.bqn
completed: raw Actual + Account evidence -> facts; production historical fallback removed
next boundary: strict Plan/Budget transaction/posting facts
must preserve: source row, exact scale, date, memo/category, plan identity, diagnostics
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
