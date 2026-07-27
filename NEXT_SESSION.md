# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 1C: raw Journal plus strict Account evidence now reaches canonical facts entirely through `src/ledger/snapshot.bqn`; complete/single-domain admission old paths are deleted. Next prove information sufficiency for every report/editor Actual consumer and migrate narrow readers away from `actual_source.LoadTransactions` historical `delta` evidence.

```text
current daily production: tools/report -> src_next/report.bqn
completed: account lines + raw Journal + registry -> canonical Transaction/Posting facts
next boundary: fact sufficiency map + editor/cycle/completion canonical readers
must preserve: source order, descriptions, completion identity, dates, exact amounts, diagnostics
not in this slice: Plan/Budget admission, Pivot, copied section, universal context
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
