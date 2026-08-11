# Canonical Journal root admission review — 2026-08-11

## Baseline

- repository: `shumoku88-bit/bqn-ledger`
- review base: `79c5882a1f3996790caa001e2b65977d9588e852`
- active owner: `src/ledger/canonical_journal_root_admission.bqn`
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

## Current source relation

The current implementation already has a small public contract but expresses successful-path discovery procedurally:

```text
for every physical line
  test StartsDirective "include"
  strip semicolon comment
  derive path
  append path when nonempty
  append line diagnostic when empty/unknown
append duplicate-canonical-source aggregate diagnostic
```

The mutable vectors `includes` and `diagnostics` do not represent evolving domain state. Each include directive is independently classifiable once its physical source line is known.

A clearer array relation is available:

```text
physical lines
  -> include-directive mask
  -> include source-coordinate axis
  -> normalized path cells
  -> empty / known masks
  -> nonempty include publication
  -> source-ordered diagnostic cells
  -> aggregate duplicate-canonical-source law
```

Unlike Budget policy lexical parsing, no quote/escape transition state is present here. The visible mutation is therefore structural publication staging rather than necessary parser state.

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

A whole-array rewrite must retain this distinction between per-directive diagnostic cells and the final aggregate law.

## Characterization first

The focused test is extended before production work to protect:

- whitespace/tab directive boundaries;
- semicolon comment stripping;
- non-directive words beginning with `include`;
- short ordinary lines;
- publication of unknown nonempty include paths;
- exclusion of empty paths from `includes`;
- exact source order of mixed line-owned diagnostics;
- duplicate canonical-source diagnostic as a final aggregate root diagnostic.

No production code is changed by the characterization commit.

## Candidate production boundary

The coherent candidate is small and local:

1. classify physical lines once with `StartsDirective`;
2. select the directive line/source-coordinate axis;
3. derive one path cell per directive;
4. derive empty/unknown masks over that axis;
5. filter nonempty paths into public `includes`;
6. map source-ordered diagnostic cells and flatten once;
7. append the existing duplicate canonical-source aggregate diagnostic.

Do not move accounting syntax here. Do not create a generic directive parser. Do not merge this owner into application adapters or writers. The value of the owner is precisely that read and write paths share one pure topology gate.

## Protected contracts

Preserve:

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
- pure read/write qualification role with no filesystem authority;
- no downstream accounting/identity/provenance responsibility added here.

## Qualification

- review base main `79c5882a1f3996790caa001e2b65977d9588e852` follows Budget policy closeout #651;
- characterization CI: pending at the time this observation was first written.

## Current decision

Observation and characterization first. The current line loop appears to be structural append staging and is a good candidate for one include-axis classification, but production should change only after the boundary/order laws pass unchanged.
