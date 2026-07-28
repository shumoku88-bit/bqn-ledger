# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P7: retained Cycle Comparison now compares two explicit accounted windows under aligned-elapsed or complete-cycle policy, retaining distinct exact coefficients and provenance. Next implement Envelope & Backing as a bounded evidence-bearing Statement.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
completed retained proofs: Planned + Balances + Recent + Current-cycle + Monthly + Cycle Comparison
next proof: entitlement/consumption/refund/reserve/headroom plus distinct funding/backing/reconciliation coordinates
exclude: implicit envelope/funding prefixes, double Plan deduction, production cutover, private work
forbid: conflating Budget ledger with funding assets, giant all-report record, dual aliases/keys
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
