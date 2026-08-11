# Issue admission review observation — 2026-08-11

## Owner and reachability

`src/ledger/issue_admission.bqn` is the live pure admission owner for canonical `issues.tsv`.

Current production consumers include report composition and post-write validation. The Issues section consumes admitted Issue order, values, and provenance directly. This is therefore a retained runtime owner, not a migration/qualification seam.

The owner admits:

- strict eight-column TSV shape;
- Issue identity, status, optional date, category, title, optional exact amount/currency pair, and details;
- currency precision through the live currency registry;
- one-based supplied source-row coordinates and durable `issues.tsv:row:N` references;
- whole-source Issue identity uniqueness;
- fail-closed publication.

## Initial shape

The previous implementation mixed three different concerns in one file-wide mutable path:

```text
physical line vector
  -> mutable dataLines / dataSourceRows append
  -> mutable header staging
  -> mutable diagnostics / admitted rows append
  -> whole-source duplicate check
  -> fail-closed publication
```

The row-local logic itself was not the main defect. A single Issue row has real sequential dependencies: exact amount parsing precedes precision admission, currency policy is consulted only on the amount-present path, and optional Gregorian text precedes date-ordinal derivation.

The review therefore distinguishes file-axis plumbing from genuine row-local admission flow.

## Ignored-row correctness defect

The original classifier was:

```bqn
Ignored ← {𝕊 line: (0=≠line) ∨ ((0<≠line) ∧ (⊑line)∊"#\\")}
```

BQN boolean expressions do not protect a later partial expression merely because an earlier boolean would decide the result. A pure `Admit` caller supplying an empty line could therefore reach `⊑line`.

A characterization law inserted blank/comment rows between the canonical header and fixture rows and protected both successful admission and original supplied source-row provenance. Characterization-only CI #2689 failed in the focused Issue test.

The retained classifier makes first-character selection total and keeps its result scalar:

```bqn
Ignored ← {𝕊 line:
  first ← ⊑(line∾" ")
  (0=≠line) ∨ (first='#') ∨ first=⊑"\\"
}
```

CI #2702 was SUCCESS for the total classifier plus the ignored-row/source-coordinate law.

## Source-axis relation

After classification, source text and source-row coordinates are aligned arrays:

```text
lines       ┐
sourceRows  ├─ same ignored/data mask
            ↓
dataLines
dataSourceRows
```

The old mutable append loop is replaced by one mask classification and two aligned selections.

Header text and its source coordinate then use appended fill cells, removing guarded mutable header staging while preserving the established empty/absent behavior.

## BQN shape evidence from failed attempts

The failed intermediate heads are useful review evidence rather than hidden churn.

### #2700 — invalid inline conditional attempt

An attempted expression using `? ... ; ...` inside the classifier produced an `Undefined identifier` parse/import failure. The fix was not another control-flow trick: the final classifier totalizes the first cell structurally with an appended fill character.

### #2703 / #2704 — mask cell shape failure

An intermediate classifier used membership:

```bqn
first ∊ "#\\"
```

The resulting cells were unsuitable as the scalar boolean file mask used by `/`, producing:

```text
Length of compound 𝕨 must be at most rank of 𝕩
```

at `dataMask/lines`.

The retained form uses explicit scalar equality for the two comment markers. The lesson is that glyph compactness is not array clarity: a mask is useful only when its cell shape matches the semantic axis it is meant to select.

CI #2705 was SUCCESS after the scalar classifier and aligned source-axis selection were established.

## Row-local admission cells

Before changing file-wide diagnostic publication, a characterization law fixed the public ordering:

```text
row 2 status diagnostic
row 4 date diagnostic
row 0 duplicate-identity aggregate
```

CI #2706 was SUCCESS on the characterization-only head.

The retained production form is now:

```text
rowLines + rowSourceRows
  -> ParseRow¨ row axis
  -> { diagnostics, optional admitted Issue } cells
  -> flatten row diagnostics in source order
  -> select admitted Issue cells
  -> whole-source duplicate identity diagnostic
  -> fail-closed column publication
```

`ParseRow` deliberately retains local mutation for ordered diagnostics, exact parse/policy dependencies, and optional date ordinal derivation. Those are genuine dependencies inside one semantic Issue row.

The file-wide mutable `diagnostics` and `rows` accumulation is removed.

CI #2707 was SUCCESS with full `tools/check.sh` and coverage.

## Preserved behavior

The review does not change:

- Issue TSV schema or field names;
- status vocabulary;
- strict Gregorian semantics;
- exact-decimal parsing or currency precision policy;
- row-local diagnostic codes/messages/order;
- duplicate identity ownership or its `source_row=0` aggregate sentinel;
- the rule that duplicate detection sees only individually admitted rows;
- supplied source-row numbering and durable source references;
- report/section ordering;
- fail-closed Issue table publication;
- editor/writer authority.

No generic TSV framework is introduced.

## Review conclusion

The useful transformation is:

```text
file-wide mutable filtering and accumulation

->

one file-axis mask
+ aligned source coordinates
+ independent row-local admission cells
+ ordered diagnostic flattening
+ one whole-source identity law
```

The retained row item is meaningful domain structure, not accidental row plumbing. Array-native review here means exposing the source axis and separating independent row cells, while keeping sequential state where exact/date admission genuinely requires it.
