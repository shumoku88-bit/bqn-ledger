# Journal opaque legacy metadata preservation

Status: completed public-synthetic test-only implementation
Owner: journal source migration / converter contract boundary
Canonical: no; current route: `../../../TODO.md`
Exit: archived; private converter execution and any later Journal slice require separate selection
Date: 2026-07-23

## Result

The public-synthetic canonical prefix converter explicitly admits the legacy TSV metadata keys `recur` and `series`. It preserves each admitted value exactly under the existing `SafeValue` boundary and renders the original key names in deterministic order after all previously supported metadata:

```journal
; recur: <value>
; series: <value>
```

Stage 1 admits the same two keys and stores their exact key/value pairs only in generic `transaction.metadata`. No dedicated Transaction IR field or Posting IR field was added. Stage 2A retains its 16-field shape.

## Opaque boundary

`recur` and `series` receive no date, cycle, recurrence, identifier, or other semantic interpretation in this path. Their values are not checked against `config/meta_schema.tsv` enum or plan behavior. They do not affect postings, accounting calculations, identity, report routing, or writer/editor behavior.

The allowlist expansion is limited to these two keys. Completely unknown metadata such as `mystery=value` remains rejected. Duplicate keys, empty values, leading or trailing ASCII SPACE, C0 controls, and DEL remain rejected by the converter. Existing validation for semantic metadata such as `tax`, `biz`, `invoice`, `due-on`, `cashflow`, `currency`, and `income-budget` is unchanged.

## Public-synthetic evidence

A synthetic TSV transaction carries both:

```text
recur=synthetic-cycle
series=synthetic-series
```

The converter returns `ok` with no `metadata_unknown` diagnostic. Canonical Journal bytes contain both exact values. Stage 1 returns both exact generic metadata entries. Reversing TSV metadata order produces identical canonical bytes. Focused red paths cover duplicate `recur`, duplicate `series`, empty `recur`, unsafe `recur`, trailing-space `series`, DEL in `series`, and retained unknown-key rejection.

Description, metadata, accounting, and identity parity pass. Stage 2A and Stage 2B pass without IR shape changes.

## Validation

Passed with `LEDGER_DATA_DIR` unset where applicable:

```text
bqn tests/test_journal_canonical_prefix_converter.bqn
bqn tests/test_src_next_journal_profile_stage1.bqn
bqn tests/test_journal_leading_ascii_space_description_characterization.bqn
git diff --check
bash checks/check-docs-lifecycle.sh
bash checks/check-absolute-links.sh
bash checks/check-repo-index.sh
rtk bash ./tools/check.sh
```

No private path or data was accessed. No private converter, prefix generation, or reconstruction was run.

## Completion routing

```text
recur / series exact preservation: passed
opaque boundary: retained
semantic interpretation: none
fixed output order: recur, series after existing metadata
unknown-key rejection: retained
metadata parity: passed
production source truth: TSV
production report routing: unchanged
private execution: none
next finite slice: not selected
```
