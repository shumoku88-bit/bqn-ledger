# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 4A: date/month consumers now share generic sparse Group coordinates and `sparse_pivot.bqn` dense MatrixResult with contributor-preserving zero semantics. Next compose the first section-local Trial Balance Matrix report from Account-period state without copying accounting formulas or routing production.

```text
current daily production: tools/report -> src_next/report.bqn
completed capabilities: Account period + date/month Group + policy-free Pivot/MatrixResult
next report proof: Trial Balance Matrix + totals + human/compact/JSON boundary
exclude: broad report context, production routing, private source work
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
