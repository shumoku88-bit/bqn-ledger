# Currency registry review closeout — 2026-08-11

## Final state

- focused review: PR #655
- squash-merged main: `d6f7c93845680d09dd3452724b88ea9560d0fb81`
- merged-main CI: #2652 SUCCESS
- final owner: `src/ledger/currency_registry.bqn`
- detailed review evidence: `docs/CURRENCY_REGISTRY_REVIEW_OBSERVATION-2026-08-11.md`

The merged owner was reread on `main` after the squash merge.

## Retained changes

The review retained three small changes with different semantic reasons:

1. ignored-line classification is total for an empty physical row by putting first-character inspection behind a BQN predicate-body boundary;
2. currency-code uniqueness is expressed directly as the relation between the original code axis and its Deduplicate result:

   ```bqn
   duplicate ← (≠codes) ≠ ≠⍷codes
   ```

3. one pre-existing unused local binding was removed.

The existing ordered validation and `Policy` control was deliberately retained. A broader rewrite was tested and rejected rather than forcing scalar diagnostic precedence into an array-shaped implementation.

## Protected behavior

Focused laws now cover blank and ignored-only input, short rows, validation precedence, duplicate codes, fail-closed publication, supported and unsupported `Policy` requests, and agreement between `Policy` and `IsSupportedCurrency`.

No public registry surface, exact arithmetic, identity/provenance, source ownership, writer authority, or compatibility path changed.

## Review lesson

This owner is useful BQN evidence precisely because the final result is not maximal glyph compression:

```text
shape-sensitive source boundary -> make total
whole-axis uniqueness relation   -> use Deduplicate
ordered diagnostic decision      -> keep explicit control
```

The review therefore treats BQN-native structure as a match between semantic shape and language primitive, not as a rule that every branch or mutation must disappear.
