# Journal migration architecture and source identity decision

Status: completed docs-only architecture decision
Owner: architecture
Canonical: no; current routing: `TODO.md` and `NEXT_SESSION.md`
Exit: completed; promote a separately selected current contract before parser, writer, runtime, or source-of-truth implementation
Date: 2026-07-18

## Purpose

Decide how `bqn-ledger` may move from the current journal-like TSV source contract toward a human-readable hledger-compatible journal source without flattening multi-posting transactions back into one-to-one TSV movements.

This decision records architecture and migration boundaries only. It changes no runtime, editor, source file, generated journal, report, or production data.

## Evidence considered

### Current production source boundary

Current `main` reads these source files:

- `journal.tsv`
- `plan.tsv`
- `budget_alloc.tsv`
- `accounts.tsv`

The current source adapter expands one `date / memo / from / to / amount` row into one debit and one credit Posting IR row. Current report consumers also retain several `source_file + source_row` joins for source evidence.

### Existing TSV-to-journal projection

`tools/to-hledger` already provides a useful one-way generated projection:

- `accounts.tsv` -> `accounts.journal`
- `journal.tsv` -> `journal.journal`
- `plan.tsv` -> `plan.journal`
- generated includes -> `hledger.journal`

The operational owner confirms that normal TSV bookkeeping also synchronizes the generated journal into a separate repository.

The converter is valuable evidence, but its current shape is deliberately limited:

- each TSV row becomes one two-posting transaction block;
- metadata is rendered as journal tags, except currency is rendered with the amount;
- `plan.journal` is excluded from the default actual master include;
- `budget_alloc.tsv` is not projected;
- generated files are overwritten and marked as generated;
- a split receipt represented by several `txn_id` TSV rows remains several journal transaction blocks rather than one native multi-posting block.

Therefore the existing sync is a compatibility projection and shadow-read asset. It is not yet the target durable journal source model.

### Parked design evidence

Draft PR #273 remains useful background for:

- transaction postings as the accounting skeleton;
- declarations, actuals, concrete plans, and budget allocations as initial journal families;
- optional household-event coordinates;
- concrete `plan-id` completion evidence;
- keeping cycle/report configuration, issues, and development decisions outside the initial journal.

PR #273 remains parked and is not implementation authorization.

### Existing multi-posting policy

The completed A-1 decision keeps the current TSV shape and groups related one-to-one rows with `txn_id` metadata. That remains the correct current compatibility policy for the TSV source era.

This decision narrows its lifetime: A-1 is not a permanent prohibition on a future native journal source. It remains valid until a separately gated journal cutover replaces the TSV source boundary.

## Decisions

### 1. Future target source

The preferred future durable source is a human-readable journal transaction-block format with native postings.

The target dataflow is:

```text
journal text
  -> Journal Source Adapter
  -> Transaction IR
  -> checked Posting IR
  -> Cube / TBDS
  -> reports and exports
```

The final runtime boundary must not require journal transactions to be flattened back into `from / to / amount` TSV rows before checked Posting IR.

### 2. Existing generated journal role

The current `tools/to-hledger` output remains:

- a generated compatibility projection;
- a human-readability observation surface;
- a possible hledger validation surface;
- a shadow/parity input for representable current transactions.

It does not become source truth merely because it is synchronized automatically. Generated journal files remain non-editable projections while TSV is the active source truth.

### 3. No bidirectional daily synchronization

Migration must remain one-directional at every stage.

Before cutover:

```text
TSV source -> generated journal projection
```

After a future explicit cutover:

```text
journal source -> BQN Transaction IR / Posting IR
```

A later compatibility TSV export may be considered, but no stage may require ordinary transactions to be written independently to both TSV and journal. No automatic reverse sync or conflict resolver is selected.

### 4. Transaction IR is the new source-normalization boundary

A journal source adapter should first produce transaction-level records rather than directly mutating Cube or report inputs.

A future Transaction IR must preserve at least:

- transaction date and status;
- description / payee meaning;
- transaction metadata;
- layer meaning;
- ordered native postings;
- commodity and exact amount text/evidence;
- plan completion and other durable links;
- physical source diagnostics.

Posting IR remains the accounting arithmetic boundary consumed by current Cube/TBDS-family logic.

### 5. Future source identity model

Line number alone is not durable transaction identity for a block journal.

The future adapter target separates semantic identity from physical diagnostics:

```text
source_event_id
source_path
source_start_line
source_end_line
posting_index
posting_id
```

Rules:

1. `source_event_id` identifies one parsed journal event block.
2. An explicit durable event identifier is preferred when the profile requires cross-reference or stable editing.
3. Legacy TSV compatibility may derive `source_event_id` as `legacy:<source_file>:<source_row>`.
4. `source_start_line` and `source_end_line` locate diagnostics but are not durable identity.
5. `posting_index` is deterministic within the parsed event.
6. `posting_id` derives from `source_event_id + posting_index`.
7. Content hashes must not be the sole durable identity because ordinary edits change them.
8. Business links remain distinct fields: `txn_id`, `plan_id`, `allocation_id`, receipt/agreement IDs, and similar links must not all be collapsed into one identifier.

Current `source_file / source_row / source_id / tx_id / posting_id` fields remain valid for the TSV adapter. Consumer migration away from row-number joins must occur one consumer at a time before source cutover.

### 6. Initial journal families

The first profile should cover only:

- declarations;
- actual transactions;
- concrete planned transactions;
- budget allocation transactions.

Cycle-view configuration, report/UI configuration, issues, and development decisions remain outside the initial household journal.

### 7. Plan completion and execution-envelope linkage

Concrete plans remain non-destructive journal evidence. Completion is represented by an actual event carrying the matching `plan_id`; the plan is not deleted or rewritten into an actual.

The current Envelope characterization shows that execution-plan coverage cannot safely rely on an implicit global plan pool. A future journal profile must carry explicit durable linkage when a plan belongs to a particular execution envelope.

The exact metadata spelling and the representation of ordinary dynamic budget consumption remain Stage 0 questions. A future design must not silently reinterpret old history solely because mutable account metadata changed.

### 8. Migration sequence

The approved sequence is architectural only; every stage remains separately selectable.

1. **Minimal BQN Journal Profile Stage 0**
   - public synthetic examples only;
   - readability and semantic-sufficiency characterization;
   - no parser.
2. **Test-only journal parser**
   - supported subset only;
   - unsupported or ambiguous syntax fails visibly;
   - emits Transaction IR.
3. **Posting IR adapter parity**
   - compare current TSV adapter and journal adapter on transactions representable by both;
   - compare postings, identities, layers, money evidence, and rejection behavior before reports.
4. **Shadow read**
   - TSV remains the only write source;
   - generated or converted journal is read-only comparison evidence;
   - no private data enters public fixtures.
5. **Writer and cutover decision**
   - preserve the existing BQN-validation / shell-safe-write ownership model where applicable;
   - define archival, rollback, and default-switch gates before any source-of-truth change.
6. **One-time cutover**
   - freeze an immutable final TSV snapshot;
   - stop TSV daily writes;
   - activate journal as source only after parity and recovery gates pass.

No stage is authorized automatically by this decision.

## Minimal Stage 0 evidence set

A future finite Stage 0 may use one public synthetic paper fixture containing:

- declarations;
- one split receipt;
- one planned payment and early completion;
- one budget allocation;
- one loan repayment split into principal and interest.

It should additionally expose candidate event IDs, posting indices, plan linkage, and execution-envelope linkage so the identity decision is testable on paper before parser work.

The private synchronized journal repository and private ledger amounts must not be copied into the public fixture.

## Compatibility and non-change

This decision does not change:

- TSV source truth today;
- `tools/to-hledger` behavior or invocation;
- the current BQN editor and safe-write path;
- current Posting IR runtime fields;
- Cube shape;
- TBDS behavior;
- report output;
- envelope runtime policy;
- plan completion runtime behavior;
- production data;
- PR #273 parked status.

It selects no parser, writer, runtime routing, source conversion, production activation, or implementation language.

## Next candidate, not selected

Minimal BQN Journal Profile Stage 0 characterization is the next coherent candidate. It remains unselected until routed explicitly through `TODO.md`.
