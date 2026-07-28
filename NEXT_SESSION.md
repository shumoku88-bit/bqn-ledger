# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio contract P1: on 2026-07-28 moko approved replacing 15-section parity with a smaller portfolio centered on Envelope & Backing, Account Balances, Recent Journal, Planned Payments, Issues, Account matrices, and Daily Target. Before more report code, define exact contracts and an old-surface retirement map.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
decision authority: docs/REPORT_PORTFOLIO_DECISION.md
completed proofs: canonical Facts/capabilities + Trial Balance + Daily Flow + Planned Payments
next work: portfolio keys/surfaces, Matrix contracts, Envelope/Backing, Daily Target, consumer removal map
forbid: mechanical 15-section migration, giant all-report record, dual aliases/keys, private work
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
