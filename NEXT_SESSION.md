# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 3F: `src/sections/trial_balance.bqn` now proves the first section-local MatrixResult and deterministic human/compact output from Account-period state, with no copied formulas or production route. Next prove the materially different Daily Flow Matrix section using date/category evidence and section-local observation policy.

```text
current daily production: tools/report -> src_next/report.bqn
completed report proof: Trial Balance Matrix + totals + human/compact (JSON unsupported by contract)
next report proof: Daily Flow income + dynamic expenses + other + net Matrix
exclude: compact/JSON for Daily Flow, broad context, production routing, private sources
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
