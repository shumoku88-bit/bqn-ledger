# Report Policy Resolution review observation — 2026-08-12

## Scope

Review `src/application/report_policy_resolution.bqn` as the pure application owner that resolves already-admitted `report.toml` query references against an explicit `latest` date and admitted Actual transaction dates.

## Characterization before production change

This owner has a real evaluation boundary: strict input validation must complete before any date ordinal calculation or symbolic query resolution. The previous focused test covered successful coordinates but did not fully pin that boundary or diagnostic order.

Before changing production code, the existing focused test was strengthened to prove:

- input diagnostics are ordered as Report-policy state, invalid `latest`, then invalid Actual journal dates in source order;
- any input diagnostic suppresses resolved report coordinates/counts;
- presentation shape remains available on an input-error result, matching admitted Report-policy shape;
- `latest` can resolve an otherwise admitted symbolic range into a reversed range;
- dynamic range diagnostics remain Profit and Loss, Daily Flow, Monthly Accounts order;
- range-error results retain the resolved coordinates that explain the error.

Characterization-only full CI passed before the production transformation.

## Production decision

Separate three different semantic relations rather than accumulating shared mutable state:

```text
admitted policy + latest + Actual date axis
  -> InputDiagnostics
  -> if invalid: FailureResult
  -> if valid: ResolveValid
       -> resolved report coordinates
       -> RangeDiagnostics
       -> result
```

`InputDiagnostics` derives policy/latest/journal diagnostics as distinct arrays and concatenates them in the existing public order.

`Resolve` uses a lazy branch. `ResolveValid` therefore cannot evaluate date ordinals when any input date is invalid.

`ResolveEnd`, `ResolveStart`, and `BeginningThrough` now select values directly rather than staging mutable results. `BeginningThrough` computes the journal ordinal axis once, masks dates through the resolved finish date, and lazily chooses the finish fallback when the eligible relation is empty.

`RangeDiagnostics` maps the three named dynamic ranges in semantic/public order. There is no diagnostic append hidden inside report-coordinate construction.

`FailureResult` explicitly publishes the same fail-closed blank coordinate shape as before, including admitted presentation policy and Daily Flow presentation width.

## Test and fixture classification

No fixture is introduced. This owner is pure and its laws are represented directly by small namespaces and date arrays in `tests/test_application_report_policy_resolution.bqn`.

The focused BQN test is the semantic law owner. Existing current-report profile integration checks remain end-to-end characterization of canonical Report policy + Actual date evidence + request construction.

## Protected boundaries

Unchanged:

- canonical Report-policy admission ownership;
- explicit `latest` application input;
- strict Gregorian date validation;
- `latest` and `beginning` meanings;
- `beginning` fallback to the resolved finish when no Actual transaction is eligible;
- Actual transaction date evidence and source order;
- diagnostic codes/messages/order;
- fail-closed input behavior;
- dynamic range validation order;
- presentation propagation;
- resolved coordinates retained on range errors;
- current-report request behavior;
- writer authority.
