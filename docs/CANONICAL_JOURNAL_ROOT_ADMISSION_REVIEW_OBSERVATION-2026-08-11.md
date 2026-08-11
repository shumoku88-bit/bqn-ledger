# Canonical Journal root admission review — 2026-08-11

## Baseline

- repository: `shumoku88-bit/bqn-ledger`
- review base: `79c5882a1f3996790caa001e2b65977d9588e852`
- active owner: `src/ledger/canonical_journal_root_admission.bqn`
- focused review PR: #652
- repository cursor reached this owner after #651 closed canonical Budget policy review

## Ownership and history

This is a live canonical topology gate, not legacy migration residue.

The owner originated as the canonical Actual-root topology check and was promoted in #555 to a shared canonical Journal-root owner when Plan Facts moved onto the same canonical source contract. The Actual-specific owner was removed at that point.

Its responsibility is deliberately narrow:

```text
one raw canonical Journal root
+ expected canonical Account source basename
  -> include paths in source order
  -> topology diagnostics
```

Accounting grammar, dates, Postings, exact amounts, balance, identity, provenance, and Journal semantics stay in downstream Journal admission owners.

## Consumers and safety role

Read adapters for canonical Actual, Plan, and Budget all run this topology gate before their semantic Journal admission/projection. It therefore protects one shared invariant across the canonical Household Journal family: a root may include only the canonical Account source.

The gate also participates in writer safety. For example, canonical Budget movement candidate preparation admits both the existing root and the complete proposed root through this owner before semantic Budget admission. Plan add/edit and other canonical writer paths likewise use the shared root gate. This means the owner is not merely a read convenience; it is part of complete-source publication qualification.

Repository search found no production consumer that reads the returned `includes` field directly; focused laws do. That may be useful later in the repository-wide public-surface reachability audit, but it is deliberately not removed as a side effect of this local topology-kernel review.

## Previous source relation

The previous implementation had a small public contract but expressed successful-path discovery procedurally:

```text
for every physical line
  test StartsDirective "include"
  strip semicolon comment
  derive path
  append path when nonempty
  append line diagnostic when empty/unknown
append duplicate-canonical-source aggregate diagnostic
```

The mutable vectors `includes` and `diagnostics` did not represent evolving domain state. Each include directive is independently classifiable once its physical source line is known.

## Directive boundary semantics

The root gate recognizes only the lexical directive word `include` followed by end-of-line or whitespace after leading whitespace is removed.

Protected boundary behavior includes:

- leading spaces are allowed;
- ASCII tab is a valid directive boundary;
- semicolon comments are removed from the path after directive recognition;
- comment lines containing the word `include` are not directives;
- `includeaccounts.journal` is not a directive;
- `included accounts.journal` is not a directive;
- short ordinary lines remain ordinary source text;
- `include ; comment` is an empty include and owns its physical line diagnostic.

These are topology grammar rules, not downstream accounting grammar.

## Characterization exposed an existing totality bug

The focused test was extended before structural production work to protect:

- whitespace/tab directive boundaries;
- semicolon comment stripping;
- non-directive words beginning with `include`;
- short ordinary lines;
- publication of unknown nonempty include paths;
- exclusion of empty paths from `includes`;
- exact source order of mixed line-owned diagnostics;
- duplicate canonical-source diagnostic as a final aggregate root diagnostic.

Characterization-only CI #2623 failed before any structural refactor. The short ordinary line `in` reached this expression inside `StartsDirective`:

```bqn
keyword≡n↑text
```

Although `enough ← n≤≠text` was false, BQN evaluates the full boolean expression rather than short-circuiting it. Taking seven characters from a shorter character vector therefore required a fill value that was unavailable.

This is the same evaluation-totality class previously exposed while making Account Journal line classification whole-array. The root owner already called `StartsDirective` for every physical line, so the bug was latent in the existing implementation rather than introduced by the proposed array rewrite.

The retained fix is explicit padding:

```bqn
prefix ← n↑text∾n⥊space
```

`enough` remains the semantic guard, while `prefix` is now safe to evaluate for every physical line. CI #2624 passed the focused characterization, full repository check, and coverage after this fix.

## BQN-native include relation

After totality was established, the line-by-line append staging was replaced by one aligned include relation:

```text
physical lines
  -> includeMask
  -> includeIndices / includeRows / includeLines
  -> normalized path cells
  -> emptyPath / knownPath / unknownPath masks
  -> nonempty include publication
  -> source-ordered diagnostic cells
  -> aggregate duplicate-canonical-source law
```

The production kernel now makes the shared directive axis explicit:

```bqn
indices ← ↕≠lines
includeMask ← {StartsDirective ⟨"include",𝕩⟩}¨lines
includeIndices ← includeMask/indices
includeRows ← 1+includeIndices
includeLines ← includeMask/lines
```

Each selected line then produces exactly one normalized path cell. `emptyPath`, `knownPath`, and `unknownPath` stay aligned with that path axis. Public `includes` is a simple filter of the nonempty path cells.

Diagnostic publication is kept separate from relation classification. One diagnostic cell is produced per directive coordinate and flattened in source order, after which the duplicate canonical-source aggregate law is appended.

CI #2625 passed the resulting structural form with the full repository check and coverage.

## Diagnostic/publication semantics

`includes` publishes every nonempty include path in physical source order, including unknown paths when the result is an error. Empty directives do not contribute a path.

Line-owned diagnostics are source ordered. The aggregate duplicate law is evaluated only for the expected canonical Account source and is appended after all line-owned diagnostics with line `0`.

For example:

```text
include typo-accounts.journal
include ; comment
include accounts.journal
include accounts.journal
```

publishes paths:

```text
typo-accounts.journal
accounts.journal
accounts.journal
```

and diagnostics in this order:

```text
journal_include_unknown @ line 1
journal_include_empty @ line 2
journal_include_duplicate @ line 0
```

The new relation retains this distinction between per-directive diagnostic cells and the final aggregate law.

## What was deliberately not changed

The review remains narrow:

- no downstream Journal/accounting grammar moved into the root gate;
- no generic directive parser was introduced;
- no filesystem, writer, or mutation authority moved here;
- application adapters and writer candidates continue sharing the same pure root topology owner;
- public `includes` was retained despite having no production reader found in this review, because removing a tested public surface is a separate reachability decision.

## Protected contracts

Preserved by focused and full qualification:

- canonical Journal root topology ownership;
- expected Account basename supplied by the canonical source owner/caller;
- optional include: a fully resolved root with no include remains valid;
- only the canonical Account source may be included;
- at most one canonical Account include;
- physical source order of `includes`;
- unknown nonempty paths remain visible in `includes` on error;
- physical line coordinates for empty/unknown include diagnostics;
- line-owned diagnostic order before aggregate duplicate diagnostic;
- semicolon comment semantics and directive word boundary;
- total directive classification for short ordinary source lines;
- pure read/write qualification role with no filesystem authority;
- no downstream accounting/identity/provenance responsibility added here.

## Qualification

- review base main `79c5882a1f3996790caa001e2b65977d9588e852` follows Budget policy closeout #651;
- CI #2623: FAILED during characterization and exposed the pre-existing short-line fill failure in `StartsDirective`;
- CI #2624: SUCCESS after explicit classifier padding, including full repository check and coverage;
- CI #2625: SUCCESS for the include-axis structural transformation, including full repository check and coverage;
- final documented PR-head CI: pending at the time this observation was updated.

## Review decision

Retain `src/ledger/canonical_journal_root_admission.bqn` as the shared pure canonical Journal topology gate.

Its successful path is clearer as an aligned source relation than as mutable publication staging:

```text
physical source
  -> total include classification
  -> directive/source-coordinate axis
  -> path cells and masks
  -> source-ordered line diagnostics
  -> aggregate root law
  -> topology result
```

The short-line failure found during characterization is fixed as part of this owner review. No broader public-surface or parser abstraction change is selected.
