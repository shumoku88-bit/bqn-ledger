# Journal converter leading-space admission relaxation

Status: completed public-synthetic test-only implementation
Owner: journal source migration / converter contract boundary
Canonical: no; current route: `../../../TODO.md`
Exit: archived; private converter execution and any later Journal slice require separate selection
Date: 2026-07-23

## Result

`journal_canonical_prefix_converter.DescriptionRepresentable` now admits a nonempty description when it has no trailing ASCII SPACE, C0 control, or DEL. One or multiple leading ASCII SPACEs are description-owned payload and are not trimmed, normalized, or removed.

`SafeValue` remains unchanged. Metadata values, account text, and source identity therefore retain their existing leading- and trailing-space rejection.

Public-synthetic rows prove exact conversion of both `" Leading synthetic description"` and a two-leading-space description. The canonical header is `date + " * " + exact description`; Stage 1 returns the exact description in Transaction IR. Converter state, Stage 1, Stage 2A, Stage 2B, description parity, accounting parity, identity parity, and metadata parity all pass.

## Retained rejection boundary

The converter continues to reject:

- empty descriptions;
- trailing ASCII SPACE;
- TAB, LF, CR, NUL, and all other C0 controls;
- DEL.

Ordinary UTF-8 descriptions and existing canonical converter bytes remain unchanged. Metadata admission, Transaction IR shape, the 16-field Posting IR shape, recur/series support, trailing-space policy, writer/editor behavior, production source truth, and production routing are unchanged.

## Validation

Passed with `LEDGER_DATA_DIR` unset where applicable:

```text
bqn tests/test_journal_canonical_prefix_converter.bqn
bqn tests/test_journal_leading_ascii_space_description_characterization.bqn
bqn tests/test_src_next_journal_profile_stage1.bqn
git diff --check
bash checks/check-docs-lifecycle.sh
bash checks/check-absolute-links.sh
bash checks/check-repo-index.sh
rtk bash ./tools/check.sh
```

No private path or data was accessed. The private converter was not run.

## Completion routing

```text
converter leading-space admission relaxation: completed
leading-space exact round-trip: passed
metadata admission: unchanged
private converter execution: not selected
production source truth: TSV
production report routing: TSV
production cutover: blocked
next finite slice: not selected
```
