# Currency Stage 2 BuildPeriodView Downstream Boundary Decision

Status: current contract / docs-only decision record
Owner: config
Canonical: yes
Decision date: 2026-07-10
Depends on: `docs/CURRENCY_STAGE2_SINGLE_CURRENCY_DOMAIN_DECISION.md`, `docs/CURRENCY_STAGE2_MINIMAL_DOMAIN_PROOF_IMPLEMENTATION_PLAN.md`, `docs/POSTING_IR_CONTRACT.md`, `docs/archive/audits/CURRENCY_STAGE2_POST_IMPLEMENTATION_CONTRACT_VERIFICATION-2026-07-09.md`
Exit: supersede only if a later runtime/API decision makes `BuildPeriodView` an enforced proof boundary, narrows its export, or replaces the Posting IR downstream boundary

This document selects the narrow Stage 2 downstream proof-boundary meaning after the post-implementation audit. It is docs-only and does not authorize runtime changes.

## 1. Question

What is the intended currency-proof boundary role of the exported function:

```text
BuildPeriodView ⟨rows, resolved, cy⟩
```

after Stage 2 minimal domain-proof implementation?

The audit found that the normal `BuildContext` path is proof-gated before row construction, but `BuildPeriodView` itself remains exported and does not receive or validate an arithmetic currency proof.

## 2. Selected meaning

Selected option:

```text
A. BuildPeriodView is an intentional trusted post-gate downstream function.
```

Meaning:

```text
BuildPeriodView
=
trusted post-gate downstream consumer
```

Its caller contract requires posting rows that have already passed the applicable upstream arithmetic-currency proof and projection authorization path.

`BuildPeriodView` itself must not, in this slice:

- resolve source currency evidence;
- invent or carry an independent arithmetic currency proof;
- become a second projection authorization owner;
- independently infer arithmetic currency domain;
- automatically receive a new proof argument.

## 3. Boundary distinction

Preserve this distinction:

```text
projection boundary
= arithmetic authorization gate before naked delta construction

BuildPeriodView
= downstream consumer of already-authorized Posting IR rows
```

The Stage 2 proof chain remains:

```text
proof source != runtime carrier
runtime carrier != enforcement gate
projection gate != semantic owner
downstream aggregation != currency inference
trusted precondition != mechanically enforced boundary
```

## 4. Normal checked path claim

The executable claim is intentionally scoped to the normal checked context path:

```text
normal checked BuildContext path
-> proof resolution
-> projection-owned authorization
-> authorized posting rows
-> BuildPeriodView
```

Current evidence supports this normal-path ordering. The claim does not mean that arbitrary direct invocation of exported `BuildPeriodView` is mechanically proof-gated.

Therefore avoid repository-wide wording such as:

```text
all downstream aggregation entry is restricted to proven-domain rows
```

unless a later runtime/API slice adds a mechanical boundary at that export or narrows the export surface.

## 5. Consequences

Selected consequences:

- `BuildPeriodView` may remain proof-free under the trusted caller precondition.
- Downstream cube / TBDS / reports do not own currency inference or proof resolution.
- The projection-owned authorization gate remains the arithmetic enforcement boundary before naked Posting IR delta construction.
- Any future change to add a proof argument, authorized-row carrier, or export reduction requires a separate runtime/API decision.

Not selected:

- making `BuildPeriodView` an enforced downstream boundary;
- requiring `BuildPeriodView` to receive proof in this slice;
- narrowing or removing the `BuildPeriodView` export in this slice;
- Stage 3;
- admitted explicit row `currency=` support;
- per-row multi-currency support;
- `base_amount=`, `BASE_CURRENCY`, FX, conversion, or valuation semantics.

## 6. Evidence check

Reviewed repository evidence did not materially contradict selecting option A:

- `src_next/context.bqn` currently calls `BuildAuthorizedRowsFromSnapshot` from `BuildContext` before `BuildPeriodView`.
- `BuildAuthorizedRowsFromSnapshot` resolves proof from the same posting-source snapshot and calls the projection-owned authorization requirement before row construction.
- `BuildPeriodView` has shape `BuildPeriodView ⟨rows, resolved, cy⟩` and does not inspect or validate proof.
- The audit already identified this as an unresolved semantic boundary rather than a proven defect.

This decision records that the current shape is intentional under a trusted precondition, not that the export itself enforces the precondition.

## 7. Non-authorization

This decision does not authorize:

- runtime changes;
- tests, checks, or fixtures;
- source TSV changes;
- proof argument changes;
- carrier/API changes;
- export reduction;
- Stage 3;
- explicit row currency support;
- per-row multi-currency;
- `base_amount=`;
- `BASE_CURRENCY`;
- FX, conversion, or valuation semantics.
