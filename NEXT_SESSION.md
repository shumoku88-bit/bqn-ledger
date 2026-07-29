# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P11G: all eight currency_setup consumers now use a load-explicit canonical registry and narrow editor default-view/selection admission. DEFAULT_CURRENCY never fills source evidence. Live editor blockers are 17 files/eight modules.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
editor currency: registry-supported Policy/scale, exact missing/duplicate/empty/unsupported default failures
newly src_next-free: account_add, journal_add, journal_native_source_check, plan_add, plan_edit
next slice: extract eight journal_profile_stage1 consumers as one coherent parser/rewrite cluster with canonical Account/Posting boundaries
remaining gates: eight editor dependencies, retained helper decisions, rehearsal, separately authorized private readiness
exclude: production switch, old-key deletion, private ledger inspection
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
