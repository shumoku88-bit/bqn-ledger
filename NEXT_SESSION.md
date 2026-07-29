# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P10G: all nine individual routes and fail-closed catalog-ordered human/compact `all` now pass public proof. CLI request/source hardening is complete. Next define atomic cache publication and operational route separation.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
parallel proof: tools/report-destination; individual and per-key-manifest all
all semantics: same individual argv routes, buffered output, no partial publication, no aggregate JSON
hardening: catalog authority only; stable missing-source diagnostics; relative base uses caller cwd
next proof: final nine-key/all cache manifest and atomic publication, then ledger-check/ledger-inspect ownership
exclude: production switch, private source inspection/migration, old-key deletion before external consumer confirmation
forbid: universal context, alternate all calculations, hidden clock, stale partial cache
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
