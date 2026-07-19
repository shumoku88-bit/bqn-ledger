# Next session

Status: selected finite-slice pointer
Owner: journal source migration
Canonical: no; canonical contract: `docs/JOURNAL_POSTING_IR_IDENTITY_PROVENANCE_PARITY_STAGE2B_PLAN.md`
Exit: replace when Stage 2B is completed, deselected, or superseded; do not auto-select a later stage

## Selected next finite slice

**Journal Posting IR identity/provenance parity Stage 2B is selected and not yet completed.**

Read in this order:

1. `AGENTS.md`
2. `docs/AI_CODEMAP.md`
3. `TODO.md`
4. `docs/QUALITY_BAR.md`
5. `docs/JOURNAL_POSTING_IR_IDENTITY_PROVENANCE_PARITY_STAGE2B_PLAN.md`
6. `docs/POSTING_IR_CONTRACT.md`
7. `docs/archive/completed-plans/JOURNAL_MIGRATION_ARCHITECTURE_AND_SOURCE_IDENTITY_DECISION-2026-07-18.md`
8. `docs/archive/completed-plans/MINIMAL_BQN_JOURNAL_PARSER_STAGE1-2026-07-18.md`
9. `docs/archive/completed-plans/JOURNAL_POSTING_IR_ADAPTER_PARITY_STAGE2A_PLAN-2026-07-18.md`
10. `src_next/journal_profile_stage1.bqn`
11. `src_next/journal_posting_ir_stage2a.bqn`
12. `tests/test_journal_posting_ir_adapter_stage2a.bqn`

## Current baseline

- TSV remains source truth and the current BQN editor remains the daily write path.
- The future boundary remains `journal text -> Transaction IR -> checked Posting IR -> Cube / TBDS -> reports`.
- Minimal Journal parser Stage 1 is complete as test-only work.
- Posting IR adapter parity Stage 2A success path is complete.
- Stage 2A did not compare identity or provenance.
- Existing `source_row` joins remain legacy compatibility surfaces and are not migrated by Stage 2B.
- No production Journal loader, routing, writer, conversion, shadow read, source switch, reverse sync, or private-data read is selected.

## Stage 2B implementation handoff

Implement only the contract's pure, test-only identity/provenance carrier and focused public synthetic fixture:

- proposed module: `src_next/journal_posting_identity_provenance_stage2b.bqn`
- proposed test: `tests/test_journal_posting_identity_provenance_stage2b.bqn`
- proposed fixture: `fixtures/journal-posting-ir-stage2b/`

Preserve the existing 16-field Posting IR row. Carry these fields separately and align them one-to-one with Posting IR rows:

- `source_event_id`
- `identity_kind`
- `source_start_line`
- `source_end_line`
- `posting_index`
- `posting_id`

The fixture contains exactly one explicit-durable-ID plan and one physical-fallback ordinary actual, each with exactly two postings. Parity means structural identity/provenance invariant equivalence, not equality of Journal and legacy TSV ID strings.

Required assertions and fail-closed conditions are canonical in `docs/JOURNAL_POSTING_IR_IDENTITY_PROVENANCE_PARITY_STAGE2B_PLAN.md`; do not broaden them by inference.

## Still unselected

- rejection/red-path parity as a parity campaign;
- native Journal parity for three or more postings;
- production Journal loader or routing;
- writer/editor work;
- TSV-to-Journal conversion;
- shadow read or private-data comparison;
- source-of-truth cutover;
- report, Cube, or TBDS consumer changes;
- `source_row` consumer migration;
- bidirectional/reverse sync or conflict resolution;
- Stage 2C or any later stage.

Stage 2A remains completed. Do not mark Stage 2B completed until its separately authorized implementation satisfies the contract and normal checks.
