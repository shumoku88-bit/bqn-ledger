# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P9: retained Daily Target now computes exact conservative capacity from explicit assets and once-only obligations, with proven reservation linkage and successful deficit state. Next implement strict source-ordered Issues.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
completed retained proofs: Planned + Balances + Recent + Current-cycle + Monthly + Comparison + Envelopes + Daily Target
next proof: strict issue admission and open-by-default human List
exclude: issue rows from accounting Facts, report-text parsing by editors, production cutover, private work
forbid: inferred issue identity/status, partial invalid Lists, giant all-report record, dual aliases/keys
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
