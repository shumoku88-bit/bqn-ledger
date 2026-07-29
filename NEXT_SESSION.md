# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P10D: the parallel destination CLI now admits key/surface before source reads and selectively wires Balances, Recent, Monthly Accounts, and Issues. Next wire strict cycle-backed keys, then explicit ownership-backed Envelope/Daily Target without widening context.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
parallel proof: tools/report-destination; four keys only, explicit coordinates/basenames
selective evidence: Recent needs only Accounts/Actual; Issues needs only strict Issue TSV; unknown requests read no base
next proof: strict cycle admission/resolution for Planned, Cycle Accounts, Cycle Comparison
then: explicit funding ownership and asset/obligation/reservation application adapters, then all iteration
exclude: production route switch, private source inspection/migration, old-key deletion before external consumer confirmation
forbid: read-all-before-key, Account-name ownership inference, universal context, hidden clock
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
