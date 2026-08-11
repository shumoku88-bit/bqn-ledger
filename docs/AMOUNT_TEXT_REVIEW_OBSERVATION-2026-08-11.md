# Exact amount text review — 2026-08-11

## Baseline

- repository: `shumoku88-bit/bqn-ledger`
- runtime review base: `945fbb11f9f0a3b7a89006110e88468a063a2a64`
- active owner: `src/ledger/amount_text.bqn`
- durable queue advanced to this owner in PR #646 after the canonical Account Journal review closeout

## Ownership

`amount_text.Format` is the shared policy-free formatter for already-admitted exact ledger values.

Input:

```text
⟨signed integer coefficient, nonnegative scale⟩
```

Output:

```text
plain exact decimal text
```

The owner intentionally does not add:

- Commodity or currency symbols;
- grouping separators;
- rounding;
- color;
- report-specific sign or presentation policy.

Adjacent exact-value owners establish the precondition that coefficient is an admitted integer and scale is nonnegative. This formatter should not duplicate that admission policy.

## Characterization

A dedicated focused test now fixes the small value algebra independently of downstream Facts/report tests:

- zero at scale 0;
- ordinary integer at scale 0;
- zero with fractional scale;
- ordinary decimal split;
- leading fractional zero padding;
- negative fractional value;
- retained trailing fractional zeros;
- scale wider than coefficient digits;
- one fractional trailing zero.

The characterization-only branch passed full repository check and coverage in CI #2599 before production change.

## Previous form

The old implementation first constructed the padded magnitude as the scale-neutral body and then conditionally replaced that body when `scale > 0`:

```text
padded
  -> body
  -> if fractional scale: split + mutate body
  -> sign + body
```

The branch is not wrong, but the value transformation itself has no stateful meaning. Scale 0 and positive scale are the same structural split; only the decimal separator has cardinality 0 or 1.

## BQN-native form

After left-padding the magnitude to at least `scale + 1` digits, one split coordinate is valid for every admitted scale:

```text
split = length(padded) - scale
```

The final character array is therefore:

```text
optional minus
  ∾ integer-side digits
  ∾ optional decimal point
  ∾ fractional-side digits
```

with the separator itself expressed as a filtered character array:

```bqn
(0<scale)/"."
```

The production expression becomes:

```bqn
((negative)/"-")∾(split↑padded)∾((0<scale)/".")∾split↓padded
```

For `scale = 0`, `split` is the full padded length, the separator array is empty, and the fractional suffix is empty. No separate control-flow path is required.

## Protected contracts

Keep unchanged:

- exact digits from the integer coefficient;
- no rounding or floating conversion;
- negative sign only for negative coefficients;
- no negative-zero spelling;
- left zero padding for scales wider than the magnitude;
- decimal point only for positive scale;
- exact retention of trailing fractional zeros;
- shared public `Format` export and all consumers.

## Qualification

- characterization-only CI #2599: SUCCESS;
- production plus dedicated laws and observation CI #2602: SUCCESS;
- while #2602 was running, docs-only PR #646 advanced main from `945fbb11f9f0a3b7a89006110e88468a063a2a64` to `b971308f84158f5891c7b774e8db3184c192b50a`;
- that intervening main commit changes only the Account Journal review closeout documentation/TODO cursor and has no runtime, test, or `amount_text` overlap;
- final PR-head CI #2603: SUCCESS after that docs-only drift;
- PR #647 squash merged as main `e78430d9709f716f2c59d98c55311be8b2c577b5`;
- merged `src/ledger/amount_text.bqn` was reread on that main and contains the intended structural split expression with no temporary debug path;
- merged-main CI #2604: SUCCESS.

## Review decision

Retain `amount_text.bqn` as the shared exact plain-text formatter. Replace only the branch-local body mutation with one structural character-array expression and retain the new dedicated boundary laws.

## Closeout

The owner is finally reviewed on main `e78430d9709f716f2c59d98c55311be8b2c577b5`. The Phase 2 queue may mark `src/ledger/amount_text.bqn` complete and advance through the subsequently reviewed Budget Journal owner.
