# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P10B: all nine report proofs are complete, and the source-independent final catalog/request admission now selects exact supported surfaces with no aliases. Next build purpose-specific one-request composition over already-read evidence.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
static catalog: nine final keys; all is a selector, not a tenth entry
request behavior: unknown legacy key and unsupported surface are explicit errors; all JSON unsupported
next proof: section-specific explicit coordinates/evidence adapters and one-result composition, then parallel destination CLI
exclude: production route switch, private source inspection/migration, old-key deletion before external consumer confirmation
forbid: universal all-report record, dual aliases/keys, five-column Issues fallback, hidden clock in core
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
