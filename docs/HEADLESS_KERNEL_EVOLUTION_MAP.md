# Headless Kernel Evolution Map

Status: active plan
Owner: other
Canonical: yes; canonical for this workstream sequencing, current phase, and restart procedure
Exit: archive as completed or superseded when this workstream closes or a replacement map is adopted

## 1. Purpose

This document is the durable map for evolving the current `bqn-ledger` engine toward clearer headless, pure-computation, event-projection, and optional event-sourcing boundaries without breaking the household ledger that already works.

It exists so the work does not depend on one conversation, one assistant session, or remembered intent.

```text
conversation memory        -> non-authoritative
this map + TODO.md          -> current workstream state
current main implementation -> runtime truth
audit / merged PR evidence  -> phase completion evidence
```

This map owns:

- the workstream vocabulary;
- the current phase;
- the order of finite slices;
- phase entry and exit conditions;
- invariants that every slice must preserve;
- explicit non-goals and deferred choices;
- the restart procedure for a later session.

It does not replace the current accounting contracts:

- [`POSTING_IR_CONTRACT.md`](POSTING_IR_CONTRACT.md)
- [`CANONICAL_DAILY_CUBE.md`](CANONICAL_DAILY_CUBE.md)
- [`TBDS_CONTRACT.md`](TBDS_CONTRACT.md)
- [`TIME_AS_AXIS.md`](TIME_AS_AXIS.md)

## 2. Restart procedure

Any future session working on this direction must begin in this order:

1. Read [`../TODO.md`](../TODO.md) to identify the one active finite slice.
2. Read this map from the beginning through **Current phase**.
3. Read the evidence document linked from the current phase row.
4. Inspect current `main`; do not assume this document proves runtime behavior after later merges.
5. Compare the intended slice with the actual changed paths before committing or opening a PR.
6. Update this map in the same PR whenever the current phase, selected next slice, or a workstream decision changes.
7. Never infer phase completion from chat history, an unmerged branch, or an abandoned draft.

If `TODO.md`, this map, and current `main` disagree:

```text
current main determines runtime truth
TODO.md determines active finite work
this map determines workstream sequence and preserved decisions
```

Resolve the disagreement with a docs-only routing correction before starting a broad runtime change.

## 3. Workstream vocabulary

These ideas are layers, not competing replacements.

| Idea | Meaning in this workstream | What it is not |
|---|---|---|
| Event sourcing | A storage and history model based on replayable state changes | The 6D view, a cube shape, or proof by itself |
| 6D | A derived coordinate/view over event meaning | The source-of-truth format by default |
| Headless engine | A calculation surface callable without terminal UI assumptions | Merely removing report formatting |
| Pure calculation kernel | Functions that own deterministic calculation and return data or diagnostics | File loading, `•Out`, `•Exit`, UI, or household advice |
| Evidence | Structured observations derived from one exact source snapshot | A universal proof that every downstream meaning is valid |
| Proof | A checked claim with explicit basis and diagnostics | A generic name for every validation in the repository |
| Checked projection | A projection admitted only after its required evidence and proof pass | A polished report created from invalid input |
| Projection | A derived structure such as Posting IR, Cube, TBDS, 6D rows, or issue state | A replacement source file unless separately decided |

The long-form conceptual direction is:

```text
source records
  -> evidence
  -> proof
  -> checked projection
  -> Cube / TBDS / double-entry / 6D / reports / state views
```

The current runtime implements a narrower accounting-specific form of this flow. The work must start from that runtime truth rather than inventing a new universal carrier first.

## 4. Current runtime truth

At the start of this workstream, current `main` uses this path for journal-like posting sources:

```text
LoadPostingSourceSnapshot
  -> BuildRowEvidenceFromSnapshot
  -> currency_arithmetic.Build
  -> ResolveArithmeticCurrencyProof
  -> RequireArithmeticCurrencyProof
  -> BuildProjectionRowsForEvidence
  -> Posting IR rows
  -> cube.Materialize / tbds.Build
  -> accounting and household views
```

Current ownership:

| Boundary | Current owner | Current character |
|---|---|---|
| Read source files | `src_next/loader.bqn`, `src_next/context.bqn` | I/O and orchestration |
| Exact decimal parse | `src_next/exact_decimal.bqn` | Pure calculation kernel |
| Snapshot currency arithmetic | `src_next/currency_arithmetic.bqn` | Pure calculation kernel |
| Row evidence construction | `src_next/context.bqn` | Source adapter plus validation orchestration |
| Arithmetic proof construction | `src_next/context.bqn` | Checked-claim orchestration |
| Proof authorization | `src_next/projection.bqn` | Fail-closed accounting gate |
| Debit/credit Posting IR construction | `src_next/context.bqn` | Accounting projection adapter |
| Dense Cube materialization | `src_next/cube.bqn` | Fixed accounting projection |
| TBDS construction | `src_next/tbds.bqn` | Accounting-state projection |
| Household policy and reports | individual `src_next/*.bqn` modules | Household/view layer |
| Issue loading and display | `src_next/context.bqn`, `src_next/issues.bqn` | Separate household state source/view |

Important precision:

- the current proof is an arithmetic-currency proof;
- it does not replace date, account, layer, balance, or row-acceptance validation;
- Posting IR is already the normalized accounting boundary;
- debit/credit is already a projection from a journal-like source movement;
- Cube and TBDS are projections from validated Posting IR, not source-of-truth formats.

The point-in-time evidence for this baseline is:

- [`archive/audits/HEADLESS_KERNEL_AND_EVENT_PROJECTION_BOUNDARY_AUDIT-2026-07-11.md`](archive/audits/HEADLESS_KERNEL_AND_EVENT_PROJECTION_BOUNDARY_AUDIT-2026-07-11.md)

## 5. Preserved invariants

Every phase must preserve these unless a separate explicit decision replaces one.

### 5.1 Source and daily-use safety

- `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, and `accounts.tsv` remain source data.
- The journal-like first five columns remain `date memo from to amount`.
- Real source TSV is not migrated or rewritten as part of boundary discovery.
- Existing editor and daily report paths remain valid.
- AI does not edit real source data without explicit authorization.

### 5.2 Runtime behavior

- Existing report meanings and output values do not change during docs-only or extraction-only slices.
- JPY and checked ILS behavior remain covered.
- Mixed arithmetic currency domains remain fail-closed.
- Invalid input must not become a zero-valued successful projection.
- One source snapshot supplies evidence, arithmetic, proof, and posting construction.

### 5.3 Architecture

- Posting IR remains the current accounting normalization boundary.
- Ledger-wide postings are not truncated to one report period.
- Cube remains a materialized view, not the balance source of truth.
- TBDS remains the accounting-state boundary for opening, movement, and closing.
- Household policy does not move inward into the pure calculation kernel.
- Shell and UI do not acquire accounting or household meaning.

### 5.4 Change control

- One finite question per PR.
- A docs-only decision precedes a new runtime boundary unless an existing current contract already authorizes the exact change.
- No phase starts automatically because the previous phase finished.
- A shared abstraction requires at least two demonstrated consumers with the same semantics.
- The actual diff must be reviewed against the intended scope before publication.

## 6. Current phase

| Phase | Status | Question owned by the phase | Exit evidence | Runtime authorization |
|---|---|---|---|---|
| A. Current boundary map | **active docs-only slice** | What kernel, household layer, side effects, and projection boundaries already exist? | This map, the point-in-time audit, TODO routing, docs routing, and green repository checks | None |
| B. Pure checked-result contract | not started | What data-only result can replace inner `•Out` / `•Exit` without changing outer behavior? | A docs-only contract with inputs, result carrier, diagnostics, wrappers, and tests | None until separately selected |
| C. Pure checked projection extraction | not started | Can the selected result builder be implemented while preserving all existing outputs and failures? | Focused tests, fixture parity, full checks, actual-diff review | Not authorized by Phase A |
| D. 6D feasibility from existing evidence | not started | Can a read-only 6D projection be derived from current evidence/raw fields without a new shared event carrier? | Docs/test evidence classifying sufficient, small extension, or insufficient | Not authorized by Phase A |
| E. Shared event carrier decision | not started | Do at least two independent projections require the same normalized event carrier? | Explicit adopt/reject/defer decision with consumer evidence | No `CanonicalEvent` implementation is authorized now |

### Phase A finite scope

Phase A may:

- record the current implementation path;
- classify I/O, pure computation, accounting, household, and presentation ownership;
- identify current side effects and seams;
- compare the input needs of existing and candidate projections;
- record why a shared event carrier is not yet selected;
- route the next possible docs-only phase without starting it.

Phase A must not:

- modify BQN runtime code;
- change source TSV or metadata schema;
- add a 6D report or export;
- add `CanonicalEvent` or `Project(events, spec)`;
- convert issues or journal records to append-only event sourcing;
- generalize Cube or TBDS axes;
- start a new numbered Stage or broad campaign.

## 7. Planned finite sequence

### Phase B: Pure checked-result contract

The candidate design question is whether the current inner path can return a data result similar to:

```text
{
  state
  row_evidence
  arithmetic_evidence
  proof
  posting_rows
  diagnostics
}
```

The contract must distinguish:

```text
pure result construction
  !=
CLI rendering and process exit
```

It must decide:

- exact inputs;
- whether account resolution and temporal coordinates are inputs or adapters;
- error and diagnostic carrier shape;
- which current functions remain compatibility wrappers;
- how current `•Out` / `•Exit` behavior remains unchanged at outer boundaries;
- focused test and fixture requirements.

Phase B is docs-only and must be selected explicitly after Phase A review.

### Phase C: Runtime extraction

Only after Phase B selects a contract may one small runtime extraction be considered.

The expected shape is:

```text
pure checked builder
  -> data result

existing compatibility wrapper
  -> render diagnostic
  -> preserve current process exit behavior
```

No report, Cube, TBDS, currency, or source semantics may widen in the same PR.

### Phase D: 6D feasibility

The first 6D work is a feasibility check, not a source schema migration.

Candidate dimensions remain provisional:

```text
when
party / place
what
where-to / account destination
amount
what-happened / action
```

The phase must compare each candidate dimension with fields already preserved by row evidence and raw source fields. Its conclusion must be one of:

```text
A. existing evidence is sufficient
B. a small provenance extension is sufficient
C. an independent intermediate representation is required
```

No formal 6D source contract is selected before this evidence exists.

### Phase E: Shared event carrier decision

A shared event carrier is justified only if at least two independent consumers require the same normalized information and cannot safely consume current evidence or Posting IR.

Possible consumers include:

- a 6D view;
- issue-state replay;
- subscription/trial state;
- another non-accounting event projection.

A carrier must not become a sparse universal record merely because several future ideas exist.

The name `CanonicalEvent` is provisional and currently unselected.

## 8. Deferred event-sourcing direction

Current source logs have event-like characteristics, but the repository is not currently strict event sourcing:

- source rows may be corrected by editing TSV;
- general recorded/transaction time is not preserved;
- issue close currently replaces issue state rather than appending a state-change event;
- replay of every historical correction is not guaranteed.

A future event-sourcing experiment, if selected, should begin in one bounded domain such as issue state rather than migrating journal, plan, budget, and issues together.

Possible later experiment:

```text
issue_opened
issue_resolved
issue_dropped
decision_recorded
  -> current issue state projection
```

This is a parked direction, not an authorized phase in the current sequence.

## 9. Decisions retained by this map

| Decision | Current state | Reopen condition |
|---|---|---|
| Keep work in `bqn-ledger` | selected | A concrete repository boundary problem requires reconsideration |
| Preserve current source TSV | selected | Separate source migration decision with concrete consumer and compatibility plan |
| Treat 6D as a projection first | selected | Evidence proves source-level 6D ownership is required |
| Reuse Posting IR for accounting projections | selected | A concrete accounting projection cannot be represented safely |
| Add `CanonicalEvent` now | rejected for now | Two independent consumers demonstrate the same missing carrier semantics |
| Start strict event sourcing now | rejected for now | One bounded domain and replay requirement are selected with migration safety |
| Start broad headless refactor | rejected | A finite pure-result seam is selected and tested first |
| Create a new repository | rejected for now | Current repository constraints demonstrably block the selected work |

## 10. Map maintenance rule

Every PR in this workstream must include a **Map impact** statement in its description:

```text
Map impact: none
```

or:

```text
Map impact: updates current phase / decision / evidence link
```

When a phase closes, the same PR or its immediate docs-only verification follow-up must:

1. change the phase status in this map;
2. link the merged PR and verification evidence;
3. state whether the next phase is merely eligible or explicitly selected;
4. update `TODO.md` so only one finite active slice is shown;
5. avoid retaining a long completion log in `TODO.md`.

The map should remain compact enough to restart work, but complete enough that a new session does not need hidden context.

## 11. Current next action

Complete Phase A only:

```text
current implementation inspection
  -> durable workstream map
  -> point-in-time boundary audit
  -> TODO and docs routing
```

After Phase A merges, review its findings and make a separate decision on whether Phase B becomes the next active finite slice.
