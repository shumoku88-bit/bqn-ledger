# Editor Phase 6 native Journal command observation — 2026-08-17

## Status

The normal Phase 6 review has covered the native Journal command family:

- `src_edit/journal_list_cmd.bqn`
- `src_edit/journal_native_reverse_cmd.bqn`
- `src_edit/journal_native_source_check.bqn`

These owners form one useful boundary to review together:

```text
admitted Actual rows
  -> read-only selector projection
  -> inverse posting intent
  -> shell-owned append
  -> mandatory complete-source validation
```

The review does not move writer authority into the selector or validator.

## Journal List

Journal List already obtains semantic transaction rows through `src/application/editor_actual.bqn`. It does not reparse Journal syntax or own Account/Currency admission.

The remaining procedural residue was presentation-only: account keys were joined by growing a mutable string accumulator.

The reviewed implementation uses a separator Join over the projected Account relation. Debit/credit selection, exact amount reduction, source order, and the seven-field TSV contract remain unchanged.

### Commodity visibility

The prior human display ended at the numeric amount even though admitted Actual rows carry a transaction domain and the currency registry now admits multiple currencies.

That made values such as `25` ambiguous in a mixed-currency Household.

The structural TSV contract remains seven fields:

```text
number date memo from to amount display
```

Only the human `display` field now includes the admitted commodity, for example:

```text
2: 2026-07-23  Ordinary purchase  assets:cash→expenses:food  25 JPY
```

No new selector field or shell-owned currency lookup is introduced.

## Native Reverse

Native Reverse remains a read-only selector that emits exact inverse posting intent. It does not append or mutate the Journal itself.

The previous selector staged `selected` with a sentinel and mutated it in separate index/id branches.

The reviewed form makes the selection law explicit:

```text
index = 0  -> exact id/description match, exactly once
index > 0  -> one-based admitted transaction row
index < 0  -> reject
```

A negative direct index previously fell through both mutation branches and could reach later field access without a domain diagnostic. It now fails closed as an out-of-range selector. A regression fixes that behavior.

Posting inversion remains text-exact and preserves admitted posting order. The shell still owns the later reverse event construction and append protocol.

## Mandatory Native Source Check

`journal_native_source_check.bqn` remains an independent post-write validator.

It still performs its own expected-posting protocol parse and then checks the fully written Journal through complete-source admission. This independence is deliberate: the validator must not become a trivial echo of the writer candidate object.

The reviewed changes remove only incidental machinery around that safety boundary.

### Optional currency coordinate

The optional `currency=CODE` marker is now observed as a boolean coordinate. Currency and posting-tail position derive from that coordinate instead of mutating `currency` and `argIndex`.

The default remains JPY and the supported currency policy remains registry-owned.

### Expected posting relation

Expected posting arguments are mapped into records instead of accumulated into an initially empty relation.

Each record retains:

```text
account_key
amount_text
source_coefficient
source_scale
normalized_coefficient
commodity
```

The validator still rejects malformed, unsupported-precision, zero, unbalanced, or too-short expected posting protocols before candidate comparison.

### Shared exact-scale primitive

Before this review the mandatory validator normalized scales by formatting the absolute coefficient as decimal text, appending zero characters, reparsing it, and restoring the sign.

The native writer had already moved to the repository's `src/ledger/exact_scale.bqn` owner in #785.

The validator now uses the same exact arithmetic primitive:

```text
scale.Normalize ⟨source_coefficient, source_scale, calculation_scale⟩
```

This shares the arithmetic law, not candidate authority. The validator still independently parses expected protocol arguments, reads the written source, re-admits the complete Journal, and compares the admitted candidate.

A focused synthetic USD witness uses the registry-admitted two-fraction-digit policy and requires `1.20` and `-1.2` to normalize exactly to the same calculation scale.

## Safety laws deliberately retained

The mandatory validator still checks:

- canonical nonnegative candidate ordinal syntax;
- Account source admission;
- complete written Journal admission;
- exactly one appended transaction beyond the candidate ordinal;
- candidate source boundary after all prior transactions;
- exact posting Account order;
- exact normalized posting coefficients;
- posting index sequence;
- transaction commodity alignment;
- ordinary versus effective durable identity shape;
- Plan/reverse derived-transaction identity policy;
- date, description, status, layer, domain, scale, and posting count equality.

The shell still owns safe publication, snapshot/digest guards, rollback, optional broader post-checks, and generated reverse IDs.

## Tests

The existing Journal List, Journal Block Add, and Journal Reverse contracts remain active.

Additional evidence in this review:

- Journal List stays seven-column TSV and the human display includes the transaction commodity;
- a direct negative reverse index fails closed and leaves source bytes unchanged;
- the mandatory source validator accepts a synthetic USD mixed-scale candidate with `1.20` / `-1.2` through shared exact normalization while remaining read-only.

## Decision

The native Journal command family is now clearer without collapsing independent safety layers:

```text
List
  = admitted-row projection + presentation

Reverse
  = explicit selection + inverse intent

Source Check
  = independently reconstructed expectation
    + canonical complete-source observation
    + exact candidate equality
```

The next normal Phase 6 cursor is:

```text
src_edit/journal_reconstructible_identity_cleanup.bqn
```
