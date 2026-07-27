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

### Completed finite slice: Phase 0C contract and readiness review

- [x] Captured and approved human, compact, JSON, metadata, cache, CLI, diagnostic, and exit-status parity (`docs/REPORT_OUTPUT_MIGRATION_CONTRACT.md`).
- [x] Inventoried every recognized `src_next` export/caller and 37 compatibility candidates with deletion gates.
- [x] Approved all strict-source requirements and audited public fixture readiness.
- [x] Defined private audit/write authorization without reading private data.
- [x] Added the strict public synthetic Phase 1 proof fixture and recorded topology/size/source-read/timing characterization (`docs/PHASE0_REPORT_ENGINE_CHARACTERIZATION.md`).
- [x] Completed Phase 0 without creating `src/`, a new context, or copied section modules.

### Current finite slice: Phase 1A canonical fact schema proof

- [ ] Define minimal Transaction Facts, Posting Facts, account/domain tables, and admission diagnostics required by the public proof fixture.
- [ ] Project complete admitted Actual transactions without importing historical parser/context/report modules.
- [ ] Prove aligned posting columns, multi-posting transaction identity, exact JPY coefficients/scale, event metadata, source lines, and zero-sum transaction boundaries.
- [ ] Keep the destination readonly and independent from Plan/Budget/report construction during this first proof.
- [ ] Compare canonical facts with `fixtures/ledger-facts-phase1-proof/` and current observable Trial Balance/Recent evidence.
- [ ] Do not copy a section, create a universal context, or add a textual query DSL.

Phase 0 exit evidence is `docs/PHASE0_REPORT_ENGINE_CHARACTERIZATION.md`: every observable report capability has an owner, every compatibility path has a deletion gate, and no undecided fallback is permitted in the destination fact schema.

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
