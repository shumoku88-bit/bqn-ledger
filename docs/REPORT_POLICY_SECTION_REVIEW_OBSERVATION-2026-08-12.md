# Report policy section review observation — 2026-08-12

## Owner and scope

`src/ledger/report_policy_admission.bqn` is the live canonical admission owner for `report.toml`.

It owns only Report query defaults and presentation policy. Physical source basenames, Household classification, writer authority, clocks, and report execution remain outside this owner.

The application reaches it through `src/application/report_policy_source_adapter.bqn`.

This review focused on the physical section/key traversal before the existing Report-policy semantic stage.

## Characterization first

The old implementation carried file-wide mutable:

```text
active
current
blocks
Finalize
```

Before replacing that traversal, focused characterization fixed the actual source-ownership law.

### Physical ownership

A nonignored key before any section is outside a supported section.

A supported header owns following nonignored, nonheader rows until the next physical header.

An unsupported header resets supported ownership. Therefore:

```text
unsupported header
  -> report_policy_section_unsupported at the header row
  -> following nonignored key rows are report_policy_key_outside_section
  -> next supported header begins a new admitted section
```

Comments and blank rows do not participate in ownership or key parsing.

A malformed key row inside a supported section remains a row-local key-shape failure.

The mixed characterization protects exact physical-source order:

```text
key_outside_section
section_unsupported
key_outside_section
key_shape_invalid
```

with their physical line coordinates.

The first two characterization attempts failed only because of test-fixture BQN syntax. The corrected characterization-only CI #2757 succeeded before any production change.

## Section source relation

The reviewed production form exposes section ownership as a source-axis relation:

```text
physical lines
  -> trimmed lines
  -> ignored mask
  -> header mask
  -> prefix Scan of header mask
  -> Group physical source coordinates by section segment
  -> local segment admission
```

The core structural coordinates are:

```bqn
indices ← ↕≠lines
trimmed ← Trim¨lines
ignored ← (0=≠¨trimmed) ∨ hash=FirstOrSpace¨trimmed
header ← {(2≤≠𝕩) ∧ ('['=FirstOrSpace 𝕩) ∧ ']'=FirstOrSpace⌽𝕩}¨trimmed
segmentIds ← +`header
segments ← segmentIds⊔indices
```

Every physical header starts a new segment, including unsupported headers. This is what makes unsupported-header ownership reset structural rather than mutable state.

## Local segment admission

Each segment returns one local result:

```text
{ diagnostics, block? }
```

There are three structural cases.

### Prefix segment

Rows before the first header have no section owner. Every nonignored row produces `report_policy_key_outside_section` in physical order.

### Supported section segment

The header is admitted as the block identity. Nonignored, nonheader rows are mapped through local pair admission:

```text
source coordinate
  -> exactly-one '=' check
  -> nonempty key/value check
  -> { diagnostics, pair? }
```

Row-local diagnostics are flattened in source order, and valid pairs become the block pair axis.

### Unsupported section segment

The header produces `report_policy_section_unsupported`. The segment's following nonignored rows are not parsed as supported key/value pairs; they produce `report_policy_key_outside_section` instead. This preserves the previous ownership reset and diagnostic frontier.

## Production result

The previous file-wide state machine is removed:

```text
active/current/Finalize + append blocks
```

becomes:

```text
header classification
-> Scan section coordinate
-> Group physical coordinates
-> local segment cells
-> source-order diagnostics + block axis
```

Production CI #2758 succeeded with full `tools/check.sh` and coverage.

## Retained Report-policy semantic stage

The remainder of the owner is intentionally unchanged.

`Singles`, `RequireOne`, and `OptionalOne` express section cardinality by domain name. `CheckKeys` owns required/optional key policy. `ParseString`, `PositiveInteger`, date-reference validation, explicit-range checking, presentation defaults, and report-specific publication all encode dependent Report-policy semantics.

These axes are small and domain-named. Replacing them with a generic TOML abstraction or extra coordinate machinery would not remove a demonstrated traversal problem and would make Report-policy meaning less direct.

## Preserved boundaries

The review does not change:

- supported section names;
- section cardinality rules;
- required/optional key rules;
- string/integer/date/range semantics;
- presentation defaults;
- report query defaults;
- diagnostic codes, ordering, or source coordinates;
- canonical source ownership or writer authority.

## Review conclusion

The useful subtraction was the physical section state machine. Its sequential meaning is now represented by a header-derived Scan coordinate and Grouped source segments. The remaining local guards and named semantic helpers carry Report-policy meaning and are retained.
