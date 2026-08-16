# Editor Phase 6 Journal Block Add observation — 2026-08-16

## Status

`src_edit/journal_block_add_cmd.bqn` has been reviewed under the 2026-08-16 BQN-native re-baseline.

The review does not treat every mutation or sequential guard as a defect. It separates regular input collections from the source-shape and publication boundaries that make a Journal writer safe.

## Owner shape

Journal Block Add owns one explicit native Actual append candidate. Its BQN side is responsible for:

```text
CLI values already separated by the shell
  -> typed/structural field admission
  -> Posting + metadata relations
  -> exact Posting normalization and balance law
  -> canonical Account/currency resolution
  -> candidate block rendering
  -> full proposed Journal re-admission
  -> exact candidate/source-boundary verification
  -> append protocol publication
```

The shell remains responsible for path containment, symlink rejection, target snapshot/concurrency protection, confirmation/dry-run behavior, safe-write publication, and post-write validation orchestration.

That split remains appropriate. BQN does not gain filesystem mutation authority merely to make the editor more "native".

## Regular collections changed

### Optional currency coordinate

The optional `currency=CODE` prefix previously mutated both `currency` and the next argument index. It is now one boolean coordinate:

```text
hasCurrencyMarker
  -> selected currency
  -> posting-count coordinate
```

No parser state needs to be accumulated for a single optional prefix.

### Posting arguments

The prior implementation initialized an empty `postings` collection and appended one record per argument under Each. Each input already determines exactly one Posting record or fails.

The reviewed shape is therefore:

```text
postingArgs
  -> PostingRecord¨
  -> common calculation scale
  -> NormalizePosting¨
  -> aligned Posting relation
```

Per-Posting validation order is retained inside `PostingRecord`; only the result accumulator disappears.

### Exact normalization owner

Journal Block Add also duplicated the exact-scale normalization algorithm by formatting a coefficient as text, appending zero characters, and parsing it again.

That semantic operation is already owned by `src/ledger/exact_scale.bqn`:

```text
signed coefficient × source scale × target scale
  -> exact normalized coefficient or failure
```

The editor now calls `exact_scale.Normalize` directly. `exact_decimal.Parse` remains responsible for reading the user's source amount text; `exact_scale.Normalize` owns scale conversion. The previous diagnostic text for a normalization failure is retained at the editor boundary.

The transaction balance check is intentionally unchanged in this review. Replacing that check with another reduction owner would be a separate law/diagnostic decision rather than a necessary consequence of the normalization cleanup.

### Metadata arguments

Metadata tokens have the same regular shape already established by reviewed Budget Add:

```text
metadataArgs -> MetadataRecord¨ -> source-ordered metadata relation
```

Legacy-to-native key spelling remains an aligned lookup. Duplicate, payment-value, plan-link, and identity laws remain after the relation is constructed.

No generic key/value parser is introduced. Journal and other writers may have different supported-key and failure contracts.

### Rendered block

`blockLines` is already the semantic rendering relation: header, metadata lines, Posting lines. The final text is now a pure Join of the first line and newline-prefixed continuation lines rather than a mutable string accumulator.

The transport separator remains separate because it depends on the existing source ending and is part of exact source-shape preservation.

## Complexity deliberately retained

### Complete Journal re-admission

The writer does not trust its local renderer merely because local fields passed validation. It reads and admits the existing complete Journal, constructs the exact proposed bytes, and re-admits the complete candidate before publication.

This catches interactions with the surrounding source that a detached block validator cannot prove.

### Candidate cardinality and source boundary

After re-admission, the command requires exactly one new transaction and proves that its source start lies after every prior transaction end. These checks connect semantic admission back to the physical source append boundary and remain explicit.

### Identity and provenance comparison

The parsed candidate is compared against the intended:

- date and description;
- actual layer / status marker;
- identity mode and durable event identity rules;
- metadata preservation;
- Posting count and order;
- Account keys;
- exact normalized coefficients;
- Commodity.

This is not duplicate parsing authority. The canonical admission owner parses the proposed source; the editor verifies that the admitted result is exactly the candidate it intended to write.

### Source-ending transport law

No-final-newline, one-final-newline, and existing paragraph-separator inputs intentionally have different transport prefixes but converge to the same canonical completed bytes. The source-ending logic remains local and explicit rather than being replaced by a generic text append helper.

### Shell safe-write boundary

`tools/edit-bqn` still owns:

- canonical base/path containment;
- lexical `.journal` target restriction;
- traversal and symlink rejection;
- regular-file requirement;
- pre-write snapshot token;
- BQN protocol validation;
- recheck before publication;
- dry-run/confirmation;
- safe write and mandatory native validation.

Moving those effects into this BQN command would blur, not improve, the architecture.

## Residue observed, not pulled into this owner

`docs/JOURNAL_METADATA_INVENTORY.md` currently describes the general writer metadata surface as thirteen keys, while the live Journal Block Add allowlist also includes `trip_id -> trip-id` and `payment`. This is stale documentation evidence for the later cross-cutting RESIDUE lane, not a reason to alter the writer contract during this review.

The broader `src_edit/validate.bqn` review remains pending. Journal Block Add keeps its local error-code contract until that owner is reached in the normal Phase 6 sequence.

## Decision

The reviewed owner now has the intended division:

```text
regular CLI collections
  -> BQN map / aligned relations
  -> shared exact scale owner
  -> local writer laws
  -> canonical complete-Journal admission
  -> exact candidate verification
  -> effect-free append protocol

shell
  -> filesystem safety + publication
```

No further Journal Block Add rewrite is justified in this pass.

The next normal Phase 6 cursor is:

```text
src_edit/journal_canonical_surface_apply_cmd.bqn
```
