# Currency Stage 2 Slice C Post-implementation Verification — 2026-07-11

Status: audit snapshot
Owner: currency
Canonical: no; current staged contract remains `docs/CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md`
Exit: retain as point-in-time evidence; do not use as automatic authorization for broader currency work

## 1. Status and reviewed lineage

Date: 2026-07-11

Reviewed implementation:

```text
PR #162  feat: implement Currency Stage 2 Slice C checked ILS path
head     d3d3a995800b17b54c863f385a672cb2f5fbc944
merge    33fe0c7981cad7de047720c9e88722d90391032b
```

GitHub Actions evidence:

```text
workflow: check
run:      #610
status:   completed
result:   success
```

Overall result:

```text
Slice C selected claims -> verified
material unresolved plan/runtime mismatch -> none
Currency Stage 2 -> complete enough for now
next action -> no automatic currency implementation
```

## 2. Actual implementation diff

PR #162 changed exactly seven paths:

```text
checks/check-src-next-currency-domain-proof.sh
fixtures/src-next-currency-c-ils-normalized/accounts.tsv
fixtures/src-next-currency-c-ils-normalized/cycle.tsv
fixtures/src-next-currency-c-ils-normalized/journal.tsv
src_next/projection.bqn
tests/test_src_next_currency_b3.bqn
tests/test_src_next_currency_c.bqn
```

Runtime change is limited to `src_next/projection.bqn`. No context, arithmetic, cube, TBDS, source schema, report, JSON, editor, workflow, or source-data path changed.

The checked proof authorizer now admits:

- proven JPY proofs with the existing allowed bases;
- proven ILS proofs only with `basis=resolved_single_currency`;
- only non-negative integer `amount_scale` values;
- `empty_source_compatibility` only with `amount_scale=0`.

Impossible ILS combinations such as `legacy_compatibility` and `empty_source_compatibility` remain rejected.

## 3. Claim-to-evidence review

| # | Selected claim | Current evidence | Classification |
|---|---|---|---|
| 1 | Proven ILS reaches the existing checked projection path | `IsAllowedProofDomainBasis` admits ILS only with `resolved_single_currency`; focused tests assert successful authorization. | **verified** |
| 2 | ILS does not acquire legacy or empty-source compatibility | Focused authorizer cases reject ILS with `legacy_compatibility` and `empty_source_compatibility`. | **verified** |
| 3 | All-ILS exact decimals preserve the shared normalized-integer model | The Slice C fixture resolves `domain=ILS`, `basis=resolved_single_currency`, and `amount_scale=2`, then asserts exact signed posting deltas. | **verified** |
| 4 | Normalized ILS postings reach cube and TBDS without conversion | The full-context test asserts six valid postings, zero skipped rows, balanced totals, exact expense movement, and exact asset movement. | **verified** |
| 5 | Existing JPY behavior remains covered | Legacy integer JPY, implicit decimal JPY, explicit JPY, empty source, and exact downstream JPY aggregation remain asserted. | **verified** |
| 6 | Mixed JPY/ILS remains closed | Mixed-domain proof resolution remains `unsupported` with `mixed_currency_domains`. | **verified** |
| 7 | Slice C did not widen into broader currency semantics | The seven-path diff contains no FX, conversion, valuation, base-currency, display, rounding, mixed aggregation, currency-axis, report, or JSON implementation. | **verified** |

## 4. Exact all-ILS evidence

Fixture:

```text
fixtures/src-next-currency-c-ils-normalized/
```

Source amounts:

```text
1200 ILS
42.50 ILS
0.05 ILS
```

Expected and asserted proof:

```text
state = proven
domain = ILS
basis = resolved_single_currency
amount_scale = 2
```

Expected and asserted normalized postings:

```text
debit:   120000, 4250, 5
credit: -120000, -4250, -5
debit total: 124255
credit total: -124255
balance: 0
```

Downstream evidence:

```text
cube valid postings: 6
cube skipped rows: 0
actual expense total: 124255
expense TBDS movement: 124255
asset TBDS movement: -124255
```

This is checked admission and downstream observation of normalized integer values. It is not currency conversion, valuation, or display policy.

## 5. Boundary retained after completion

Currency Stage 2 is complete enough for now. This verification does not authorize a Stage 3 or another automatic currency campaign.

Do not auto-start:

- FX or conversion;
- valuation or base currency;
- display precision or rounding policy;
- mixed-currency aggregation;
- a currency axis;
- report or JSON widening.

Any future currency work requires a concrete consumer, daily-use problem, or reproducible defect, followed by a new finite routing decision.

## 6. Routing decision

```text
Slice C implementation -> merged through PR #162
Slice C CI -> green
Slice C selected claims -> verified
Currency Stage 2 -> complete enough for now
Active currency slice -> none
```

The repository should retain an intentionally quiet Active work slot rather than promoting a Next candidate merely because Slice C has closed.
