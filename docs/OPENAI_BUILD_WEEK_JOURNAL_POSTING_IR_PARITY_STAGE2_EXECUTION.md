# OpenAI Build Week: Journal Posting IR Adapter Parity Stage 2 Execution Record

Status: active plan
Owner: workflow
Canonical: no; canonical routing remains `TODO.md`
Exit: move to `docs/archive/completed-plans/` after the selected implementation is merged and the Build Week submission evidence is recorded
Date: 2026-07-18

## 1. Purpose

This record fixes the exact Codex-owned implementation slice for the OpenAI Build Week submission before the primary Codex session begins.

The project already existed before the hackathon. The submission must therefore distinguish existing `bqn-ledger` work from the meaningful extension built for Build Week. Only work after the core baseline below may be presented as the selected Build Week implementation.

## 2. Registration and baseline

- OpenAI Build Week registration: complete on 2026-07-18
- Entrant type: individual
- Submission deadline: 2026-07-22 09:00 JST
- Repository: `shumoku88-bit/bqn-ledger`
- Core implementation baseline: `9af8f307af6270436f5a3493e7ad92296904a6b2`
- Baseline commit title: `docs: select Build Week submission work (#285)`

The Stage 0 profile, Stage 1 parser, accounting matrix studies, existing TSV Posting IR path, reports, editor, and all commits at or before the baseline are pre-existing work. They may be shown as context, but they must not be described as functionality built by Codex for this submission.

## 3. Selected Codex-owned core slice

Build a bounded, test-only parity gate:

```text
Minimal Journal text
  -> existing Stage 1 parser
  -> Journal Transaction IR
  -> new Journal Posting IR adapter
  -> semantic parity comparator

public synthetic TSV
  -> existing checked TSV Posting IR path
  -> semantic parity comparator

comparator
  -> human-readable parity report
  -> process exit status
```

The existing TSV reference path is:

```text
src_next/context.bqn
  BuildCheckedPostingProjectionFromSnapshot
```

The journal input boundary is:

```text
src_next/journal_profile_stage1.bqn
  Parse
```

## 4. Common subset

Parity covers only journal transactions representable by one current TSV source row:

- exactly two postings;
- exactly one positive debit and one negative credit;
- one supported JPY commodity;
- `actual` or `plan` layer;
- explicit durable `event-id`;
- the same event identity carried by the TSV source id and `txn_id` metadata;
- accounts declared in both the journal profile and `accounts.tsv`.

Native journal multi-posting events are not flattened. A transaction outside this common subset must return an explicit unsupported or error result rather than silently changing its accounting meaning.

## 5. Journal Transaction IR to Posting IR mapping

The new adapter produces the current Posting IR row shape without changing the current contract.

| Posting IR field | Journal source |
|---|---|
| `source_file` | caller-supplied public fixture label such as `profile.journal` |
| `source_row` | zero-based physical transaction start line derived from `source_start_line` |
| `source_id` | `source_event_id` |
| `tx_id` | `source_event_id` for this bounded slice |
| `posting_id` | existing deterministic Stage 1 posting id |
| `date` | transaction date |
| `day_index` | current date resolver relative to supplied cycle start |
| `account_key` | posting account key |
| `account_key_index` | resolved account-key index |
| `layer_name` | transaction layer |
| `layer_index` | current `actual` / `plan` layer mapping |
| `side` | existing Stage 1 posting side |
| `delta` | existing signed posting delta |
| `kind` | current role-based `projection.InferKind` policy |
| `status` | `ok` for admitted rows |
| `message` | empty for admitted rows |

The adapter must return a checked result with `state`, `posting_rows`, and `diagnostics`. It must emit no posting rows when parser evidence, account resolution, layer resolution, date resolution, common-subset shape, or balance validation fails.

## 6. Parity policy

### Exact semantic equality

For paired postings, compare these fields exactly:

- `source_id`;
- `tx_id`;
- `date`;
- `day_index`;
- `account_key`;
- `account_key_index`;
- `layer_name`;
- `layer_index`;
- `side`;
- `delta`;
- `kind`;
- `status`.

Pair postings by the common-subset key:

```text
source_id + side
```

The comparator must first prove that this key is one-to-one on both sides. Duplicate keys, missing pairs, extra pairs, or unsupported posting shapes fail closed.

### Identity correspondence

Raw posting ids are not required to be textually identical because the two source formats preserve different physical provenance. Instead verify that:

- source and transaction identities correspond through the shared durable event id;
- posting ids are nonempty and unique within each path;
- each paired debit and credit has a deterministic identity in its own source path;
- the two paired postings belong to the same semantic event and side.

### Provenance preservation

Do not erase source differences to manufacture equality.

- Journal rows preserve the journal fixture label and journal source line.
- TSV rows preserve the TSV source file and TSV source row.
- The report states that physical provenance differs by source while semantic accounting parity passes.

## 7. Public synthetic fixture

Add one success fixture directory containing:

- `profile.journal`;
- `accounts.tsv`;
- `journal.tsv`;
- `plan.tsv`;
- an optional empty `budget_alloc.tsv` only if required by the current loader contract;
- a short fixture README.

The success fixture should contain a small hand-checkable set such as:

1. actual expense;
2. actual income;
3. actual asset transfer;
4. planned expense.

Each journal event id must equal the matching TSV source id, and each matching TSV row must carry `txn_id=<event-id>`.

Add one public synthetic mismatch fixture or an equivalent deterministic test input where both sides are individually valid but one signed amount differs. It must exercise the field-level mismatch report and nonzero exit status.

## 8. Runnable interface

Provide one documented command, with final naming chosen consistently during implementation. Preferred command:

```text
tools/journal-posting-ir-parity fixtures/journal-posting-ir-parity-stage2
```

Successful output should make the gate legible without reading test code:

```text
Journal Posting IR Parity

Journal parse                 PASS
Journal adapter               PASS
TSV checked projection        PASS
Transaction identity          PASS
Posting correspondence        PASS
Signed accounting fields      PASS
Source provenance preserved   PASS

Result: PARITY
```

A valid-but-different fixture must identify at least:

- event identity;
- posting side or account;
- field name;
- expected TSV value;
- actual journal value.

Exit status:

- `0`: parity;
- nonzero: parse, adapter, checked TSV projection, unsupported common-subset shape, or semantic mismatch.

No JSON format, web UI, server, database, or network service is required for this slice.

## 9. Expected implementation surfaces

The implementation may choose equivalent names, but should remain close to this finite shape:

- one test-only Journal Transaction IR to Posting IR adapter module;
- one parity comparison and formatting module or a clearly separated section in the adapter module;
- one runnable tool entry point;
- one focused BQN test file;
- success and mismatch public fixtures;
- one short English testing section for the Build Week submission path.

Do not refactor the existing Stage 1 parser, current TSV projection path, accounting matrix tests, Cube, TBDS, reports, or editor merely to make the new files look generic.

## 10. Fail-closed tests

Focused tests must cover at least:

- successful exact semantic parity;
- valid source mismatch with a field-level diagnostic;
- parser rejection produces no adapted rows;
- unknown resolved account produces no adapted rows;
- unsupported multi-posting journal transaction is not flattened;
- duplicate or missing `source_id + side` pairing fails;
- posting ids are nonempty and unique on each side;
- each admitted event remains zero-sum;
- success command exits `0`;
- mismatch command exits nonzero.

## 11. Codex and owner boundary

The majority of the adapter, comparator, runnable report, fixtures, and focused tests must be built in one primary Codex thread using GPT-5.6. Retrieve and preserve that thread's `/feedback` Session ID.

Owner-controlled work includes:

- choosing this accounting and migration scope;
- defining the common subset and parity policy;
- source-truth, privacy, production, and cutover decisions;
- reviewing the generated code and accounting behavior;
- deciding whether the completed PR is acceptable;
- writing the final project description in the owner's own voice.

Normal pi-agent planning or review must not be represented as Codex work.

## 12. Non-goals and hard boundaries

- no production journal read activation;
- no private ledger data;
- no source TSV conversion or mutation;
- no journal writer;
- no dual write or reverse synchronization;
- no source cutover;
- no Cube, TBDS, report, or editor connection;
- no arbitrary hledger parser expansion;
- no multi-currency expansion;
- no silent multi-posting flattening;
- no automatic repair of rejected evidence;
- no broad common fixture framework extraction;
- no web UI added solely for the hackathon.

## 13. Validation and acceptance

Before opening the implementation PR:

```text
focused adapter/parity tests
existing Stage 1 parser test
existing bookkeeping matrix tests
bash tools/check.sh
bash tools/coverage
git diff --check origin/main...HEAD
```

The implementation slice is complete when:

- the public success command visibly reports parity and exits `0`;
- the public mismatch command visibly reports the exact difference and exits nonzero;
- the adapter and comparator remain test-only and production-disconnected;
- all focused and repository checks pass;
- the implementation diff is clearly after baseline `9af8f307af6270436f5a3493e7ad92296904a6b2`;
- the primary Codex `/feedback` Session ID is saved outside private data;
- README material accurately distinguishes pre-existing work, Codex-built extension, and owner decisions.

## 14. Start gate

Do not begin the primary Codex implementation session until this execution record is reviewed and merged.

After merge, create a fresh implementation branch from the resulting `main`, start one primary Codex GPT-5.6 thread, and use this document plus the referenced current contracts as the bounded build instruction.
