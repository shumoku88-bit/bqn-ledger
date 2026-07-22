# Journal Canonical TSV-to-Native Prefix Converter Plan

Status: completed
Owner: journal source migration / conversion
Canonical: no; completion route: JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_COMPLETION-2026-07-22.md and ../../../TODO.md
Date: 2026-07-22
Exit: archived; do not use as authorization for private verification, conversion, reconstruction, cutover, or another Journal slice

Native Journal remains the owner-selected future durable actual source truth. Production cutover is blocked until canonical historical-prefix reconstruction succeeds.

## Canonical finite question

> Can the repository define a deterministic one-way converter contract that transforms an immutable legacy `journal.tsv` snapshot into a canonical native Journal historical prefix while preserving accounting movements, established description semantics, legacy physical source identity, distinct business `txn_id` linkage, supported metadata, transaction order, posting order, layer, status, and diagnostics, and can it define a fail-closed reconstruction procedure that combines that verified prefix with an existing byte-preserved Journal-only suffix without modifying production code or private data in this docs-only slice?

This plan answers only whether that contract can be defined. It performs no conversion or reconstruction.

## Current observation

The structural observation is:

```text
current private candidate
=
noncanonical TSV-derived prefix
+
valid preserved Journal-only suffix
```

The read-only comparison established that accounting signed movements, posting order, layer and status, transaction grouping, and the exact prefix boundary match. The Journal-only suffix is preserved. Description semantics do not yet match, source identity is not canonical, business `txn_id` was not retained distinctly, and supported metadata was not fully retained or mapped.

The current candidate remains valuable migration and recovery evidence. It must not be destroyed, rewritten, normalized, or treated as a failed disposable artifact.

## Converter role

The converter is a one-way migration tool:

```text
immutable journal.tsv snapshot
  -> legacy TSV source adapter semantics
  -> canonical Journal transaction renderer
  -> verified native Journal historical prefix
```

The converter must not:

- write back to TSV;
- read the generated hledger projection as source truth;
- modify the existing Journal-only suffix;
- make production routing decisions;
- perform daily synchronization;
- silently discard unsupported information.

## Canonical transaction topology

The historical compatibility prefix has this topology:

```text
one physical journal.tsv row
  -> one native Journal transaction block
  -> two explicit ordered postings
```

The converter must:

- preserve original TSV physical row order;
- preserve the debit-then-credit posting order established by the current TSV adapter;
- not merge rows merely because they share a business `txn_id`;
- not flatten later native multi-posting transactions;
- retain related-row business linkage through metadata rather than transaction merging;
- balance every generated transaction exactly;
- retain exact integer JPY evidence.

This topology applies only to the converted legacy prefix. It does not constrain new native Journal transactions.

## Description semantics

Implementation must inspect and reuse the repository's established meaning of the TSV description or memo field. Before rendering, it must produce an explicit public mapping table derived from current source code and tests.

The converter must preserve:

- textual transaction-description meaning;
- any distinction the current adapter makes between description, memo, payee, or display text;
- exact supported Unicode text;
- existing rejection behavior for empty or invalid descriptions;
- structured diagnostic evidence for text that cannot be represented safely.

This slice does not invent a new payee model. If the current TSV adapter and supported Journal profile cannot express equivalent description semantics, implementation must stop and select a separate profile-extension slice.

## Source identity contract

Physical source identity remains separate from business linkage. Each legacy TSV row receives a deterministic legacy source event identity derived from:

```text
source file identity
+
physical source row
```

The exact encoding must reuse or conform to the repository's established legacy identity contract.

Requirements:

- do not promote `txn_id` to `event-id`;
- do not use a content hash as the sole identity;
- do not derive identity from mutable descriptions or amounts;
- derive generated posting IDs deterministically from source event identity plus posting index;
- keep posting indices contiguous and ordered;
- treat source-line evidence as diagnostic provenance, not business identity;
- preserve enough provenance to compare converted Journal transactions with legacy TSV adapter output.

## Business `txn_id` contract

When a TSV row has business `txn_id` metadata, the converter must:

- retain it as a distinct business-link metadata field;
- not collapse it into `source_event_id`;
- not merge all rows sharing the value;
- preserve absence as absence;
- reject duplicate or malformed metadata only according to the established TSV contract;
- let later consumers distinguish physical source identity from business transaction grouping.

The exact Journal metadata spelling must be derived from the supported Journal profile or selected explicitly after repository inspection. If the current parser does not support the required distinct business-link field, implementation must stop and select a separate parser/profile slice rather than silently dropping it.

## Other metadata mapping

Implementation must inventory every metadata field currently supported by `journal.tsv` and classify each as:

```text
direct Journal metadata mapping
rendered accounting field
legacy provenance only
unsupported and fail-closed
intentionally excluded with documented proof
```

Requirements:

- represent currency consistently with explicit JPY amounts;
- preserve current layer and status semantics;
- never silently discard supported links or classifications;
- return a structured diagnostic for unknown or unsupported metadata;
- ensure field order does not alter semantic comparison;
- never expose private metadata values in public tests or documentation.

The implementation must add a public mapping table using field names and synthetic examples only.

## Deterministic rendering

The canonical prefix renderer must define:

- declaration requirements;
- transaction-block layout;
- exact status rendering;
- exact metadata ordering;
- exact posting ordering;
- integer amount rendering;
- commodity rendering;
- blank-line and final-newline behavior;
- stable output for identical input;
- locale-independent formatting;
- no automatic account creation;
- no implicit balancing postings.

Identical snapshot bytes and identical account-registry semantics must produce identical canonical prefix bytes.

## Parser and Posting IR validation

Every complete generated prefix must pass the unchanged existing boundaries:

```text
canonical Journal prefix
  -> existing supported Journal parser
  -> Transaction IR
  -> account resolver
  -> checked Stage 2A Posting IR
```

Validation must fail closed on:

- malformed TSV;
- unknown or ambiguous accounts;
- incompatible commodity;
- invalid date or exact-integer amount;
- unsafe description text;
- unsupported metadata;
- duplicate source event identity;
- invalid posting identity;
- imbalance;
- unexpected parser incompatibility.

No partial prefix may be published.

## Canonical parity dimensions

A future implementation compares the legacy TSV adapter output and converted Journal output across independent dimensions.

### Accounting parity

Require equality of:

- date semantics;
- account keys;
- signed movements;
- posting order;
- actual layer;
- status;
- balance;
- downstream actual-layer Cube coordinates;
- TBDS actual rows;
- Trial Balance;
- Balances and supported report totals.

### Identity and provenance parity

Require canonical correspondence for:

- legacy source event identity;
- source-file evidence;
- physical-row evidence;
- posting index;
- posting identity;
- deterministic transaction order.

Physical Journal line numbers may differ, but semantic source identity must remain traceable.

### Business-link parity

Require preservation of:

- distinct business `txn_id`;
- every other supported metadata field;
- absence-versus-presence semantics.

A converter passes only when all required dimensions pass. Accounting parity alone is insufficient.

## Prefix output contract

The converter produces a prefix only at an explicitly supplied new output path.

Requirements:

- the output path must not already contain the Journal-only suffix;
- existing files must not be overwritten without an explicit guarded mode;
- the production canonical Journal must not be the default converter-development target;
- use temporary construction and atomic publish;
- retain a source-snapshot manifest privately;
- produce a machine-readable, non-sensitive validation result;
- never append directly to the currently preserved candidate during the first conversion phase.

## Suffix-preserving reconstruction

Only after canonical-prefix validation may a separate fail-closed procedure reconstruct a candidate:

```text
verified canonical prefix
+
exact preserved Journal-only suffix bytes
=
new reconstructed native Journal candidate
```

Transaction non-overlap is identity-based in this finite reconstruction proof. Equality of durable `source_event_id` defines overlap. Equal date, description, and postings with distinct durable IDs remain distinct events; no content-, amount-, account-, or normalized-description heuristic is used.

The procedure must:

- operate on a new target file;
- never edit the preserved current candidate in place;
- establish the suffix boundary structurally;
- copy exact suffix bytes without reparsing and re-rendering them unless that is separately proven safe;
- prove the suffix exists exactly once;
- prove no converted-prefix durable `source_event_id` appears in the suffix;
- prove every durable `source_event_id` is unique within the suffix;
- prove no suffix durable `source_event_id` appears in the frozen TSV snapshot;
- parse and validate the complete reconstructed candidate;
- compare the complete result as frozen prefix plus suffix delta;
- retain both original and reconstructed candidates until cutover completion;
- require explicit owner approval before either becomes the permanent source path.

No reconstruction occurs in this docs-only slice.

## Recovery contract

If conversion fails:

- publish no prefix;
- leave the TSV snapshot unchanged;
- leave the current Journal candidate unchanged;
- retain diagnostics.

If reconstruction fails:

- publish no reconstructed candidate;
- leave verified-prefix evidence available;
- leave the original candidate and suffix unchanged.

Never delete the only copy of the Journal-only suffix. Never overwrite a later Journal writer's bytes.

## Relationship to production cutover

The production cutover readiness gate remains blocked. It may be selected again only after:

1. canonical prefix conversion passes;
2. description semantics pass;
3. source identity passes;
4. business `txn_id` retention passes;
5. other supported metadata mapping passes;
6. the reconstructed candidate passes complete parser and Posting IR validation;
7. frozen-prefix parity passes;
8. Journal-only suffix preservation passes.

Converter completion must not select the later cutover slice automatically.

## `tools/to-hledger` boundary

- `tools/to-hledger` remains a compatibility projection.
- It is not the canonical converter selected here.
- Its output must not become the editable native source.
- It must not overwrite the preserved candidate or future canonical Journal.
- Changing it requires separately demonstrated need.

## Privacy and public synthetic fixture strategy

Future implementation tests must use public synthetic data containing at least:

- multiple legacy TSV rows;
- two rows sharing a business `txn_id` while remaining separate physical transactions;
- Unicode descriptions;
- supported and missing metadata;
- explicit JPY;
- deterministic legacy source identities;
- a synthetic Journal-only multi-posting suffix;
- a reconstruction check proving the suffix is copied exactly once.

Private validation may be read-only and local. No private data, source files, derived reports, identifiers, values, or snapshots may enter Git.

## Expected implementation surface

These are provisional, inspection-dependent candidates, not a promise that every area changes:

```text
a new canonical TSV-to-native Journal converter owner
legacy TSV adapter or reusable semantic projection helpers
Journal exact renderer
identity/provenance validation helpers
synthetic fixtures
focused converter checks
focused reconstruction checks
tools/check.sh
TODO.md
NEXT_SESSION.md
docs/README.md
completion archive
```

Parser, Posting IR, Cube, TBDS, production routing, private-data, and default-writer changes are not authorized without demonstrated need.

## Explicit non-goals

This selected slice does not authorize:

- production source cutover;
- production report-routing changes;
- default-writer changes;
- private-data conversion;
- replacement of the current private candidate;
- editing the Journal-only suffix;
- dual writes;
- reverse synchronization;
- automatic conflict resolution;
- TUI work;
- plan or budget migration;
- envelope-policy changes;
- correction or reversal-policy expansion;
- parser grammar expansion without a separate stop;
- Posting IR schema changes;
- Cube or TBDS shape changes;
- branch merge or deletion.

## Completion and routing

Completion requires implementation within the selected contract, public synthetic validation, read-only private structural verification, full repository checks, independent review, and a completion archive. The same completion change must explicitly return routing to no selected Journal slice. It must not select cutover or any later Journal slice automatically.
