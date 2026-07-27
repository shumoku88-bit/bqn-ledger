# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 0B: inventory observable output contracts and every compatibility path before creating new runtime code. Phase 0A report construction classification is complete in `docs/REPORT_CONSTRUCTION_INVENTORY.md`.

```text
current daily production: tools/report -> src_next/report.bqn
current migration work: output contract + caller + compatibility inventory
new src/ tree: not authorized until Phase 0 review
private source migration: explicit human direction required
```

Do not add a new context, copy section modules, or introduce compatibility adapters in the destination design during this slice.
