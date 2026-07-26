# `projection.bqn` date ownership P3e — TBDS

Date: 2026-07-26
Status: implementation evidence for bounded P3e
Owner: TBDS materialization boundary
Canonical: no; current runtime modules and contracts remain authoritative

## Finite question

> Can `src_next/tbds.bqn` stop reaching date validation and epoch coordinates through `projection.bqn` without changing Trial Balance Dataset period semantics, Layer aggregation, query helpers, or rendered output?

## Finding

Yes.

At baseline main `0c12ab470745f91c2da08b2cf9a82f1f4bdddf85`, `tbds.bqn` imported `projection.bqn` only for:

- `IsValidDateText`;
- `DaysFromEpoch`.

All Layer names, Layer counts, Layer indices, exact summation, and query behavior already came from `cube.bqn` or local TBDS logic. The module did not consume Posting IR field helpers, source mapping, proof authorization, or `ResolveDayFromCycle`.

The projection import was therefore a forwarded date dependency rather than part of TBDS materialization ownership.

## P3e change

- replace `projection.bqn` with a direct `date.bqn` import;
- call `date.IsValidDateText` for cycle-bound validation;
- call `date.DaysFromEpoch` for cycle bounds and Posting IR row coordinates;
- remove the unused projection import;
- extend `checks/check-projection-compatibility-exports.sh` so the forwarding dependency cannot silently return.

## Preserved boundaries

This slice does not change:

- valid Posting IR row admission;
- unavailable-cycle sentinel behavior;
- opening movement before period start;
- movement inside `[period_start, period_end_exclusive)`;
- closing = opening + movement;
- debit and credit movement separation;
- AccountKey, account metadata, Layer, and currency fields;
- TBDS row ordering or period identifiers;
- expense and income classification;
- query helper results;
- compact TBDS formatting;
- Cube, report, source format, currency policy, or private household data.

## Validation gate

The pull request must pass:

- `tests/test_src_next_tbds.bqn`;
- `tests/test_src_next_tbds_opening_before_cycle.bqn`;
- all TBDS-consuming report and snapshot checks;
- projection/date ownership guard;
- direct-import graph validation;
- `tools/check.sh`;
- Coverage;
- GitHub Actions.

## Remaining P3 shape

The temporary `projection.IsValidDateText` and `projection.DaysFromEpoch` exports remain for unmigrated callers.

Remaining callers now fall mainly into:

- CLI and query-view modules that use only date forwarding;
- mixed modules that also consume `FieldOrEmpty`, Layer constants, proof helpers, or `ResolveDayFromCycle`;
- Journal Posting IR modules where date validation and posting-coordinate construction should be separated deliberately.

P3e does not select or combine those later groups.
