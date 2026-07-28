# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 3D: month × category now proves two-month/multi-category/mixed-scale rollup, and date/month consumers both use `sparse_group.bqn` for the identical explicit-axis exact Group operation. Next materialize those sparse results through one policy-free Pivot/MatrixResult boundary.

```text
current daily production: tools/report -> src_next/report.bqn
completed capabilities: Account period + date/category + month/category + sparse Group
next capability: sparse coordinates -> dense values/contributors MatrixResult
exclude: category policy, labels/signs, observation/as-of, formatting, runtime/private sources
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
