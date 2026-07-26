# projection date ownership P3c — 2026-07-26

Status: implementation evidence
Owner: date / report-facing dependency boundary
Baseline: `d97fcd3b4df5da791696f6710b2ef9bc417dd90e`

## Finite question

Can the two clearest report-facing date-only projection consumers use `date.bqn` directly without changing YTD range construction, planned-payment observation dates, report output, or structured output?

## Selected group

- `src_next/ytd_summary.bqn`;
- `src_next/planned_payments.bqn`.

Both modules imported `projection.bqn`, but every qualified projection call was either:

- `IsValidDateText`;
- `DaysFromEpoch`.

Neither module consumed Layer constants, Posting IR helpers, proof helpers, source mapping, or `ResolveDayFromCycle`. They therefore form a coherent low-risk report-facing group whose projection imports are forwarding dependencies only.

## P3c change

- import `date.bqn` directly in both modules;
- replace forwarded validation and epoch-coordinate calls;
- remove the unused `projection.bqn` imports;
- extend the static ownership guard to keep these dependencies direct.

## Preserved

- YTD calendar-year range and Cube materialization inputs;
- planned-payment latest-Actual observation boundary;
- planned-payment compact, human, and JSON views;
- plan identity and completion ownership in `plan_rows.bqn` and `actual_source.bqn`;
- temporary projection date exports for remaining callers;
- accounting semantics, source formats, and private data boundaries.

## Later groups

Remaining callers should stay separated by ownership:

- low-level accounting/state hubs such as `tbds.bqn`;
- Actual source/admission modules such as `actual_source.bqn`;
- mixed projection-vocabulary modules that also use Layer, Posting IR, proof, or `ResolveDayFromCycle`;
- CLI and other report/query consumers.

P3c does not select or move those groups.
