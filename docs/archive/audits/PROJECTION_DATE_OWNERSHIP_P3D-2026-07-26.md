# `projection.bqn` date ownership P3d — Actual source

Date: 2026-07-26
Status: implementation evidence for bounded P3d
Owner: Actual source / shared Actual evidence
Canonical: no; current runtime modules and contracts remain authoritative

## Finite question

> Can `src_next/actual_source.bqn` stop reaching date validation and epoch coordinates through `projection.bqn` without changing Actual source selection, Journal admission, completion evidence, or cycle filtering?

## Finding

Yes.

At baseline main `837dede9ecbb2026d3da91ec624ce01040874ed5`, `actual_source.bqn` imported `projection.bqn` only for:

- `IsValidDateText`;
- `DaysFromEpoch`.

All qualified calls occurred inside `PlanIdsInCycle`. The module did not consume projection Layer constants, Posting IR field helpers, source mapping, proof authorization, or `ResolveDayFromCycle`. Actual-layer row selection already comes from `cube.layer_actual`.

The projection import was therefore a forwarded date dependency rather than part of Actual source ownership.

## P3d change

- replace `projection.bqn` with a direct `date.bqn` import;
- call `date.IsValidDateText` and `date.DaysFromEpoch` in `PlanIdsInCycle`;
- remove the unused projection import;
- extend `checks/check-projection-compatibility-exports.sh` so the forwarding dependency cannot silently return.

## Preserved boundaries

This slice does not change:

- configured Actual Journal selection;
- direct-path versus `data/` path resolution;
- parser profile selection;
- complete-source admission;
- fallback parsing when account metadata is unavailable;
- income-date extraction;
- completion-evidence identity or amounts;
- half-open cycle filtering in `PlanIdsInCycle`;
- Actual-layer row selection;
- source formats, metadata, currency policy, or private household data.

## Validation gate

The pull request must pass:

- Actual-source and plan-completion callers through the complete repository check;
- projection/date ownership guard;
- direct-import graph validation;
- `tools/check.sh`;
- Coverage;
- GitHub Actions.

## Remaining P3 shape

The temporary `projection.IsValidDateText` and `projection.DaysFromEpoch` exports remain for unmigrated callers.

The next candidates remain separate ownership slices:

- `tbds.bqn`, a high-fan-in materialization boundary with a date-only projection dependency;
- CLI and query-view modules such as `calc/main.bqn`, `snapshot.bqn`, and daily-flow/trend modules;
- mixed modules that also consume `FieldOrEmpty`, Layer constants, proof helpers, or `ResolveDayFromCycle`.

P3d does not select or combine those later groups.
