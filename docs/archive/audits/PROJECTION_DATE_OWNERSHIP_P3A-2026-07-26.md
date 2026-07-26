# projection date ownership P3a — 2026-07-26

Status: implementation evidence
Owner: date / projection dependency boundary
Baseline: `adc65236c0de800efacb743ce8fb910233a602bb`

## Finite question

Can the clearest existing direct-date consumers stop reaching `IsValidDateText` and `DaysFromEpoch` through `projection.bqn` without changing date behavior, cycle semantics, Actual snapshot semantics, or report output?

## Caller observation

Repository search on the baseline found forwarded projection-date usage across 21 runtime modules and 4 focused tests. The migration is therefore intentionally staged rather than performed as one mass path rewrite.

The first group is:

- `src_next/cycle.bqn`;
- `src_next/actual_snapshot.bqn`;
- `tests/test_src_next_date.bqn`.

Both runtime modules already import `date.bqn`. Their forwarded calls are dependency noise rather than compatibility necessities. The focused date test should test the date owner directly instead of preserving projection aliases as a contract.

`src_next/actual_comparison.bqn` also already imports `date.bqn`, but it is a larger report-facing module and remains for a separate bounded group.

## P3a change

- replace `proj.IsValidDateText` with the existing direct date import;
- replace `proj.DaysFromEpoch` with the existing direct date import;
- keep non-date `projection.bqn` uses unchanged;
- remove projection alias assertions/import from the focused date test;
- add a static boundary guard for these completed paths.

## Preserved

- `date.bqn` implementations and exports;
- `projection.ResolveDayFromCycle`;
- cycle half-open interval meaning;
- Actual snapshot observation and rejected-evidence behavior;
- Posting IR, Cube, TBDS, reports, source formats, and private data boundaries.

## Next bounded group

Move the remaining already-direct date consumer `actual_comparison.bqn`, then characterize modules that import `projection.bqn` only or primarily for forwarded date functions before adding new direct imports.
