# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 0C: inventory observable output contracts and all exports/callers, review strict-source decisions, and audit public source readiness before creating new runtime code. Phase 0A construction classification and Phase 0B compatibility inventory are complete in `docs/REPORT_CONSTRUCTION_INVENTORY.md` and `docs/RUNTIME_COMPATIBILITY_INVENTORY.md`.

```text
current daily production: tools/report -> src_next/report.bqn
current migration work: output contract + export/caller + source-readiness decisions
new src/ tree: not authorized until Phase 0 review
private source migration: explicit human direction required
```

Do not add a new context, copy section modules, or introduce compatibility adapters in the destination design during this slice.
