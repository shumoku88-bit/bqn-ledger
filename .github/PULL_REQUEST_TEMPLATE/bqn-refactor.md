## Finite question

Can `<current procedural form>` become `<array-native form>` while preserving `<named contracts>`?

## Before

```text
<procedural stages>
```

## Array model

```text
<input cells / columns>
→ <coordinate, mask, classification, group, or selected function>
→ <output cells / columns>
```

## Change

- 

## Preserved contracts

- ordering:
- empty behavior:
- diagnostics:
- provenance:
- exact arithmetic:
- output bytes / public shape:
- evaluation behavior:

## Edge evidence

- empty:
- unknown / not found:
- nested cell:
- non-adjacent duplicate:
- invalid rank / shape:
- boundary index:
- eager versus conditional evaluation:
- exact arithmetic failure:

Use `not-applicable` where a case cannot occur in this finite slice.

## BQN refactor lenses

Review against [`docs/BQN_REFACTORING_REVIEW_GUIDE.md`](../../docs/BQN_REFACTORING_REVIEW_GUIDE.md).

- Marshall: `green / improve / blocked / not-applicable` —
- Hui: `green / improve / blocked / not-applicable` —
- Scholes: `green / improve / blocked / not-applicable` —
- Adám: `green / improve / blocked / not-applicable` —
- Aaron: `green / improve / blocked / not-applicable` —
- Iverson: `green / improve / blocked / not-applicable` —
- Whitney: `green / improve / blocked / not-applicable` —

## Ownership and scope

- changed owners:
- intentionally untouched owners:
- no new utility bag, forwarding wrapper, universal context, or fallback:
- correctness and refactoring remain separate:

## Verification

- [ ] focused test
- [ ] full `tools/check.sh`
- [ ] coverage
- [ ] current-main integration
- [ ] final bounded patch review

## Decision

`accept / revise / reject`

Reason:
