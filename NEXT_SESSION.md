# Next session

Status: idle / temporary repository pointer
Owner: architecture
Canonical: no
Exit: replace when a new finite implementation or design slice is selected

Journal migration architecture and source identity decision is complete.

Latest decision record and evidence:

- `docs/archive/completed-plans/JOURNAL_MIGRATION_ARCHITECTURE_AND_SOURCE_IDENTITY_DECISION-2026-07-18.md`
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
- current A-1 `txn_id` grouping remains valid for the TSV era;
- future event identity separates semantic `source_event_id` from physical source spans and deterministic posting indices;
- current `source_row` joins must migrate consumer by consumer before any source cutover;
- no dual daily write, reverse sync, automatic conflict resolver, parser, writer, runtime routing, production conversion, or source-of-truth switch is selected.

## Selected next finite slice

No next finite slice is selected.

Candidates for future sessions:

1. **Minimal BQN Journal Profile Stage 0 characterization** (unselected)
   - Public synthetic declarations, split receipt, planned payment with early completion, budget allocation, and principal/interest loan repayment.
   - Judge readability, semantic sufficiency, event/posting identity, plan completion, and execution-envelope linkage only.
   - No parser, writer, runtime, source cutover, or private-data fixture.
2. **Envelope runtime compatibility decision** (parked / unselected)
   - Decide completion-aware Cube modification, linkage filter implementation, and fail-closed migration.
3. **Daily Capacity connection** (parked)
4. **Privacy-safe AI context-bundle contract** (unselected program candidate)

PR #273 remains parked background design evidence and is not implementation authorization.
