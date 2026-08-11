# Exact scale review observation — 2026-08-11

## Baseline and ownership

- repository: `shumoku88-bit/bqn-ledger`
- review base: `c75fa0c65118ba78e7f4cae9ec62091e3af60a62`
- active owner: `src/ledger/exact_scale.bqn`
- focused review PR: #661

`exact_scale.bqn` is a live exact-arithmetic owner. Accounting kernels and sections use it to normalize already-admitted coefficients onto one calculation scale and to sum those normalized coefficients without silently accepting an inexact runtime addition.

Its two public responsibilities are distinct:

```text
Normalize
  admitted coefficient + source scale + target scale
  -> exact power-of-ten normalization

Sum
  admitted coefficient axis in caller order
  -> checked source-order prefix additions
  -> exact total or fail closed
```

The review therefore does not assume that the two functions should have the same implementation shape.

## Characterization before production change

A dedicated `tests/test_ledger_exact_scale.bqn` was added before changing production. It protects:

- same-scale normalization;
- upward power-of-ten normalization;
- negative coefficient normalization;
- zero normalization to a large target scale;
- target-scale regression rejection;
- normalized-coefficient exact-range failure;
- empty sum = exact zero;
- ordinary positive and negative accumulation;
- exact cancellation;
- the representable `2^53` boundary;
- fail-closed behavior when a runtime addition is not reversible;
- source-order sequential exactness.

Characterization-only CI #2666 was SUCCESS.

The order law is intentional for this runtime contract. For example:

```text
2^53, 1, -1
```

fails because the second prefix addition is not exact, even though the mathematical final sum would return to `2^53`. By contrast:

```text
1, -1, 2^53
```

stays exact at every prefix and succeeds.

This review does not introduce arbitrary-precision arithmetic or reorder values to search for a representable mathematical total. Callers receive a guarantee about the actual checked source-order computation.

## The old Sum hid a prefix relation inside mutable state

The previous implementation carried three mutable scalar cells:

```bqn
state ← "ok" ⋄ code ← "" ⋄ total ← 0
```

and traversed every coefficient, conditionally computing a candidate only while state remained `ok`. For each step it checked reversibility in both directions:

```bqn
candidate ← total+value
exactAdd ← ((candidate-total)=value) ∧ ((candidate-value)=total)
```

That correctness check was valuable. The mutable control shape around it was not the semantic center.

## Sum is now an explicit prefix axis

The retained implementation prepends the additive identity and computes the complete prefix-total axis directly:

```bqn
prefixes ← +` 0∾coefficients
previous ← ¯1↓prefixes
candidates ← 1↓prefixes
```

`previous`, `candidates`, and the original `coefficients` are aligned cells describing every source-order addition. Exactness is therefore one relation over those aligned arrays:

```bqn
exactAdds ← ((candidates-previous)=coefficients) ∧ ((candidates-coefficients)=previous)
allExact ← ∧´1∾exactAdds
```

The final prefix is available because the prefixed axis is never empty:

```bqn
total ← ¯1⊑prefixes
```

Publication then depends only on `allExact`. The public success/error shapes and error code are unchanged.

Production CI #2667 was SUCCESS with the dedicated laws, full repository checks, and coverage.

## Empty input becomes ordinary structure

The prefix formulation removes an otherwise special-looking empty-sum case without adding a branch.

For no coefficients:

```text
0 ∾ coefficients
```

contains exactly the initial zero. The previous/candidate axes are empty, the exactness reduction is true through the explicit `1∾` identity, and the final prefix is zero. Empty exact sum therefore follows from the same array structure as every nonempty sum.

## Normalize deliberately remains staged scalar control

`Normalize` was reviewed separately and left unchanged.

Its semantics are not a many-cell accumulation problem:

1. validate that source and target scale are ordered nonnegative admitted scales;
2. derive one power-of-ten zero count;
3. append that many zero characters to the absolute coefficient text;
4. re-enter the exact-decimal owner;
5. restore the sign only after exact admission succeeds.

That sequence carries real validation and exactness boundaries. Recasting it as a Scan, Group, or generic arithmetic abstraction would not expose a hidden semantic axis.

## Review conclusion

The final owner makes a useful contrast:

```text
Normalize: ordered scalar exactness boundary -> keep explicit staging
Sum:       repeated source-order additions   -> expose prefix Scan axis
```

The BQN lesson is not that mutation is categorically forbidden. It is that when mutable state is merely carrying a prefix relation, Scan names the actual computation more directly and makes its aligned exactness law visible.
