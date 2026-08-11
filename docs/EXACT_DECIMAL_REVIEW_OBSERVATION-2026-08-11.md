# Exact decimal review observation — 2026-08-11

## Baseline and ownership

- repository: `shumoku88-bit/bqn-ledger`
- review base: `aeb23ba72d34b6e998971dc373be1ac9ebb2d47f`
- active owner: `src/ledger/exact_decimal.bqn`
- focused review PR: #660

`exact_decimal.bqn` is a live exactness boundary rather than migration residue. Journal admission, editor candidate/validation paths, issue admission, travel-event editors, daily-scope admission, and exact-scale normalization all depend on its `Parse` result.

Its permanent responsibility is deliberately narrow:

```text
canonical decimal magnitude text
  -> strict decimal grammar
  -> character-axis canonicalization
  -> coefficient text + scale
  -> runtime integer conversion
  -> exact round-trip admission
```

Signs remain outside this owner. Current Journal admission strips the sign before `Parse` and restores it to the admitted coefficient afterwards. This keeps decimal magnitude grammar and signed posting semantics separate.

## Historical exactness contract remains current

The kernel was introduced in PR #143 with an important boundary that remains correct:

- accept only `digits+` or `digits+ "." digits+`;
- never parse source decimal text directly as a generic decimal Number;
- canonicalize source text to coefficient text plus scale before numeric conversion;
- convert only the canonical digit-only coefficient text;
- admit the runtime value only when `•Fmt` round-trips the identical canonical integer text;
- publish syntax and exact-range failures explicitly rather than substituting zero.

This review found no reason to weaken or generalize that contract.

## The array kernel is already visible

The central production path already exposes meaningful character-array relations.

`ParseValid` classifies each character by the number of decimal points observed through that coordinate:

```bqn
dotMask ← s = dot
prefixDots ← +` dotMask
intMask ← (prefixDots = 0) ∧ (¬ dotMask)
fracMask ← (prefixDots = 1) ∧ (¬ dotMask)
intText ← intMask / s
fracText ← fracMask / s
```

The two zero-normalization owners are likewise explicit run classifications:

```bqn
zeroPrefix ← ∧` (xs = zero)
dropCount ← +´ zeroPrefix
```

and

```bqn
zeroSuffix ← ∧` ((⌽ xs) = zero)
keepCount ← (≠ xs) - +´ zeroSuffix
```

These are not procedural loops hiding an array problem. They are direct prefix/suffix Scan descriptions of the source character axis. Replacing them with generic string helpers, regex-like machinery, or denser trains would hide rather than reveal the BQN idea.

## Characterization strengthened before production changes

The focused exact-decimal laws were extended with cases that pressure the canonicalization/exactness boundary rather than merely repeating short examples:

- long leading-zero source forms still retain original `source_text` while canonicalizing to the same coefficient/scale;
- a long all-zero form canonicalizes to coefficient 0, scale 0;
- `0.0000000000000000001` demonstrates that a large decimal scale is independent from coefficient magnitude and remains exact as coefficient 1, scale 19;
- the known runtime range failure remains fail-visible after leading-zero canonicalization;
- the same range failure remains fail-visible after a syntactic fractional `.0` is removed by canonicalization.

Characterization-only CI #2662 was SUCCESS.

## Production subtraction was intentionally tiny

The review found one dead private binding:

```bqn
IsDigits ← { (0 < ≠ 𝕩) ∧ ∧´ (𝕩 ∊ digits) }
```

`Parse` already owns grammar admission through its `allowed`, `dotCount`, and shape relations; `IsDigits` was not used by this module and is not exported. It was removed rather than kept as speculative parsing vocabulary.

The top comment also still described the owner as "Currency Stage 2 Slice A". That migration label was replaced with the permanent responsibility: a pure exact-decimal source parser for canonical decimal magnitude text.

No algorithmic path changed. CI #2663 was SUCCESS after the subtraction.

## Why no broader refactor was selected

Several visible names are intentionally retained because they expose meaning rather than plumbing:

- `dotMask`, `prefixDots`, `intMask`, `fracMask` expose the character-axis partition;
- `fracCanonical`, `coefficientText`, `scale` expose the exact quantity carrier transition;
- `TryInteger` and `ConvertExactInteger` separate runtime conversion failure from exact round-trip admission;
- `InvalidSyntax`, `OutOfRangeResult`, and `SuccessResult` retain the public result alternatives.

Likewise, `OutOfRangeResult` accepts the same dispatch argument shape as `SuccessResult` even though only source text is needed for its payload. That common dispatch shape is local structural clarity, not an independent abstraction to eliminate.

A shorter implementation would not automatically be a more BQN-native one. Here the semantic axes and exactness boundary are already explicit.

## Review conclusion

The final shape is deliberately conservative:

```text
retain Scan-based source classification
retain coefficient/scale canonicalization
retain runtime round-trip exactness admission
strengthen boundary laws
remove one dead private helper
replace one stale migration label
```

This owner is useful teaching material because the review result is mostly recognition rather than transformation: the existing program already expresses the right array problem in the right place.
