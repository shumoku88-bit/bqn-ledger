# Exact arithmetic review closeout — 2026-08-11

## Final state

- `src/ledger/exact_decimal.bqn`: PR #660, squash-merged main `c75fa0c65118ba78e7f4cae9ec62091e3af60a62`
- `src/ledger/exact_scale.bqn`: PR #661, squash-merged main `9091cc860a9c29893fd50350d9c95a54b033ed7f`
- merged-main CI for #661: #2669 SUCCESS
- next normal Phase 2 owner: `src/ledger/facts.bqn`

Both owners were reread from merged `main` before this closeout.

## The useful contrast

The two exact-arithmetic owners did not receive the same treatment.

### Exact decimal: recognize an existing array kernel

`exact_decimal.bqn` already expresses source-decimal meaning as character-array structure:

```text
decimal text
  -> decimal-point prefix Scan
  -> integer/fraction masks
  -> prefix/suffix zero-run Scan
  -> canonical coefficient text + scale
  -> runtime conversion
  -> identical integer-text round-trip admission
```

The review therefore retained the algorithm, strengthened canonicalization/exact-range laws, removed one dead private binding, and replaced a stale migration-stage comment with the permanent owner responsibility.

### Exact scale: expose a hidden prefix relation

`exact_scale.bqn` had a different shape. `Sum` carried `state`, `code`, and `total` through a coefficient loop even though the semantic object was the sequence of source-order prefix totals.

The retained implementation is now:

```text
coefficient axis
  -> prepend zero
  -> prefix `+` Scan
  -> previous / candidate / input aligned cells
  -> reversible-addition mask
  -> all exact ? final prefix : fail closed
```

This preserves the existing source-order exactness contract. A later cancellation does not authorize an earlier inexact intermediate addition.

`Normalize` remains staged scalar control because scale admission, power-of-ten text construction, exact-decimal re-admission, and sign restoration are real ordered boundaries rather than a hidden many-cell relation.

## Review lesson

The policy is not “replace loops with glyphs.”

A better test is:

```text
What semantic axis or relation is the code carrying?
```

If the state is merely a prefix relation, Scan may expose it directly. If the current code already names the meaningful character axes, leave it alone. If control represents genuine ordered validation, preserve the staging.

This contrast is now part of the repository-resident review evidence rather than an undocumented style preference.