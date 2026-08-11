# Household policy section review observation — 2026-08-11

## Owner and scope

`src/ledger/household_policy_admission.bqn` is the live canonical `household.toml` admission owner. It carries Household-only Cycle policy, Budget structural coordinates, optional primary Commodity, Daily Target selections, and Account-policy axes while Account identity/type remains in `accounts.journal` and general Envelope/Backing policy remains in `budget.toml`.

This review isolates one structural question: which apparent parser state is genuinely sequential, and which state only hides a source-axis relation?

## Genuine sequential state retained

Canonical TOML Account arrays may span physical lines. Quote state and logical-row assembly therefore depend on prior characters/rows:

```text
physical rows
  -> quote/array closure state
  -> pending multiline text
  -> logical rows + first physical owner line
```

The canonical fixture already contains a multiline `variable = [...]` Account array. That path remains unchanged.

`ArrayClosed`, `SplitArrayItems`, and physical-to-logical `pending` state are not treated as procedural debt merely because they mutate local state. They represent actual lexical history.

## Structural state removed

After logical rows exist, the previous owner still maintained file-wide:

```text
active
current block
Finalize
```

Every header finalized the previous block and activated a new supported block. That state did not represent lexical history. It represented the section coordinate of each already-complete logical row.

The retained form is now:

```text
logical rows
  -> ignored mask
  -> table / array-table header masks
  -> header mask
  -> prefix Scan of header mask
  -> Group source indices by section coordinate
  -> parse each segment locally
```

Header classification is total for short rows through explicit padding before two-character prefix/suffix comparisons.

## Unsupported sections remain non-owning

An unknown header is not merely an unknown block kind. Under the established Household contract it terminates any previous supported ownership but does not establish a new active block. Therefore following keys are outside a supported section.

The new segmentation preserves exactly that rule:

- segment header emits `household_section_unsupported`;
- no block is published for that segment;
- every nonignored tail row emits `household_key_outside_section` in source order.

A key in the prefix segment before the first header receives the same outside-section diagnostic.

## Characterization and evidence

A focused structural test was added before production changed.

It protects:

- the existing multiline canonical fixture;
- key-before-section line ownership;
- unsupported-section diagnostic ownership;
- unsupported-section followed by outside-key diagnostic order.

Evidence:

- CI #2679 SUCCESS: characterization-only head;
- CI #2680 SUCCESS: Scan/Group section implementation, full `tools/check.sh`, and coverage.

## Deliberate non-change

This slice does not change semantic Household policy admission after block construction. `RequireOne`, key/value parsing, Account role validation, Envelope/Daily Target relation building, Account-policy axes, diagnostics, and fail-closed result publication remain intact.

Those later relations have their own array-shape questions. In particular, repeated Account lookup and Account-policy dense-axis construction should be reviewed as semantic Account relations rather than mixed into section parsing.

## Lesson

The useful distinction is not mutation versus no mutation.

```text
state that depends on prior source characters
  -> genuine sequential parser state

state that only names which completed section a row belongs to
  -> source coordinate
  -> Scan / Group
```

The resulting code keeps real lexical state and removes only the incidental section machine.