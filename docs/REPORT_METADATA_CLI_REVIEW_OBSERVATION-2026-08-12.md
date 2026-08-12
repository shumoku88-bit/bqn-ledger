# Report Metadata CLI review observation — 2026-08-12

## Scope

Review `src/application/report_metadata_cli.bqn` as the source-independent CLI leaf over the already-reviewed Report section metadata owner.

## Observation

The CLI owns only two selections:

1. omitted arguments mean the default `tsv` format, while `--format FORMAT` supplies an explicit format;
2. admitted `tsv` / `json` selects the corresponding pure metadata formatter.

The previous implementation staged both decisions through mutable `format↩` and `text↩` variables. No source, accounting evidence, Report policy, or runtime context participates in either decision.

## Decision

Keep the CLI as a leaf and express both selections as values.

- `ParseFormat` validates the exact optional `--format FORMAT` argv shape lazily;
- no arguments select `tsv` directly;
- the existing supported-format guard remains explicit so its public error text is unchanged;
- `tsv` versus `json` selects the already-owned pure formatter lazily;
- final newline publication remains unchanged.

No formatter registry or generic CLI parser is introduced. Two stable formats do not justify another abstraction owner.

## Test and fixture classification

No new test or fixture is needed.

`checks/check-report-section-metadata.sh` already characterizes this complete leaf boundary:

- TSV output is byte-for-byte equal to the checked-in golden;
- JSON output is byte-for-byte equal to the checked-in golden;
- JSON exposes all twelve retained metadata rows with the exact schema;
- TSV keys equal retained catalog selection order;
- owner/category/publication metadata remains valid;
- retired report keys remain absent;
- invocation from an empty working directory preserves output;
- unsupported format fails;
- metadata/catalog/application owners are guarded against source/runtime dependencies.

Those checks are sufficient characterization plus architecture guards. Adding another fixture or a duplicate BQN unit around CLI argument plumbing would not add a distinct law.

## Protected boundaries

Unchanged:

- source independence;
- retained catalog order and metadata schema;
- TSV / JSON public bytes;
- default TSV behavior;
- `--format` syntax and unsupported-format failure;
- formatter ownership in `src/report/section_metadata.bqn`;
- absence of Household source/runtime dependencies;
- writer authority.
