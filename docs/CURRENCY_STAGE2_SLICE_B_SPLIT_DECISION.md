# Currency Stage 2 Slice B Split Decision

Status: active plan
Owner: config
Canonical: yes
Decision date: 2026-07-10
Exit: archive or supersede after the selected staged runtime path reaches checked ILS posting path (Slice C completion) or a later decision replaces this split

## Purpose

Decide how the remaining selected Currency Stage 2 Slice B semantics should be divided into the smallest executable runtime sub-slices with explicit ownership, boundaries, prerequisites, and exit evidence, to ensure safety, ease of verification, and adherence to the Quality Bar.

## Reviewed Current Owners

*   [exact_decimal.bqn](../src_next/exact_decimal.bqn) - Pure exact-decimal source parser module (Slice A kernel).
*   [context.bqn](../src_next/context.bqn) - Ingestion orchestration, proof resolution, and projection coordination.
*   [projection.bqn](../src_next/projection.bqn) - Proof authorization and posting row projection.

## Preserved Semantics

This decision preserves the semantics already selected by [CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_EXACT_DECIMAL_IMPLEMENTATION_PLAN.md](CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_EXACT_DECIMAL_IMPLEMENTATION_PLAN.md):
*   **Exact decimal representation**: `{coefficient, scale, source_text, state, message}`.
    *   *Example*: `12.00` yields `coefficient = 12`, `scale = 0`, and `source_text = "12.00"`. Trailing fractional zeros are removed for arithmetic canonicalization.
    *   *Example*: `12.34` yields `coefficient = 1234`, `scale = 2`, and `source_text = "12.34"`.
    *   *Preserve*: Canonical arithmetic scale (`scale`) is distinct from the raw source spelling or display precision.
*   **Parser grammar**: `digits+` or `digits+ "." digits+`.
*   **Snapshot-wide scale (`amount_scale`)**: Maximum canonical scale of all admitted rows.
*   **Coefficient normalization**: `normalized_coefficient = coefficient × 10^(amount_scale - row.scale)`.
*   **Fail-closed invariants**: Fails closed on any invalid decimal syntax, duplicated metadata, or coefficient overflow (parsed or normalized).
*   **One shared-snapshot invariant**: Load, parse, resolve, normalize, prove, and project must happen on the same in-memory snapshot.

---

## Selected Split

Execution status at 2026-07-11:

- B1 merged in PR #146 and is post-implementation verified by [`CURRENCY_STAGE2_SLICE_B1_POST_IMPLEMENTATION_VERIFICATION-2026-07-10.md`](archive/audits/CURRENCY_STAGE2_SLICE_B1_POST_IMPLEMENTATION_VERIFICATION-2026-07-10.md).
- B2 merged in PR #155 and is post-implementation verified by [`CURRENCY_STAGE2_SLICE_B2_POST_IMPLEMENTATION_VERIFICATION-2026-07-11.md`](archive/audits/CURRENCY_STAGE2_SLICE_B2_POST_IMPLEMENTATION_VERIFICATION-2026-07-11.md).
- B3 is present on `main` and is post-implementation verified by [`CURRENCY_STAGE2_SLICE_B3_POST_IMPLEMENTATION_VERIFICATION-2026-07-11.md`](archive/audits/CURRENCY_STAGE2_SLICE_B3_POST_IMPLEMENTATION_VERIFICATION-2026-07-11.md).
- Slice C is the next authorized finite runtime slice. Broader currency work remains unauthorized.

We divide the remaining work into four sequential, independently finite executable sub-slices:

```mermaid
graph TD
    A[Slice A: Exact Decimal Kernel - Completed] --> B1[Slice B1: Row Ingestion & Pre-Gate Evidence]
    B1 --> B2[Slice B2: Snapshot Arithmetic Evidence]
    B2 --> B3[Slice B3: Proof & JPY Posting Integration]
    B3 --> C[Slice C: Checked ILS Posting Path]
```

### Slice B1: Row Ingestion and Pre-Gate Row Evidence

*   **Description**: Replaces the simple integer-only amount check in `context.bqn` row ingestion with a pre-gate row evidence stage that consumes the in-memory snapshot exactly once. Resolves row currency metadata and parses row amounts using `exact_decimal.Parse`.
*   **Prerequisites**: Slice A (completed).
*   **Ownership**: `src_next/context.bqn` (ingestion orchestration).
*   **Execution Flow**:
    1.  `LoadPostingSourceSnapshot` once.
    2.  `BuildRowEvidenceFromSnapshot`:
        *   Splits admitted rows into fields.
        *   Resolves currency metadata (no tag → JPY, currency=JPY → JPY, currency=ILS → ILS, others/duplicates → fail closed).
        *   Invokes `exact_decimal.Parse` to parse the amount text.
        *   Fails closed immediately on any row-level syntax error, duplicate metadata token, unsupported currency, or out-of-range parsed coefficient.
        *   Returns a list of structured row evidence records carrying resolved currency and parsed exact-decimal fields.
    3.  `ResolveArithmeticCurrencyProof` consumes this pre-built row evidence list (rather than re-splitting the snapshot lines).
*   **Boundary Constraints**:
    *   **B1 row evidence != projection posting rows**: The evidence is internal and does not replace or modify the final projection posting rows.
    *   **B1 must not admit explicit currency rows or implicit JPY decimal rows (canonical scale > 0) through the proof gate**: Since the proof carrier is not extended and the basis `resolved_single_currency` is not introduced until Slice B3, `ResolveArithmeticCurrencyProof` must continue to accept only legacy JPY snapshots (where all rows lack explicit currency metadata, mapping to `legacy_compatibility`) or empty snapshots (`empty_source_compatibility`) AND every participating row has parsed canonical amount scale = 0. If any row contains explicit currency metadata (e.g. `currency=JPY` or `currency=ILS`) or has parsed canonical scale > 0 (e.g. `12.34` without `currency=`), the proof gate must fail closed. `legacy_compatibility` must not be reused for explicit currency rows or implicit decimal JPY rows, as normalization is not integrated yet.
    *   `delta` in final projection posting rows remains the parsed JPY integer (with scale 0).
*   **Exit Evidence**:
    *   Valid legacy JPY integers (e.g. `1200`) parse to scale 0 and resolve to JPY.
    *   Valid explicit JPY decimals (e.g. `12.34 currency=JPY`) parse to scale 2 and resolve to JPY in internal row evidence.
    *   Valid explicit ILS decimals (e.g. `42.50 currency=ILS`) parse to scale 1 and resolve to ILS in internal row evidence.
    *   Context load fails closed on any snapshot containing explicit JPY rows, explicit ILS rows, implicit JPY decimal rows with canonical scale > 0, or mixed rows, because the proof resolver remains strictly JPY-legacy-only during B1.
    *   Focused tests verify row currency resolution and amount parsing fail closed on duplicate metadata, unsupported currency, invalid syntax, and parsed range failures.

### Slice B2: Snapshot Arithmetic Evidence

*   **Description**: Implements the snapshot-wide arithmetic verification logic in a pure helper function. Aggregates row evidence, selects the snapshot-wide `amount_scale`, and normalizes coefficients.
*   **Prerequisites**: Slice B1.
*   **Ownership**: `src_next/currency_arithmetic.bqn` (dedicated pure snapshot arithmetic owner), orchestrated by `src_next/context.bqn`. The completed ownership recheck is [`CURRENCY_STAGE2_B2_ARITHMETIC_OWNERSHIP_RECHECK-2026-07-11.md`](archive/completed-plans/CURRENCY_STAGE2_B2_ARITHMETIC_OWNERSHIP_RECHECK-2026-07-11.md).
*   **Execution Flow**:
    *   Aggregates the row evidence records from Slice B1.
    *   Requires exactly one resolved currency domain across all rows and fails closed on mixed domains.
    *   Selects `amount_scale` as the maximum canonical row scale.
    *   Exact-normalizes coefficients to `amount_scale`.
    *   Fails closed if any normalized coefficient overflows the exact integer range.
    *   Returns an internal arithmetic evidence structure.
*   **Boundary Constraints**:
    *   No proof carrier extension.
    *   No projection row `delta` changes.
    *   No ILS projection admission.
    *   Full projection admission for scale > 0 rows remains closed until B3.
*   **Exit Evidence**:
    *   Mixed JPY/ILS row evidence fails closed.
    *   Normalized coefficient range overflow fails closed.
    *   Single-currency JPY and ILS evidence returns the correct `amount_scale` and normalized coefficients in input order.

### Slice B3: Proof and JPY-only Posting Integration

*   **Description**: Integrates snapshot arithmetic evidence into the main context proof carrier and projection posting rows. B3 is the first slice that integrates the selected proof basis and normalization into the main projection path, permitting checked scale > 0 JPY posting admission.
*   **Prerequisites**: Slice B2.
*   **Ownership**: `src_next/context.bqn` (context building orchestration) and `src_next/projection.bqn` (proof authorization JPY-only constraint).
*   **Execution Flow**:
    *   Extends `arithmetic_currency_proof` to `{state, domain, basis, amount_scale, message}`.
    *   Supports `resolved_single_currency` proof basis.
    *   Uses signed normalized coefficients for final projection row `delta` values.
*   **Boundary Constraints**:
    *   Projection authorization remains JPY-only. Proven ILS remains closed until Slice C.
*   **Exit Evidence**:
    *   Legacy integer-only JPY remains scale 0 with unchanged posting deltas.
    *   Explicit and implicit decimal JPY use the maximum canonical scale and exact normalized signed posting deltas.
    *   Aggregate totals remain exact and balanced.
    *   ILS proof resolves internally with the correct scale but context loading fails closed at projection authorization.
    *   Fixture tests confirm normalized JPY postings and exact TBDS movements.

### Slice C: Checked ILS Posting Path

*   **Description**: Opens the projection authorization gate to permit proven `ILS` domain proofs. Downstream cube and TBDS receive normalized signed integer deltas under the same-snapshot invariant.
*   **Prerequisites**: Slice B3, now post-implementation verified.
*   **Ownership**: `src_next/projection.bqn` (proof authorizer logic).
*   **Inputs**: Snapshot proof and normalized rows.
*   **Outputs**: Admitted ILS projection rows in cube/TBDS.
*   **Exit Evidence**:
    *   An all-ILS fixture loads and runs successfully through context, cube, and TBDS with exact balances.
    *   Mixed JPY/ILS still fails closed.
    *   JPY continues to work exactly as before.
*   **Still excluded**:
    *   FX, conversion, valuation, base currency, display precision, rounding policy, mixed-currency aggregation, currency axis, report widening, and JSON widening.

---

## Responsibility Table

| Feature / Invariant | Introduced in Slice | Owner | Input | Output / Evidence |
|---|---|---|---|---|
| Row currency resolution | **Slice B1** | `context.bqn` | Raw metadata fields | Row evidence resolved currency |
| Row exact decimal parsing | **Slice B1** | `exact_decimal.bqn` (parsing) / `context.bqn` (orchestration) | Raw amount text | Row evidence parsed amount |
| Row-level exact range check | **Slice B1** | `exact_decimal.bqn` (diagnostic) / `context.bqn` (orchestration) | Parsed coefficient | Fail closed on parsed overflow |
| Single domain constraint | **Slice B2** | `currency_arithmetic.bqn` | Pre-built B1 row evidence currencies | Fail closed if mixed domains |
| Snapshot-wide `amount_scale` | **Slice B2** | `currency_arithmetic.bqn` | Pre-built B1 row evidence scales | Snapshot arithmetic scale |
| Coefficient normalization | **Slice B2** | `currency_arithmetic.bqn` | Pre-built B1 row evidence coefficients | Normalized coefficients |
| Normalized range check | **Slice B2** | `currency_arithmetic.bqn` | Normalized coefficients | Fail closed on normalized overflow |
| Extended proof carrier | **Slice B3** | `context.bqn` | Arithmetic evidence | `arithmetic_currency_proof` |
| Normalized posting deltas | **Slice B3** | `context.bqn` | Normalized coefficients | Projection posting row `delta` |
| ILS projection admission | **Slice C** | `projection.bqn` | Admitted proof & rows | Admitted ILS posting rows |

---

## Snapshot Invariant Preservation

The one-shared-snapshot invariant is preserved across the split as follows:
1.  **Ingestion**: `LoadPostingSourceSnapshot` is called once, loading `journal.tsv`, `plan.tsv`, and `budget_alloc.tsv` into memory.
2.  **Row Evidence (B1)**: All rows in the snapshot are parsed and validated in place by `BuildRowEvidenceFromSnapshot`. No files are re-read.
3.  **Arithmetic & Proof Generation (B2/B3)**: `context.bqn` passes the in-memory B1 row evidence directly to pure `currency_arithmetic.bqn`; the arithmetic owner does not read files or rebuild evidence. `context.bqn` consumes the same evidence and arithmetic result for final proof generation.
4.  **Authorization (B3/C)**:
    *   **B3**: The proof and normalized rows come from the same in-memory evidence, while projection authorization remains JPY-only.
    *   **C**: Widen authorization to proven ILS without source re-read, preserving the same-snapshot invariant.

---

## Exact-Decimal Ownership Preservation

The pure exact-decimal grammar, canonicalization, and coefficient exactness diagnostics are owned exclusively by `src_next/exact_decimal.bqn`. `src_next/context.bqn` orchestrates and consumes `exact_decimal.Parse` as a black box and does not reimplement parser or exact-range validation logic.

---

## Rejected Alternatives

*   **Alternative 1: Original single Slice B bundle**
    *   *Why rejected*: Combined too many changes. Row metadata parsing, amount parsing, domain aggregation, scale selection, normalization, and proof extension would be implemented all at once, making verification and rollback harder.
*   **Alternative 2: Separating B1 into B1a and B1b**
    *   *Why rejected*: Amount parsing and currency resolution are coherent row-level ingestion operations over the same source row. Separating them would create unnecessary temporary schemas.
*   **Alternative 3: Combining normalization and integration in B2**
    *   *Why rejected*: B2 would mix pure snapshot arithmetic with proof and projection integration. The B2/B3 split allows arithmetic to be verified independently before changing the checked JPY projection path.

---

## Next Runtime Slice Only

After B3 post-implementation verification, the next authorized runtime slice is:

```text
Currency Stage 2 Slice C: Checked ILS Posting Path
```

Its owner is `src_next/projection.bqn`. The slice widens only the existing checked proof authorization to proven ILS and proves an all-ILS path through context, cube, and TBDS while preserving JPY behavior and mixed-domain failure. It does not implement FX, conversion, valuation, base currency, display precision, rounding policy, mixed-currency aggregation, a currency axis, report changes, or JSON widening.
