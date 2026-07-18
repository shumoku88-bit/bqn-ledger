# Next session

Status: idle / temporary repository pointer
Owner: architecture
Canonical: no
Exit: replace when a new finite implementation or design slice is selected

Journal migration architecture/source identity and Minimal BQN Journal Profile Stage 0 characterization are complete.

Latest decision records and evidence:

- `docs/archive/completed-plans/JOURNAL_MIGRATION_ARCHITECTURE_AND_SOURCE_IDENTITY_DECISION-2026-07-18.md`
- `docs/archive/completed-plans/MINIMAL_BQN_JOURNAL_PROFILE_STAGE0_CHARACTERIZATION-2026-07-18.md`
- `fixtures/journal-profile-stage0/profile.journal`
- `fixtures/journal-profile-stage0/expected-posting-matrix.tsv`
- `tools/to-hledger`
- `docs/POSTING_IR_CONTRACT.md`
- `docs/archive/completed-plans/DECISION_MULTI_POSTING_INVESTIGATION.md`
- Draft PR #273 as parked background design evidence

Current source and projection boundary:

- TSV remains current source truth and the current BQN editor remains the daily write path;
- the owner-confirmed bookkeeping workflow already synchronizes TSV into a separate generated journal repository;
- `tools/to-hledger` is classified as a one-way compatibility projection and shadow-read asset, not the future journal parser or writer;
- generated journal output remains non-editable while TSV is source truth;
- the future target boundary is `journal text -> Transaction IR -> checked Posting IR -> Cube / TBDS -> reports`;
- Stage 0 separates compact human input from explicit durable source blocks;
- ordinary actual events may omit explicit `event-id`, while plans, budget allocations, stable editing, and durable event references require explicit identity;
- durable source postings remain explicit even when a future editor calculates the balancing posting during preview;
- actual is the minimal default layer, while plan and budget blocks require explicit layer metadata;
- plan completion remains non-destructive through matching `plan-id` evidence;
- envelope-bound plans and completions carry explicit `execution-envelope` linkage;
- the public synthetic fixture exposes a signed `event x account` matrix whose event rows balance to zero and whose account columns support BQN-native projection;
- current A-1 `txn_id` grouping remains valid for the TSV era;
- future event identity separates semantic `source_event_id` from physical source spans and deterministic posting indices;
- current `source_row` joins must migrate consumer by consumer before any source cutover;
- no dual daily write, reverse sync, automatic conflict resolver, parser, writer, runtime routing, production conversion, or source-of-truth switch is selected.

## Selected next finite slice

No next finite slice is selected.

Candidates for future sessions:

1. **Test-only Minimal BQN Journal parser Stage 1** (unselected)
   - Parse only the public Stage 0 subset into Transaction IR.
   - Compare normalized postings with the expected signed event-account matrix.
   - Fail visibly on unsupported, ambiguous, duplicate-required, or unbalanced evidence.
   - No production routing, writer, conversion, private-data read, or source cutover.
2. **Bookkeeping matrix study extension** (unselected)
   - Add one hand-checkable synthetic accounting topic at a time, such as receivables/payables, accruals, depreciation, inventory, adjustments, closing, trial balance, or financial statements.
   - Preserve journal evidence, expected matrix, and accounting explanation together.
   - Do not infer a broad accounting-engine rewrite.
3. **Envelope runtime compatibility decision** (parked / unselected)
   - Decide completion-aware Cube modification, linkage filter implementation, and fail-closed migration.
4. **Daily Capacity connection** (parked)
5. **Privacy-safe AI context-bundle contract** (unselected program candidate)

PR #273 remains parked background design evidence and is not implementation authorization.
