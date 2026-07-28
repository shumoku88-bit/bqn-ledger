# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P6: retained Monthly Accounts now builds a dense explicit Month × all-Account signed movement Matrix with empty months/cells, source-qualified evidence, and cross-axis reconciliation. Next implement Cycle Comparison over two explicit resolved windows.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
completed retained proofs: Planned + Balances + Recent + Current-cycle Accounts + Monthly Accounts
next proof: Account × current/baseline/difference under aligned_elapsed | complete_cycles
exclude: inferred similar periods, ratios/status lanes, production cutover, private work
forbid: mechanical 15-section migration, giant all-report record, dual aliases/keys
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
