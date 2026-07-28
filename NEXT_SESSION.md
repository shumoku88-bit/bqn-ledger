# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 3H: fixed/calendarMonth/incomeAnchor now use mode-specific pure resolvers and one explicit ok/unavailable/error result shape. IncomeAnchor is the first Actual+Plan consumer, so Facts now carry the deferred Source table/index and resolver contributors are source-qualified durable references. Next build canonical Plan completion Join by durable plan_id only.

```text
current daily production: tools/report -> src_next/report.bqn
completed capabilities: two Matrix reports + mode-specific pure cycle resolution
next capability: Plan Facts × Actual Facts durable completion Join
forbid: five-field fallback, universal cycle/context input, source I/O/format/private work
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
