# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 2B: strict Plan/Budget companion admission now produces common aligned Facts with explicit currency, Account agreement, exact scale, and durable unique Plan ID; either source failure publishes neither source. Next isolate strict config/cycle admission using public fixtures only.

```text
current daily production: tools/report -> src_next/report.bqn
completed: Actual + strict Plan/Budget canonical facts as separate pure roots
next boundary: strict config/cycle source coordinates versus report policy
intentionally deferred: shared Source table until a cross-source query consumer exists
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
