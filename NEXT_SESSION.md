# Next session

Status: ledger-facts report engine migration selected
Owner: ledger kernel / report
Canonical queue: `TODO.md`
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`

## Current finite slice

Phase 1A: prove the minimal canonical Transaction/Posting fact schema from complete admitted Actual evidence using `fixtures/ledger-facts-phase1-proof/`. Phase 0 exited with approved strict-source/output contracts and characterization in `docs/PHASE0_REPORT_ENGINE_CHARACTERIZATION.md`.

```text
current daily production: tools/report -> src_next/report.bqn
new proof: strict complete Actual admission -> canonical aligned facts
first evidence: 3 transactions, 7 Actual postings, split transaction, event/source provenance
not in this slice: Plan/Budget admission, Pivot, copied section, universal context
private audit or migration: separate explicit human direction required
```

Destination code must not import old context, historical parser, report modules, or compatibility shapes. Keep `tools/report` unchanged while the readonly proof develops.
