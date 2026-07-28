# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P8: retained Envelope & Backing now passes the destination quality gate with named accounting stages, separated Budget/funding/Plan evidence, broad scenarios, and human/compact/JSON Statement surfaces. Next implement conservative Daily Target.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
completed retained proofs: Planned + Balances + Recent + Current-cycle + Monthly + Comparison + Envelopes
next proof: explicit assets minus once-only open obligations over [observation,target), including deficit
exclude: future income in safe capacity, aggregate reservation inference, production cutover, private work
forbid: double obligation deduction, fabricated reservation provenance, giant all-report record, dual aliases/keys
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
