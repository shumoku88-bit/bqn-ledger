# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 0C review: strict-source requirements are approved; output contracts, export/caller inventory, public readiness counts, and the private-audit protocol are recorded. Review `docs/REPORT_OUTPUT_MIGRATION_CONTRACT.md`, especially the atomic `src_next_` → `ledger_` compact-key rename and deletion of historical report-next entrypoints. The remaining Phase 0 roadmap items are a deliberately selected public synthetic parity cohort and final characterization/exit review before runtime code.

```text
current daily production: tools/report -> src_next/report.bqn
approved source policy: strict currency/identity/role/path/empty-source requirements
proposed output cutover: semantic parity + destination route byte identity; no dual compact keys
new src/ tree: not authorized until Phase 0 exit review
private audit or migration: separate explicit human direction required
```

Do not add a new context, copy section modules, inspect private sources, or introduce compatibility adapters during this review slice.
