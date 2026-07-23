# Journal header delimiter exact-consumption implementation

Status: completed public-synthetic test-only implementation
Owner: journal source migration / parser contract boundary
Canonical: no; current route: `../../../TODO.md`
Exit: archived; converter admission and any later Journal slice require separate selection
Date: 2026-07-23

## Result

The previous observed classification was `silent_normalization`. Stage 1 now preserves a Journal transaction description exactly after consuming the required marker delimiter.

The header rule for this finite slice is:

```text
YYYY-MM-DD + one ASCII SPACE + (* or !) + one ASCII SPACE delimiter + description payload
```

After reading the status marker, the parser verifies one ASCII SPACE, consumes exactly that character, and stores all remaining description payload in Transaction IR. Therefore `* Normal`, `*  Leading`, and `*   Two leading spaces` produce `Normal`, ` Leading`, and `  Two leading spaces` respectively.

A missing marker delimiter is rejected with `header_description_delimiter_missing`. A present delimiter followed by an empty payload retains `header_description_missing`. Existing whole-line trailing trim behavior is unchanged.

## Unchanged boundaries

- Transaction IR shape is unchanged; only its existing `description` value is preserved exactly at this boundary.
- Stage 2A remains successful and retains its existing description-free 16-field Posting IR shape.
- `converter.DescriptionRepresentable` still returns false for leading-space legacy descriptions.
- Converter conversion still rejects them with `description_not_canonically_representable`.
- Metadata parsing, posting parsing, writer/serializer behavior, production source truth, and production routing are unchanged.
- Production source truth and report routing remain TSV; cutover remains blocked.
- No private path, source, value, hash, conversion, or reconstruction was accessed.

## Validation

Passed with `LEDGER_DATA_DIR` unset where applicable:

```text
bqn tests/test_journal_leading_ascii_space_description_characterization.bqn
bqn tests/test_src_next_journal_profile_stage1.bqn
bqn tests/test_journal_canonical_prefix_converter.bqn
bqn tests/test_journal_posting_ir_adapter_stage2a.bqn
git diff --check
bash checks/check-docs-lifecycle.sh
bash checks/check-absolute-links.sh
bash checks/check-repo-index.sh
rtk bash ./tools/check.sh
```

The repository's real Stage 1 and Stage 2A test paths are `tests/test_src_next_journal_profile_stage1.bqn` and `tests/test_journal_posting_ir_adapter_stage2a.bqn`.

## Completion routing

```text
previous classification: silent_normalization
new behavior: exact preservation
parser delimiter implementation: completed
converter admission relaxation: not selected
private converter retry: not selected
production source truth: TSV
production report routing: TSV
production cutover: blocked
next finite slice: not selected
```
