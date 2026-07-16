# Report Section Descriptor Centralization Completion

Status: completed
Owner: report
Canonical: no; current runtime paths: src_next/report_sections.bqn, src_next/report_builder_order.bqn, src_next/report.bqn, src_next/report_section_metadata.bqn
Exit: retained as implementation and verification record; do not treat as future work authorization

## Summary

Report section static identity no longer has duplicate runtime ownership. A pure descriptor module now owns static identity and metadata fields, while executable builder ownership remains in `src_next/report.bqn`. The pure `src_next/report_builder_order.bqn` seam validates builder correspondence and orders valid builders into descriptor order. Metadata projection and formatting remain in `src_next/report_section_metadata.bqn`. Public output and report semantics did not change.

## Completed commits

- `8ab149b docs: plan report section descriptor centralization`
- `8ab4759 refactor: centralize report section descriptors`
- `80bbca55a1b6a75c2bac9ffc6007cf117766f7e4 fix: harden report section descriptor validation`

## Final ownership

| Path | Final ownership |
|---|---|
| `src_next/report_sections.bqn` | The 15 static section descriptors: canonical key/order, `label_spec`, category, owner path, and current human/structured metadata values. |
| `src_next/report_builder_order.bqn` | Pure duplicate/missing/extra/count validation, cause-specific diagnostic evidence, and canonical builder ordering. |
| `src_next/report.bqn` | Runtime section implementation imports, human builders, execution/rendering, JSON dispatch, first-line markers, CLI, and cache. |
| `src_next/report_section_metadata.bqn` | Descriptor-to-metadata projection, label resolution, TSV/JSON formatting, and metadata CLI. |
| `src_next/report_labels.bqn` | Configured label resolution and its existing fail-closed behavior. |
| `tests/test_src_next_report_sections.bqn` | Independent exact 15-row, six-field descriptor contract oracle. |
| `tests/fixtures/report_section_metadata_expected.tsv` | Independent exact resolved metadata contract oracle. It is not a runtime input. |
| `checks/check-report-section-metadata.sh` | Descriptor/runtime/metadata/public-contract verification, including exact TSV and JSON field-value checks. |

## Confirmed drift repaired

- Synchronized `daily-flow` into the current inventory in `docs/REPORT_CONTRACTS.md` at its runtime position.
- Added `issues` and `daily-flow` to explicit UI smoke required-key coverage.
- Synchronized current ownership routing across the code map and report section checklist.
- Improved builder mismatch failure evidence to distinguish duplicate, missing, extra, and count causes with key/count values.
- Made exact descriptor and resolved metadata contracts permanent executable verification.

## Validation hardening

The production pure validator now performs correct adjacent key-string duplicate detection. Persistent tests directly exercise the production seam for:

- duplicate;
- missing;
- extra;
- count mismatch;
- duplicate plus missing;
- extra plus missing; and
- reordered valid builders.

Invalid inputs remain fail closed, combined causes remain visible, and valid reordered builders return in canonical descriptor order.

## Output equivalence

Independent comparisons between the pre-implementation state and the completed implementation found exact agreement for:

- `tools/report --list-sections`;
- metadata TSV;
- metadata JSON;
- the full human report;
- `snapshot`;
- `daily-flow`;
- `debug`;
- cache inventory; and
- all 16 cache contents.

Normal-path public output differences were zero.

## Verification

The following all passed:

- descriptor exact contract test;
- builder-order failure-path test;
- metadata exact contract check;
- structured UI boundary check;
- UI smoke check;
- src_next report check;
- metadata TSV/JSON with an invalid `LEDGER_DATA_DIR`;
- repo-index diff;
- git diff check; and
- full `tools/check.sh`.

## Privacy and migration boundary

Verification used repository fixtures only. No private production data was accessed. No source TSV migration or config migration was performed.

## Final review

Final verdict: `approve-with-follow-up`.

There were no blocker, high, or medium findings. The remaining low finding—missing `src_next/report_builder_order.bqn` ownership routing in `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md`—was corrected in this docs-only completion slice.

## Explicitly not selected

The following remain unselected and are not authorized by this completion:

- changing the meaning of the `structured_output` column;
- metadata schema or value changes;
- unifying the metadata serializer with `src_next/json.bqn`;
- additional section-specific JSON ViewModels;
- Outlook / `actual_snapshot`;
- report-wide `as_of`;
- the next projection-alignment slice;
- generic plugin architecture;
- UI redesign; and
- splitting `context.bqn`.

Do not automatically start any of these from this completion record.

## Result

```text
completed
```
