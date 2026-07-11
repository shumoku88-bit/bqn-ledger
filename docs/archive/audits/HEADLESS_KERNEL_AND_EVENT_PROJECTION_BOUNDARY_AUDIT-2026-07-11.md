# Headless Kernel and Event Projection Boundary Audit — 2026-07-11

Status: audit snapshot
Owner: other
Canonical: no; current workstream map: `docs/HEADLESS_KERNEL_EVOLUTION_MAP.md`
Exit: retain as point-in-time evidence; do not use as automatic runtime authorization

## 1. Purpose

This audit records what already exists on current `main` before introducing a new headless kernel boundary, a 6D projection, a shared event carrier, or stricter event sourcing.

The questions are:

1. Which parts already behave like a pure calculation kernel?
2. Which parts are accounting-specific or household-specific?
3. Where are I/O, `•Out`, and `•Exit` coupled to calculation?
4. Can current row evidence or Posting IR support the proposed projections?
5. Is a new `CanonicalEvent`-like intermediate representation currently justified?

This audit does not authorize implementation.

## 2. Reviewed baseline

Point-in-time baseline:

```text
repository: shumoku88-bit/bqn-ledger
branch:     main
head:       a92f01d8a7ac60fd750138ecf7b0854ba7694439
head PR:    #163 docs: verify Currency Stage 2 Slice C closure
runtime:    #162 feat: implement Currency Stage 2 Slice C checked ILS path
```

Relevant current paths inspected:

```text
README.md
TODO.md
docs/AI_CODEMAP.md
docs/ARCHITECTURE.md
docs/QUALITY_BAR.md
docs/POSTING_IR_CONTRACT.md
docs/TBDS_CONTRACT.md
docs/SRC_NEXT_CURRENT.md
src_next/main.bqn
src_next/loader.bqn
src_next/context.bqn
src_next/exact_decimal.bqn
src_next/currency_arithmetic.bqn
src_next/account_key.bqn
src_next/projection.bqn
src_next/cube.bqn
src_next/tbds.bqn
src_next/report.bqn
src_next/summary.bqn
src_next/household_policy.bqn
src_next/issues.bqn
src_edit/issue_close_cmd.bqn
```

## 3. Current runtime path

The current posting-source path is:

```text
journal.tsv / plan.tsv / budget_alloc.tsv
  -> LoadPostingSourceSnapshot
  -> BuildRowEvidenceFromSnapshot
  -> currency_arithmetic.Build
  -> ResolveArithmeticCurrencyProof
  -> projection.RequireArithmeticCurrencyProof
  -> BuildProjectionRowsForEvidence
  -> Posting IR rows
  -> cube.Materialize
  -> tbds.Build
  -> report-specific and household-specific views
```

The path already contains the proposed conceptual sequence in an accounting-specific form:

```text
source
  -> evidence
  -> arithmetic evidence
  -> arithmetic proof
  -> checked Posting IR projection
  -> Cube / TBDS / reports
```

The main mismatch with the broad conceptual vocabulary is that current `Proof` is not universal. It proves an arithmetic-currency claim with explicit domain, basis, and amount scale. Other invariants remain owned by row construction, Posting IR status, Cube row acceptance, balance checks, and downstream contracts.

## 4. Existing kernel inventory

### 4.1 High-purity calculation owners

#### `src_next/exact_decimal.bqn`

Current role:

- validates exact decimal grammar;
- canonicalizes source text into coefficient and scale;
- converts only canonical integer text;
- rejects values that cannot round-trip exactly through the current BQN runtime;
- returns structured success or failure data;
- does not read source files;
- does not build Posting IR;
- does not print or exit.

Classification:

```text
pure calculation kernel
```

This is already a useful model for future extraction work: a narrow owner, structured result, explicit failure state, and no CLI behavior.

#### `src_next/currency_arithmetic.bqn`

Current role:

- consumes pre-built row evidence;
- verifies one arithmetic currency domain across the snapshot;
- chooses snapshot-wide `amount_scale`;
- exact-normalizes coefficients in source order;
- returns structured arithmetic evidence;
- does not load source files;
- does not parse source rows itself;
- does not authorize projection;
- does not build posting rows;
- does not print or exit.

Classification:

```text
pure snapshot calculation kernel
```

This is the clearest existing example of the intended colorless kernel direction.

### 4.2 Mostly structural calculation owners

#### `src_next/cube.bqn`

Current role:

- partitions Posting IR rows into valid and skipped sets;
- validates day, account-key, layer, and row status before indexing;
- materializes `Day × AccountKey × Layer`;
- returns validation summaries and derived totals.

Pure aspects:

- accepts in-memory rows and scalar dimensions;
- performs deterministic array accumulation;
- returns structured data.

Embedded accounting/project semantics:

- four fixed layers: actual, plan, budget, forecast;
- `account_key_index` is a required coordinate;
- expense totals depend on `kind=expense` and `side=debit`;
- current result includes report-adjacent convenience totals.

Classification:

```text
pure function with a fixed accounting projection contract
```

It is not yet a generic `Project(rows, spec)` kernel, and this audit finds no current reason to rewrite it as one.

#### `src_next/tbds.bqn`

Current role:

- consumes ledger-wide Posting IR plus one selected period;
- computes opening, debit movement, credit movement, net movement, and closing;
- emits one account/layer state row per period;
- does not parse source TSV;
- does not own report text layout or household advice.

Embedded accounting semantics:

- debit and credit side meaning;
- account roles and naming fallbacks;
- fixed layer model;
- period accounting measures.

Classification:

```text
accounting-state kernel, not household policy
```

TBDS is intentionally less colorless than exact decimal arithmetic because its purpose is accounting-state construction.

### 4.3 Resolution and parsing owners

#### `src_next/account_key.bqn`

Current role:

- parses account rows and metadata;
- resolves AccountKey as account plus currency;
- exposes parallel role, type, budget, group, spend-class, kind, and envelope-role metadata arrays.

Classification:

```text
accounting dictionary/source adapter
```

The index-building mechanics are reusable, but the current fields and AccountKey meaning are accounting-specific.

#### `src_next/loader.bqn`

Current role:

- resolves paths;
- reads UTF-8 source text through `•FChars`;
- removes comments and empty lines;
- splits TSV while preserving empty fields where required.

Classification:

```text
read-only I/O adapter
```

It is deliberately simple and inspectable. It is not part of a pure calculation kernel because file access is its purpose.

## 5. `context.bqn` responsibility concentration

`src_next/context.bqn` currently owns several distinct layers:

```text
I/O orchestration
source snapshot definition
row evidence construction
currency metadata interpretation
arithmetic proof construction
proof/projection coordination
Posting IR construction
period view coordination
issue source loading
context assembly
```

This concentration does not itself prove that a broad refactor is needed. It identifies candidate seams that must be tested one at a time.

### 5.1 Snapshot boundary already exists

`LoadPostingSourceSnapshot` loads:

```text
journal.tsv      required
plan.tsv         optional
budget_alloc.tsv optional
```

and returns one in-memory source list.

The current currency path then uses the same snapshot for:

```text
row evidence
arithmetic evidence
proof
normalized Posting IR construction
```

This one-shared-snapshot invariant is already a strong checked boundary and should be preserved.

### 5.2 Row evidence already retains raw source meaning

Each row evidence record carries:

```text
source_file
source_row
flds
currency
provenance
parsed
state
message
```

Because `flds` is retained, the existing first five fields and metadata remain available before debit/credit expansion.

This means a future 6D feasibility study can begin from current evidence without first inventing a new event carrier.

### 5.3 Proof construction is narrower than general validation

`ResolveArithmeticCurrencyProof` combines:

```text
row evidence
+
snapshot arithmetic evidence
```

into:

```text
state
domain
basis
amount_scale
message
```

This proof currently establishes whether normalized arithmetic may cross the checked posting gate. It does not prove:

- account existence;
- date validity;
- layer validity;
- debit/credit balance for every future projection;
- issue-state validity;
- 6D semantic completeness.

A future broad architecture must not silently rename this proof into a universal event proof.

### 5.4 Posting construction is the accounting projection seam

`BuildProjectionRowsForEvidence` converts one row evidence item and one normalized coefficient into two Posting IR rows:

```text
debit  -> destination account, positive delta
credit -> source account, negative delta
```

It also resolves:

```text
date
source and transaction identity
account indexes
account roles
cycle-relative day index
layer from source file
kind from account roles
row status and diagnostics
```

This is not a colorless event kernel. It is the current journal-like source adapter into the accounting Posting IR contract.

It is also the most important seam for a future 6D feasibility study because source meaning is still available immediately before accounting expansion.

## 6. Proof authorization and headless limitations

`src_next/projection.bqn` owns the current arithmetic proof authorizer.

Current accepted domain/basis combinations include:

```text
JPY + allowed proof bases
ILS + resolved_single_currency only
```

It also validates non-negative integer `amount_scale` and the empty-source scale rule.

The pure predicate:

```text
AuthorizeArithmeticCurrencyProof
```

already returns a Boolean without exiting.

The wrapper:

```text
RequireArithmeticCurrencyProof
```

prints a diagnostic and calls `•Exit 1` on rejection.

`BuildAuthorizedRowsFromSnapshot` also calls `•Exit 1` for evidence/coefficient length mismatch.

Therefore the current engine is headless in the practical sense that report computation is BQN-owned and UI-independent, but it is not yet a fully embeddable data-result kernel at this inner boundary.

The smallest plausible future seam is:

```text
pure checked result
  -> state / data / diagnostics

outer CLI compatibility wrapper
  -> •Out / •Exit
```

This audit does not select the result carrier or authorize that extraction.

## 7. Accounting-specific and household-specific layers

### 7.1 Accounting-specific core

Current accounting-specific meanings include:

- AccountKey;
- debit and credit side;
- balanced signed deltas;
- actual / plan / budget / forecast layers;
- period opening, movement, and closing;
- income, expense, transfer, and budget kind;
- trial balance and account-role grouping.

These are not household advice, but they are not colorless general event processing either.

### 7.2 Household policy and report layer

Clear household-specific consumers include:

- envelope computation;
- budget groups and spend classes;
- planned payments;
- cycle summary;
- outlook;
- daily trend;
- actual comparison;
- household metadata and policy diagnostics;
- issue display.

`src_next/household_policy.bqn` is already correctly downstream-oriented: it consumes resolved account metadata and valid accepted projection rows, then emits policy diagnostics. It does not own source parsing or posting construction.

### 7.3 Issue state is currently separate

`issues.tsv` is loaded separately inside `BuildContext` and converted into simple issue rows.

The report filters current rows by `status=open`.

The editor close command currently replaces the selected row with:

```text
status = resolved | dropped
memo += Decision: ...
```

Therefore current issue handling is not event-sourced state replay.

It also does not share the current Posting IR path.

This is useful evidence for later architecture decisions:

- forcing issue state into Posting IR would mix non-monetary state with accounting postings;
- introducing a universal event carrier now would be speculative;
- a future bounded issue-event experiment could test event replay without migrating journal data.

## 8. Projection input matrix

| Projection / view | Current input | Is a new shared event carrier required now? | Notes |
|---|---|---|---|
| Debit/credit postings | row evidence + normalized coefficient + account resolution + cycle start | No | Already implemented as Posting IR construction |
| Canonical Daily Cube | validated Posting IR rows + day/account dimensions | No | Current fixed projection is sufficient |
| TBDS | ledger-wide Posting IR + resolved accounts + period | No | Current accounting-state boundary is explicit |
| Trial balance and accounting reports | TBDS / Posting IR / context | No | Existing contracts already define the handoff |
| Household reports | context, Cube, TBDS, source-specific helpers | No immediate shared carrier requirement | Consumers should remain downstream |
| 6D view | candidate input: row evidence including raw `flds` and metadata | Unknown; probably not yet | Requires a dedicated feasibility study before carrier invention |
| Current issue state | `issues.tsv` rows | No for current behavior | Current implementation is direct state, not replay |
| Event-sourced issue state | hypothetical issue events | Possibly a domain-specific carrier | Must be a separate bounded decision |
| Generic `Project(events, spec)` | no demonstrated second same-contract consumer | No | Premature abstraction |

## 9. 6D feasibility observations

Candidate 6D vocabulary:

```text
when
party / place
what
where-to / destination
amount
what-happened / action
```

Potential current sources:

| Candidate dimension | Existing evidence candidate | Current certainty |
|---|---|---|
| when | first source field `date` | High |
| party / place | metadata such as `party=`, memo, or future explicit metadata | Partial |
| what | memo, account role, account metadata, or explicit metadata | Ambiguous |
| destination | `to`, account key, or projection-specific destination | Multiple possible meanings |
| amount | exact parsed coefficient/scale and normalized coefficient | High for monetary rows |
| action | source file, from/to relation, kind, or explicit event verb | Ambiguous |

The uncertain dimensions are semantic questions, not proof that a new carrier is needed.

The correct next test is:

```text
current row evidence/raw fields
  -> candidate 6D view rows
```

and then classify:

```text
sufficient
small provenance extension sufficient
independent intermediate representation required
```

A 6D source format or Cube axis change is not justified by current evidence.

## 10. `CanonicalEvent` decision

Current decision:

```text
Do not introduce CanonicalEvent now.
```

Reasons:

1. Posting IR already serves the accounting normalization boundary.
2. Current row evidence retains raw source fields before accounting expansion.
3. No 6D feasibility test has shown missing carrier information.
4. Issue state does not currently share the posting path.
5. Monetary and non-monetary event common semantics are not yet demonstrated.
6. A universal carrier could become a sparse record containing optional account, amount, issue, action, party, and state fields without one stable invariant.
7. No second independent same-contract consumer currently justifies a shared abstraction.

Reopen only when at least two independent projections demonstrate the same missing normalized input semantics.

## 11. Event-sourcing classification

Current `bqn-ledger` is event-like but not strict event sourcing.

Event-like properties:

- journal and plan rows record dated facts or expectations;
- projections are derived read-only;
- Posting IR, Cube, TBDS, and reports can be rebuilt from source TSV.

Non-event-sourcing properties:

- source rows may be corrected through direct visible editing;
- general correction history is not replayable from source alone;
- recorded/transaction time is not preserved for every fact;
- issue close replaces current row state;
- the repository does not guarantee reconstruction of what was known at every historical knowledge point.

Therefore event sourcing should remain classified as a possible storage/history layer, not as a synonym for current derived projections.

## 12. Existing headless surfaces

The repository already has several headless or machine-oriented characteristics:

- `tools/report` is non-interactive;
- `src_next/report.bqn` is independent of terminal selection UI;
- `src_next/summary.bqn` emits a machine-oriented summary;
- selected report sections emit JSON;
- report meaning is BQN-owned rather than shell-owned;
- UI presentation is downstream from BQN meaning.

The missing inner property is not “no GUI.” It is a consistently data-returning checked calculation boundary that does not terminate the process from inside reusable computation.

## 13. Boundary candidates ranked

### Candidate 1: pure checked-result boundary

Evidence strength: high.

Why:

- pure predicate and diagnostic formatter already exist;
- current wrappers introduce `•Out` / `•Exit`;
- extraction can preserve existing outer behavior;
- it improves embedding without changing accounting meaning.

Required before runtime work:

- docs-only input/result/diagnostic contract;
- compatibility wrapper plan;
- exact failure parity plan;
- focused tests.

### Candidate 2: 6D view over current evidence

Evidence strength: medium.

Why:

- raw fields are retained;
- no source migration is required for a feasibility test;
- ambiguous dimension semantics must be resolved by examples.

Required before implementation:

- docs/test-only field mapping;
- explicit missing-data behavior;
- proof that the view is useful without becoming source authority.

### Candidate 3: shared generic event carrier

Evidence strength: low.

Why:

- no demonstrated second same-contract consumer;
- Posting IR already handles accounting;
- issues are currently separate;
- 6D requirements remain provisional.

Decision:

```text
defer
```

### Candidate 4: broad event-sourcing migration

Evidence strength: low.

Why:

- source correction and issue-state semantics would change;
- migration and replay rules are undefined;
- current daily-use behavior is stable;
- a bounded domain experiment would provide better evidence.

Decision:

```text
do not start
```

## 14. Documentation drift observed

Two comments in `src_next/context.bqn` still describe projection authorization as JPY-only and ILS as closed. PR #162 changed runtime authorization to admit proven ILS with `resolved_single_currency`.

This is comment drift, not a runtime defect.

It should not be mixed into this docs-only architecture slice. If corrected later, use a separate narrow comment-only change or include it only in a directly related finite slice with explicit scope.

`src_next/main.bqn` also retains prototype-era “Phase 1 / Phase 2” commentary even though `src_next` is now the current production report engine. That is historical naming drift and not evidence for a runtime rewrite.

## 15. Recommended next finite decision

After this audit is merged and reviewed, the strongest next candidate is a docs-only contract for a pure checked-result boundary.

Candidate question:

```text
What structured result can the inner snapshot -> evidence -> proof -> Posting IR path return
without printing or exiting, while existing wrappers preserve current behavior exactly?
```

This audit does not auto-select or auto-start that phase.

## 16. Scope result

```text
existing pure arithmetic kernel          -> confirmed
existing accounting projection boundary -> confirmed
household policy separation              -> substantially present
fully data-returning inner headless seam -> not yet complete
6D from current evidence                 -> plausible, untested
CanonicalEvent requirement               -> not established
event-sourcing migration                 -> not authorized
runtime changes in this audit            -> none
```
