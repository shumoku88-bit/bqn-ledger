# Journal transaction body relation review observation — 2026-08-12

## Owner and scope

`src/ledger/journal_transaction_structure.bqn` is the pure structural admission owner for one already domain-normalized Journal transaction partition.

It owns transaction grammar, metadata shape/value rules, normalized structural Posting shape, structural Account declaration references, layer/budget identity laws, fallback/durable identity, Posting side/id, and fail-closed structural Transaction publication.

Semantic exact amount/currency proof remains in `journal_single_domain_admission`.

This review focused on the transaction body axis and the semantic metadata subset.

## Characterization first

Focused laws were added before each production transformation.

### Body relation

The first characterization protects diagnostic layering and physical source order:

```text
body row-local diagnostics
  -> Account relation diagnostics
  -> aggregate transaction diagnostics
```

A mixed-invalid body proves the exact public order:

```text
metadata_colon_missing      line 8
transaction_body_not_indented line 9
posting_shape_invalid       line 10
posting_account_unknown     line 11
```

The first three arise while parsing body rows. `posting_account_unknown` is deliberately later because Account declaration membership is a relation over successfully parsed Postings.

A valid interleaved body proves that metadata and Posting rows form separate source-order axes:

```text
metadata lines 8,10
Posting  lines 9,11
```

Posting indices and ids follow admitted Posting order, not physical body-row count.

Duplicate metadata remains an aggregate transaction diagnostic at the transaction start.

Characterization-only CI #2745: SUCCESS.

### Semantic metadata relation

After body-cell production was green, additional characterization fixed the semantic metadata carriers used by downstream identity/layer laws:

- `layer`;
- `event-id`;
- `plan-id`;
- `allocation-id`;
- `execution-envelope`;
- `actual-event-id`;
- `txn-id`.

Separate valid Budget examples protect the allocation-linked and Actual-linked direct-link shapes without conflating their exclusivity rule.

Characterization CI #2747: SUCCESS.

## Body-row cells

The previous implementation walked `bodyIndices` while mutating shared:

```text
diagnostics
metadata
rawPostings
```

The reviewed form maps one domain-named local parser over the body axis:

```text
body source coordinate
  -> indentation classification
  -> metadata / Posting classification
  -> local parser
  -> { diagnostics, metadata?, posting? }
```

Then:

```text
body result cells
  -> source-order diagnostic flatten
  -> admitted metadata cells
  -> admitted Posting cells
```

This makes metadata and Posting axes explicit without introducing a generic row-parser abstraction.

Production CI #2746: SUCCESS with full `tools/check.sh` and coverage.

## Account relation diagnostics

Account membership remains a separate relation over admitted structural Postings:

```text
admitted Posting Account keys
  x declared Account keys
  -> posting_account_unknown diagnostic cells
  -> Posting-order flatten
```

It is intentionally not folded into `ParsePosting`, because text/structural Posting admission does not own declaration membership.

## Semantic metadata coordinates

The previous owner rescanned the complete metadata axis seven times through `MetaOr`.

The reviewed form classifies the semantic subset once:

```bqn
semanticKeys ← ⟨
  "layer","event-id","plan-id","allocation-id",
  "execution-envelope","actual-event-id","txn-id"
⟩
semanticCoordinates ← keys⊐semanticKeys
values ← {𝕩.value}¨metadata
semanticValues ← semanticCoordinates⊏(values∾⟨""⟩)
```

The absent coordinate is `≠keys`; the appended empty string is therefore the aligned absent cell.

This preserves the previous first-occurrence meaning when duplicate metadata exists. Duplicate metadata is still independently diagnosed before final publication.

`layer` alone applies a nonempty fallback:

```text
missing layer -> actual
```

All other semantic metadata fields retain empty-string absence.

Production CI #2748: SUCCESS with full `tools/check.sh` and coverage.

## Local dependent state retained

Several small guarded states remain intentionally.

### Metadata text parsing

`ParseMetadata` first discovers the colon boundary, then obtains key/value, then applies key-dependent value policy. Eagerly evaluating all key-specific validators would obscure the grammar and can make invalid intermediate values reachable.

### Posting integer parsing

`ParsePosting` validates digit text before converting the exact structural integer coefficient.

### Header marker

The optional `*` / `!` marker changes how the header tail is divided into status and description. This is a finite semantic branch, not traversal state.

### Fallback identity

Absent `event-id` selects the physical `stage0-line-<start>` fallback identity. This is a domain identity boundary, not incidental mutation.

### Final transaction publication

The owner continues to publish a Transaction only when the accumulated structural diagnostics are empty.

## Review conclusion

The useful subtraction was:

```text
shared body traversal accumulation
+ repeated semantic metadata rescans
```

becoming:

```text
body source axis
-> local result cells
-> explicit metadata / Posting axes
-> relation diagnostics
-> one semantic metadata coordinate vector
-> aggregate transaction laws
```

The remaining local guards represent parsing, identity, or publication dependencies and are retained.

No semantic currency authority, exact monetary evidence, Account semantic proof, identity meaning, source-line provenance, diagnostic ordering, or complete-Journal partitioning changed.
