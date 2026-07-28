# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P3: retained Account Balances now derives exact source-qualified closing for every Account through explicit observation and renders one result as human/compact/JSON across JPY/ILS/USD/empty evidence. Next implement retained Recent Journal directly from canonical Transaction/Posting Facts.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
completed retained proofs: Planned Payments + Account Balances
next proof: newest-first bounded Transaction List with multi-posting lanes and ledger_recent_journal compact key
exclude: old context/transaction rows, one-from/one-to fabrication, production routing/key cutover, private work
forbid: mechanical 15-section migration, giant all-report record, dual aliases/keys
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
