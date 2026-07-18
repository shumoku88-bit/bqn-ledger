# Minimal BQN Journal Profile Stage 0 characterization

Status: completed docs/fixture-only characterization
Owner: architecture
Canonical: no; current routing remains `TODO.md` and `NEXT_SESSION.md`
Exit: completed; any parser, writer, runtime route, conversion, or source cutover requires a separately selected slice
Date: 2026-07-18

## Purpose

Characterize a minimal human-readable journal profile that can preserve native multi-posting accounting structure, plan completion evidence, budget allocation evidence, and future source identity without making ordinary daily input carry every internal field by hand.

This Stage 0 also adds an accounting-array test surface: the same synthetic journal events are expressed as a signed `event x account` matrix so future BQN work can treat double-entry invariants and account projections as first-class evidence.

## Scope

This characterization uses public synthetic evidence only:

- declarations;
- one split receipt;
- one planned payment and one early actual completion;
- one budget allocation;
- one loan repayment split into principal and interest.

Evidence files:

- `fixtures/journal-profile-stage0/profile.journal`
- `fixtures/journal-profile-stage0/expected-posting-matrix.tsv`
- `fixtures/journal-profile-stage0/README.md`

This work does not implement or select:

- a journal parser;
- a writer or editor;
- runtime routing;
- report integration;
- production conversion;
- source cutover;
- reverse synchronization;
- private-data fixtures.

Current TSV source truth and the current BQN editor remain unchanged.

## Characterization result

The profile is readable and semantically sufficient for the Stage 0 evidence set when the durable source block is allowed to be more explicit than the daily input interaction.

The central boundary is:

```text
small human input
  -> validated preview / generated balancing details
  -> explicit durable journal block
  -> future Transaction IR
  -> checked Posting IR
  -> event x account matrix / Cube / TBDS / reports
```

The user does not need to calculate balancing amounts or type internal identity fields for every ordinary purchase. A future safe editor may infer the balancing posting in its preview, generate required IDs where policy requires them, and serialize an explicit journal block after validation.

The durable journal remains directly readable and editable, but the ordinary daily path does not need to expose its full ceremony.

## Stage 0 profile decisions

### 1. Transaction postings are authoritative money evidence

One household event is normally one transaction block. Split receipts and compound payments use several postings inside that block rather than several flattened source rows.

Metadata may preserve household meaning, but it must not duplicate or override the authoritative monetary postings.

### 2. Durable source postings are explicit

All posting amounts are explicit in the Stage 0 durable source profile.

This is intentionally stricter than permissive hledger syntax. It makes the source independently inspectable and gives future validation a direct balance invariant without hidden amount inference.

A future editor may accept a compact interaction such as expense lines plus payment account, calculate the balancing posting in preview, and then write all amounts explicitly.

### 3. Actual is the minimal default layer

An ordinary transaction block without `layer` metadata is interpreted as an `actual` candidate by the future profile design.

`plan` and `budget` event blocks require explicit `layer` metadata. The transaction status marker such as `*` or `!` is not sufficient by itself to define the household layer.

This keeps ordinary actual entries small while preventing plans and budget decisions from being inferred from physical filenames or punctuation alone.

### 4. Event identity is conditional, not universal typing burden

An explicit `event-id` is not required for every ordinary actual transaction.

It is required when at least one of these applies:

- the event is a plan or budget allocation expected to receive stable automated editing;
- another durable record refers to the event itself;
- stable editing must survive physical line movement;
- recovery, deduplication, or external synchronization requires durable event identity.

A future parser may expose a physical path/span diagnostic identity for an ordinary event that lacks `event-id`, but that fallback is not durable identity and must not be advertised as stable editing identity.

Business identifiers remain separate:

- `plan-id` identifies a plan relationship;
- `allocation-id` identifies an allocation decision;
- `receipt-id` identifies receipt evidence;
- `agreement-id` identifies an agreement;
- none of these is silently collapsed into `source_event_id`.

### 5. Posting identity follows textual order

`posting_index` is the zero-based order of postings within the parsed transaction block.

`posting_id` derives from `source_event_id + posting_index` when durable event identity exists. Posting order provides deterministic identity and diagnostics, but does not change the accounting meaning of the postings.

### 6. Plans remain non-destructive evidence

A concrete plan carries:

- `layer: plan`;
- a durable `event-id`;
- a durable `plan-id`;
- explicit postings.

An actual completion carries the matching `plan-id`. The plan is not deleted or rewritten into an actual event.

The fixture demonstrates early completion: the actual date precedes the planned date while the durable business link remains exact.

### 7. Execution-envelope linkage is explicit where it matters

An envelope-bound plan carries explicit `execution-envelope` metadata.

Its matching actual completion copies the same linkage. A future parser or adapter should reject or fail visibly on a mismatch rather than silently choosing one side.

This duplication is acceptable at the durable source boundary because a future editor can copy it from the selected plan automatically. It avoids reinterpreting old history solely from later mutable account metadata.

This Stage 0 does not decide ordinary dynamic budget consumption for every purchase. It characterizes explicit allocation and explicit execution-plan linkage only.

### 8. Budget allocation is a balanced budget-layer event

Budget allocation is represented as balanced movement inside the budget namespace. It records a household allocation decision without pretending that bank assets moved.

The fixture uses:

```text
budget:daily        +7000
budget:unassigned   -7000
```

Ordinary budget consumption, category-to-envelope derivation, and completion-aware envelope runtime behavior remain separate unresolved questions.

## Accounting matrix characterization

The expected matrix uses:

- rows: normalized journal events;
- columns: account keys;
- cells: signed Posting IR deltas;
- debit: positive;
- credit: negative.

For every event row `r`:

```text
sum(matrix[r, all accounts]) = 0
```

This is the double-entry conservation invariant.

The fixture matrix has these row totals:

| event | layer | debit total | credit total | row sum |
|---|---|---:|---:|---:|
| split receipt | actual | 1100 | -1100 | 0 |
| rent plan | plan | 5000 | -5000 | 0 |
| rent paid early | actual | 5000 | -5000 | 0 |
| budget allocation | budget | 7000 | -7000 | 0 |
| loan repayment | actual | 1000 | -1000 | 0 |

Column reduction gives account movement. Layer masks decide which world is being projected.

### Actual layer column totals

| account | delta |
|---|---:|
| `assets:cash` | -1100 |
| `assets:bank` | -6000 |
| `liabilities:loan` | 900 |
| `expenses:food` | 800 |
| `expenses:household` | 300 |
| `expenses:rent` | 5000 |
| `expenses:interest` | 100 |

The positive total is 7100 and the negative total is -7100.

### Plan layer column totals

| account | delta |
|---|---:|
| `assets:bank` | -5000 |
| `expenses:rent` | 5000 |

### Budget layer column totals

| account | delta |
|---|---:|
| `budget:daily` | 7000 |
| `budget:unassigned` | -7000 |

The plan and actual rent rows intentionally have the same account vector but different dates and layers. This shows why accounting coordinates alone are not enough to represent plan completion, while metadata alone must not own the money arithmetic.

## BQN direction exposed by this Stage 0

The future journal adapter should make it possible to derive a dense or sparse `event x account` representation from checked postings without changing the canonical Posting IR boundary.

That representation supports several accounting questions as array operations:

- row reduction tests whether each event balances;
- column reduction produces account movement;
- a layer mask separates actual, plan, and budget projections;
- a date mask creates period views;
- account classification maps account movement into trial balance and financial-statement groups;
- provenance coordinates explain which event blocks contribute to each result.

The matrix is an analytical projection, not a replacement source format. Journal transaction blocks preserve event structure and evidence; Posting IR preserves normalized accounting rows; matrices provide a BQN-native field for invariants, aggregation, comparison, and later bookkeeping study.

## Bookkeeping specialization direction

This Stage 0 records a deliberate evaluation axis for future work: `bqn-ledger` may deepen not only as a household input tool but as a BQN-based study environment for double-entry accounting structure.

Future synthetic accounting studies may add, one finite fixture at a time:

- receivables and payables;
- accruals and deferrals;
- depreciation;
- inventory and cost of goods sold;
- correcting entries;
- adjusting and closing entries;
- trial balance to financial statements.

Each study should preserve a hand-checkable expected matrix and accounting explanation. This direction does not automatically authorize those fixtures or any broad accounting-engine rewrite.

## Readability judgment

The Stage 0 source is readable enough when:

- ordinary actuals omit unnecessary identity and layer metadata;
- optional household metadata is added only when it preserves durable meaning;
- plans and allocations carry the extra fields their lifecycle requires;
- the editor, not the person, performs routine balancing and ID generation;
- every durable source block remains explicit after generation.

The profile becomes too heavy if every ordinary purchase must manually provide event identity, layer, balancing arithmetic, plan fields, and envelope fields. That design is rejected.

## Semantic sufficiency judgment

The profile is sufficient for the Stage 0 evidence set because it can represent:

- native split postings;
- actual, plan, and budget layers;
- early plan completion without destructive mutation;
- explicit execution-envelope linkage;
- balanced budget allocation;
- principal and interest in one repayment event;
- deterministic posting order;
- optional versus durable event identity.

It is not yet sufficient as a complete parser contract. Unsupported syntax, lexical details, include topology, commodity precision rules, metadata duplicate handling, and diagnostic shapes remain future parser questions.

## Compatibility boundary

`tools/to-hledger` remains a generated one-way compatibility projection and shadow-read asset. Its output is not the target grammar, writer, or source truth.

The Stage 0 fixture does not alter:

- `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, or `accounts.tsv`;
- the current BQN editor;
- `tools/to-hledger`;
- current Posting IR runtime fields;
- Cube shape;
- TBDS behavior;
- report output;
- envelope runtime policy;
- production data;
- Draft PR #273 parked status.

## Exit result

Minimal BQN Journal Profile Stage 0 characterization is complete.

The next coherent migration candidate is a test-only parser for this supported public subset that emits Transaction IR and can be compared with the expected posting matrix. It remains unselected.

Any such parser slice must fail visibly on unsupported or ambiguous syntax and must not route production reads, write journals, convert private data, or change source truth.
