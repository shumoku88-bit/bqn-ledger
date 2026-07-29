# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P10H: destination individual/all routes and the exact nine-key-plus-all cache now pass direct-byte, fail-closed staging, stale deletion, and timestamp-last publication proofs. Next separate operational check/debug ownership.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
parallel cache: tools/report-destination-cache; same individual routes, canonical manifest, all bytes
failure semantics: bad manifest/token preserves prior timestamp and all.txt; stale retired txt removed only on success
next proof: source-facing tools/ledger-check and non-authoritative tools/ledger-inspect, neither in report catalog/cache
then: final tracked cutover inventory and external consumer/private readiness gates
exclude: production switch, private source inspection/migration, old-key deletion before external consumer confirmation
forbid: report check/debug sections, diagnostic compact keys, stale partial cache
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
