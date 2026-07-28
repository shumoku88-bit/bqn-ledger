# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P4: retained Recent Journal now builds a bounded newest-first Transaction List from canonical Facts, preserving multi-posting lane arrays, exact totals, and source-qualified provenance with human/`ledger_recent_journal` output. Next implement Current-cycle Accounts over resolved cycle and explicit observation.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
completed retained proofs: Planned Payments + Account Balances + Recent Journal
next proof: Account × opening/debit/credit/movement/closing through explicit cycle observation
exclude: old Cycle Summary/Trial Balance routes, hidden today, production routing/key cutover, private work
forbid: mechanical 15-section migration, giant all-report record, dual aliases/keys
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
