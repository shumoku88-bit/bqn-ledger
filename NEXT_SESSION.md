# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P10E: the parallel destination CLI now selectively wires seven keys, including strict mode-specific cycle resolution. Next define explicit ownership adapters for Envelope and Daily Target, then implement `all` as repeated one-result composition.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
parallel proof: tools/report-destination; seven keys, explicit coordinates/basenames
cycle evidence: two explicit comparison definitions; fixed/calendar read no Plan; incomeAnchor requires Plan
next proof: funding Account identity admission and owner-produced asset/obligation/reservation scopes
then: all iteration, cache manifest, operational route separation
exclude: production switch, private source inspection/migration, old-key deletion before external consumer confirmation
forbid: Account-name ownership inference, universal context, hidden clock, aggregate reservation inference
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
