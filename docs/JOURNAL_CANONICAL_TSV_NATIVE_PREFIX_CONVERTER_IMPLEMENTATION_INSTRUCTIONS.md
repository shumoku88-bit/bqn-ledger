# Journal Canonical TSV-to-Native Prefix Converter Implementation Instructions

Status: active execution instructions for the selected converter slice
Owner: journal source migration / conversion
Canonical: no; governing plan is `docs/JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_PLAN.md`
Date: 2026-07-22
Exit: archive together with converter completion, return routing to no selected Journal slice, and do not select cutover automatically

## 1. Purpose

Implement the already-selected canonical one-way converter from an immutable legacy `journal.tsv` snapshot to a verified native Journal historical prefix, using public synthetic evidence only in the implementation PR.

This instruction refines execution of the governing plan. It does not select a new Journal slice.

The implementation must preserve:

- one physical legacy transaction row as one native Journal transaction block;
- two explicit ordered postings per converted row;
- accounting movements and exact integer JPY evidence;
- canonical legacy source identity;
- optional business `txn_id` separately from source identity;
- every admitted legacy metadata field;
- transaction order and posting order;
- actual layer and cleared status;
- deterministic bytes and fail-closed diagnostics.

It must also implement a public-synthetic reconstruction check that combines a verified prefix with exact preserved suffix bytes into a new target. It must not perform private reconstruction.

## 2. Required starting gate

Expected starting `main`:

```text
a3f0e719dc5c77cc6ebdc47432245932015b428e
```

Before creating the implementation branch:

1. Verify local `main` and `origin/main` both equal the expected SHA.
2. Verify the working tree is clean.
3. Verify remote `main` has not moved unexpectedly.
4. Read the governing plan, this instruction, `TODO.md`, `NEXT_SESSION.md`, and the completed metadata/profile prerequisite.
5. Read the current TSV adapter, Journal parser, Stage 2A adapter, Stage 2B carrier, account resolver, loader, safe-write path, and focused identity/provenance tests.
6. Confirm no private candidate, TSV snapshot, suffix, amount, description, ID, hash, manifest, or absolute private path will be read or committed.

If the base differs, stop and report the new SHA before implementing.

## 3. Implementation branch and PR

Use a separate implementation branch, provisionally:

```text
feat/journal-canonical-tsv-native-prefix-converter
```

Open the implementation PR as Draft.

Do not combine production cutover, default writer changes, production source routing, report routing, or private reconstruction into the PR.

## 4. Owner decision: description preservation

The converter must not trim, normalize, rewrite, split, or reinterpret the TSV memo/description field.

A legacy description is canonically representable only when all of the following hold:

- it is nonempty;
- it contains no TAB, LF, CR, NUL, other C0 control character, or DEL;
- it has no leading or trailing ASCII space;
- rendering it as the Journal transaction-header description and parsing the complete generated Journal returns exactly the same Unicode code-point sequence;
- no Unicode normalization is performed;
- no payee/description split is introduced.

Internal spaces, punctuation, and supported Unicode characters must remain unchanged.

The renderer must use the original admitted description exactly. It must not use `Trim`, `strip`, compatibility `tools/to-hledger` behavior, or a newly invented normalization as conversion semantics.

If a description is not canonically representable, return a structured error with the stable code:

```text
description_not_canonically_representable
```

No prefix may be published when any row fails this condition.

Public tests must cover:

- exact Unicode preservation;
- internal repeated spaces preserved;
- leading-space rejection;
- trailing-space rejection;
- empty-description rejection;
- control-character rejection;
- parse-roundtrip equality.

A later private read-only verification may reveal a real row that fails this gate. In that case, stop. Do not rewrite the row and do not select a normalization automatically.

## 5. Legacy row admission

The converter accepts only admitted `journal.tsv` transaction data rows from an immutable snapshot.

It must:

- preserve the current adapter's physical source-row evidence;
- preserve admitted transaction-row order;
- ignore comments and blank lines only according to the existing loader/adapter contract;
- retain their effect on physical row numbering when the current adapter retains that effect;
- reject malformed non-comment rows;
- reject fewer than five required fields;
- reject invalid date, amount, account, commodity, description, or metadata evidence;
- publish no partial prefix.

Do not invent a second row-numbering convention. Derive source identity from the exact physical-row evidence produced by the existing legacy source boundary.

## 6. Canonical legacy source identity

For every admitted legacy transaction row, derive one deterministic `source_event_id` using the established legacy identity contract:

```text
legacy:<source_file_identity>:<physical_source_row>
```

Requirements:

- `source_file_identity` must be the established stable identity for the frozen `journal.tsv` source, not an absolute path;
- `physical_source_row` must use the same indexing semantics as the existing adapter evidence;
- `txn_id` must never become `source_event_id`;
- descriptions, amounts, and content hashes must not determine source identity;
- posting IDs must be `source_event_id + posting_index` using the existing profile encoding;
- posting indices must be zero-based, contiguous, and in emitted order;
- duplicate generated source identities fail closed.

The public fixture must prove that two rows sharing one `txn_id` retain distinct source event identities.

## 7. Canonical transaction topology

For each admitted legacy row:

```text
one journal.tsv data row
  -> one native Journal transaction block
  -> two explicit ordered postings
```

The transaction must render:

- the original date;
- cleared status `*`;
- the exact admitted description;
- deterministic metadata;
- actual layer;
- debit posting to the legacy `to` account with positive exact integer JPY;
- credit posting to the legacy `from` account with the negative exact integer JPY;
- no implicit amount and no implicit balancing posting.

Rows sharing `txn_id` must not be merged.

## 8. Business `txn_id` and metadata

Reuse the completed profile-extension mapping contract.

The converter must map TSV spellings to supported Journal spellings exactly:

```text
tax           -> tax
biz           -> biz
invoice       -> invoice
note          -> note
due_on        -> due-on
receipt       -> receipt
txn_id        -> txn-id
party         -> party
plan_id       -> plan-id
cashflow      -> cashflow
currency      -> currency
income_budget -> income-budget
```

Requirements:

- preserve metadata absence as absence;
- reject empty values where the profile rejects them;
- reject duplicate keys;
- reject unknown keys;
- reject malformed controlled values;
- preserve supported Unicode values exactly;
- retain `txn_id` as optional business linkage;
- do not merge rows sharing `txn_id`;
- preserve metadata semantically independent of input column order.

Use one fixed canonical metadata order for output bytes:

```text
event-id
layer
tax
biz
invoice
note
due-on
receipt
txn-id
party
plan-id
cashflow
currency
income-budget
```

Omit absent optional metadata without emitting empty placeholders.

The implementation must demonstrate that reordering equivalent TSV metadata columns does not change canonical output bytes.

## 9. Currency boundary

This converter slice supports exact integer JPY legacy history only.

Rules:

- absent legacy `currency` metadata is admitted only through the established JPY compatibility/default contract;
- explicit `currency=JPY` maps to `currency: JPY` and explicit JPY posting commodities;
- `currency=ILS`, another currency, fractional amounts, or incompatible account currency fail closed;
- no FX conversion or currency normalization is authorized;
- no parser/profile currency expansion is authorized inside this converter slice.

Use a structured diagnostic for incompatible currency evidence. No prefix may be published.

## 10. Declaration preamble gate

The complete generated prefix must parse through the existing supported Journal parser. Therefore implementation must define a deterministic declaration preamble.

Before selecting the exact preamble, inspect the current account registry and Journal declaration contracts.

The implementation may proceed only if a public-synthetic account registry can be rendered so that:

- `commodity JPY` is declared exactly once;
- every account needed by the converted prefix and synthetic Journal-only suffix is declared exactly once;
- account keys resolve to the same canonical account keys as the legacy adapter;
- required supported account metadata is preserved;
- unsupported account metadata is not silently dropped when it affects parser, account resolution, accounting, envelope, or report semantics;
- declaration order is deterministic;
- identical account-registry semantics produce identical declaration bytes.

If the current Journal profile cannot represent required account-registry semantics, stop and report a separate account-declaration profile prerequisite. Do not weaken account metadata or validation inside the converter.

## 11. Deterministic bytes

The canonical output contract must specify and test:

- UTF-8 text;
- LF line endings;
- declaration order;
- transaction order;
- metadata order;
- posting order;
- four-space indentation;
- explicit signed integer amounts;
- explicit `JPY` commodity on every posting;
- exactly one blank line between top-level groups;
- exactly one final newline;
- locale-independent formatting;
- stable bytes for identical input snapshot bytes and identical account-registry semantics.

No timestamp, random value, absolute path, environment-dependent ordering, or mutable hash may enter canonical bytes.

## 12. Converter result boundary

The semantic owner must return an all-or-nothing result containing at least:

```text
state
canonical_prefix_bytes
diagnostics
validation_summary
```

On success:

- `state = ok`;
- canonical bytes are complete;
- diagnostics are empty;
- validation summary contains only non-sensitive structural counts and pass/fail dimensions.

On failure:

- `state = error`;
- canonical bytes are empty;
- at least one structured diagnostic exists;
- no output file is published.

Do not print source descriptions, metadata values, amounts, IDs, hashes, or private paths in machine-readable public-safe summaries used for later private verification.

## 13. Validation chain

Every complete generated prefix must pass unchanged existing boundaries:

```text
canonical prefix bytes
  -> journal_profile_stage1.Parse
  -> Transaction IR
  -> account resolver
  -> journal_posting_ir_stage2a.Build
  -> journal_posting_identity_provenance_stage2b.Build
```

The implementation must compare the legacy and Journal routes across independent dimensions:

### Accounting

- date;
- account keys;
- signed movements;
- debit-then-credit posting order;
- actual layer;
- cleared/ok status;
- transaction balance;
- downstream actual-layer Cube coordinates;
- TBDS actual rows;
- Trial Balance;
- Balances and selected supported report totals.

### Identity and provenance

- source file identity;
- physical source row evidence;
- canonical source event identity;
- posting index;
- posting identity;
- transaction order.

### Business links and metadata

- optional `txn_id`;
- every admitted metadata field;
- presence versus absence;
- description exact roundtrip.

Accounting parity alone is not success.

## 14. Output publication

The converter writes only to an explicitly supplied new prefix target.

Requirements:

- never default to the production Journal path;
- never target the preserved private candidate;
- refuse an existing output unless an explicit guarded replacement mode is separately authorized by the plan;
- construct in a temporary sibling path;
- parse and validate the complete temporary bytes;
- atomically publish only after all checks pass;
- leave the immutable TSV snapshot untouched;
- leave the existing candidate and suffix untouched.

Public implementation tests use temporary synthetic paths only.

## 15. Public-synthetic reconstruction helper

Implement a separate fail-closed reconstruction operation for public synthetic evidence:

```text
verified canonical prefix bytes
+
exact preserved synthetic suffix bytes
=
new reconstructed synthetic candidate
```

It must:

- require a separately verified prefix result;
- read suffix bytes without parsing and re-rendering them for the copy operation;
- copy suffix bytes exactly once;
- create a new output path;
- never edit either input in place;
- prove the suffix occurs exactly once in the reconstructed bytes;
- prove no suffix transaction is duplicated into the prefix fixture;
- parse and validate the complete reconstructed Journal;
- preserve suffix bytes byte-for-byte;
- fail without publishing on any mismatch.

This helper must not read or reconstruct the private candidate in the implementation PR.

## 16. Required public fixtures

Use invented evidence only. Cover at least:

- multiple legacy transaction rows;
- comments and blank lines affecting physical source evidence according to the current adapter;
- two rows sharing one business `txn_id` while remaining separate transactions;
- one row without `txn_id`;
- Unicode descriptions and metadata;
- internal repeated spaces in a valid description;
- every admitted metadata mapping;
- metadata absence;
- metadata input-order independence;
- exact integer JPY;
- deterministic source identities;
- deterministic prefix bytes;
- duplicate identity rejection;
- malformed TSV rejection;
- unknown account rejection;
- invalid date rejection;
- invalid amount rejection;
- description rejection cases;
- unknown, duplicate, empty, and malformed metadata rejection;
- `currency=ILS` rejection;
- synthetic multi-posting Journal-only suffix;
- exact-once suffix reconstruction;
- reconstruction failure without partial publish.

No private-derived fixture is allowed, even with values replaced.

## 17. Expected implementation surface

Inspect first. Expected candidates include:

```text
one new converter semantic owner
one explicit converter command or narrow tool entry
one reconstruction semantic owner or narrowly separated operation
existing legacy adapter helpers reused without production behavior change
existing Journal parser and Stage 2A/Stage 2B validation reused unchanged unless a stop is triggered
public synthetic fixtures
focused tests and checks
tools/check.sh registration
TODO.md
NEXT_SESSION.md
docs/README.md
completion archive
```

Production source loading, parser routing, report routing, writer defaults, Posting IR schema, Cube shape, TBDS shape, and private data are not authorized.

## 18. Stop conditions

Stop and report rather than simplify if implementation requires:

- trimming or normalizing descriptions;
- inventing a payee model;
- changing the legacy source-row identity convention;
- collapsing `txn_id` into source identity;
- merging rows sharing `txn_id`;
- silently dropping supported metadata;
- accepting arbitrary unknown metadata;
- supporting ILS or FX;
- weakening account-registry semantics;
- expanding parser grammar beyond the completed metadata prerequisite;
- changing the 16-field Posting IR schema;
- changing production routing, reports, or writers;
- reading or modifying private files;
- reconstructing the private candidate;
- cutover, dual writes, reverse sync, or automatic conflict resolution.

## 19. Validation commands

Run at minimum:

```text
focused converter tests
focused deterministic-render tests
focused description tests
focused identity/provenance tests
focused metadata tests
focused public reconstruction tests
git diff --check
checks/check-docs-lifecycle.sh
checks/check-absolute-links.sh
checks/check-repo-index.sh
rtk bash ./tools/check.sh
```

Verify the changed-file scope, prohibited-evidence scan, clean working tree, and local HEAD/remote branch SHA equality.

## 20. Completion and routing

On successful implementation:

1. Keep private conversion and reconstruction unperformed.
2. Archive the governing plan and this execution instruction under `docs/archive/completed-plans/`.
3. Update `TODO.md`, `NEXT_SESSION.md`, and `docs/README.md` in the same completion change.
4. Route Journal work explicitly to:

```text
no finite Journal slice selected
```

5. State that production source truth and reports remain TSV.
6. State that cutover remains blocked.
7. Do not select private verification, reconstruction, cutover, writer switching, or another Journal slice automatically.
8. Keep the implementation PR Draft until focused validation and independent review are complete.
9. Do not merge or delete the implementation branch without explicit owner instruction.

## 21. Required final report

Report:

```text
initial main/origin SHA
implementation branch
commit SHA
changed files
exact converter command surface
exact reconstruction command surface
public fixture coverage
description contract result
account declaration gate result
focused validation results
full tools/check.sh result
Draft PR number and URL
working tree status
remote branch SHA
local HEAD/remote equality
remaining gates
```
