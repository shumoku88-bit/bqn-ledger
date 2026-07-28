# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P5: retained Current-cycle Accounts now composes resolved cycle and explicit observation into an all-Account exact five-column Matrix with signed credit and source-qualified provenance. Next implement Monthly Accounts as Month × Account movement only.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
completed retained proofs: Planned Payments + Account Balances + Recent Journal + Current-cycle Accounts
next proof: explicit month range × all Accounts signed movement with zero cells and contributor reconciliation
exclude: month-end balance/YTD Card, old Cycle Summary/Trial Balance routes, production cutover, private work
forbid: mechanical 15-section migration, giant all-report record, dual aliases/keys
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
