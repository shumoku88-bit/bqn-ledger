# Journal human-readable boundary audit

Status: audit snapshot
Owner: journal source migration / editor
Canonical: no; current routes: `../../../TODO.md`, `../../AI_CODEMAP.md`, and `../completed-plans/MINIMAL_BQN_JOURNAL_PROFILE_STAGE0_CHARACTERIZATION-2026-07-18.md`
Exit: retain as current-main evidence until a separately selected human-readable Journal contract or implementation slice supersedes this audit
Date: 2026-07-23

## Finite question

> On current remote `main`, what is the smallest human-readable actual-transaction surface already supported by the parser, which persisted fields are forced only by the current writer/validator, and what ordered changes would restore the Stage 0 readability boundary without deleting private production data?

## Scope and non-change

This is a public-code and public-fixture, read-only design audit.

It does not:

- read, rewrite, normalize, or delete the private production Journal;
- change parser, writer, report, editor, config, fixture, or runtime behavior;
- decide removal of user-authored tax, evidence, note, party, receipt, or plan metadata;
- select broad hledger grammar support;
- create a sidecar identity store;
- claim that a repository check was executed through the GitHub connector.

Repository evidence was inspected at remote `main`:

```text
584877162a7582ee395e9efba8282951b5e75f03
feat: add temporal plan filtering and multi-posting journal UI support
```

The production Journal cutover commit is:

```text
375e7a6337775c3713680c952d946bad7d8e3554
feat: cut over production actuals to native Journal (#334)
```

## Executive finding

The current unreadable ordinary transaction shape is not required by the accounting engine or even by the current Stage 1 parser.

It is produced by a narrower implementation choice in the native writer and its mandatory post-write validator:

```text
ordinary editor input
  -> tools/edit-bqn generates an event-id
  -> journal_block_add_cmd requires event-id
  -> journal_block_add_cmd always renders event-id + layer: actual
  -> journal add additionally injects currency: JPY
  -> journal_native_source_check requires the new event to be durable
```

The earlier Stage 0 decision already rejected this result. It states that:

- ordinary actuals should omit unnecessary identity and layer metadata;
- explicit `event-id` is conditional, not universal;
- an actual transaction without `layer` is interpreted as actual;
- the profile becomes too heavy if every ordinary purchase carries identity, layer, balancing arithmetic, plan fields, and envelope fields.

Therefore this is primarily **implementation drift from an already recorded design boundary**, not a newly invented aesthetic preference.

## Target human surface

### T0: ordinary actual

This is the target baseline for an ordinary actual transaction:

```journal
2026-07-23 * スーパー
    expenses:food    1200 JPY
    assets:bank     -1200 JPY
```

Properties:

- valid hledger transaction-block syntax;
- explicit status remains for the current parser;
- all posting amounts remain explicit for fail-closed balance evidence;
- posting commodity remains explicit;
- no `event-id`;
- no `layer: actual`;
- no transaction-level `currency: JPY`;
- no metadata unless a human or business process has durable information to preserve.

### T1: actual with human-authored durable meaning

```journal
2026-07-23 * 書籍
    ; tax: business
    ; note: 技術書
    expenses:learning    1800 JPY
    assets:bank         -1800 JPY
```

`tax` and `note` remain because they preserve meaning not contained in the postings. They are not required merely because the editor wrote the transaction.

### T2: plan completion

```journal
2026-07-23 * 家賃
    ; plan-id: plan-2026-07-25-rent
    ; execution-envelope: reserve
    expenses:rent    64000 JPY
    assets:bank     -64000 JPY
```

The business link remains. The transaction is still actual by omission of `layer`. An opaque source event ID is not automatically required merely because a business link exists.

### T3: event requiring durable source identity

```journal
2026-07-23 * Externally referenced event
    ; event-id: event-example-001
    expenses:other    1000 JPY
    assets:bank      -1000 JPY
```

This shape is reserved for a real durable-identity requirement, such as another record referring to this event, stable automated editing across physical movement, deduplication, or external synchronization.

## hledger compatibility boundary

Official hledger journal syntax permits:

- optional transaction status;
- optional transaction code;
- transaction comments and tags;
- flexible account names;
- optional posting amounts, with one amount inferred to balance;
- transaction, posting, and account tags.

References:

- https://hledger.org/SPEC-journal.html
- https://hledger.org/1.52/hledger.html
- https://hledger.org/journal-entries.html

This audit does **not** recommend implementing that entire grammar now.

T0 is deliberately narrower than hledger while remaining hledger-compatible:

- keep `*` for now;
- keep every amount explicit;
- keep explicit `JPY` on every posting;
- keep the current supported account-name subset initially;
- remove only metadata ceremony that is already derivable or conditionally unnecessary.

This restores a clean source surface without turning the next slice into an hledger parser rewrite.

## Current parser capability

The parser already supports the key T0 semantics.

### Actual layer is already the omission default

`journal_profile_stage1.bqn` resolves:

```text
layer = metadata["layer"] or "actual"
```

So `layer: actual` carries no additional information in an actual-only production Journal.

### Event ID is already optional for ordinary actuals

When `event-id` is absent, the parser emits:

```text
source_event_id = stage0-line-<source_start_line>
identity_kind   = physical_fallback
```

The Stage 1 test suite explicitly verifies that the first ordinary actual in the Stage 0 fixture has `identity_kind = physical_fallback`.

The public Stage 0 fixture already contains an ordinary split purchase with no `event-id` and no `layer`:

```journal
2026-08-03 * Example Market | groceries and soap
    ; action: buy
    ; receipt-id: receipt-example-001
    expenses:food             800 JPY
    expenses:household        300 JPY
    assets:cash             -1100 JPY
```

Therefore the parser contract is closer to the desired surface than the current writer contract.

### Posting IR arithmetic accepts fallback identity

`journal_posting_ir_stage2a.bqn` maps `transaction.source_event_id` into `source_id`, `tx_id` fallback, and posting IDs, but its accounting arithmetic does not require `identity_kind = durable`.

The parser-derived physical fallback is sufficient for:

- transaction grouping within one parse;
- posting ordering;
- checked debit/credit deltas;
- layer assignment;
- Cube/TBDS/report arithmetic.

It is not stable across physical line movement and must not be advertised as a durable external identifier.

## Current writer drift

### `event-id` is mandatory at the editor boundary

`tools/edit-bqn` generates an opaque hash-like ID for ordinary `journal add` and `journal multi-add` operations and passes it to `journal-block add`.

`journal-block add` rejects absence of `--event-id`.

`src_edit/journal_block_add_cmd.bqn` then always renders:

```journal
    ; event-id: <generated-id>
    ; layer: actual
```

### `currency: JPY` is injected redundantly

The stable `journal add` route passes:

```text
--meta currency=JPY
```

while every posting already contains explicit `JPY` commodity evidence.

The Stage 1 parser stores transaction-level `currency` only as generic metadata. Stage 2A reads the posting commodity and does not derive arithmetic currency from the transaction metadata.

### Mandatory post-write validation requires durable identity

`src_edit/journal_native_source_check.bqn` locates the appended candidate only when:

```text
identity_kind = durable
source_event_id = expected event-id
```

This validator requirement is the immediate technical reason the writer cannot simply stop rendering `event-id` without a separately designed candidate-location protocol.

The accounting validation itself does not require durable identity; the exact-new-candidate verification does.

## Field classification

| Persisted surface | Current source | Current necessity | Human-readable target | Finding |
|---|---|---|---|---|
| `layer: actual` | always rendered by native writer | parser defaults omission to actual | omit on ordinary actuals | fully derivable and safe to characterize for removal |
| `currency: JPY` | injected by stable daily writer | postings already carry explicit JPY; Stage 2A uses postings | omit | redundant transaction metadata |
| `event-id` | generated for every native append | required by writer duplicate check and post-write candidate lookup; not required by arithmetic | conditional only | main design problem; needs identity/write-verification slice |
| `plan-id` | copied from completed plan | used as durable business completion link | retain only on completions | meaningful source information |
| `execution-envelope` | copied from selected plan | preserves historically resolved execution linkage | retain where required | meaningful conditional source information |
| `txn-id` | legacy/business input | distinct business grouping identifier | retain when supplied | do not replace with event-id |
| tax/evidence/note/party metadata | legacy or human input | not arithmetic, but may be irreplaceable evidence | retain when present | not cleanup-by-default candidates |
| account `role` / `kind` / `default-envelope` declarations | converted from `accounts.tsv` | current parser requires Journal declarations; runtime also resolves `accounts.tsv` | move to a separate later boundary decision | duplicated registry surface, but not the first slice |
| `commodity JPY` declaration | converted Journal prefix | current parser requires declaration | retain initially | parser simplification is a later slice |

## Account declaration duplication

The actual Journal contains account declarations copied from `accounts.tsv`, including selected `role`, `kind`, and `default-envelope` metadata.

At runtime, however:

- Stage 1 validates postings against Journal declarations;
- Stage 2A and writer validation separately resolve `accounts.tsv`;
- production account role/currency meaning is taken again from the resolved external registry.

This creates a two-registry seam:

```text
Journal declaration registry
        +
accounts.tsv resolved registry
```

The current code detects some mismatch, but the human Journal still carries a large generated prefix that is not ordinary transaction evidence.

A later design should choose one of these explicit models:

1. **BQN transaction file + external registry**
   - `actual.journal` contains transactions only;
   - BQN parses transaction syntax and validates accounts against `accounts.tsv`;
   - hledger compatibility can use a generated master/include file.

2. **Self-contained hledger Journal**
   - account declarations are authoritative in Journal;
   - `accounts.tsv` is retired or derived;
   - broader migration and editor work is required.

Current production architecture still depends heavily on `accounts.tsv`, so model 1 is the smaller coherent direction. Removing declarations before parser support for an external registry would break current admission and is not selected by this audit.

## Consumer impact of conditional event identity

### Numeric reports

Current checked posting arithmetic can operate with physical fallback identity. Ordinary balances, movement, Cube, TBDS, and trial-balance calculations do not require a durable event ID.

### Journal list and reverse

Native reverse can select by:

- index; or
- exact match against source event ID or description.

Index-based operation remains possible without explicit `event-id`. Description selection is ambiguous when descriptions repeat, so it is not a durable replacement.

A future safe editor should distinguish:

- ephemeral selection token used during one fresh snapshot;
- durable source event ID stored only where long-lived reference is required.

The current safe-write snapshot/stale-check model already provides a useful boundary for ephemeral index/span selection.

### Plan completion

Plan completion is detected through `plan-id`, not through the completion event's `event-id`.

`plan_finish_cmd.bqn` currently generates `completion-<plan-id>-<actual-date>` as a source event ID, but the durable business relationship is already the copied `plan-id`. The need for a second persisted ID must be justified separately rather than assumed.

### Budget companion links

The parser's `actual-event-id` companion relation requires a durable actual target. Current production budget allocation remains `budget_alloc.tsv`; the Journal budget-companion work is characterization evidence, not a reason to force IDs onto every production actual transaction.

If a future production feature refers directly to a particular actual event, that transaction can carry an explicit conditional `event-id`.

## Ordered restoration path

### Slice A: ordinary actual minimal-surface characterization

Status: recommended first finite candidate; test/fixture only.

Prove with public synthetic evidence that these two transactions produce equivalent accounting semantics:

```journal
2026-07-23 * Example purchase
    ; event-id: entry-example
    ; layer: actual
    ; currency: JPY
    expenses:food    1200 JPY
    assets:bank     -1200 JPY
```

```journal
2026-07-23 * Example purchase
    expenses:food    1200 JPY
    assets:bank     -1200 JPY
```

Required comparison:

- parse state;
- date, description, status, layer;
- ordered account/delta/commodity postings;
- Stage 2A accounting coordinates and values;
- Cube/TBDS numeric result;
- explicit difference only in identity classification and generic metadata;
- no production route or writer change.

### Slice B: omit fully derived metadata in writer

After Slice A passes, change ordinary native serialization to omit:

```text
layer: actual
currency: JPY
```

Keep `event-id` temporarily so the existing append protocol and mandatory post-write validator remain stable.

This is the smallest reversible production cleanup and removes two of the three automatic metadata lines without changing identity behavior.

### Slice C: conditional event identity writer contract

Separately redesign candidate verification so ordinary actual appends can omit `event-id`.

The slice must define:

- how the exact appended block is identified during post-write verification;
- how stale-write protection prevents index/span confusion;
- how duplicate ordinary input is treated without pretending every repeated purchase is invalid;
- how list/reverse selects an ordinary fallback-identity transaction;
- which commands still require explicit durable identity;
- how explicit event IDs remain unique when present;
- whether plan completion needs an event ID in addition to `plan-id`;
- rollback behavior unchanged from the current safe-write path.

A viable candidate is to verify the exact appended transaction by the pre-write transaction count plus the appended terminal block under the already checked immutable snapshot, while retaining explicit IDs only for durable-reference cases. This is an inference for future design, not an implementation decision.

### Slice D: external account-registry Journal profile

Only after ordinary transactions are clean, characterize a transaction-only actual Journal that validates accounts and commodities against the external resolved registry rather than duplicated declarations.

This slice must not be combined with broad hledger grammar, account-source retirement, or private data rewriting.

## Rejected shortcuts

### Hide metadata only in the UI

This improves display but leaves the source truth noisy and does not restore the human-editable source boundary.

### Replace event IDs with content hashes

Ordinary edits change hashes. The completed identity decision already rejects content hash as the sole durable identity.

### Use line numbers as if they were durable IDs

Physical fallback is useful for one parse and diagnostics, but line movement changes it. It must remain explicitly non-durable.

### Delete all metadata

Tax, notes, evidence references, plan links, and historically resolved envelope information are not equivalent to generated writer ceremony.

### Implement full hledger parsing first

The target ordinary transaction is already inside the current parser's supported subset. Broad grammar work would delay the direct correction.

### Move all identity to a sidecar immediately

A sidecar introduces synchronization and recovery obligations. Conditional inline identity should be characterized before adding another source file.

## Decision table

| Question | Audit answer |
|---|---|
| Is the current noisy ordinary Journal required by BQN arithmetic? | No |
| Does the current parser already allow no `event-id` and no `layer` for actuals? | Yes |
| Is `currency: JPY` needed when every posting says JPY? | No observed semantic consumer |
| Is universal `event-id` part of the original Stage 0 readability decision? | No; Stage 0 explicitly made it conditional |
| Can `event-id` be removed from the writer immediately without other changes? | No; append validation currently requires durable identity |
| Should user-authored metadata be deleted with generated ceremony? | No |
| Should embedded account declarations be removed in the first slice? | No; current parser requires them |
| Is full hledger adoption required to regain a clean source surface? | No |
| Is hledger-compatible Journal still a viable source boundary? | Yes, if ordinary actuals return to the already-recorded minimal profile |

## Audit conclusion

The target should not be an internal IR printed as Journal comments.

The target should be:

```text
human transaction evidence
  + explicit postings
  + only conditional durable metadata
  -> Transaction IR
  -> checked Posting IR
  -> BQN projections and reports
```

Current code already contains most of this boundary:

- the parser defaults missing layer to actual;
- the parser admits ordinary actuals without event IDs;
- Stage 2A can calculate from fallback identity;
- Stage 0 explicitly rejected universal identity/layer ceremony.

The main correction belongs first at the writer/validator boundary, not in report arithmetic and not in private-data deletion.

Recommended next finite work:

> Implement **Slice A: ordinary actual minimal-surface characterization** as public-synthetic test-only evidence, with no production writer change and no private Journal access.
