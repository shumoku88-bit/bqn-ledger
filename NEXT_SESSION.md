# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 3J: destination Planned Payments now composes cycle selection, explicit observation, durable completion Join, temporal state, exact single-domain total, and one List result rendered as human/compact/JSON. Next prove narrow requested-section use-case composition for the three destination sections without building an all-report context.

```text
current daily production: tools/report -> src_next/report.bqn
completed section proofs: Trial Balance + Daily Flow + Planned Payments
next boundary: already-read strict evidence -> one requested destination section result
forbid: giant all-section record, source reload/clock in sections, dual compact keys, private work
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
