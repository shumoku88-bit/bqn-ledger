# Notes and open directions

This is the lightweight queue for current work. Completed implementation history belongs in Git and `docs/archive/`.

## Current state

- Native Journal is the sole production Actual source; companion sources are `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `issues.tsv`.
- Daily human reporting runs through `tools/report` → `src_next/report.bqn`; compact output uses `tools/report-next-summary` → `src_next/summary.bqn`.
- The current engine has 75 BQN modules and 13,027 physical lines. The completed prepared-boundary reduction track ended 29 lines below its 13,056-line baseline while preserving all report sections.
- Canonical Daily Cube, TBDS, and purpose-specific sparse consumers remain views over checked posting facts, not competing source truths.
- The current runtime still contains dual context/admission routes, historical transaction/proof fallbacks, compatibility exports, test seams, and historical entrypoint names.
- Current reporting remains production until a separately verified ledger-facts engine passes the cutover gate.

## Selected work: ledger-facts report engine migration

The active roadmap is [`docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`](docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md).

Goal:

```text
strict source snapshot and admission
  -> canonical transaction/posting facts
  -> narrow accounting capabilities
  -> all 15 existing report sections
  -> human / compact / JSON
  -> atomic cutover
  -> complete deletion of old compatibility runtime
```

This is not a section-reduction campaign and must not recreate the old giant all-report record. Shared records are bounded by source/accounting facts; section-specific results remain local. The destination also includes an array-oriented Select/Join/Group/Pivot layer so current report definitions are disposable and new matrix/list reports do not require ledger-kernel changes.

### Completed finite slice: Phase 0A report construction inventory

[`docs/REPORT_CONSTRUCTION_INVENTORY.md`](docs/REPORT_CONSTRUCTION_INVENTORY.md) classifies all 15 sections by facts, filters, axes, measures, joins, time/currency policy, result shape, output surface, and compatibility pressure.

- [x] Classified every section as Matrix, List, Card, hybrid, or custom semantic Build.
- [x] Selected Trial Balance and Daily Flow as materially different real Matrix/Pivot proofs.
- [x] Selected a monthly expense matrix with contributor posting IDs as the novel extensibility gate.
- [x] Confirmed that transaction facts must remain first-class and that Outlook/Envelope/Trend/Comparison must not be forced into a universal Pivot spec.

### Completed finite slice: Phase 0B runtime compatibility inventory

[`docs/RUNTIME_COMPATIBILITY_INVENTORY.md`](docs/RUNTIME_COMPATIBILITY_INVENTORY.md) classifies 37 known runtime/source/API candidates and assigns prerequisites, canonical replacements, and deletion phases.

- [x] Inventoried dual contexts, alternate transaction carriers, source-loading fallback, projection/API shelves, test seams, historical entrypoints, and report compatibility fields.
- [x] Distinguished runtime compatibility from canonical empty-source, physical identity, diagnostics, config defaults, and offline migration behavior.
- [x] Assigned every known compatibility candidate to Phase 1, 2, 3, 4, 5, or final Phase 7 eradication.
- [x] Proposed strict decisions for report/account/row currency, Plan identity, role metadata, source path, event identity, empty source, and cycle observation.

### Current finite slice: Phase 0C contract, export, and source-readiness decisions

- [x] Capture all human, compact, JSON, metadata, cache, CLI, diagnostic, and exit-status contracts (`docs/REPORT_OUTPUT_MIGRATION_CONTRACT.md`).
- [x] Decide byte parity versus semantic/schema parity for each surface, including intentional generation-name breaks.
- [x] Inventory every `src_next` export and qualified repository caller, including `src_edit`, tools, checks, and tests (`docs/SRC_NEXT_EXPORT_CALLER_INVENTORY.md`).
- [x] Review and approve the strict-source decision table in the compatibility inventory; moko approved all eight source requirements after plain-language review.
- [x] Audit public fixtures for required default currency, account/row currency, Plan identity, role metadata, and canonical source layout (`docs/PUBLIC_SOURCE_READINESS_AUDIT.md`).
- [x] Define readonly private-source audits without reading or changing private data absent explicit direction (`docs/PRIVATE_SOURCE_READINESS_PROTOCOL.md`); no private audit has run.
- [x] Record current public synthetic parity evidence and per-slice old/new evidence requirements without using private household data.
- [ ] Do not create `src/`, a new context, or copied section modules before Phase 0 review.

Phase 0 exit:

- every current report capability has an observable contract and owner;
- every compatibility path has a deletion gate;
- no undecided fallback is permitted in the destination fact schema.

## Migration rules

- Keep the current daily report usable at every merged checkpoint.
- New code must never accept an old context or historical transaction shape.
- New code may not import old report code.
- Move modules with all callers and leave no forwarding wrapper at the old path.
- Replace a section across human, compact, JSON, cache, query, tests, and docs in one slice, then delete its old implementation.
- Migrate source data rather than carrying a fallback into the destination runtime.
- Apply private-data migration only under explicit human direction, with preview, backup, and stale checks.
- Final cutover deletes `src_next`, old entrypoints, fallback parsers/proofs, compatibility delegates, `ForTest` aliases, and `_for_test` production modules.
- Git is rollback; compatibility wrappers are not rollback.

## Standing work outside the selected migration

- Keep improving daily editor safety and ergonomics from actual use.
- Treat migration/cleanup tools for historical source data separately from production runtime compatibility.
- Do not add FX conversion, mixed-domain totals, a universal Cube, or a generic query DSL without a separate concrete decision.
- Do not modify or publish canonical private household data without explicit human direction.

## Working principles

- Arithmetic domain is an explicit partition/key requirement, not an implicit property of numeric grouping.
- Transaction metadata is not posting-level account classification.
- Native multi-posting transactions are never flattened back into a two-account source row.
- Share admitted evidence and proven accounting capabilities, not all-report semantic results.
- A section core receives narrow prepared evidence and an explicit observation; it does not read source files or the system clock.
- Flat stages preserve first-failure ownership and return no partial admitted result.
- Code and directory beauty mean truthful ownership, not maximum splitting or nesting.
