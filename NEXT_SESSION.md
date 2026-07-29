# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P10F: all nine retained keys now have key-first individual parallel CLI routes. Envelope uses explicit asset Account ownership; Daily Target links strict asset/Plan/reservation policy to canonical balance/completion evidence. Next prove `all` without universal coordinates.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
parallel proof: tools/report-destination; all nine individual keys
ownership: exact Account keys and durable plan_id; positive exclusion requires unique exact reservation reference
next proof: an explicit per-key request manifest whose all runner invokes the same one-result route in catalog order
then: cache manifest, operational check/debug separation, cutover inventory
exclude: production switch, private source inspection/migration, old-key deletion before external consumer confirmation
forbid: universal context, Account-name inference, hidden clock, aggregate reservation inference
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
