# Currency Stage 2 Slice B3 Post-implementation Verification — 2026-07-11

Status: audit snapshot
Owner: currency
Canonical: no; current staged contract remains `docs/CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md`
Exit: retain as point-in-time evidence

## 1. Status, date, and scope

Date: 2026-07-11

Reviewed runtime lineage:

```text
37703d9  merge PR #156 and establish the B3 base
b0097e2  feat: implement Currency Stage 2 Slice B3
12a9f4e  fix: B3 correction pass
58514f1  chore: keep Currency B3 diff focused
```

The B3 commits reached `main` directly. No B3 pull request exists, and GitHub exposes no PR-triggered Actions run for runtime head `58514f18f201c1668a57a783e1893cf05d9b5029`. Therefore this audit does not invent PR review, review-thread, or implementation-head CI evidence. The docs-only verification PR containing this record is the first PR-backed aggregate check of the B3-containing main lineage and must not merge unless the repository checks succeed.

Overall result:

```text
B3 selected claims -> verified
material unresolved plan/runtime mismatch -> none
process deviation -> B3 bypassed the intended PR review and PR-triggered CI lane
next finite currency route -> Currency Stage 2 Slice C: Checked ILS Posting Path
```

The direct-main integration is a workflow/process deviation. It is not a B3 semantic mismatch because the final runtime tree can still be inspected against the selected B3 contract.

## 2. Actual implementation diff

Compared base `37703d9ad94746e72ae9d8972e32b9ba3458b46b` with B3 head `58514f18f201c1668a57a783e1893cf05d9b5029`:

- 3 commits ahead;
- 0 commits behind;
- exactly 8 changed paths;
- runtime changes limited to `src_next/context.bqn` and `src_next/projection.bqn`;
- focused changes limited to one shell check, two tests, and one three-file fixture;
- no Slice C, source-schema, editor, account-add, workflow, JSON, report, cube, or TBDS implementation path changed;
- `AI_WORKING_FEEDBACK_LOG.md` is absent from the final B3 diff.

The final eight paths are:

```text
checks/check-src-next-currency-domain-proof.sh
fixtures/src-next-currency-b3-jpy-normalized/accounts.tsv
fixtures/src-next-currency-b3-jpy-normalized/cycle.tsv
fixtures/src-next-currency-b3-jpy-normalized/journal.tsv
src_next/context.bqn
src_next/projection.bqn
tests/test_src_next_currency_b3.bqn
tests/test_src_next_currency_domain_proof.bqn
```

## 3. Claim-to-evidence table

| # | Selected claim | Current owner / evidence | Classification |
|---|---|---|---|
| 1 | The proof carrier is `{state, domain, basis, amount_scale, message}` | `ResolveArithmeticCurrencyProof` constructs all success and failure carriers with the five selected fields. Missing scale is rejected by the projection authorizer tests. | **verified** |
| 2 | Empty source remains JPY scale 0 compatibility | Empty evidence returns `state=proven`, `domain=JPY`, `basis=empty_source_compatibility`, and `amount_scale=0`; focused tests assert an empty posting list. | **verified** |
| 3 | All implicit JPY rows use `legacy_compatibility`, including decimals | Basis selection checks whether any row provenance is non-legacy. An implicit decimal-only snapshot resolves JPY with legacy basis and normalized posting admission. | **verified** |
| 4 | Any participating explicit identity uses `resolved_single_currency` | Explicit JPY, all ILS, and missing plus explicit JPY tests resolve with `resolved_single_currency`; the domain and scale come from B2 arithmetic evidence. | **verified** |
| 5 | One integrated proof owns failure and authorization | `BuildAuthorizedRowsFromSnapshot` builds one evidence list, calls `arith.Build` once, constructs one integrated proof, and passes that proof to `RequireArithmeticCurrencyProof`. The redundant second arithmetic failure gate was removed. | **verified** |
| 6 | Projection authorization remains JPY-only and validates scale | `projection.bqn` admits only `state=proven`, `domain=JPY`, an allowed basis, and a non-negative integer scale; empty-source basis additionally requires scale 0. Missing, negative, fractional, text, malformed, forged-basis, and ILS cases are rejected. | **verified** |
| 7 | Evidence and coefficients cannot silently truncate | Runtime compares evidence length with normalized-coefficient length before indexing. Pairing is index-based over `↕ ≠ evidence`; the shell check records the guard and rejects shortest-length pairing shapes. | **verified** |
| 8 | Posting signs are introduced only at final construction | B2 normalized coefficients remain unsigned. `BuildProjectionRowsForEvidence` receives the same-index coefficient and emits debit `amount` and credit `-amount`. | **verified** |
| 9 | Original amount text no longer controls checked posting admission | Row parsing remains parser-owned, arithmetic normalization supplies the admitted coefficient, and final posting construction uses that coefficient. Source text remains available only for diagnostics and source identity. | **verified** |
| 10 | Decimal and explicit JPY reach normalized posting rows | Focused cases cover legacy integer JPY, implicit decimal JPY, explicit decimal JPY, and missing plus explicit JPY. The full fixture asserts scales, exact debit/credit deltas, and exact balance. | **verified** |
| 11 | ILS resolves internally but remains closed at projection | All-ILS evidence produces a proven ILS proof with `resolved_single_currency`; `AuthorizeArithmeticCurrencyProof` rejects it. The shell check expects context failure with the ILS-domain diagnostic. | **verified** |
| 12 | Normalized values reach downstream TBDS without semantic widening | The full-context fixture asserts exact TBDS debit, credit, and movement fields. No cube or TBDS implementation file changed in the B3 diff. | **verified** |
| 13 | Mixed domains, invalid rows, and overflow fail closed | Focused tests cover mixed JPY/ILS, invalid explicit and implicit rows, duplicate/unsupported metadata through the retained domain tests, and normalized exact-range overflow. | **verified** |
| 14 | The checked API boundary remains narrow | `BuildProjectionRowsForEvidence` remains private. Exported row builders derive proof from their own snapshot and do not accept an independently supplied proof. Existing shell evidence rejects the old cross-snapshot API and direct projection bypass shapes. | **verified** |
| 15 | Slice C and broader currency work remain absent | Projection admits no ILS, and the eight-path diff contains no FX, conversion, valuation, base-currency, display-precision, JSON, report, currency-axis, cube, or TBDS implementation changes. | **verified** |

## 4. Current runtime flow

```text
BuildContext
  -> LoadPostingSourceSnapshot once
  -> BuildAuthorizedRowsFromSnapshot(snapshot, ...)
       -> BuildRowEvidenceFromSnapshot(snapshot) once
       -> currency_arithmetic.Build(evidence) once
       -> ResolveArithmeticCurrencyProof(evidence, arithmetic evidence) once
       -> projection.RequireArithmeticCurrencyProof(proof)
       -> verify evidence/coefficient length equality
       -> pair row and normalized coefficient by index
       -> construct debit and credit posting rows
  -> BuildPeriodView(rows, ...)
```

The proof input, arithmetic input, and projection-row input originate from one in-memory snapshot and one evidence list. Compatibility wrappers load a snapshot and route through the same checked builder; they do not accept an independent proof.

## 5. Full-context normalized-JPY evidence

Fixture:

```text
fixtures/src-next-currency-b3-jpy-normalized/
```

Source amounts:

```text
1200
42.50
0.05 currency=JPY
```

Expected and asserted proof:

```text
state = proven
domain = JPY
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

The test also asserts exact TBDS movements for the asset and expense accounts. This is downstream observation of the normalized posting rows, not a cube or TBDS semantic change.

## 6. Review-discovered correction pass

The initial implementation was followed by correction commit `12a9f4eba9fe99caabf370c2e0b0675308268025`, which:

- removed stale four-field proof constructors;
- removed the redundant second arithmetic failure gate;
- converted a constant-only length assertion into structural runtime/check evidence;
- isolated malformed-proof negative cases so each test proves the field it names;
- strengthened the full fixture with proof, signed totals, and TBDS movement assertions;
- updated old proof-call shapes in the shell check.

Final focus commit `58514f18f201c1668a57a783e1893cf05d9b5029` removed the unrelated feedback-log hunk from the runtime diff. The feedback remains valid evidence and is restored separately through a docs-only change.

No material selected B3 claim remains contradicted by the final tree.

## 7. Process deviation and CI evidence boundary

The intended workflow was runtime branch -> B3 PR -> review -> merge -> post-implementation verification. Actual history was runtime commits directly on `main`.

Consequences:

- there is no B3 PR description to treat as evidence;
- there are no B3 review threads to inspect;
- there is no PR-triggered Actions run attached to runtime head;
- the final code and repository diff, rather than a PR narrative, are the primary evidence;
- the verification PR must provide the aggregate repository check before this audit is merged.

This finding does not reopen B3 runtime semantics. It is retained as workflow learning: actual-diff review and claim-to-evidence review do not replace the PR/CI lane.

## 8. AI actual-diff pilot — comparable slice 3 of 3

B3 qualifies as the third comparable finite AI-authored runtime slice.

Observed evidence:

- the initial implementation commit was not the final B3 state;
- a correction pass removed stale constructors and a redundant gate, strengthened negative evidence, and replaced a constant-only assertion with a structural guard;
- a final focus pass removed the unrelated feedback-log hunk from the runtime diff;
- the final base-to-head diff contains exactly the intended eight paths;
- no contemporaneous evidence proves that either correction happened before the first push;
- no PR boundary exists, so no claim is made about post-PR review timing;
- the removed feedback hunk is a concrete diff-scope correction, but it was retained for a separate docs-only change rather than discarded;
- no token-savings, causation, or statistical claim is supported.

Classification:

- primary observable: correction loops occurred after the initial implementation commit;
- escaped unrelated-diff incident: the feedback-log hunk entered the initial runtime commit and was removed only by the final focus commit;
- positive intercepted-before-first-push signal: not established;
- process observation: direct-main integration bypassed the intended PR/CI lane.

## 9. Pilot final Review / Learning assessment

Observation window:

```text
B1 -> correction loops exposed stronger safety-boundary gaps
B2 -> one implementation commit; no visible correction loop or escaped unrelated diff
B3 -> correction pass plus final unrelated-doc removal; no PR boundary
```

Result:

```text
selected rule -> retain
pilot plan -> complete and retire
new tooling / telemetry / permanent form -> reject
statistical or token-efficiency conclusion -> not supported
```

Learning:

1. A short actual-diff review is useful for changed-file and hunk scope. B3's final focus pass is concrete evidence that the mechanism can separate valid feedback from a one-purpose runtime diff.
2. Actual-diff review alone is not sufficient for semantic safety. B1 and B3 both needed claim-to-evidence review that inspected owners, failure paths, authorization, and test meaning rather than filenames alone.
3. The rule should remain small and human-readable in `AGENTS.md`. Expanding it into lint, telemetry, a tracker, a parser, a permanent form, or a metrics service is not justified.
4. PR and CI discipline is a separate boundary. A clean final diff does not compensate for bypassing review and PR-triggered checks.

The finite pilot is therefore closed as **completed; retain the existing small rule without expansion**.

## 10. Routing decision

```text
B3 selected claims -> verified
material unresolved plan/runtime mismatch -> none
next finite currency route -> Currency Stage 2 Slice C: Checked ILS Posting Path
```

Slice C may now be planned and implemented as one separate finite runtime slice with this narrow boundary:

- owner: `src_next/projection.bqn`;
- admit proven ILS proofs through the existing checked path;
- preserve the same normalized integer and snapshot-wide `amount_scale` model;
- prove an all-ILS fixture through context, cube, and TBDS;
- preserve JPY behavior exactly;
- preserve mixed JPY/ILS failure.

Still excluded:

- FX;
- conversion;
- valuation;
- base currency;
- display precision;
- rounding policy;
- mixed-currency aggregation;
- currency axis;
- report or JSON widening.

This audit changes documentation and routing only. It does not implement Slice C.
