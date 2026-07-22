# Journal canonical TSV-to-native prefix converter completion

Status: completed
Owner: journal source migration / conversion
Canonical: no; current route: `../../../TODO.md`
Exit: archived; no finite Journal slice is selected
Date: 2026-07-22

## Selection and repository evidence

The owner explicitly selected converter resumption after PR #324's Journal report-coverage audit. The implementation started from remote `main` SHA `ed0f0add1a22fbdad255135d1b61292f1bc884bd` on replacement branch `feat/journal-canonical-tsv-native-prefix-converter-replacement`.

The stopped branch existed locally at `d6f497fab67ca640f663c53e692aad2431d83353` and was absent remotely. The evidence commit existed and was an ancestor of `origin/main`. The old branch was not switched to, changed, rebased, merged, deleted, or used as the replacement base.

## Implemented surface

- Pure semantic owner: `src_next/journal_canonical_prefix_converter.bqn`.
  - `Convert ⟨snapshotRaw, sourceFileIdentity, accountLines, cycleStart⟩`
  - `Reconstruct ⟨verifiedPrefixResult, suffixBytes, resolvedAccounts, cycleStart⟩`
  - all-or-nothing state, canonical bytes, structured privacy-safe diagnostics, structural validation summary, and focused evidence carriers.
- Narrow file adapter: `src_edit/journal_prefix_converter_cmd.bqn`.
- Explicit command: `tools/journal-prefix`.
  - `convert ACCOUNTS_TSV SNAPSHOT_TSV SOURCE_FILE_IDENTITY CYCLE_START OUTPUT`
  - `reconstruct ACCOUNTS_TSV SNAPSHOT_TSV SOURCE_FILE_IDENTITY CYCLE_START VERIFIED_PREFIX SUFFIX OUTPUT`
- Public evidence: `tests/test_journal_canonical_prefix_converter.bqn` and `checks/check-journal-canonical-prefix-converter.sh`.

No existing parser, account resolver, Stage 2A, Stage 2B, Posting IR, Cube, TBDS, report, production context, or writer semantic owner required modification. `tools/check.sh` changed only to register the focused check.

## Canonical converter contract

One admitted legacy row becomes one durable native Journal transaction with two explicit ordered postings: debit first and credit second. Transaction-row order is preserved and rows sharing one business `txn_id` are not merged. Each transaction balances exactly and every posting renders an explicit signed integer and explicit `JPY`.

Descriptions are nonempty exact Unicode sequences with internal and repeated spaces preserved. Empty text, leading/trailing ASCII space, TAB, LF, CR, NUL, other C0 controls, and DEL are rejected as `description_not_canonically_representable`. The converter performs no trim, normalization, Unicode normalization, payee split, or silent rewrite.

Canonical source identity is `legacy:<source_file_identity>:<zero-based admitted source_row>`. The indexing matches `loader.ReadLines`: comments and blank lines do not enter the admitted row array. Posting IDs are the source identity plus zero-based contiguous `:0` and `:1`. `txn_id` remains separate business metadata, and duplicate canonical identities fail closed.

The fixed metadata mapping is:

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

Output order is `event-id`, `layer`, then the mapped fields in the table order. Absence remains absence. Input order does not affect bytes. Unknown, duplicate, empty, unsafe, and malformed controlled metadata fails closed.

The boundary is exact integer JPY only. Missing currency uses the established legacy JPY compatibility lane; explicit `currency=JPY` is retained. Fractional amounts, ILS, other currencies, zero/nonpositive source amounts, and incompatible account currency are rejected.

The declaration preamble emits `commodity JPY` exactly once and every registry account exactly once in lexical account-name order. Supported declaration metadata is emitted deterministically as `role`, `kind`, and the existing account `budget` semantic mapped to `default-envelope`. Stage 2A continues to resolve against the explicit unchanged account registry; there is no automatic account creation or fallback.

Canonical bytes use UTF-8 text supplied by CBQN, LF, four-space indentation, explicit signed integers, explicit JPY, deterministic declarations/transactions/metadata/postings, one blank line between top-level groups, and one final newline. They contain no timestamp, random value, absolute path, locale ordering, or environment-dependent value.

## Validation and parity

Every complete prefix is validated with:

```text
journal_profile_stage1.ParseWithProfile historical_external_plan
  -> unchanged Transaction IR
  -> unchanged account resolver
  -> journal_posting_ir_stage2a.Build
  -> journal_posting_identity_provenance_stage2b.Build
```

Default `Parse` remains strict and is separately asserted to reject the synthetic external `plan-id`; no parser profile or grammar was changed. Transaction IR is unchanged and Posting IR remains 16 fields.

The public fixture proves accounting parity for dates, account keys, signed movements, debit/credit order, actual layer, ok/cleared status, exact balance, Cube, TBDS, actual Trial Balance, and Balances. It separately proves canonical source identity, admitted source row, source event identity, posting index/ID, transaction order, shared-versus-absent `txn_id`, every mapped metadata field, presence/absence, and exact description roundtrip.

Failure evidence covers malformed/fewer-field TSV, invalid date and amount, unknown account, duplicate source identity, all description boundaries, unknown/duplicate/empty/malformed metadata, ILS, existing output, and concurrent publication. Every semantic failure returns empty canonical bytes, and every command failure publishes no converter bytes.

## Atomic publication and reconstruction

`tools/journal-prefix` requires every input and output path explicitly, refuses an existing target, stages complete bytes in a temporary sibling, verifies the semantic result and staged bytes, checks immutable inputs for change, and publishes by exclusive same-filesystem hard link. A concurrent target wins without replacement; no partial converter output is published.

Reconstruction is a separate operation. It reconverts the supplied immutable snapshot, requires the supplied verified prefix to match those canonical bytes exactly, copies suffix bytes without rendering, proves exact-once suffix occurrence and nonduplicate suffix event identity, parses and validates the complete candidate through Stage 2A and Stage 2B, and publishes only a new target. Public evidence uses a synthetic native three-posting suffix and proves byte-for-byte suffix preservation. Failure leaves no reconstructed output.

## Public fixture inventory

All values are invented public data. Coverage includes multiple rows, comments, blank lines, zero-based admitted-row semantics, shared and absent `txn_id`, Unicode, punctuation, repeated internal spaces, every admitted metadata mapping, metadata absence and input-order independence, deterministic JPY bytes/identities/posting IDs, an external historical plan reference, strict-default profile behavior, malformed input classes, and exact synthetic suffix reconstruction. No fixture is private-derived or obtained by replacing private values.

## Validation results

Focused unit and command checks passed:

```text
bqn tests/test_journal_canonical_prefix_converter.bqn
rtk bash checks/check-journal-canonical-prefix-converter.sh
```

Completion validation also passed:

```text
git diff --check
bash checks/check-docs-lifecycle.sh
bash checks/check-absolute-links.sh
bash checks/check-repo-index.sh
rtk bash ./tools/check.sh
```

`rtk` was available; no fallback invocation was needed.

## Changed files and privacy review

Implementation and routing changes are limited to the converter semantic owner, narrow command adapter, explicit shell command, public focused test/check, check registration, archived plan/instructions, this completion record, and current routing/index docs (`TODO.md`, `NEXT_SESSION.md`, `docs/README.md`, `docs/AI_CODEMAP.md`).

The prohibited-evidence scan found no local absolute path, private source-directory name, rehearsal directory name, private hash, ID, amount, description, or metadata value. No private path was listed, statted, hashed, read, converted, reconstructed, or used to derive public evidence.

## Unchanged production boundary and final routing

```text
production source truth: TSV
production report routing: TSV
production writer default: unchanged
private conversion: not performed
private reconstruction: not performed
production cutover: blocked
final routing: no finite Journal slice selected
```

This completion does not select private read-only verification, private conversion, private reconstruction, cutover, writer switching, report routing, one-report Journal parity, or another Journal slice.
