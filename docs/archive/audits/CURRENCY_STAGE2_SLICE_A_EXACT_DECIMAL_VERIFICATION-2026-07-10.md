# Currency Stage 2 Slice A Exact-Decimal Verification — 2026-07-10

Status: audit snapshot
Owner: config
Canonical: no; current contract remains `docs/CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_EXACT_DECIMAL_IMPLEMENTATION_PLAN.md`
Exit: keep as point-in-time evidence; any Slice B runtime work requires separate explicit routing

## Purpose

Verify that the merged Currency Stage 2 Slice A exact-decimal kernel matches the selected implementation plan before later snapshot/domain arithmetic work begins.

Review lens:

```text
safety claim
-> current runtime owner
-> executable or structural evidence
```

This audit is docs-only. It does not authorize runtime changes by itself.

## Scope

Reviewed:

- `docs/CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_EXACT_DECIMAL_IMPLEMENTATION_PLAN.md`
- `src_next/exact_decimal.bqn`
- `tests/test_src_next_exact_decimal.bqn`
- `src_next/context.bqn`
- `src_next/projection.bqn`
- merged PR #143 final scope and CI evidence

Out of scope:

- Slice B implementation
- row currency resolver changes
- snapshot-wide `amount_scale`
- normalized coefficients
- `arithmetic_currency_proof` extension
- `currency=ILS` projection admission
- source TSV changes
- metadata schema changes
- editor changes
- cube / TBDS changes
- report / JSON changes
- mixed-currency operation
- FX / conversion / valuation

## Verification result

Overall assessment:

```text
Slice A selected claims
=
aligned with current runtime owner and focused evidence
```

Material plan/runtime mismatch found:

```text
none
```

Important boundary preserved:

```text
Slice A exact coefficient conversion evidence
!=
Slice B snapshot normalization evidence
```

The current kernel proves only its selected parse/canonicalization/exact-coefficient boundary. It does not prove that a later snapshot-wide normalized coefficient remains exact.

## Claim-to-evidence table

| Contract claim | Current runtime owner | Current evidence | Assessment |
|---|---|---|---|
| accept only `digits+` or `digits+ "." digits+` | `exact_decimal.Parse` | valid cases plus invalid matrix | aligned |
| do not parse decimal source text directly as a generic decimal Number | `ParseValid` builds canonical digit-only coefficient text before `ConvertExactInteger`; `TryInteger` receives coefficient text | current call structure; decimal/canonicalization unit cases | aligned |
| return canonical coefficient + scale | `ParseValid` + `SuccessResult` | `1200`, `42.50`, `0.05`, `00042.50`, `0.000`, `0000.000`, `42.5000` | aligned |
| remove leading coefficient zeros without changing quantity | `TrimLeadingZeros` | `00042.50`, `0000.000` | aligned |
| remove trailing fractional zeros for arithmetic canonicalization | `TrimTrailingZeros` | `42.50`, `42.5000`, `0.000` | aligned |
| preserve source spelling for diagnostics | `Failure` / `SuccessResult` `source_text` | both success and failure assertions | aligned |
| invalid syntax fails visibly rather than becoming zero | `InvalidSyntax` -> `Failure` | failure helper asserts empty coefficient/scale and explicit state/message | aligned |
| non-exact coefficient conversion fails closed | `ConvertExactInteger` round-trip gate + `OutOfRangeResult` | `9007199254740993` exact-range case | aligned for current coefficient conversion path |
| exact-range boundary is implementation-owned rather than a hardcoded policy limit | round-trip equality against current runtime formatting | executable boundary case, no fixed numeric max constant | aligned |
| Slice A does not choose snapshot-wide `amount_scale` | no such owner in `exact_decimal.bqn` | current module shape | aligned scope boundary |
| Slice A does not extend arithmetic proof carrier | `context.ProofProven` still carries state/domain/basis/message only | current context shape | aligned scope boundary |
| Slice A does not admit ILS projection | context still marks any explicit `currency=` unsupported; projection still authorizes proven JPY only | current context/projection gates | aligned scope boundary |

## Detailed findings

### 1. Grammar claim is executable

The selected grammar is:

```text
digits+
```

or:

```text
digits+ "." digits+
```

Current `Parse` checks:

- non-empty input;
- all characters are digits or dot;
- zero dots, or exactly one dot;
- the dot is neither first nor last.

Focused negative evidence includes:

```text
empty
+1
-1
.5
5.
1e3
1E3
1,000
42 50
1.2.3
```

Assessment:

```text
aligned
```

### 2. Decimal source text is not directly admitted through generic numeric parsing

Current flow is:

```text
source text
-> validate selected grammar
-> split integer/fractional digit regions
-> remove trailing fractional zeros
-> concatenate digit-only coefficient text
-> remove leading coefficient zeros
-> convert coefficient text
```

`•BQN` is used inside `TryInteger`, but the current caller passes the canonical digit-only `coefficientText`, not the original decimal source string.

Therefore the implemented claim is narrower and safer than:

```text
•BQN "42.50"
```

Assessment:

```text
aligned
```

### 3. Canonical coefficient + scale examples match the plan

Current executable evidence includes:

```text
1200
  -> coefficient 1200
  -> scale 0

42.50
  -> coefficient 425
  -> scale 1

0.05
  -> coefficient 5
  -> scale 2

00042.50
  -> coefficient 425
  -> scale 1

0.000
  -> coefficient 0
  -> scale 0
```

Additional cases cover:

```text
0000.000
42.5000
```

Assessment:

```text
aligned
```

### 4. Failure states do not become coefficient zero

Current failure carrier returns:

```text
state
coefficient = empty
scale = empty
source_text
message
```

The focused test helper asserts empty coefficient and scale for every syntax failure and for the exact-range failure case.

This distinguishes:

```text
valid zero amount
```

from:

```text
invalid or non-exact amount
```

Assessment:

```text
aligned
```

### 5. Exact coefficient conversion has executable fail-closed evidence

Current conversion gate requires:

```text
canonical coefficient text
=
•Fmt converted runtime value
```

The focused boundary case:

```text
9007199254740993
```

must return:

```text
state = out_of_exact_range
message = amount_out_of_exact_range
coefficient = empty
scale = empty
```

This is implementation-owned evidence for the current runtime path. The audit does not turn that example into a repository-wide fixed maximum.

Assessment:

```text
aligned for Slice A coefficient conversion
```

Preserve:

```text
coefficient conversion exactness
!=
future normalized coefficient exactness
```

The latter belongs to later snapshot arithmetic work.

### 6. ILS admission remains closed

Current `context.ResolveArithmeticCurrencyProof` still treats any explicit `currency=` metadata as unsupported in the minimal runtime path.

Current `projection.AuthorizeArithmeticCurrencyProof` still requires:

```text
state = proven
domain = JPY
basis in {
  legacy_compatibility,
  empty_source_compatibility
}
```

Therefore the merged exact-decimal parser does not create a side door into ILS projection.

Assessment:

```text
aligned scope boundary
```

### 7. Slice B carriers are not present yet

Current exact-decimal kernel does not own:

- row currency identity resolution;
- exactly-one-domain aggregation;
- snapshot-wide `amount_scale` selection;
- normalized coefficients;
- `arithmetic_currency_proof.amount_scale`.

Current context proof carrier still has:

```text
state
domain
basis
message
```

Assessment:

```text
aligned scope boundary
```

## CI / execution evidence

PR #143 reached a final normal GitHub Actions green run after one BQN syntax correction.

Final normal workflow evidence recorded in the PR:

```text
Run check.sh -> success
Coverage     -> success
```

The earlier red run was caused by an invalid multi-line parenthesized `⎊` expression, not by an arithmetic-contract mismatch. The fix preserved the selected exact-decimal semantics.

## Next routing decision

Do not automatically execute the full existing Slice B bundle as one runtime PR.

Reason:

```text
Slice B currently groups:
  row currency resolver
  exact decimal row parse
  exactly-one-domain proof
  amount_scale selection
  normalized coefficients
  proof carrier extension
  focused fixture evidence
```

That is broader than the repository's preferred one-purpose finite slice shape.

Selected next finite slice:

```text
Currency Stage 2 Slice B execution split
```

Docs-only goal:

- preserve the semantics already selected by the exact-decimal implementation plan;
- divide Slice B into the smallest executable sub-slices with explicit owner and exit evidence;
- preserve one shared in-memory posting-source snapshot;
- keep ILS projection authorization closed;
- do not implement runtime in the split-decision PR.

Candidate split to evaluate, not yet authorized as runtime:

```text
B1 shared-snapshot row evidence
  -> resolve row currency state
  -> parse amount with exact_decimal.Parse
  -> preserve per-row source evidence
  -> no domain aggregation
  -> no amount_scale
  -> no projection admission

B2 snapshot arithmetic proof
  -> require exactly one resolved domain
  -> select amount_scale
  -> exact-normalize coefficients
  -> extend proof carrier
  -> focused fixture evidence
  -> still no ILS projection admission
```

The next docs-only slice must confirm or replace this split before implementation.

## Closure

```text
Slice A post-implementation verification -> complete
selected grammar -> aligned
canonical coefficient + scale -> aligned
visible invalid syntax -> aligned
exact coefficient range failure -> aligned
failure becomes zero -> no
ILS projection admission -> still closed
proof carrier extension -> not implemented
snapshot amount_scale / normalization -> not implemented
material plan/runtime mismatch -> none
next finite slice -> docs-only Slice B execution split
```

This audit is evidence, not a runtime backlog or automatic authorization for later slices.
