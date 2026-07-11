# Currency Stage 2 Slice B2 Post-implementation Verification — 2026-07-11

Status: audit snapshot
Owner: currency
Canonical: no; current staged contract remains `docs/CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md`
Exit: retain as point-in-time evidence

## 1. Status, date, and scope

Date: 2026-07-11

Reviewed implementation: PR #155, implementation head `395dd1fe69eddc6c8b7f644dc92e4c8d1fcf0050`.
Merge commit: `32f6c474dd73b49d539f1beef04203d57aa56722`.
Implementation-head GitHub Actions run #587: **success**.

Overall result:

```text
B2 selected claims -> verified, with one non-material out-of-contract diagnostic imprecision
material unresolved plan/runtime mismatch -> none
next finite currency route -> Currency Stage 2 Slice B3: Proof and JPY-only Posting Integration
```

This is a docs-only claim-to-evidence audit. It inspects merged `main`, the implementation, focused tests, the existing currency check, and the full aggregate check. Green checks and the Actions result are supporting evidence, not substitutes for the claim mapping below.

## 2. Claim-to-evidence table

| # | Selected claim | Current owner / evidence | Classification |
|---|---|---|---|
| 1 | `src_next/currency_arithmetic.bqn` is the dedicated pure B2 owner and exposes exactly one main API, `Build` | Module export namespace contains only `Build`; implementation imports only `exact_decimal.bqn` and has no loader, context, projection, cube, or TBDS import. `Success`, `Failure`, and `Normalize` remain private. | **verified** |
| 2 | Input is only pre-built B1 row evidence | `context.BuildAuthorizedRowsFromSnapshot` calls `BuildRowEvidenceFromSnapshot` once, passes that exact `evidence` list to `arith.Build`, and passes the same list to `ResolveArithmeticCurrencyProof`; the arithmetic module does not split TSV, scan metadata, parse source amount text, rebuild evidence, or read files. | **verified** |
| 3 | Empty evidence preserves compatibility | `currency_arithmetic.Build ⟨⟩` returns `state=ok`, `domain=JPY`, `amount_scale=0`, empty normalized coefficients, and empty message; the direct unit test asserts all five fields. This is an explicit empty-source compatibility case, not ordinary non-empty domain aggregation. | **verified** |
| 4 | Exactly one domain is required | Direct tests prove all-JPY and all-ILS internal success and JPY+ILS failure with `mixed_currency_domains`. Domain is read only from B1 `row.currency`; no account or AccountKey lookup occurs. Invalid row evidence is rejected before aggregation. | **verified** |
| 5 | Snapshot-wide scale is the maximum canonical parsed scale | Direct JPY and ILS tests use scales `1,2,0` and assert `amount_scale=2`; reordered input asserts order-independent scale selection. Empty evidence asserts scale 0. The value is internal arithmetic evidence, not currency identity or display precision. | **verified** |
| 6 | Normalization is exact and order-preserving | `Normalize` constructs canonical integer text by appending `amount_scale-row.parsed.scale` zeroes and validates it through `exact_decimal.Parse`; no unchecked decimal multiplication is used. Tests assert `4250,5,1800` and a reordered `1800,4250,5`. Coefficients remain unsigned; signs are not introduced. | **verified** |
| 7 | Normalized overflow fails closed | The direct test derives `999999999999999` from `exact_decimal.Parse`, proves it succeeds without scale-up, then proves scale-up fails with `normalized_amount_out_of_exact_range`. Failure asserts empty domain, scale, and coefficient list; no rounded value is admitted. | **verified** |
| 8 | Invalid evidence fails closed | Tests cover `row.state != ok` and `row.parsed.state != ok`; both return `invalid_row_evidence` with empty success fields. The implementation checks both states before reading currencies or normalizing, so absent coefficient/scale is not converted to zero. | **verified** |
| 9 | Context integration preserves the existing B1 boundary | The same evidence list feeds B2 and the unchanged four-field proof resolver. `proj.RequireArithmeticCurrencyProof` remains in place before the B2 failure exit, preserving explicit-currency and B1 diagnostics; B2 success does not widen authorization. | **verified** |
| 10 | No B3 leakage | `arithmetic_currency_proof` remains `{state, domain, basis, message}`; no `amount_scale` or `resolved_single_currency` exists in the proof path. Projection rows still use `row.parsed.coefficient` only when `IsIntegerText` accepts the original amount text, and `delta` remains the legacy signed integer path. | **verified** |
| 11 | No Slice C leakage | Pure B2 can return internal ILS evidence, but `projection.AuthorizeArithmeticCurrencyProof` still permits only proven JPY with legacy/empty basis. Existing explicit ILS tests fail before projection; no cube/TBDS or authorization change exists. | **verified** |
| 12 | Existing safety and regression paths remain intact | Focused domain tests, `check-src-next-currency-domain-proof.sh`, and `tools/check.sh` pass. Legacy JPY, empty source, invalid rows, same-snapshot mutation, canonical `snapshot.sources`, old independent-proof API rejection, forged projection bypass rejection, and checked exported row-building paths remain covered. | **verified** |

## 3. Current runtime flow

```text
BuildContext
  -> LoadPostingSourceSnapshot once
  -> BuildAuthorizedRowsFromSnapshot(snapshot, ...)
       -> BuildRowEvidenceFromSnapshot(snapshot)
       -> currency_arithmetic.Build(evidence)
       -> ResolveArithmeticCurrencyProof(evidence)
       -> projection.RequireArithmeticCurrencyProof(proof)
       -> fail closed if B2 arithmetic state is error
       -> private BuildProjectionRowsForEvidence over the same evidence
  -> BuildPeriodView(rows, ...)
```

The arithmetic owner has no source-loading or projection responsibility. The existing same-snapshot shell check mutates the source after loading and confirms the loaded amount is projected; the inconsistent-snapshot case confirms `snapshot.sources` remains canonical. The arithmetic and proof paths therefore share the same in-memory B1 evidence.

## 4. B2 semantics and exclusions

The implemented and tested B2 meaning is:

- aggregate pre-built B1 row evidence;
- require one resolved domain;
- select maximum canonical row scale as `amount_scale`;
- exact-normalize unsigned coefficients in input order;
- fail closed on normalized exact-range failure;
- return internal arithmetic evidence.

Still excluded and unchanged:

- no proof-carrier extension;
- no projection `delta` change;
- no explicit or decimal JPY projection admission;
- no ILS projection admission;
- no cube/TBDS changes;
- no FX, conversion, valuation, display, JSON, or generic arithmetic framework.

## 5. Existing diagnostics and authorization

For source-derived B1 evidence, unsupported currencies and duplicate metadata become `row.state=error` in `context.bqn`, so `currency_arithmetic.Build` returns `invalid_row_evidence` before domain aggregation. Explicit JPY, explicit ILS, and implicit decimal JPY continue to receive the existing B1 proof rejection diagnostics because proof authorization remains unchanged.

The direct B2 API does not infer currency from accounts, AccountKey suffixes, or source text. It consumes the B1 evidence contract only.

## 6. Non-material out-of-contract defensive diagnostic imprecision

The module uses this defensive branch:

```text
(oneDomain ∧ supportedDomain) == false
  -> mixed_currency_domains
```

A handcrafted namespace with `state="ok"`, `parsed.state="ok"`, and `currency="USD"` therefore receives `mixed_currency_domains`, although it is a single unsupported domain. Classification: **non-material out-of-contract defensive diagnostic imprecision**.

This namespace is not regular pre-built B1 evidence:

- the B1 constructor cannot generate `state=ok` for `currency=USD`; it sets `currency_state="error"`, which produces `row.state="error"`;
- source-derived unsupported currency therefore reaches B2 as invalid evidence and is rejected before domain aggregation with `invalid_row_evidence`;
- B2 rejects the forged input fail-closed as well, with no successful domain, scale, or coefficient list;
- the selected B2 input contract is B1 row evidence, and no independent diagnostic contract for forged unknown domains was selected.

The message is narrower than ideal for this contract-invalid defensive input, but the imprecision does not affect the selected B2 runtime claims, safety behavior, same-snapshot boundary, or projection boundary. It does not block B3. This is not an active runtime correction route; any future hardening remains optional and separately authorized.

## 7. AI actual-diff pilot observation — comparable slice 2 of 3

PR #155 qualifies as the second comparable finite AI-authored slice based on current evidence:

- one implementation commit (`395dd1f`) before push;
- the PR recorded a pre-push full actual-diff self-review;
- no post-first-push correction commit is visible;
- no review thread or later scope correction is visible;
- no escaped unrelated changed file or hunk is visible;
- no contemporaneous evidence proves a scope leak was intercepted before push;
- no causation, token-savings, or statistical claim is made.

Observation window status: **2 of 3 comparable slices observed; incomplete; no final Review / Learning assessment**.

## 8. Routing decision

```text
B2 selected claims -> verified, with one non-material out-of-contract diagnostic imprecision
material unresolved plan/runtime mismatch -> none
next finite currency route -> Currency Stage 2 Slice B3: Proof and JPY-only Posting Integration
```

B3 remains unimplemented in this docs-only audit. Its canonical boundary is:

- owners: `src_next/context.bqn` and `src_next/projection.bqn`;
- extend `arithmetic_currency_proof` with `amount_scale`;
- support `resolved_single_currency`;
- use signed normalized coefficients for projection posting deltas;
- preserve JPY-only projection authorization;
- keep ILS projection closed;
- no Slice C, FX, conversion, valuation, display, or JSON widening.

This audit records evidence and routing only. It does not implement B3 or Slice C.
