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
3. Read the evidence or contract linked from the current phase row.
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

At the start of this workstream, the snapshot posting path used `RequireArithmeticCurrencyProof` directly to authorize calculations and exit on failure. Since Phase C, the path uses the pure checked posting projection to return a result without inner terminal effects:

```text
LoadPostingSourceSnapshot
  -> BuildCheckedPostingProjectionFromSnapshot
       -> row evidence
       -> arithmetic evidence
       -> arithmetic-currency proof
       -> proof authorization
       -> structural admission
       -> Posting IR rows or structured diagnostic
  -> BuildAuthorizedRowsFromSnapshot compatibility wrapper
       -> existing success shape
       -> existing ERROR stdout / exit 1
  -> Cube / TBDS / reports
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
| A. Current boundary map | **complete** | What kernel, household layer, side effects, and projection boundaries already exist? | PR #164, the point-in-time audit, canonical map/TODO/docs routing, and green CI run #614 | None |
| B. Pure checked-result contract | **complete** | What data-only result can replace inner `•Out` / `•Exit` without changing outer behavior? | PR #165, [`PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md`](PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md), canonical routing, and green CI run #616 | None; design contract only |
| C. Pure checked projection extraction | **complete** | Can the selected result builder be implemented while preserving all existing outputs and failures? | Focused direct-result tests, compatibility parity, full checks, coverage, and actual-diff review | Authorized only for the exact Phase B contract seam; no semantic widening |
| D. 6D feasibility from existing evidence | **selected investigation** | Can a read-only 6D projection be derived from current evidence/raw fields without a new shared event carrier? | Dimension-by-dimension docs/test evidence and one A/B/C feasibility conclusion | Read-only inspection and evidence only; no runtime, source/schema, report, or export change |
| E. Shared event carrier decision | not started | Do at least two independent projections require the same normalized event carrier? | Explicit adopt/reject/defer decision with consumer evidence | No `CanonicalEvent` implementation is authorized now |

### Phase A completion evidence

Phase A closed through:

- merged PR #164, `docs: map headless kernel and projection evolution`;
- [`archive/audits/HEADLESS_KERNEL_AND_EVENT_PROJECTION_BOUNDARY_AUDIT-2026-07-11.md`](archive/audits/HEADLESS_KERNEL_AND_EVENT_PROJECTION_BOUNDARY_AUDIT-2026-07-11.md);
- GitHub Actions run #614 with `tools/check.sh` and coverage successful.

Phase A established the map and made Phase B eligible. Phase B was then explicitly selected as a separate docs-only slice.

### Phase B completion evidence

Phase B closed through:

- merged PR #165, `docs: define pure checked posting result contract`;
- [`PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md`](PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md);
- GitHub Actions run #616 with `tools/check.sh` and coverage successful.

Phase B selected the exact pure builder inputs, six-field result carrier, fatal diagnostics, compatibility-wrapper ownership, and Phase C verification requirements. Phase C was then selected separately through the docs-only routing update that made it the sole active finite slice.

### Phase C completion evidence

Phase C closed through:

- merged PR #167, `feat: extract pure checked posting projection` (merge commit `ced42eaf9852b17a2fedf87262be8e0f6dbab9d9`);
- GitHub Actions run #622 with `tools/check.sh` and coverage successful;
- focused direct-result tests covering legacy-compatible JPY, explicit JPY, explicit ILS, empty-source, mixed-currency, unsupported/duplicate/malformed metadata, and structural mismatch in `tests/test_src_next_checked_posting_projection.bqn`;
- compatibility-wrapper parity checks in `checks/check-src-next-checked-posting-projection.sh`;
- actual-diff review confirming exactly 4 files changed.

### Phase C finite scope

Phase C may:

- add `BuildCheckedPostingProjectionFromSnapshot ⟨snapshot, resolved, cycleStart⟩`;
- return the selected six-field data result without inner terminal effects;
- adapt `BuildAuthorizedRowsFromSnapshot` to preserve current success shape, fatal stdout, and exit behavior;
- add focused direct-result tests, failure-order checks, and compatibility parity evidence;
- update the map and TODO with implementation evidence when the slice closes.

Phase C must not:

- broaden the split of `context.bqn` beyond the selected checked-projection seam;
- change source TSV or metadata schema;
- change arithmetic proof domain, basis, scale, or admission rules;
- change Posting IR fields or row statuses;
- change Cube, TBDS, report, or JSON meaning;
- add a 6D report or export;
- add `CanonicalEvent` or `Project(events, spec)`;
- convert issues or journal records to append-only event sourcing;
- start Phase D automatically;
- start a new numbered Stage or broad campaign.

## 7. Planned finite sequence

### Phase B: Pure checked-result contract

The selected contract is:

- [`PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md`](PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md)

It selects this pure calculation boundary:

```text
BuildCheckedPostingProjectionFromSnapshot
  ⟨snapshot, resolved, cycleStart⟩
```

and this data result:

```text
{
  state
  row_evidence
  arithmetic_evidence
  arithmetic_currency_proof
  posting_rows
  diagnostics
}
```

The contract distinguishes:

```text
pure result construction
  !=
CLI rendering and process exit
```

Selected decisions include:

- source loading, account-file loading, cycle-file loading, and clocks remain outside;
- proof is derived from the same snapshot and is not independently supplied;
- proof rejection and coefficient-length mismatch return `state = "error"` with no posting rows;
- `unknown_account` and `invalid_date` remain Posting IR row statuses under current semantics;
- diagnostics contain data and omit the `ERROR: ` terminal prefix;
- `BuildAuthorizedRowsFromSnapshot` remains the compatibility wrapper that preserves current output and exit behavior.

Phase B is docs-only. This contract does not itself authorize runtime extraction.

### Phase C: Runtime extraction

Phase C was selected as one small runtime extraction using the merged Phase B contract.

The selected implementation shape is:

```text
pure checked builder
  -> data result

existing compatibility wrapper
  -> render first fatal diagnostic
  -> preserve current process exit behavior
```

The selected finite slice is:

```text
add BuildCheckedPostingProjectionFromSnapshot
adapt BuildAuthorizedRowsFromSnapshot as compatibility wrapper
add focused result and parity tests
```

The implementation must satisfy the direct-result and compatibility checks in the Phase B contract. No report, Cube, TBDS, currency, source, 6D, or event-storage semantics may widen in the same PR.

### Phase D: 6D feasibility

Phase D is selected as the sole active finite investigation. The first 6D work is a feasibility check, not a source schema migration or projection implementation.

Candidate dimensions remain provisional:

```text
when
party / place
what
where-to / account destination
amount
what-happened / action
```

The phase must compare each candidate dimension with fields already preserved by row evidence and raw source fields. For every dimension, the evidence must state:

- the exact current field or fields that supply the meaning;
- whether the meaning is direct, derived, ambiguous, or absent;
- whether provenance survives through current row evidence;
- whether Posting IR loses information that the 6D view would require.

Its overall conclusion must be exactly one of:

```text
A. existing evidence is sufficient
B. a small provenance extension is sufficient
C. an independent intermediate representation is required
```

Allowed evidence work:

- inspect current `main`, source adapters, row-evidence construction, fixtures, contracts, and focused tests;
- document exact field ownership and information loss;
- add narrowly scoped read-only test or inspection evidence when current preservation cannot be established from docs alone.

No formal 6D source contract is selected before this evidence exists.

For clarity:
- runtime implementation is not authorized
- source schema or metadata changes are not authorized
- 6D export/report is not authorized
- `CanonicalEvent`, `Project(events, spec)`, and another shared carrier are not authorized
- strict event sourcing is not authorized
- Phase E does not start automatically when the investigation closes

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
| Pure checked builder inputs | selected as `snapshot`, `resolved`, `cycleStart` | Phase C evidence proves the boundary cannot preserve current behavior |
| Fatal checked-result behavior | selected as structured error plus empty posting rows | A separate contract selects partial or accumulated projection behavior |
| Existing wrappers own terminal effects | selected | A separate CLI/API boundary migration is justified |
| Phase C runtime extraction | complete | Implementation evidence shows the seam preserves current behavior and exits on failure correctly |
| Phase D read-only feasibility investigation | selected | The investigation closes with one A/B/C conclusion and explicit dimension evidence |
| Add `CanonicalEvent` now | rejected for now | Two independent consumers demonstrate the same missing carrier semantics |
| Start strict event sourcing now | rejected for now | One bounded domain and replay requirement are selected with migration safety |
| Start broad headless refactor | rejected | A finite pure-result seam is implemented and tested first |
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

Perform Phase D only:

```text
inventory current row evidence and raw fields
  -> compare six provisional dimensions
  -> identify direct, derived, ambiguous, or absent meaning
  -> classify provenance sufficiency
  -> conclude A, B, or C
  -> do not implement 6D
```

After the investigation evidence merges, close Phase D separately and make another docs-only decision about what becomes eligible next. Phase E, a shared event carrier, and strict event sourcing do not begin automatically.
