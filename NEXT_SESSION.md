# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P11F: eight operational AccountKey consumers now use strict canonical Account tables with explicit role/currency; redundant Stage 2A carrier checks were removed after complete Journal admission. Live editor blockers are 22 files/nine modules.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
strict editor Accounts: canonical keys/currency/role, registry-supported domain, no JPY/default/prefix inference
one deferred AccountKey caller: journal_canonical_surface_rewrite, coupled to old profile/Posting IR and moved with that cluster
newly src_next-free: account_list_cmd
next slice: replace eight currency_setup.bqn editor consumers with canonical registry/selection/scale admission
remaining gates: nine editor dependencies, retained helper decisions, rehearsal, separately authorized private readiness
exclude: production switch, old-key deletion, private ledger inspection
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
