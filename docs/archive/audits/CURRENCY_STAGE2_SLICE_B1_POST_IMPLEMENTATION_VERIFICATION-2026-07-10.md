# Currency Stage 2 Slice B1 Post-implementation Verification — 2026-07-10

Status: audit snapshot
Owner: config
Canonical: no; current plan: `docs/CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md`
Exit: keep as point-in-time evidence; later currency work follows the current split decision and `TODO.md`, not this audit

## 1. Status, date, and scope

Date: 2026-07-10

Reviewed merge: PR #146, merge commit `f3c5f6c30028386ea220899c2b4c9e9946219031`.

Overall result:

```text
Currency Stage 2 Slice B1 selected claims -> verified
material unresolved plan/runtime mismatch -> none
next finite currency route -> Slice B2: Snapshot Arithmetic Evidence
```

This is a docs-only post-implementation verification. It maps selected B1 claims to current runtime owners and executable evidence; merge state, CI success, and a green aggregate check are supporting facts rather than substitutes for that mapping.

Reviewed owners and evidence include:

- `docs/CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md`
- `docs/CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_EXACT_DECIMAL_IMPLEMENTATION_PLAN.md`
- `src_next/context.bqn`
- `src_next/exact_decimal.bqn`
- `src_next/projection.bqn`
- `tests/test_src_next_currency_domain_proof.bqn`
- `tests/test_src_next_account_key.bqn`
- `checks/check-src-next-currency-domain-proof.sh`
- PR #146 final changed files, three commits, final body, and final successful `check` run

## 2. Reviewed selected claims, current owners, and executable evidence

| # | Selected claim | Current runtime owner | Executable / structural evidence | Status |
|---|---|---|---|---|
| 1 | One shared posting-source snapshot | `context.LoadPostingSourceSnapshot`, `BuildAuthorizedRowsFromSnapshot`, `BuildContext` | `check-src-next-currency-domain-proof.sh` mutates the file after loading and still projects the loaded amount; its inconsistent-snapshot case proves `snapshot.sources` is the canonical input; the old independently supplied-proof API shape fails | **verified** |
| 2 | Row evidence exists before proof resolution | `context.BuildRowEvidenceFromSnapshot`; `ResolveArithmeticCurrencyProof` accepts evidence only | Unit helper `ResolveProof` explicitly builds evidence then resolves proof; `BuildAuthorizedRowsFromSnapshot` has the same call graph; current resolver does not split fields, parse amounts, or resolve metadata | **verified** |
| 3 | `exact_decimal` owns exact parsing | `exact_decimal.Parse`; `context` only orchestrates its result | B1 row-evidence cases assert canonical coefficient/scale and parser diagnostics; Slice A parser unit evidence remains the grammar/range owner; no decimal parser is duplicated in `context.bqn` | **verified** |
| 4 | Currency metadata provenance is preserved | `context.BuildRowEvidenceForLine` | Unit cases distinguish untagged JPY / `legacy_compatibility`, explicit JPY / `explicit`, and explicit ILS / `explicit`; duplicate and unsupported metadata become row `error` | **verified** |
| 5 | Invalid row evidence fails closed | Row `state` in `BuildRowEvidenceForLine`; `has_error` and `bad_mask` in `ResolveArithmeticCurrencyProof`; projection `RequireArithmeticCurrencyProof` | Tagged and untagged invalid syntax/range cases, duplicate metadata, unsupported currency, `unsupported_row_evidence` basis assertions, and the invalid-posting context failure check | **verified** |
| 6 | B1 projection admission remains narrow | `ResolveArithmeticCurrencyProof` plus `projection.AuthorizeArithmeticCurrencyProof` | Legacy untagged scale-0 JPY and empty-source regressions are admitted; explicit JPY, explicit ILS, and untagged scale > 0 JPY cases are rejected | **verified** |
| 7 | No B2 leakage | Current `context` row evidence and four-field proof carrier | Tree search and owner inspection find no snapshot `amount_scale`, domain aggregation, coefficient normalization, normalized-overflow stage, or B2 arithmetic evidence carrier | **verified** |
| 8 | No B3 leakage | `context.ProofProven`, projection-row construction, projection authorizer | Proof remains `{state, domain, basis, message}`; no `resolved_single_currency`; posting delta remains the parsed scale-0 integer; decimal JPY is closed | **verified** |
| 9 | No Slice C leakage | `projection.AuthorizeArithmeticCurrencyProof` | Authorization still requires proven `JPY` and legacy/empty basis; explicit ILS fails before cube/TBDS admission | **verified** |
| 10 | No unchecked projection bypass | Private `context.BuildProjectionRowsForEvidence`; checked exported context builders | The helper is absent from the module export namespace; `BuildAuthorizedRowsFromSnapshot` requires proof before invoking it; compatibility exports route through the checked builder; projection exports no equivalent row-building helper; bypass-shape regression checks reject old/forged APIs | **verified** |

No claim is partially verified, mismatched, or unevidenced at this snapshot.

## 3. Current runtime flow and one-snapshot finding

The current normal flow is:

```text
BuildContext
  -> LoadPostingSourceSnapshot once
  -> BuildAuthorizedRowsFromSnapshot(snapshot, ...)
       -> BuildRowEvidenceFromSnapshot(snapshot)
       -> ResolveArithmeticCurrencyProof(evidence)
       -> projection.RequireArithmeticCurrencyProof(proof)
       -> private BuildProjectionRowsForEvidence over that evidence
  -> BuildPeriodView(rows, ...)
```

`BuildRowsForFile`, `BuildRowsForFileOptional`, `BuildAllRows`, and `BuildAllRowsFromSnapshot` are compatibility paths, but each routes through `BuildAuthorizedRowsFromSnapshot`; none accepts an independently supplied proof. No source read occurs between evidence construction, proof resolution, authorization, and row projection.

The same-snapshot shell check is stronger than a call-count comment: it loads a snapshot, mutates the file on disk, then confirms authorized projection still uses amount `100` from the loaded snapshot rather than re-reading `999`. A second case confirms an extra legacy-looking `snapshot.journal` field cannot displace canonical `snapshot.sources`.

Assessment: **verified**.

## 4. Pre-built evidence and exact-decimal ownership

`BuildRowEvidenceFromSnapshot` alone splits snapshot lines with `loader.SplitTsvKeepEmpty`, resolves `currency=` metadata, and calls `dec.Parse`. Its evidence records carry source location, original fields, resolved currency, provenance, parser result, row state, and message.

`ResolveArithmeticCurrencyProof` receives the evidence list. It contains no TSV splitting, amount-text parsing, `exact_decimal.Parse` call, or metadata scan. `BuildAuthorizedRowsFromSnapshot` constructs evidence before calling it.

`src_next/exact_decimal.bqn` remains the sole owner of:

- accepted `digits+` / `digits+ "." digits+` grammar;
- canonical coefficient and scale;
- source spelling preservation;
- `invalid_decimal_syntax` and `amount_out_of_exact_range` diagnostics.

`context.bqn` consumes `parsed.state`, `parsed.coefficient`, `parsed.scale`, and `parsed.message`; it does not duplicate the parser.

Assessment: **verified**.

## 5. Provenance, row failures, and narrow B1 admission

### Provenance

| Input metadata | Resolved currency | Provenance | B1 projection result |
|---|---|---|---|
| no `currency=` | JPY | `legacy_compatibility` | admitted only when row state is `ok` and canonical scale is 0 |
| `currency=JPY` | JPY | `explicit` | closed |
| `currency=ILS` | ILS | `explicit` | closed |
| duplicate `currency=` | row error | `explicit` | closed |
| unsupported `currency=<value>` | row error | `explicit` | closed |

Explicit JPY is therefore not collapsed into legacy compatibility.

### Invalid evidence

The proof resolver's positive legacy branch is reachable only when all three snapshot predicates are false:

```text
has_error
has_explicit
has_scale
```

Accordingly, a row with `state != ok` cannot produce a proven `legacy_compatibility` proof. Focused regressions cover:

- untagged invalid syntax -> `unsupported_row_evidence` and `invalid_decimal_syntax` diagnostic;
- tagged invalid syntax -> unsupported proof preserving parser diagnostic;
- untagged parsed coefficient out of range -> `unsupported_row_evidence` and `amount_out_of_exact_range`;
- tagged parsed coefficient out of range -> unsupported proof preserving range diagnostic;
- duplicate metadata -> row error and unsupported proof;
- unsupported currency -> row error and unsupported proof.

`checks/check-src-next-currency-domain-proof.sh` additionally confirms `BuildContext` fails for the existing invalid-posting fixture.

### Admission boundary

The only admitted non-empty B1 snapshot shape is:

```text
every participating row has state = ok
AND every participating row has provenance = legacy_compatibility
AND every participating row has canonical parsed scale = 0
```

Executable evidence confirms:

- legacy untagged JPY integer: admitted;
- explicit JPY integer or decimal: closed;
- explicit ILS decimal: closed;
- implicit untagged JPY decimal with canonical scale > 0: closed.

Assessment: **verified**.

## 6. Material mismatch findings

Material unresolved plan/runtime mismatch:

```text
none
```

One non-material evidence-location difference exists: the split decision names `tests/test_src_next_context.bqn` as the anticipated focused unit-test location, while merged B1 evidence is owned by `tests/test_src_next_currency_domain_proof.bqn` and the currency-domain shell check. The selected behavior and executable coverage are present, so this is not a runtime or safety mismatch.

The final PR's successful GitHub Actions `check` run and this verification's local `tools/check.sh` result support, but do not independently establish, the claim findings above.

## 7. Review-discovered corrections and implementation learning

### A. Fail-closed row-error hole

Initial mismatch:

- the first B1 implementation gated on explicit provenance and scale > 0 but not row error state itself;
- untagged invalid syntax or out-of-range evidence has legacy provenance and empty parser scale, so it could avoid both predicates and risk a proven `legacy_compatibility` result.

Why initial green evidence was insufficient:

- tagged parser-error cases exercised the explicit-provenance rejection path;
- they did not prove that untagged parser errors independently close the proof gate.

Final prevention:

- `ResolveArithmeticCurrencyProof` includes row `state != ok` in both the snapshot rejection predicate and first-bad-row mask;
- focused tagged and untagged syntax/range regressions assert unsupported proof state, stable `unsupported_row_evidence` basis for untagged failures, and preserved parser diagnostics;
- the shell check confirms invalid source rows fail at `BuildContext`.

Reusable learning:

```text
when a proof's positive branch is defined by the absence of disqualifiers,
executable evidence must cover each disqualifier independently,
including errors whose other fields are empty or compatibility-valued
```

This is justified review guidance, not authorization for a new lint, registry, CI gate, checklist, form, or telemetry.

### B. Unchecked projection bypass

Temporary mismatch:

- correction commit `a4adf9c` exported `BuildProjectionRowsForEvidence`;
- `tests/test_src_next_account_key.bqn` then used it directly, constructing final rows without proof authorization.

Why green tests were insufficient:

- direct helper tests could validate row shape while bypassing the safety property that final posting rows require proof authorization;
- passing output assertions therefore did not prove the stronger checked-path claim.

Final prevention:

- commit `e8287f0` removed the helper from `context.bqn` exports;
- the account-key test returned to `BuildAuthorizedRowsFromSnapshot`;
- all exported current row-building compatibility paths route through that checked builder;
- the currency-domain shell check rejects old independent-proof and forged projection API shapes and scans for known direct exported projection bypass forms.

Reusable learning:

```text
safety-boundary tests should exercise the checked public path;
a private construction helper must not become an exported convenience merely to simplify a test
```

Current ownership and evidence are sufficient; no broader permanent mechanism is recommended by this audit.

## 8. Remaining boundaries and explicit non-claims

This verification does **not** claim or implement:

- B2 exactly-one-domain aggregation;
- snapshot-wide `amount_scale` selection;
- coefficient normalization;
- normalized-coefficient overflow handling;
- a B2 arithmetic evidence carrier;
- B3 proof-carrier `amount_scale` extension;
- `resolved_single_currency` basis;
- normalized projection deltas;
- full decimal JPY posting admission;
- Slice C ILS authorization, cube admission, or TBDS admission;
- mixed-currency operation, FX, conversion, valuation, or base currency;
- report or JSON currency readiness.

B1 row currency resolution is per-row evidence. It is not B2 exactly-one-domain aggregation.

## 9. AI actual-diff self-review pilot observation

B1 qualifies as the first comparable finite AI-authored slice in the observation window owned by `docs/archive/active-plans/AI_DIFF_SELF_REVIEW_PILOT_PLAN-2026-07-10.md`:

- finite one-purpose runtime slice: yes;
- AI-authored slice after the pilot Execution rule: yes;
- PR opened at `2026-07-10T14:22:40Z`, after first commit `f3207ed` and before correction commits `a4adf9c` and `e8287f0`;
- descriptive signal: **post-first-push / post-PR scope/safety correction loops occurred**;
- actual-diff/review evidence found stronger-claim gaps that green checks had not established: the untagged row-error gate and the temporarily exported unchecked projection helper;
- `e8287f0` also corrected the bypass introduced during the first correction loop, so the two loops are distinct rather than one pre-push interception;
- no contemporaneous evidence shows a **pre-first-push / pre-PR intercepted scope-leak incident**; the issues were not caught before PR creation.

The fail-closed issue and helper export were corrections to implementation/safety-boundary claims, not unrelated changed files. Therefore this audit does not relabel them as an `escaped unrelated-diff incident`, and it does not claim the pilot rule caused or would necessarily have prevented them. The useful descriptive observation is that post-PR actual-diff review exposed claim/evidence gaps despite green checks.

Observation window status: **1 of the first 3 comparable slices observed; no final Review / Learning conclusion**.

## 10. Next routing decision

With all selected B1 claims verified and no material unresolved mismatch, the exact next finite currency route is:

```text
Currency Stage 2 Slice B2: Snapshot Arithmetic Evidence
```

B2's preserved boundary is only:

- aggregate B1 row evidence;
- require exactly one resolved currency domain;
- select snapshot-wide `amount_scale`;
- normalize coefficients exactly;
- fail closed on normalized overflow;
- return internal arithmetic evidence.

Still excluded from B2:

- no proof carrier extension;
- no projection delta change;
- no ILS projection admission;
- scale > 0 full projection admission remains closed.

This audit records routing; it does not implement B2, B3, or Slice C.
