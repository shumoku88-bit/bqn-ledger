# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P2: the nine-key destination catalog, all three Account Matrix contracts, Envelope & Backing terms, conservative Daily Target arithmetic, and old-surface retirement map are selected. Next implement retained Account Balances over explicit Actual Facts/domain/observation.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
authorities: REPORT_PORTFOLIO_DECISION.md + REPORT_PORTFOLIO_CONTRACT.md + REPORT_SURFACE_RETIREMENT_MAP.md
next proof: exact Account closing Matrix/List + human/compact/JSON for JPY/ILS/USD/empty
exclude: implicit domain, old balance ViewModel, production routing/key cutover, filesystem/private work
forbid: mechanical 15-section migration, giant all-report record, dual aliases/keys
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
