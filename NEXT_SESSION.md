# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 3B: `src/accounting/account_period.bqn` now proves selected-domain/layer opening, debit/credit movement, closing, exact totals, and contributor Posting indices directly from canonical Facts. Next prove the materially different date × dynamic expense-category grouping needed by Daily Flow before extracting shared query vocabulary.

```text
current daily production: tools/report -> src_next/report.bqn
completed capability: Account period state without Cube/TBDS/context/section fields
next capability: strict period expense postings -> sparse date/category groups
only after comparison: extract narrow shared Select/Group primitives
private source audit/migration: still requires separate explicit instruction
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Move coherent ownership with callers and leave no forwarding wrapper. Private audit or migration still requires separate explicit direction.
