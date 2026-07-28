# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 3I: canonical Plan completion now joins explicit Plan/Actual selections by durable plan_id only, preserves each source's exact amount/direction/provenance, and distinguishes open/completed/duplicate/ambiguous without summing duplicate evidence. Next compose the destination Planned Payments section over cycle result, observation, selection, and Join.

```text
current daily production: tools/report -> src_next/report.bqn
completed capabilities: two Matrix reports + cycle resolution + Plan completion Join
next section proof: Planned Payments human/compact/JSON over strict public Facts
forbid: five-field fallback, exact-any-match duplicate collapse, broad context, private work
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
