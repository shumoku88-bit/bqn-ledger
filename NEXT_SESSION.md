# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P10: all nine retained destination report proofs now pass the quality gate. Issues uses strict durable eight-column admission and an open source-ordered human List; editor migration remains atomic/private-protocol work. Next build destination composition and cutover preparation without changing production yet.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
completed retained proofs: envelopes + balances + recent + planned + cycle-accounts + cycle-comparison + monthly-accounts + daily-target + issues
next proof: static catalog, explicit coordinates, one-request composition, CLI surface errors, public full/individual behavior
exclude: production route switch, private source inspection/migration, old-key deletion before external consumer confirmation
forbid: universal all-report record, dual aliases/keys, five-column Issues fallback, hidden clock in core
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
