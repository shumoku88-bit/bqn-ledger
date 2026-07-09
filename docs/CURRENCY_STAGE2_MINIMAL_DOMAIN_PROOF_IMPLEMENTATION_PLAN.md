# Currency Stage 2 Minimal Domain-Proof Implementation Plan

Status: active implementation plan / docs-only
Owner: config
Canonical: yes
Decision date: 2026-07-09
Depends on: `docs/CURRENCY_STAGE1_AMOUNT_SEMANTICS_DECISION.md`, `docs/CURRENCY_STAGE2_SINGLE_CURRENCY_DOMAIN_DECISION.md`, `docs/CURRENT_CURRENCY_ASSUMPTION_MAP.md`, `docs/POSTING_IR_CONTRACT.md`
Exit: archive or supersede after the narrow runtime slice proves the current JPY compatibility domain before posting-row construction, carries the proof in context, and enforces it at the projection boundary

This document plans the smallest runtime implementation slice after the Stage 2 single-currency domain decision. It does not implement currency support.

## 1. Current runtime flow

Current `src_next/context.bqn` flow is effectively:

```text
BuildContext
  -> read cycle
  -> resolve accounts
  -> BuildAllRows
       -> BuildRowsForFile / BuildRowsForFileOptional
       -> read source TSV files
       -> loader.SplitTsvKeepEmpty
       -> projection.MakeRow
       -> create naked debit/credit deltas
  -> BuildPeriodView
  -> cube / TBDS
```

Current posting-row source files are:

```text
journal.tsv
plan.tsv
budget_alloc.tsv
```

Current relevant exported entry points:

```text
src_next/context.bqn:
  BuildContext
  BuildAllRows
  BuildRowsForFile
  BuildRowsForFileOptional

src_next/projection.bqn:
  MakeRow
```

Current additional direct projection paths observed in repository code/tests:

```text
src_next/main.bqn       -> local BuildRowsForFile / proj.MakeRow
src_next/ytd_summary.bqn -> local BuildRows / proj.MakeRow
tests/*                 -> direct proj.MakeRow helpers and fixture row builders
```

Current implementation fact: `BuildRowsForFile*` reads source files and then immediately calls `projection.MakeRow`. Therefore a proof established only after `BuildAllRows` is too late, because naked deltas already exist.

## 2. Selected minimal runtime slice

Selected smallest runtime capability:

```text
current source rows have no explicit source-row currency metadata
  -> resolve as legacy JPY compatibility evidence
  -> prove arithmetic currency domain = JPY
  -> carry proof in context
  -> authorize projection
  -> create current naked Posting IR deltas
```

Also selected:

```text
no monetary source rows
  -> prove arithmetic currency domain = JPY
  -> basis = empty_source_compatibility
  -> operation remains usable
```

Not selected for the minimal slice:

```text
explicit source-row currency support
per-row multi-currency support
explicit JPY row support
FX / conversion
```

The minimal runtime slice is intentionally narrower than the Stage 1 semantic model. Stage 1 says explicit `currency=JPY` is semantically a known explicit source currency. This implementation slice will reject explicit row-currency markers because row-level currency runtime support is not implemented yet.

## 3. Same-source-snapshot invariant

Core invariant for the runtime implementation:

```text
proof input snapshot
=
projection input snapshot
```

The runtime must not do this:

```text
read source files for proof
  -> prove JPY
read source files again for projection
  -> create naked deltas
```

That double-read shape is a TOCTOU gap: the source snapshot used for proof may differ from the source snapshot used for projection.

Selected implementation direction:

```text
load posting-source snapshot once
  -> resolve compatibility proof from that in-memory snapshot
  -> build posting rows from that same in-memory snapshot
```

The plan does not require OS-level file locking in the first slice. It requires the in-process proof and projection path to share one loaded immutable snapshot.

## 4. Source snapshot loading boundary

Add a small source-snapshot boundary in `src_next/context.bqn` or a new focused `src_next` helper module if implementation clarity requires it.

Planned conceptual function:

```text
LoadPostingSourceSnapshot base
  -> {
       journal_lines,
       plan_lines,
       budget_alloc_lines,
       sources
     }
```

Repository-grounded details:

- `journal.tsv` remains required and should use the same required-read behavior as today.
- `plan.tsv` remains optional and should use current optional-read behavior.
- `budget_alloc.tsv` remains optional and should use current optional-read behavior.
- Lines are the already filtered data lines returned by `loader.ReadLines` / `loader.ReadLinesOptional`.
- The snapshot should preserve source file identity so proof diagnostics and row building can identify which file contained unsupported metadata.
- Source lines should be split with `loader.SplitTsvKeepEmpty` only when constructing evidence rows / projection arguments, preserving current journal-like empty-column behavior.

Preferred shape for source entries:

```text
{
  source_file ⇐ "journal.tsv",
  required    ⇐ 1,
  lines       ⇐ journalLines
}
```

or an equivalent repository-native namespace/list shape. Exact BQN names may be adjusted during implementation, but the shape must make it impossible for proof to use one set of lines while projection reads another set internally.

## 5. JPY compatibility proof resolver responsibility

Add a narrow resolver whose only first-slice job is current compatibility proof:

```text
ResolveArithmeticCurrencyProof snapshot
  -> proof namespace
```

Selected proof behavior for the minimal slice:

```text
all admitted monetary source rows have no explicit source-row currency marker
  -> proof.state = "proven"
  -> proof.domain = "JPY"
  -> proof.basis = "legacy_compatibility"
```

If the snapshot has no monetary source rows:

```text
proof.state = "proven"
proof.domain = "JPY"
proof.basis = "empty_source_compatibility"
```

The resolver owns source compatibility evidence resolution. The run context later carries its result; the context does not invent it.

### Monetary source row scope

The resolver must inspect every source row admitted to the posting-row construction path:

```text
journal.tsv
plan.tsv
budget_alloc.tsv
```

It must not prove from only `journal.tsv` while allowing `plan.tsv` or `budget_alloc.tsv` to enter naked-delta arithmetic with unresolved currency semantics.

### Explicit currency marker detection boundary

Explicit source currency detection must inspect only metadata tokens after the protected first five TSV fields.

A currency marker means an exact metadata token with key `currency`, for example:

```text
currency=JPY
```

Do not detect currency semantics by raw-line substring search. Do not treat memo text, `currency_hint=...`, or another metadata value containing `currency=...` as an explicit source currency marker.

This boundary is about proof evidence precision only. It does not introduce admitted row-currency support in the minimal slice.

### What counts as a row for the empty-source case

For this minimal slice, a monetary source row means a data line from one of the posting-source files in the loaded snapshot. Current files are already read as data lines after comments and empty lines are filtered by the loader.

Thus:

```text
sum of snapshot data lines across journal.tsv / plan.tsv / budget_alloc.tsv = 0
  -> empty_source_compatibility

otherwise, if no explicit source currency marker is found
  -> legacy_compatibility
```

## 6. Explicit currency unsupported / fail-closed behavior

Selected minimal-slice behavior:

```text
any explicit source-row currency marker encountered
  -> unsupported by this minimal runtime slice
  -> proof.state = "unsupported"
  -> fail closed before naked delta creation
```

This includes:

```text
currency=JPY
currency=ILS
currency=USD
currency=UNKNOWN
```

Rationale:

```text
explicit JPY may be semantically known under Stage 1
but
explicit row-currency runtime support is not implemented in this minimal Stage 2 slice
```

The minimal implementation should therefore not pretend to support explicit row currency merely because the domain would be JPY.

Planned diagnostic class/name may be one of:

```text
unsupported_source_currency
unsupported_explicit_currency
```

The exact status string should be chosen during implementation to fit existing diagnostic vocabulary, but it must clearly say that explicit row currency is unsupported in this runtime slice and must stop before naked deltas are created.

## 7. Unknown / unresolved / mixed states

For this minimal slice:

```text
unknown explicit currency
  -> fail closed as unsupported/invalid before projection

unresolved proof
  -> fail closed before projection

mixed domain
  -> fail closed before projection
```

Because the minimal runtime rejects all explicit source currency markers, mixed-domain proof is not expected through supported input yet. The proof representation should still have enough state vocabulary for tests to forge invalid/mixed/unresolved proof values and verify the gate fails closed.

No FX behavior is planned. No conversion behavior is planned.

## 8. Run context proof carrier

Selected context carrier shape:

```text
ctx.arithmetic_currency_proof = {
  state,
  domain,
  basis,
  message
}
```

Planned successful examples:

```text
{
  state   ⇐ "proven",
  domain  ⇐ "JPY",
  basis   ⇐ "legacy_compatibility",
  message ⇐ ""
}
```

```text
{
  state   ⇐ "proven",
  domain  ⇐ "JPY",
  basis   ⇐ "empty_source_compatibility",
  message ⇐ ""
}
```

Planned failing examples:

```text
{
  state   ⇐ "unsupported",
  domain  ⇐ "",
  basis   ⇐ "explicit_source_currency",
  message ⇐ "explicit source currency unsupported in Stage 2 minimal runtime slice: journal.tsv row 3"
}
```

```text
{
  state   ⇐ "unresolved",
  domain  ⇐ "",
  basis   ⇐ "",
  message ⇐ "missing arithmetic currency proof"
}
```

Do not add both of these as independent truths unless a concrete consumer requires it:

```text
ctx.arithmetic_currency_domain
ctx.arithmetic_currency_proof.domain
```

The proof namespace is the carrier. Consumers that need the domain read `ctx.arithmetic_currency_proof.domain` after verifying `state="proven"`.

## 9. Projection enforcement gate

Selected gate location:

```text
projection-owned authorization helper before the MakeRow loop creates naked deltas
```

Planned projection API addition:

```text
AuthorizeArithmeticCurrencyProof proof
  -> ok / fail-closed diagnostic
```

or an equivalent predicate + diagnostic pair such as:

```text
ProjectionAuthorized proof
ProjectionAuthorizationMessage proof
```

Selected successful authorization rule:

```text
proof.state = "proven"
proof.domain = "JPY"
proof.basis ∊ {"legacy_compatibility", "empty_source_compatibility"}
  -> projection authorized
```

Selected failure rule:

```text
proof missing
proof.state != "proven"
proof.domain missing
proof.domain unsupported
proof.basis unsupported
  -> projection not authorized
  -> no naked deltas
```

This gate belongs to `projection.bqn` because Stage 2 selected the projection boundary as the enforcement gate. Source compatibility resolution remains the proof owner; context remains the carrier.

## 10. Gate-bypass prevention

Current exports make bypass possible if only `BuildContext` checks proof:

```text
context.BuildAllRows is exported
context.BuildRowsForFile is exported
context.BuildRowsForFileOptional is exported
projection.MakeRow is exported and used directly by tests and older/auxiliary paths
```

Selected strategy for the next runtime slice:

```text
B. require proof authorization at every exported row-building entry point,
   while introducing snapshot-based entry points as the preferred path
```

Planned shape:

1. Add snapshot-based context row builder:

```text
BuildAllRowsFromSnapshot ⟨snapshot, resolved, cycleStart, proof⟩
```

2. Make current `BuildAllRows` either:

```text
- a compatibility wrapper that loads one snapshot, resolves proof, and calls BuildAllRowsFromSnapshot
```

or:

```text
- a deprecated/internal wrapper not used by BuildContext, if compatibility constraints allow
```

The preferred first implementation is compatibility wrapper, because current tests and consumers may import it.

3. Update `BuildRowsForFile` and `BuildRowsForFileOptional` signatures or wrap them so any exported form requires proof authorization before calling `proj.MakeRow`.

4. Add a projection-owned checked row-builder for loops:

```text
MakeRowsAuthorized ⟨proof, args⟩
```

or:

```text
AuthorizeArithmeticCurrencyProof proof
# called once before ∾ (proj.MakeRow ¨ args)
```

A single gate before the row projection loop is preferred because the proof is run-owned, not row-owned. However, exported lower-level paths must not bypass the gate.

5. Keep `projection.MakeRow` available only if one of these is true:

```text
- it becomes an internal helper not exported; or
- its signature requires proof; or
- it remains exported only for pure unit tests with a separate explicit test-only bypass that production/context paths cannot call accidentally
```

Preferred implementation direction: change the exported production row-building API to require proof, and update direct unit tests accordingly. Do not leave a production-usable exported `MakeRow` path that can create naked deltas without proof.

6. Review and adapt direct callers:

```text
src_next/context.bqn
src_next/main.bqn
src_next/ytd_summary.bqn
tests/test_src_next_account_key.bqn
tests that define local BuildRowsForFile helpers around proj.MakeRow
```

`src_next/main.bqn` is a legacy/demo entrypoint but still exists and should not keep an unproven naked-delta path. `src_next/ytd_summary.bqn` currently rebuilds journal rows from disk separately; the implementation plan should either route it through context rows/snapshot or give it the same proof/snapshot protection. A later implementation must not leave YTD as a hidden double-read bypass.

## 11. Planned function / module shape

Preferred minimal implementation shape:

```text
src_next/context.bqn
  LoadPostingSourceSnapshot
  ResolveArithmeticCurrencyProof
  BuildAllRowsFromSnapshot
  BuildAllRows            # compatibility wrapper, if retained
  BuildRowsForFile*       # proof-aware or no longer exported if feasible
  BuildContext            # carries arithmetic_currency_proof

src_next/projection.bqn
  AuthorizeArithmeticCurrencyProof
  MakeRowAuthorized or proof-aware MakeRow path
```

The implementation may split source snapshot / proof resolver into a focused module if the code becomes clearer, for example:

```text
src_next/currency_domain.bqn
```

If a new module is added, add BQN unit tests and update `tools/repo-index --baseline` as required by repo policy.

Planned context construction ordering:

```text
BuildContext
  -> read cycle
  -> resolve accounts
  -> LoadPostingSourceSnapshot base
  -> ResolveArithmeticCurrencyProof snapshot
  -> BuildAllRowsFromSnapshot ⟨snapshot, resolved, cy.start, proof⟩
       -> projection authorization gate
       -> projection.MakeRow only after authorization
  -> BuildPeriodView
  -> return ctx including arithmetic_currency_proof
```

The exact BQN namespace fields may be adjusted, but the semantic shape must remain:

```text
proof source != runtime carrier
runtime carrier != enforcement gate
projection gate before naked deltas
proof input snapshot = projection input snapshot
```

## 12. Planned tests

The later runtime implementation must include focused tests. Suggested filenames are examples; exact names may follow existing conventions.

### 12.1 Legacy current JPY compatibility

Fixture/source shape:

```text
journal.tsv / plan.tsv / budget_alloc.tsv contain no explicit source currency metadata
```

Expected:

```text
proof.state = "proven"
proof.domain = "JPY"
proof.basis = "legacy_compatibility"
projection succeeds
existing output behavior remains unchanged
```

This should use an existing golden fixture where possible to avoid broad fixture churn.

### 12.2 Empty monetary source

Fixture/source shape:

```text
no monetary rows across journal.tsv / plan.tsv / budget_alloc.tsv
```

Expected:

```text
proof.state = "proven"
proof.domain = "JPY"
proof.basis = "empty_source_compatibility"
operation succeeds
```

This can likely reuse or adapt the existing empty projection fixture.

### 12.3 Explicit currency marker in journal

Fixture/source shape:

```text
journal.tsv row contains metadata token currency=JPY or currency=ILS
```

Expected:

```text
proof.state = "unsupported"
fail closed before projection creates naked deltas
no posting rows are produced for cube/TBDS consumption
```

Include explicit `currency=JPY` to prove semantic validity is not the same as minimal-runtime support.

### 12.4 Explicit currency marker in plan or budget_alloc

Fixture/source shape:

```text
journal.tsv clean
plan.tsv or budget_alloc.tsv contains currency=JPY / currency=ILS
```

Expected:

```text
proof fails closed before projection
```

This proves all three posting-source files participate in evidence resolution.

### 12.5 Unresolved / forged proof state

Unit tests for projection authorization should cover:

```text
missing proof
proof.state != "proven"
domain missing
domain != "JPY" in this minimal slice
basis unsupported
```

Expected:

```text
projection authorization fails
MakeRow / naked delta creation is not reachable through exported row-building paths
```

### 12.6 Same-snapshot property

Add a focused test that proves:

```text
LoadPostingSourceSnapshot base
  -> ResolveArithmeticCurrencyProof snapshot
mutate backing TSV fixture after snapshot is loaded
BuildAllRowsFromSnapshot snapshot
  -> consumes the originally loaded snapshot, not the changed file
```

This test must use a temporary fixture directory, not real source TSV. It may copy an existing small fixture into a temp directory, load the snapshot, modify the temp TSV, then assert projection rows match the pre-modification snapshot.

If direct file mutation in BQN tests is awkward, an equivalent shell check may be added in `checks/` that creates a temporary fixture and exercises a BQN helper. The important assertion is:

```text
proof input snapshot = projection input snapshot
```

### 12.7 Bypass regression

Add tests/checks that direct exported row-building entry points cannot create naked deltas without a valid proof:

```text
BuildAllRows / BuildRowsForFile* without proof -> rejected or no longer exported production path
projection row builder with forged/unproven proof -> rejected
```

Update existing direct `proj.MakeRow` tests to use the new proof-aware API or explicitly test that raw helpers are internal/unexported.

## 13. Explicit non-goals

This plan does not authorize:

- runtime implementation in this PR;
- source TSV migration;
- real source TSV edits;
- sample source TSV edits;
- `currency=` runtime support for admitted rows;
- explicit JPY source-row support;
- per-row multi-currency support;
- decimal parser;
- rounding policy;
- minor-unit normalization;
- Posting IR runtime currency fields;
- BuildContext runtime changes in this docs-only PR;
- projection argument changes in this docs-only PR;
- cube / TBDS / ViewModel / JSON changes;
- editor changes;
- metadata schema changes;
- AccountKey behavior changes;
- `BASE_CURRENCY`;
- `base_amount`;
- FX;
- automatic conversion;
- currency axis;
- currency-partitioned reports.

Do not infer arithmetic domain from:

```text
account-level currency= metadata
AccountKey suffixes such as /JPY, /USD, /ILS
ledger config declarations
human display labels
```

## 14. Exact next authorized runtime slice

The next finite runtime slice authorized by this plan is only:

```text
Implement current JPY compatibility domain proof before posting-row construction by:

1. loading one posting-source snapshot for journal.tsv / plan.tsv / budget_alloc.tsv;
2. resolving a proof namespace from that same snapshot;
3. rejecting any explicit source-row currency marker as unsupported in this minimal slice;
4. carrying the proof as ctx.arithmetic_currency_proof;
5. requiring projection-owned authorization before any naked Posting IR deltas are created;
6. building posting rows from the same loaded snapshot;
7. adding focused tests for legacy compatibility, empty source, explicit currency rejection, forged proof rejection, and same-snapshot behavior.
```

No broader currency work is authorized automatically.
