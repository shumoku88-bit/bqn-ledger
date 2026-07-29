# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P10C: final catalog/request admission and all nine narrow one-result composers now reuse the exact destination section goldens; rendering dispatch calls only admitted surfaces. Next build key-first source I/O adapters and a parallel destination CLI.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
composition: nine purpose-specific signatures; no universal context or all-report record
all behavior: future adapter iterates one-result composition; aggregate JSON remains unsupported
next proof: admit key/surface first, read only required public sources, pass explicit coordinates, render parallel CLI
exclude: production route switch, private source inspection/migration, old-key deletion before external consumer confirmation
forbid: read-all-before-key, dual aliases/keys, five-column Issues fallback, hidden clock in core
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
