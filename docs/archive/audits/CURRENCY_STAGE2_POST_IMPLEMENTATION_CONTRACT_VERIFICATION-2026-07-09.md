# Currency Stage 2 Post-Implementation Contract Verification — 2026-07-09

Status: audit snapshot
Owner: config
Canonical: no; current contracts: `docs/CURRENCY_STAGE2_SINGLE_CURRENCY_DOMAIN_DECISION.md`, `docs/CURRENCY_STAGE2_MINIMAL_DOMAIN_PROOF_IMPLEMENTATION_PLAN.md`
Exit: keep as point-in-time evidence; any implementation follow-up requires a separate finite decision or plan

## Purpose

Verify that the merged Stage 2 minimal domain-proof runtime still matches the selected Stage 2 decision and implementation plan before broader per-row currency work begins.

This audit also uses the AI-work-quality classification signal:

```text
ID 20 — safety claim / executable evidence linkage
```

only as a review lens. The classification item is not implementation authorization.

## Scope

Reviewed current relationships among:

- `docs/CURRENCY_STAGE2_SINGLE_CURRENCY_DOMAIN_DECISION.md`
- `docs/CURRENCY_STAGE2_MINIMAL_DOMAIN_PROOF_IMPLEMENTATION_PLAN.md`
- `src_next/context.bqn`
- `src_next/projection.bqn`
- `tests/test_src_next_currency_domain_proof.bqn`
- `checks/check-src-next-currency-domain-proof.sh`
- `tools/check.sh`

Out of scope:

- Stage 3
- admitted explicit row `currency=` support
- per-row multi-currency support
- FX / conversion / valuation
- runtime changes
- test or check changes
- fixture changes
- source TSV changes

## Verification result

Overall assessment:

```text
core Stage 2 proof -> carrier -> gate chain
=
substantially aligned with the selected decision and plan
```

One boundary remains unresolved:

```text
exported BuildPeriodView
can consume caller-supplied posting rows
without carrying or checking arithmetic currency proof
```

The normal `BuildContext` path is gated before `BuildPeriodView`, but the broader contract claim that downstream aggregation consumes only proven-domain rows is not executable at the exported `BuildPeriodView` boundary itself.

This audit does not decide whether that is a defect. It records a finite architecture question.

## Claim-to-evidence table

| Contract claim | Current runtime owner | Current evidence | Assessment |
|---|---|---|---|
| one posting-source snapshot covers `journal.tsv`, `plan.tsv`, `budget_alloc.tsv` | `context.LoadPostingSourceSnapshot` | same-snapshot integration check; canonical `sources` test | aligned |
| proof input snapshot equals projection input snapshot | `context.BuildAuthorizedRowsFromSnapshot` derives proof from its own snapshot argument | file-mutation same-snapshot check; old independent-proof API substitution fails | aligned |
| missing row currency resolves current legacy JPY compatibility | `context.ResolveArithmeticCurrencyProof` | legacy fixture unit assertions | aligned |
| empty monetary source resolves JPY with `empty_source_compatibility` basis | `context.ResolveArithmeticCurrencyProof` | empty projection fixture unit assertions | aligned |
| explicit source-row `currency=` is unsupported in the minimal slice | `context.HasCurrencyMeta` + resolver | journal / plan / budget unit cases and BuildContext failure checks | aligned |
| metadata detection is after the protected first five fields | `context.HasCurrencyMeta` uses `5 ↓ flds` | memo / `currency_hint` / nested-value precision unit cases | aligned |
| proof is carried in run context rather than invented there | `context.BuildContext` carries result from `BuildAuthorizedRowsFromSnapshot` | context proof field assertions | aligned |
| projection authorization requires proven JPY plus allowed basis | `projection.AuthorizeArithmeticCurrencyProof` / `RequireArithmeticCurrencyProof` | negative proof-state unit matrix | aligned |
| authorization occurs before naked delta construction on the normal path | `context.BuildAuthorizedRowsFromSnapshot` calls `proj.RequireArithmeticCurrencyProof` before row construction | explicit-currency BuildContext failures; current call ordering | aligned |
| exported row-building paths do not accept an independently supplied proof | context wrappers derive proof from loaded/provided snapshot | old API substitution failure; direct projection-bypass grep | aligned for current row-building exports |
| downstream aggregation consumes only proven-domain rows | normal `BuildContext` path gates before `BuildPeriodView` | structural normal-path ordering only | partial / unresolved at exported `BuildPeriodView` boundary |

## Detailed findings

### 1. Same-source-snapshot invariant is materially implemented

Current runtime loads:

```text
journal.tsv
plan.tsv
budget_alloc.tsv
```

into one `snapshot.sources` collection.

`BuildAuthorizedRowsFromSnapshot` then:

```text
snapshot
  -> ResolveArithmeticCurrencyProof snapshot
  -> RequireArithmeticCurrencyProof proof
  -> build rows from snapshot.sources
```

The implementation does not accept an independently supplied proof at that entry point.

Evidence is stronger than a prose claim because the shell check mutates the source file after snapshot load and verifies projection still uses the original in-memory snapshot.

Assessment:

```text
aligned
```

### 2. Explicit currency fail-closed ordering is implemented

The resolver inspects metadata tokens after the first five fields.

Any token beginning with the exact key prefix:

```text
currency=
```

produces unsupported proof state in the minimal slice.

The normal authorized builder calls the projection-owned requirement before row construction.

Evidence covers:

- journal source
- plan source
- budget allocation source
- memo text containing `currency=...`
- `currency_hint=...`
- another metadata value containing `currency=...`

Assessment:

```text
aligned
```

### 3. Proof carrier and authorization responsibilities remain distinct

Current responsibility shape is:

```text
context resolver
  = proof evidence resolution

BuildContext
  = proof carrier

projection module
  = authorization predicate / fail-closed diagnostic
```

The authorization logic is owned by `src_next/projection.bqn` and the normal context path invokes it before naked delta rows are built.

Assessment:

```text
aligned
```

### 4. Current exported row-building paths close the old independent-proof shape

Current row-building entry points derive proof from the snapshot they use rather than accepting a second independently supplied proof argument.

The shell check also rejects the old cross-snapshot substitution call shape.

The repository check searches for direct exported projection bypass patterns in `src_next` and tests.

Assessment:

```text
aligned for current row-building exports
```

This is intentionally narrower than claiming that no arbitrary caller can ever construct a row-like namespace.

### 5. Downstream-only-proven-rows claim is not fully executable at `BuildPeriodView`

The Stage 2 decision says downstream cube / TBDS / reports consume posting rows only after upstream proof and gate success.

The normal path satisfies that order:

```text
BuildContext
  -> BuildAuthorizedRowsFromSnapshot
  -> proof gate
  -> rows
  -> BuildPeriodView
```

However, `BuildPeriodView` is itself exported and has the shape:

```text
BuildPeriodView ⟨rows, resolved, cy⟩
```

It does not receive or validate arithmetic currency proof.

Therefore current evidence supports:

```text
normal BuildContext path is gated
```

but does not by itself prove the stronger repository-wide statement:

```text
all downstream aggregation entry is restricted to proven-domain rows
```

Assessment:

```text
partial / unresolved boundary
```

Do not auto-fix. First decide the intended ownership contract.

## Next finite question

```text
Is exported BuildPeriodView intentionally a trusted post-gate function,
or is it an arithmetic-domain boundary that must carry or require proof?
```

Candidate meanings to decide later:

### A. Trusted post-gate function

- `BuildPeriodView` remains proof-free.
- Its current contract explicitly states that callers must supply already-authorized posting rows.
- Current export is intentional.
- Evidence should make that trust boundary visible.

### B. Enforced downstream boundary

- `BuildPeriodView` requires proof or an authorized-row carrier.
- Direct ungated caller-supplied rows fail closed.
- This would be a runtime/API change and is not authorized by this audit.

### C. Narrow/export reduction

- `BuildPeriodView` becomes internal or a narrower checked wrapper owns the public path.
- This is also an API/runtime decision and is not authorized by this audit.

No option is selected here.

## AI work quality / token-efficiency learning

This audit supports the ID 20 review principle:

```text
safety claim
-> current runtime owner
-> executable evidence
```

The useful result is not a new guard registry or new tool.

A compact claim-to-evidence table was sufficient to show:

- which Stage 2 claims are already executable;
- which claims are structural normal-path properties;
- where one exported boundary still needs an explicit semantic decision.

This reduces the need for each later AI to reconstruct the entire Stage 2 proof chain from prose, runtime, unit tests, and shell checks independently.

## Closure of this verification slice

```text
post-implementation contract verification -> complete
core proof/carrier/gate chain -> aligned
BuildPeriodView downstream boundary -> unresolved finite decision
Stage 3 -> not authorized
explicit row currency support -> not authorized
FX -> not authorized
```

Any runtime change must start from a separate decision or approved plan. This audit is evidence, not an implementation backlog.
