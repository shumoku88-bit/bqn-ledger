# Journal Posting IR identity/provenance parity Stage 2B plan

Status: completed test-only implementation
Owner: journal source migration
Canonical: no; canonical routing remains `TODO.md`
Exit: completed; later parity or production work requires a separately selected finite slice
Date: 2026-07-19

## Purpose

Stage 2B implemented test-only structural parity for semantic event identity, deterministic posting identity, and physical source provenance. It extends the completed Stage 2A success-path comparison without changing production behavior.

```text
public synthetic Journal text
  -> existing Stage 1 Transaction IR
  -> existing Stage 2A adapter
  -> current 16-field Posting IR rows
  -> pure Stage 2B identity/provenance helper
  -> unchanged Posting IR rows + separate Journal-only test provenance carrier
  -> structural invariant assertions against comparable legacy TSV identity evidence
```

The selected contract is now implemented by `src_next/journal_posting_identity_provenance_stage2b.bqn`, its focused test, and the dedicated public synthetic fixture. This record remains historical evidence, not authority for a later stage.

## Existing and future identity models

The current TSV Posting IR contract is row-oriented. Its 16 fields include `source_file`, zero-based `source_row`, `source_id`, `tx_id`, and `posting_id`. For the existing two-sided source shape, one physical TSV row is the source movement and normally expands to debit and credit rows. Several current consumers still join source evidence through `source_row`.

The future Journal model is event-oriented. One transaction block owns ordered native postings and carries:

- `source_event_id`: semantic identity of the Journal event;
- `identity_kind`: whether that identity is durable or a physical fallback;
- `source_start_line`: one-based first physical line of the event block;
- `source_end_line`: one-based last physical line of the event block;
- `posting_index`: zero-based deterministic order within the event;
- `posting_id`: deterministic identity derived from the event identity and posting index.

Semantic identity and physical provenance are separate concerns. `source_event_id`, `identity_kind`, and `posting_id` describe identity semantics. Source line spans locate evidence and diagnostics. A physical span must never be treated as durable semantic identity merely because it is available.

## Identity rules

### Durable identity

`identity_kind = durable` means `source_event_id` comes from an explicit event identifier in the Journal source. It is intended to survive physical line movement and unrelated layout changes.

An explicit durable event identity is required for:

- plan events;
- budget allocation events;
- stable editing;
- durable references or cross-event links.

An ordinary actual event may omit explicit `event-id` when no stable editing or durable reference is required. Omission is compact human input, not an assertion of durability.

### Physical fallback identity

`identity_kind = physical_fallback` means an ordinary actual omitted explicit `event-id`, so the parser derives a deterministic identity from its physical source location under the supported test profile. This identity is suitable for one parse/comparison snapshot and diagnostics, but moving the event may change it. It must not be advertised as stable editing or durable reference identity.

The current Stage 1 spelling, such as `stage0-line-<source_start_line>`, remains parser evidence for this test-only slice; Stage 2B does not promote that spelling into a production format contract.

### Posting identity

For every Journal posting:

```text
posting_id = deterministic_encode(source_event_id, posting_index)
```

For the selected test profile, the exact encoding is `source_event_id + ":" + decimal(posting_index)`, matching Stage 1. Posting indices are zero-based, contiguous, and preserve source posting order. A posting ID must be unique within the result and reproducible for identical semantic event identity and posting order.

### Comparable legacy TSV identity

The six-field provenance carrier is Journal-only and test-only in Stage 2B. Stage 2B does not add a Journal-style `identity_kind` or one-based line span to legacy TSV evidence.

For parity comparison, a test helper reads the legacy path's unchanged current 16-field Posting IR rows and derives only:

```text
normalized legacy event label = legacy:<source_file>:<source_row>
test-only posting ordinal = 0, 1 in current emitted order for that source movement
```

The normalized label groups the two postings from one legacy TSV source movement. The ordinal observes their emitted order. Neither value replaces or mutates the legacy rows' current `source_id`, `tx_id`, or `posting_id`, and neither becomes a production field.

The exact legacy TSV assertions are:

1. the two postings generated from one source movement share the same `source_file` and `source_row`;
2. those two postings share the same normalized legacy event label;
3. their current `posting_id` values are unique;
4. test-only ordinals `0, 1` preserve the current emitted posting order.

Journal and legacy identity strings are not required to match. Stage 2B does not claim that legacy TSV has gained a durable/physical-fallback production classification.

`source_row` remains part of the current 16-field Posting IR and a legacy compatibility surface for existing TSV consumers. Stage 2B starts no consumer migration. Every `source_row` join must still be migrated consumer by consumer under separately selected work before cutover.

## Carrier decision

Stage 2B **does not add fields to or reorder the existing 16-field Posting IR row**. The implementation returns identity/provenance evidence in a separate test-only carrier aligned one-to-one with emitted Posting IR rows.

Each carrier row will contain:

1. `source_event_id`
2. `identity_kind`
3. `source_start_line`
4. `source_end_line`
5. `posting_index`
6. `posting_id`

The carrier is selected because:

- current production consumers and checks depend on the established 16-field row;
- provenance is not yet a documented production consumer requirement;
- adding Journal-only fields to the shared row would prematurely choose a runtime migration shape;
- a separate aligned carrier can prove the required invariants without changing production contracts.

Alignment is itself an invariant: carrier row count and order equal Posting IR row count and order, and each carrier `posting_id` equals the corresponding existing row's `posting_id`. Whether provenance later becomes optional Posting IR fields, a transaction-level table plus posting references, or another checked runtime carrier remains unresolved and requires a production consumer decision outside Stage 2B.

### Pure helper input and result contract

The focused test first calls the existing Stage 2A adapter to generate current 16-field Posting IR rows for admitted Stage 1 Transaction IR. It then calls the Stage 2B helper exactly as:

```text
Build ⟨transactions, postingRows⟩
```

- `transactions` is admitted Stage 1 Transaction IR.
- `postingRows` is the corresponding current 16-field Posting IR rows returned by Stage 2A.
- The Stage 2B helper needs no resolved accounts or cycle start. It must not reproduce account resolution, day-index calculation, kind derivation, or any other Stage 2A behavior.

The result carrier has exactly these top-level fields:

- `state`
- `posting_rows`
- `provenance_rows`
- `diagnostics`

On success:

- `state = "ok"`;
- `posting_rows` preserves the input `postingRows` unchanged;
- `provenance_rows` has the same count and order as `posting_rows`;
- each corresponding `posting_id` matches;
- `diagnostics` is empty.

On failure:

- `state = "error"`;
- `posting_rows` is empty;
- `provenance_rows` is empty;
- `diagnostics` contains at least one item;
- no partially successful carrier is returned.

Supplying both admitted transactions and their already-built Posting IR rows makes row count, emitted order, and corresponding posting-ID mismatches observable at the Stage 2B boundary. A helper receiving transactions alone could construct provenance but could not prove alignment against the actual Stage 2A output; this contract deliberately closes that gap without reimplementing Stage 2A.

## Parity meaning

Parity is an asymmetric structural comparison, not byte-for-byte equality of Journal and TSV identifier strings.

- On the Journal side, Stage 2B proves separation of semantic event identity from physical provenance, plus deterministic posting identity and order.
- On the legacy TSV side, Stage 2B keeps the existing row-oriented event grouping as the comparison baseline and derives only a normalized event label and test-only posting ordinal.

The legacy side is not asserted to distinguish durable identity from physical location, and no Journal provenance fields are projected onto it. A Journal `event-id` must not be asserted equal to `legacy:<source_file>:<source_row>`.

## Selected public synthetic fixture

The implementation added exactly one public fixture directory:

```text
fixtures/journal-posting-ir-stage2b/
```

It contains exactly two transactions representable by both Journal and current TSV adapters:

1. one plan with an explicit durable `event-id` and exactly two postings;
2. one ordinary actual without `event-id`, using physical fallback identity, with exactly two postings.

The fixture uses anonymous accounts, integer JPY evidence, and no private data. Transaction and posting order are explicit. Three-or-more-posting native Journal parity is excluded.

## Exact follow-up assertions

The focused Stage 2B test asserts all of the following:

1. **Shared event identity:** all posting carrier rows for one event share exactly one `source_event_id` and one `identity_kind`.
2. **Unique deterministic posting IDs:** every `posting_id` is unique in the fixture result and equals the selected deterministic encoding of `source_event_id + posting_index`; rebuilding identical admitted Transaction IR yields identical IDs.
3. **Posting order preserved:** posting indices are `0, 1` for each selected event, carrier order matches Posting IR row order, and account/delta order remains the parsed source order.
4. **Durable identity independent of line movement by design:** reparsing a synthetic variant in which the plan block is moved physically preserves the plan's explicit `source_event_id` and both posting IDs while its physical span changes. This may be an in-memory string variant; no fixture writer or I/O-capable adapter is permitted.
5. **Physical span is not semantic identity:** the plan's changed `source_start_line`/`source_end_line` is observed only as provenance and is not used to generate its durable event or posting IDs; the ordinary actual is explicitly labelled `physical_fallback`, never `durable`.
6. **Plan identity preserved:** the explicit plan event identity survives Stage 1 Transaction IR, the Stage 2B carrier, and the corresponding current 16-field rows' identity projection without substitution by source lines.
7. **Legacy comparison boundary:** for each comparable TSV source movement, exactly two unchanged legacy Posting IR rows share `source_file` and `source_row`, share the derived `legacy:<source_file>:<source_row>` label, retain unique current `posting_id` values, and receive test-only ordinals `0, 1` in current emitted order. No Journal ID string equality or legacy durable/fallback classification is asserted.
8. **Carrier alignment:** exactly four Journal Posting IR rows and four provenance rows are emitted; corresponding posting IDs match.
9. **No current-row drift:** Stage 2B keeps the established 16 fields and does not add, remove, reorder, or replace legacy identity fields.

## Fail-closed boundary

The pure Stage 2B helper must not emit an `ok` identity/provenance result when admitted input violates a covered Stage 2B invariant, including duplicate posting IDs, non-contiguous or duplicate posting indices, a missing event identity, an unknown `identity_kind`, an invalid physical span, or transaction/Posting-IR count, order, or posting-ID misalignment. It must return `state = "error"`, empty `posting_rows`, empty `provenance_rows`, one or more diagnostics, and no successful partial carrier.

This is only local invariant protection for the selected success fixture and carrier assembly. Parser rejection behavior, TSV/Journal rejected-transaction diagnostic parity, and broader red-path/rejection parity remain the next independent unselected slice. Stage 2B must not absorb them.

## Test-only implementation boundary

The completed implementation is pure and test-only:

- no file I/O in the helper;
- only `Build ⟨transactions, postingRows⟩`, with admitted Stage 1 Transaction IR and corresponding Stage 2A-generated current 16-field rows, as the helper input;
- no resolved accounts or cycle start input, and no Stage 2A reimplementation;
- deterministic values only, with no clock or environment reads;
- no production importer, loader, context, Cube, TBDS, report, editor, or CLI connection.

Implemented files:

- implementation: `src_next/journal_posting_identity_provenance_stage2b.bqn`
- focused test: `tests/test_journal_posting_identity_provenance_stage2b.bqn`
- public fixture: `fixtures/journal-posting-ir-stage2b/`

The test may read only that public fixture through existing test infrastructure. The implementation module itself performs no I/O.

## Completion evidence

Stage 2B is complete with:

1. a two-event public fixture containing no private evidence;
2. a separate six-field carrier that leaves the existing 16-field Posting IR row unchanged;
3. focused success, deterministic rebuild, durable movement, legacy-boundary, and local fail-closed assertions;
4. all-or-nothing failures for every covered carrier invariant;
5. execution through the normal repository unit-test path;
6. completion routing that selects no later slice.

The implementation remains test-only and has no production consumer.

## Explicit non-goals

Stage 2B does not implement or select:

- a production Journal loader;
- production routing;
- private-data reads;
- source TSV changes;
- a Journal writer or editor;
- TSV-to-Journal conversion;
- shadow read;
- a source-of-truth switch or cutover;
- native parity for three or more postings;
- rejection/red-path parity beyond local carrier invariant fail-closed behavior;
- report, Cube, or TBDS consumer changes;
- `source_row` consumer migration;
- bidirectional sync, reverse sync, or a conflict resolver;
- automatic selection of Stage 2C or any later stage.

The completed Stage 2A remains completed. Rejection parity, native multi-posting parity, production routing, writer work, and cutover remain unselected.

## Unresolved production decisions

Stage 2B deliberately leaves these decisions open:

- the final production carrier for Journal provenance;
- whether and when the current Posting IR contract should gain optional provenance fields;
- the production physical-fallback encoding and its source-path component;
- consumer-by-consumer migration from `source_row`;
- durable ID syntax, namespace governance, and editor generation policy beyond the Stage 0/Stage 1 test profile.

None may be inferred from the test-only carrier selected here.
