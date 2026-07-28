# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 3C: `date_category_flow.bqn` now proves dynamic `food`/`other` axes, sparse exact groups, income/net, and contributor Posting indices directly from Facts. Comparison with Account-period grouping found only exact arithmetic safely shared so far. Next prove month × category before extracting narrow Select/Group coordinates.

```text
current daily production: tools/report -> src_next/report.bqn
completed capabilities: Account period state + date/category flow
next extensibility gate: at least two months × multiple dynamic categories
then: extract only identical selection/group mechanics, not report policy
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
