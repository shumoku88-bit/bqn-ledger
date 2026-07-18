# Next session

Status: idle / temporary repository pointer
Owner: architecture
Canonical: no
Exit: replace when a new finite implementation or design slice is selected

Journal migration architecture/source identity, Minimal BQN Journal Profile Stage 0, test-only Minimal BQN Journal parser Stage 1, and the receivable bookkeeping matrix study Stage 1 are complete.

Latest decision records and evidence:

- `docs/archive/completed-plans/JOURNAL_MIGRATION_ARCHITECTURE_AND_SOURCE_IDENTITY_DECISION-2026-07-18.md`
- `docs/archive/completed-plans/MINIMAL_BQN_JOURNAL_PROFILE_STAGE0_CHARACTERIZATION-2026-07-18.md`
- `docs/archive/completed-plans/MINIMAL_BQN_JOURNAL_PARSER_STAGE1-2026-07-18.md`
- `docs/archive/completed-plans/BOOKKEEPING_MATRIX_RECEIVABLE_STAGE1-2026-07-18.md`
- `fixtures/journal-profile-stage0/profile.journal`
- `fixtures/journal-profile-stage0/expected-posting-matrix.tsv`
- `fixtures/bookkeeping-matrix-receivable/profile.journal`
- `fixtures/bookkeeping-matrix-receivable/expected-event-account-matrix.tsv`
- `fixtures/bookkeeping-matrix-receivable/expected-running-balances.tsv`
- `src_next/journal_profile_stage1.bqn`
- `tests/test_src_next_journal_profile_stage1.bqn`
- `tests/test_bookkeeping_matrix_receivable.bqn`
- `tools/to-hledger`
- `docs/POSTING_IR_CONTRACT.md`
- `docs/archive/completed-plans/DECISION_MULTI_POSTING_INVESTIGATION.md`
- Draft PR #273 as parked background design evidence

Current source and projection boundary:

- TSV remains current source truth and the current BQN editor remains the daily write path;
- the owner-confirmed bookkeeping workflow already synchronizes TSV into a separate generated journal repository;
- `tools/to-hledger` is a one-way compatibility projection and shadow-read asset, not the future journal parser or writer;
- generated journal output remains non-editable while TSV is source truth;
- the future target boundary remains `journal text -> Transaction IR -> checked Posting IR -> Cube / TBDS -> reports`;
- Stage 0 separates compact human input from explicit durable source blocks;
- ordinary actual events may omit explicit `event-id`, while plans, budget allocations, stable editing, and durable event references require explicit identity;
- durable source postings remain explicit even when a future editor calculates balancing details during preview;
- actual is the minimal default layer, while plan and budget blocks require explicit layer metadata;
- plan completion remains non-destructive through matching `plan-id` evidence;
- envelope-bound plans and completions carry explicit `execution-envelope` linkage;
- Stage 1 parses only the public Stage 0 subset into a test-only Transaction IR and signed event-account matrix;
- Stage 1 fails closed for covered invalid, ambiguous, duplicate-required, unsupported-metadata, and unbalanced evidence;
- Stage 1 is not connected to the production loader, editor, reports, private data, conversion, or source cutover;
- current A-1 `txn_id` grouping remains valid for the TSV era;
- current `source_row` joins must migrate consumer by consumer before any source cutover;
- no dual daily write, reverse sync, automatic conflict resolver, writer, production routing, production conversion, or source-of-truth switch is selected.

## Selected next finite slice

No next finite slice is selected.

Candidates for future sessions:

1. **Journal Posting IR adapter parity Stage 2** (unselected)
   - Compare Stage 1 normalized postings with the current TSV adapter for public synthetic transactions representable by both.
   - Compare money, layers, transaction/posting identity, provenance, and rejection behavior before reports.
   - Keep the journal adapter test-only and do not start production routing, shadow read, writer work, private-data conversion, or cutover.
2. **Bookkeeping matrix study extension** (unselected)
   - Add one hand-checkable synthetic accounting topic at a time, such as receivables/payables, accruals, depreciation, inventory, adjustments, closing, trial balance, or financial statements.
   - Preserve journal evidence, expected matrix, and accounting explanation together.
   - Do not infer a broad accounting-engine rewrite.
3. **Envelope runtime compatibility decision** (parked / unselected)
   - Decide completion-aware Cube modification, linkage filter implementation, and fail-closed migration.
4. **Daily Capacity connection** (parked)
5. **Privacy-safe AI context-bundle contract** (unselected program candidate)

PR #273 remains parked background design evidence and is not implementation authorization.
