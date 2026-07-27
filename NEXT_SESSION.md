# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 1B continuation: normalized transaction structure, exact-decimal parsing, pure currency registry, and strict Account admission are now owned by `src/ledger` without old wrappers. The facts proof consumes the new aligned Account table. Next move complete-source domain partition/admission ownership so raw strict Journal can reach `src/ledger/facts.bqn` without a `src_next` bridge.

```text
current daily production: tools/report -> src_next/report.bqn
completed: normalized transaction grammar/metadata/side/identity -> canonical structure owner
next boundary: strict complete Journal domain admission -> facts
must preserve: diagnostics, no partial facts, JPY/ILS/USD scale, declaration-only source, source lines
not in this slice: Plan/Budget admission, Pivot, copied section, universal context
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
