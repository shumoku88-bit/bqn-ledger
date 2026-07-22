# Journal Canonical TSV-to-Native Prefix Converter Implementation Instructions

Status: active execution instructions for the selected converter slice
Owner: journal source migration / conversion
Canonical: no; governing plan is `docs/JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_PLAN.md`
Date: 2026-07-22
Exit: archive with converter completion, return routing to no selected Journal slice, and do not select cutover automatically

## 1. Finite implementation question

> Can the repository implement a deterministic one-way converter from an immutable legacy `journal.tsv` snapshot to a verified native Journal historical prefix, preserving exact accounting movements, admitted description semantics, canonical physical source identity, optional business `txn_id`, supported metadata, transaction and posting order, actual layer, cleared status, and diagnostics, while also proving public-synthetic byte-preserving suffix reconstruction without changing production routing, private files, or cutover state?

This is execution guidance for the already-selected converter. It does not select another slice.

## 2. Starting gate

The implementation branch must start from the current remote `main` **after the PR containing this instruction is merged**.

Before editing:

1. Fetch remote state.
2. Verify local `main`, `origin/main`, and remote `main` resolve to the same SHA.
3. Record that SHA in the implementation report.
4. Verify the working tree is clean.
5. Verify current `main` contains:
   - PR #320's completed metadata/profile prerequisite;
   - this implementation instruction;
   - the canonical converter plan.
6. Read `TODO.md`, `NEXT_SESSION.md`, the canonical plan, this instruction, the completed prerequisite, the current TSV adapter, Journal parser, Stage 2A, Stage 2B, account resolver, loader, safe-write helpers, and focused tests.
7. Confirm no private candidate, TSV snapshot, suffix, value, ID, hash, manifest, or absolute path will be read or committed.

If the three `main` SHAs differ, stop and report. Do not guess an expected SHA from this document.

## 3. Branch and PR

Use a separate implementation branch, provisionally:

```text
feat/journal-canonical-tsv-native-prefix-converter
```

Open the implementation PR as Draft.

Do not combine production cutover, default-writer changes, production source routing, report routing, private conversion, or private reconstruction into that PR.

## 4. Owner decision: exact description preservation

The converter must not trim, normalize, rewrite, split, or reinterpret TSV column 2.

A description is canonically representable only when:

- it is nonempty;
- it contains no TAB, LF, CR, NUL, other C0 control character, or DEL;
- it has no leading or trailing ASCII space;
- rendering it in the Journal header and parsing the complete generated Journal returns the exact same Unicode code-point sequence;
- no Unicode normalization occurs;
- no payee/description split is introduced.

Internal spaces, punctuation, and supported Unicode remain unchanged.

If any row fails, return:

```text
description_not_canonically_representable
```

Publish no prefix. Do not call `Trim`, `strip`, or reuse `tools/to-hledger` normalization as canonical semantics.

Public tests must cover Unicode, repeated internal spaces, leading/trailing-space rejection, empty rejection, control rejection, and exact parse roundtrip.

## 5. Legacy row admission

Accept only admitted `journal.tsv` transaction rows from an immutable snapshot.

Requirements:

- preserve transaction-row order;
- preserve the existing adapter's physical source-row evidence;
- follow existing comment and blank-line behavior exactly;
- retain their effect on physical row numbering when the adapter does;
- reject malformed non-comment rows;
- reject fewer than five required fields;
- reject invalid dates, amounts, accounts, currency, descriptions, and metadata;
- publish no partial prefix.

Do not invent another row-numbering convention.

## 6. Source identity

Derive one deterministic source identity per admitted row using the established contract:

```text
legacy:<source_file_identity>:<physical_source_row>
```

The implementation must determine the exact existing indexing semantics from adapter evidence and tests.

Rules:

- no absolute path in identity;
- `txn_id` never becomes source identity;
- descriptions, amounts, and content hashes do not determine identity;
- posting IDs derive from source identity plus zero-based contiguous posting index;
- duplicate source identities fail closed.

Two rows sharing one `txn_id` must retain distinct source identities.

## 7. Canonical topology

```text
one admitted journal.tsv row
  -> one native Journal transaction block
  -> two explicit ordered postings
```

Render:

- original date;
- cleared marker `*`;
- exact admitted description;
- generated `event-id`;
- `layer: actual`;
- admitted optional metadata;
- debit posting to legacy `to` with positive exact integer JPY;
- credit posting to legacy `from` with negative exact integer JPY.

Use no implicit balancing posting. Never merge rows sharing `txn_id`.

## 8. Metadata mapping and order

Reuse the completed profile mapping:

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

Output metadata in this fixed order:

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

Omit absent optional fields. Preserve absence as absence. Reject duplicates, unknown keys, empty values where prohibited, and malformed controlled values.

Equivalent TSV metadata column order must produce identical canonical bytes.

## 9. Currency boundary

This slice supports exact integer JPY only.

- absent currency metadata may pass only through the established JPY compatibility/default contract;
- explicit `currency=JPY` is retained and postings use explicit `JPY`;
- `currency=ILS`, other currencies, fractional amounts, or incompatible account currency fail closed;
- no FX, normalization, or currency-profile expansion is authorized.

No prefix is published on currency failure.

## 10. Declaration preamble gate

The complete generated prefix must parse through the unchanged supported Journal parser, so implementation must prove a deterministic declaration preamble.

Proceed only if public-synthetic evidence proves:

- `commodity JPY` exactly once;
- every account needed by the prefix and synthetic suffix declared exactly once;
- identical account keys and resolver semantics on both routes;
- required supported account metadata preserved;
- no accounting, resolver, envelope, or report-relevant account metadata silently dropped;
- deterministic declaration order and bytes.

If the profile cannot represent required account-registry semantics, stop and report a separate account-declaration prerequisite. Do not weaken the registry or parser inside the converter.

## 11. Deterministic bytes

Fix and test:

- UTF-8;
- LF line endings;
- deterministic declarations, transactions, metadata, and postings;
- four-space indentation;
- explicit signed integer amounts;
- explicit `JPY` on every posting;
- one blank line between top-level groups;
- one final newline;
- locale-independent formatting;
- no timestamp, random value, absolute path, mutable hash, or environment-dependent ordering.

Identical snapshot bytes and identical account-registry semantics must produce identical prefix bytes.

## 12. All-or-nothing result

The semantic owner returns at least:

```text
state
canonical_prefix_bytes
diagnostics
validation_summary
```

Success:

- `state = ok`;
- complete bytes present;
- diagnostics empty.

Failure:

- `state = error`;
- canonical bytes empty;
- structured diagnostics present;
- no file published.

The non-sensitive validation summary may contain structural counts and pass/fail dimensions only. It must not expose source descriptions, metadata values, amounts, IDs, hashes, or private paths.

## 13. Required validation chain

```text
canonical prefix
  -> journal_profile_stage1.Parse
  -> Transaction IR
  -> account resolver
  -> journal_posting_ir_stage2a.Build
  -> journal_posting_identity_provenance_stage2b.Build
```

Compare legacy and Journal routes independently across:

### Accounting

- date;
- account keys;
- signed movements;
- debit-then-credit order;
- actual layer;
- cleared/ok status;
- balance;
- actual-layer Cube coordinates;
- TBDS actual rows;
- Trial Balance;
- Balances and selected supported totals.

### Identity and provenance

- source file identity;
- physical row evidence;
- source event identity;
- posting index and ID;
- transaction order.

### Business and source meaning

- optional `txn_id`;
- every admitted metadata field;
- presence versus absence;
- exact description roundtrip.

Accounting parity alone is insufficient.

## 14. Prefix publication

Write only to an explicitly supplied new prefix target.

- never default to production paths;
- never target the preserved candidate;
- refuse existing targets unless a separately authorized guarded mode exists;
- construct in a temporary sibling;
- validate complete temporary bytes;
- atomically publish only after every gate passes;
- leave TSV, current candidate, and suffix unchanged.

Public tests use temporary synthetic paths only.

## 15. Public-synthetic reconstruction

Implement a separate fail-closed operation:

```text
verified canonical prefix bytes
+
exact preserved synthetic suffix bytes
=
new reconstructed synthetic candidate
```

It must:

- require a verified prefix result;
- copy suffix bytes without re-rendering;
- create a new target;
- edit neither input;
- prove suffix bytes occur exactly once;
- prove no synthetic suffix transaction is duplicated into the prefix;
- parse and validate the complete result;
- preserve suffix bytes byte-for-byte;
- publish nothing on failure.

Do not read or reconstruct private files in the implementation PR.

## 16. Required public evidence

Use invented data only. Cover at least:

- multiple TSV rows;
- comments and blank lines under current physical-row semantics;
- shared `txn_id` with separate transactions;
- absent `txn_id` fallback;
- Unicode and repeated internal spaces;
- every admitted metadata mapping;
- metadata absence and input-order independence;
- exact integer JPY;
- deterministic identity and bytes;
- malformed TSV, unknown account, invalid date and amount;
- all description rejection cases;
- unknown, duplicate, empty, and malformed metadata;
- `currency=ILS` rejection;
- synthetic multi-posting suffix;
- exact-once reconstruction;
- reconstruction failure with no partial output.

No private-derived fixture is allowed, even after replacing values.

## 17. Expected implementation surface

Inspect first. Likely candidates:

```text
new converter semantic owner
narrow converter command
distinct reconstruction operation
reused legacy adapter helpers
unchanged parser and Stage 2A/Stage 2B validation
public synthetic fixtures
focused tests and checks
tools/check.sh registration
TODO.md
NEXT_SESSION.md
docs/README.md
completion archive
```

Production loading, production parser routing, reports, writer defaults, Posting IR schema, Cube, TBDS, and private data are not authorized.

## 18. Stop conditions

Stop rather than simplify if work requires:

- description trimming or normalization;
- a new payee model;
- another source-row identity convention;
- collapsing `txn_id` into source identity;
- merging rows sharing `txn_id`;
- dropping supported metadata;
- accepting arbitrary metadata;
- ILS or FX support;
- weakened account-registry semantics;
- parser expansion beyond the completed metadata prerequisite;
- Posting IR schema change;
- production routing, report, or writer changes;
- private file access or reconstruction;
- cutover, dual writes, reverse sync, or conflict resolution.

## 19. Validation

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

Verify changed-file scope, prohibited-evidence scan, clean working tree, and local HEAD/remote branch SHA equality.

## 20. Completion routing

On success:

1. Perform no private conversion or reconstruction.
2. Archive the canonical plan and this instruction under `docs/archive/completed-plans/`.
3. Update `TODO.md`, `NEXT_SESSION.md`, and `docs/README.md` in the same completion change.
4. Route explicitly to:

```text
no finite Journal slice selected
```

5. State production source truth and reports remain TSV.
6. State cutover remains blocked.
7. Do not select private verification, reconstruction, cutover, writer switching, or another Journal slice automatically.
8. Keep the implementation PR Draft until validation and independent review are complete.
9. Do not merge or delete the implementation branch without explicit owner instruction.

## 21. Final report

Report:

```text
initial local/main/origin SHA
implementation branch
commit SHA
changed files
converter command surface
reconstruction command surface
public fixture coverage
description result
account declaration gate result
focused validation
full tools/check.sh result
Draft PR number and URL
working tree status
remote branch SHA
local HEAD/remote equality
remaining gates
```
