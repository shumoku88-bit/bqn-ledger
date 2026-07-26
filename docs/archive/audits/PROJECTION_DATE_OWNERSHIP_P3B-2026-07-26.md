# projection date ownership P3b — 2026-07-26

Status: implementation evidence
Owner: date / Actual Comparison dependency boundary
Baseline: `01bf5b9752eb8f02af0d0daf9b48487c3917bf92`

## Finite question

Can `actual_comparison.bqn`, the remaining runtime module that already imports `date.bqn`, stop reaching date validation and epoch coordinates through `projection.bqn` without changing comparison periods, diagnostics, TBDS inputs, or report output?

## Observation

`actual_comparison.bqn` imported both `projection.bqn` and `date.bqn`. Every qualified projection use was one of:

- `projection.IsValidDateText`;
- `projection.DaysFromEpoch`.

No Layer, Posting IR helper, proof helper, or other projection field was consumed. The projection dependency was therefore a date-forwarding dependency only.

## P3b change

- replace all forwarded date validation and epoch calls with the existing `dt` import;
- remove the now-unused `projection.bqn` import;
- extend the static ownership guard to include Actual Comparison;
- keep the temporary projection date exports for remaining callers.

## Preserved

- current and baseline comparison-window construction;
- previous income-anchor selection;
- rejected-Actual evidence applicability;
- local TBDS period construction;
- machine and human report formatting;
- source formats, accounting semantics, and private data boundaries.

## Next direction

The easy already-importing group is complete. Remaining callers should now be grouped by coherent responsibility before adding direct date imports. The next useful step is a caller inventory that distinguishes date-only projection dependencies from modules that also consume Posting IR, Layer, or proof vocabulary.
