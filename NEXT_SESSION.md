# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Portfolio P11E: all 12 editor Actual consumers now use explicit config routing and canonical strict Account/Journal Facts in src/application/editor_actual.bqn. Completion evidence is durable plan_id-only; no transaction-field fallback identity. Live editor blockers are 23 files/10 modules.

```text
current daily production: tools/report -> src_next/report.bqn (unchanged)
strict editor Actual: explicit readable config, explicit Account currency/role, one admitted Journal domain
public readiness updates: sandbox/demo/golden/plan fixtures declare Actual source/currency; no private source was inspected
newly src_next-free: journal_list, journal_reconstructible_identity_cleanup_cmd, plan_budget_sync
next slice: inspect 9 account_key.bqn editor consumers and replace compatibility Account resolution with canonical admitted Accounts
remaining gates: 10 editor dependencies, retained helper decisions, rehearsal, separately authorized private readiness
exclude: production switch, old-key deletion, private ledger inspection
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
